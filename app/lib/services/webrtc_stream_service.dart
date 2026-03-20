import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:http/http.dart' as http;
import 'package:permission_handler/permission_handler.dart';
import '../config/stream_config.dart';
import 'stream_service.dart';

/// WebRTC streaming service using WHIP (WebRTC-HTTP Ingestion Protocol).
/// Streams video and audio to a MediaMTX server.
class WebRtcStreamService implements StreamService {
  // State management
  final StreamController<StreamState> _stateController =
      StreamController<StreamState>.broadcast();
  StreamState _currentState = StreamState.idle;

  // WebRTC components
  RTCPeerConnection? _peerConnection;
  MediaStream? _localStream;
  RTCVideoRenderer? _localRenderer;
  String? _whipResourceUrl;

  // Configuration
  String _mediaMtxIp = '';
  String _streamName = '';
  late StreamConfig _currentConfig;

  @override
  Stream<StreamState> get stateStream => _stateController.stream;

  @override
  StreamState get currentState => _currentState;

  RTCVideoRenderer? get localRenderer => _localRenderer;

  /// Initialize the renderer for local preview
  Future<void> initializeRenderer() async {
    if (_localRenderer == null) {
      _localRenderer = RTCVideoRenderer();
      await _localRenderer!.initialize();
    }

    // Auto-start preview if not already streaming
    if (_localStream == null) {
      await _startPreview();
    }
  }

  Future<void> _startPreview() async {
    try {
      final Map<String, dynamic> mediaConstraints = {
        'audio': false, // No audio for preview
        'video': {
          'mandatory': {
            'minWidth': '1280',
            'minHeight': '720',
            'minFrameRate': '30',
          },
          'facingMode': 'environment',
          'optional': [],
        }
      };

      _localStream = await navigator.mediaDevices.getUserMedia(mediaConstraints);
      if (_localRenderer != null) {
        _localRenderer!.srcObject = _localStream;
      }
    } catch (e) {
      debugPrint('WebRtcStreamService: Preview error - $e');
    }
  }

  @override
  Future<void> startStream({
    required int port, // MediaMTX WHIP port (default 8889)
    required StreamConfig config,
    int cameraNumber = 1,
    // Note: To match the StreamService interface, these are optional and
    // we'll use configuration from elsewhere if needed, or pass them in
    // as named parameters if we update the interface.
    String mediaMtxIp = '',
    String streamName = '',
  }) async {
    if (_currentState == StreamState.streaming) return;

    _setState(StreamState.starting);
    _currentConfig = config;
    _mediaMtxIp = mediaMtxIp;
    _streamName = streamName.isEmpty ? 'cam$cameraNumber' : streamName;

    if (_mediaMtxIp.isEmpty) {
      debugPrint('WebRtcStreamService: MediaMTX IP is required');
      _setState(StreamState.error);
      return;
    }

    try {
      // 1. Request permissions
      final hasPermissions = await _requestPermissions();
      if (!hasPermissions) {
        _setState(StreamState.error);
        return;
      }

      // 2. Setup WebRTC
      await _setupWebRtc();

      // 3. WHIP Signaling
      await _performWhipSignaling(port);

      // 4. Streaming started
      _setState(StreamState.streaming);
      debugPrint('WebRtcStreamService: Streaming to http://$_mediaMtxIp:$port/$_streamName');
    } catch (e) {
      debugPrint('WebRtcStreamService: Start error - $e');
      _setState(StreamState.error);
      await _cleanupResources();
    }
  }

  Future<bool> _requestPermissions() async {
    final cameraStatus = await Permission.camera.request();
    final micStatus = await Permission.microphone.request();
    return cameraStatus.isGranted && micStatus.isGranted;
  }

