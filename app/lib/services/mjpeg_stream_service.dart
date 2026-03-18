import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:camera/camera.dart';
import 'package:permission_handler/permission_handler.dart';
import '../config/stream_config.dart';
import 'stream_service.dart';
import 'network_info.dart';

/// HTTP MJPEG streaming service using Flutter camera package.
/// Serves MJPEG stream over HTTP that OBS can connect to directly.
class MjpegStreamService implements StreamService {
  // State management
  final StreamController<StreamState> _stateController =
      StreamController<StreamState>.broadcast();
  StreamState _currentState = StreamState.idle;

  // Camera and server
  CameraController? _cameraController;
  HttpServer? _httpServer;
  int _serverPort = 0;
  final List<HttpRequest> _clients = [];

  // Configuration
  String _phoneIp = '';
  late StreamConfig _currentConfig;
  Timer? _streamTimer;
  bool _isCapturing = false;

  // MJPEG boundary marker
  static const String _boundary = 'mjpegstream';
  static const String _contentType = 'multipart/x-mixed-replace; boundary=$_boundary';

  @override
  Stream<StreamState> get stateStream => _stateController.stream;

  @override
  StreamState get currentState => _currentState;

  CameraController? get cameraController => _cameraController;

  @override
  Future<void> startStream({
    required int port,
    required StreamConfig config,
    int cameraNumber = 1,
  }) async {
    if (_currentState == StreamState.streaming) return;

    _setState(StreamState.starting);
    _currentConfig = config;

    try {
      // 1. Request permissions
      final hasPermissions = await _requestPermissions();
      if (!hasPermissions) {
        _setState(StreamState.error);
        return;
      }

      // 2. Get IP address
      final networkInfoService = NetworkInfoService();
      final networkInfo = await networkInfoService.getConnectionInfo();
      if (networkInfo == null) {
        debugPrint('MjpegStreamService: Failed to get network info');
        _setState(StreamState.error);
        return;
      }
      _phoneIp = networkInfo.ipAddress;

      // 3. Initialize camera
      await _initializeCamera();

      // 4. Start HTTP server
      await _startHttpServer(port);

      // 5. Start streaming frames
      _startStreaming();

      // 6. Server is ready
      _setState(StreamState.streaming);

      debugPrint('MjpegStreamService: Streaming at '
          'http://$_phoneIp:$_serverPort/stream');
    } catch (e) {
      debugPrint('MjpegStreamService: Start error - $e');
      _setState(StreamState.error);
      await _cleanupResources();
    }
  }

  Future<bool> _requestPermissions() async {
    final cameraStatus = await Permission.camera.request();
    if (!cameraStatus.isGranted) {
      debugPrint('MjpegStreamService: Camera permission denied');
      return false;
    }

    final micStatus = await Permission.microphone.request();
    if (!micStatus.isGranted) {
      debugPrint('MjpegStreamService: Microphone permission denied');
      return false;
    }

    return true;
  }

  Future<void> _initializeCamera() async {
    // Get available cameras
    final cameras = await availableCameras();
    if (cameras.isEmpty) {
      throw Exception('No cameras available');
    }

    // Use back camera by default
    final cameraDescription = cameras.firstWhere(
      (cam) => cam.lensDirection == CameraLensDirection.back,
      orElse: () => cameras.first,
    );

    // Create camera controller
    _cameraController = CameraController(
      cameraDescription,
      ResolutionPreset.high,
      enableAudio: false,
      imageFormatGroup: Platform.isAndroid
          ? ImageFormatGroup.jpeg
          : ImageFormatGroup.bgra8888,
    );

    await _cameraController!.initialize();
    debugPrint('MjpegStreamService: Camera initialized');
  }

  Future<void> _startHttpServer(int port) async {
    _httpServer = await HttpServer.bind('0.0.0.0', port);
    _serverPort = _httpServer!.port;

    // Handle incoming connections
    _httpServer!.listen((HttpRequest request) {
      if (request.uri.path == '/stream') {
        _handleStreamClient(request);
      } else if (request.uri.path == '/health') {
        request.response
          ..statusCode = HttpStatus.ok
          ..write('OK')
          ..close();
      } else {
        request.response
          ..statusCode = HttpStatus.notFound
          ..close();
      }
    });

    debugPrint('MjpegStreamService: HTTP server listening on port $_serverPort');
  }

  void _handleStreamClient(HttpRequest request) {
    debugPrint('MjpegStreamService: Client connected: ${request.connectionInfo!.remoteAddress}');

    // Set multipart response headers
    request.response.headers.contentType = ContentType.parse(_contentType);
    request.response.headers.chunkedTransferEncoding = false;
    request.response.bufferOutput = false;

    _clients.add(request);

    // Handle client disconnect
    request.response.done.catchError((_) {
      _clients.remove(request);
      debugPrint('MjpegStreamService: Client disconnected');
    });
  }

  void _startStreaming() {
    // Stream at target FPS
    final interval = 1000 ~/ _currentConfig.fps;

    _streamTimer = Timer.periodic(Duration(milliseconds: interval), (_) async {
      if (_cameraController == null || !_cameraController!.value.isInitialized) {
        return;
      }

      // Skip if already capturing
      if (_isCapturing) {
        return;
      }

      // Capture frame
      _isCapturing = true;
      try {
        final image = await _cameraController!.takePicture();
        final bytes = await image.readAsBytes();

        // Send to all connected clients
        final deadClients = <HttpRequest>[];
        for (final client in _clients) {
          try {
            final response = client.response;
            // Write boundary
            response.write('--$_boundary\r\n');
            response.write('Content-Type: image/jpeg\r\n');
            response.write('Content-Length: ${bytes.length}\r\n\r\n');

            // Write image data
            response.add(bytes);
            response.write('\r\n');
          } catch (e) {
            deadClients.add(client);
          }
        }

        // Remove dead clients
        for (final client in deadClients) {
          _clients.remove(client);
          try {
            client.response.close();
          } catch (_) {}
        }
      } catch (e) {
        debugPrint('MjpegStreamService: Frame capture error - $e');
      } finally {
        _isCapturing = false;
      }
    });
  }

  void _setState(StreamState state) {
    _currentState = state;
    _stateController.add(state);
  }

  @override
  Future<void> stopStream() async {
    if (_currentState == StreamState.idle) return;

    debugPrint('MjpegStreamService: Stopping stream');
    await _cleanupResources();
    _setState(StreamState.idle);
  }

  Future<void> _cleanupResources() async {
    // Stop streaming timer
    _streamTimer?.cancel();
    _streamTimer = null;

    // Close all client connections
    for (final client in _clients) {
      try {
        client.response.close();
      } catch (_) {}
    }
    _clients.clear();

    // Close HTTP server
    await _httpServer?.close();
    _httpServer = null;

    // Dispose camera
    await _cameraController?.dispose();
    _cameraController = null;

    debugPrint('MjpegStreamService: Resources cleaned up');
  }

  @override
  Future<void> dispose() async {
    await _cleanupResources();
    await _stateController.close();
  }

  @override
  String getObsStreamUrl(String phoneIp, int port) {
    return 'http://$phoneIp:$port/stream';
  }
}