  Future<void> _setupWebRtc() async {
    // If preview is running, we need to stop it and restart with audio and proper constraints
    if (_localStream != null) {
      for (var track in _localStream!.getTracks()) {
        await track.stop();
      }
      await _localStream!.dispose();
      _localStream = null;
    }

    final Map<String, dynamic> mediaConstraints = {
      'audio': true,
      'video': {
        'mandatory': {
          'minWidth': _currentConfig.resolutionWidth.toString(),
          'minHeight': _currentConfig.resolutionHeight.toString(),
          'minFrameRate': _currentConfig.fps.toString(),
        },
        'facingMode': 'environment', // Use back camera by default
        'optional': [],
      }
    };

    _localStream = await navigator.mediaDevices.getUserMedia(mediaConstraints);

    if (_localRenderer != null) {
      _localRenderer!.srcObject = _localStream;
    }

    final Map<String, dynamic> configuration = {
      'iceServers': [], // MediaMTX handles ICE usually without STUN for local net
      'sdpSemantics': 'unified-plan',
    };

    _peerConnection = await createPeerConnection(configuration);

    // Add tracks to peer connection
    _localStream!.getTracks().forEach((track) {
      _peerConnection!.addTrack(track, _localStream!);
    });

    // We don't need to handle remote tracks for ingest
  }

  Future<void> _performWhipSignaling(int whipPort) async {
    // Create offer
    RTCSessionDescription offer = await _peerConnection!.createOffer({
      'offerToReceiveAudio': false,
      'offerToReceiveVideo': false,
    });
    await _peerConnection!.setLocalDescription(offer);

    // Send WHIP POST request
    final url = Uri.parse('http://$_mediaMtxIp:$whipPort/$_streamName/whip');
    debugPrint('WebRtcStreamService: Sending WHIP offer to $url');

    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/sdp',
      },
      body: offer.sdp,
    );

    if (response.statusCode == 201 || response.statusCode == 200) {
      debugPrint('WebRtcStreamService: WHIP offer accepted');

      // Extract resource URL for teardown (standard WHIP)
      final location = response.headers['location'];
      if (location != null) {
        if (location.startsWith('http')) {
          _whipResourceUrl = location;
        } else {
          _whipResourceUrl = 'http://$_mediaMtxIp:$whipPort$location';
        }
        debugPrint('WebRtcStreamService: WHIP resource URL: $_whipResourceUrl');
      }

      final answerSdp = response.body;
      RTCSessionDescription answer = RTCSessionDescription(answerSdp, 'answer');
      await _peerConnection!.setRemoteDescription(answer);
    } else {
      throw Exception('WHIP signaling failed: ${response.statusCode} ${response.body}');
    }
  }

  void _setState(StreamState state) {
    _currentState = state;
    _stateController.add(state);
  }

  @override
  Future<void> stopStream() async {
    if (_currentState == StreamState.idle) return;

    debugPrint('WebRtcStreamService: Stopping stream');
    await _cleanupResources();
    _setState(StreamState.idle);

    // Restart preview after stopping stream
    await _startPreview();
  }

  Future<void> _cleanupResources() async {
    // 1. Perform WHIP teardown if possible
    if (_whipResourceUrl != null) {
      try {
        debugPrint('WebRtcStreamService: Sending WHIP DELETE to $_whipResourceUrl');
        await http.delete(Uri.parse(_whipResourceUrl!));
      } catch (e) {
        debugPrint('WebRtcStreamService: WHIP DELETE error - $e');
      }
      _whipResourceUrl = null;
    }

    // 2. Clear renderer
    if (_localRenderer != null) {
      _localRenderer!.srcObject = null;
    }

    // 3. Stop all tracks and dispose stream
    if (_localStream != null) {
      for (var track in _localStream!.getTracks()) {
        await track.stop();
      }
      await _localStream!.dispose();
      _localStream = null;
    }

    // 4. Close peer connection
    await _peerConnection?.close();
    _peerConnection = null;

    debugPrint('WebRtcStreamService: Resources cleaned up');
  }

  @override
  Future<void> dispose() async {
    await _cleanupResources();
    await _localRenderer?.dispose();
    _localRenderer = null;
    await _stateController.close();
  }

  @override
  String getObsStreamUrl(String phoneIp, int port) {
    // MediaMTX WHEP URL (default port 8889)
    // OBS Browser source or WHEP source (if available)
    return 'http://$_mediaMtxIp:8889/$_streamName/whep';
  }
}
