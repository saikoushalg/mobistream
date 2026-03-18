import 'dart:async';
import 'package:flutter/material.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import 'package:camera/camera.dart';
import '../config/stream_config.dart';
import '../config/app_constants.dart';
import '../services/network_info.dart';
import '../services/stream_service.dart';
import '../services/mjpeg_stream_service.dart';
import '../widgets/ip_display.dart';
import '../widgets/stream_controls.dart';
import 'help_screen.dart';

/// Main screen with camera preview and streaming controls.
class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  final NetworkInfoService _networkInfoService = NetworkInfoService();
  final MjpegStreamService _streamService = MjpegStreamService();

  StreamSelection _selection = const StreamSelection(
    cameraNumber: AppConstants.defaultCameraNumber,
    quality: StreamConfig.good,
  );

  NetworkConnectionInfo? _networkInfo;
  StreamState _streamState = StreamState.idle;
  bool _showIpDisplay = false;

  @override
  void initState() {
    super.initState();
    _initialize();
    _streamService.stateStream.listen(_onStreamStateChanged);
  }

  Future<void> _initialize() async {
    // Get network info
    final networkInfo = await _networkInfoService.getConnectionInfo();
    if (networkInfo == null) {
      _showError('Failed to get WiFi IP. Please check your connection.');
      return;
    }

    setState(() {
      _networkInfo = networkInfo;
    });

    // Enable wakelock to keep screen on
    await WakelockPlus.enable();
  }

  void _onStreamStateChanged(StreamState state) {
    setState(() {
      _streamState = state;
    });

    if (state == StreamState.ready) {
      setState(() {
        _showIpDisplay = true;
      });
    } else if (state == StreamState.idle) {
      setState(() {
        _showIpDisplay = false;
      });
    }
  }

  Future<void> _startStream() async {
    if (_networkInfo == null) {
      _showError('No network connection');
      return;
    }

    final port = AppConstants.getPortForCamera(_selection.cameraNumber);
    await _streamService.startStream(
      port: port,
      config: _selection.quality,
      cameraNumber: _selection.cameraNumber,
    );
  }

  Future<void> _stopStream() async {
    await _streamService.stopStream();
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  @override
  void dispose() {
    _streamService.dispose();
    WakelockPlus.disable();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Camera preview using Flutter camera package
          if (_streamService.cameraController != null &&
              _streamService.cameraController!.value.isInitialized)
            Positioned.fill(
              child: CameraPreview(_streamService.cameraController!),
            )
          else if (_streamState == StreamState.starting)
            const ColoredBox(
              color: Colors.black,
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(color: Colors.white),
                    SizedBox(height: 16),
                    Text(
                      'Starting camera...',
                      style: TextStyle(color: Colors.white54),
                    ),
                  ],
                ),
              ),
            )
          else
            const ColoredBox(
              color: Colors.black,
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.videocam,
                      color: Colors.white24,
                      size: 64,
                    ),
                    SizedBox(height: 16),
                    Text(
                      'Ready to stream',
                      style: TextStyle(color: Colors.white54, fontSize: 16),
                    ),
                  ],
                ),
              ),
            ),

          // Top bar
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: _buildTopBar(),
          ),

          // IP display overlay (shown when streaming)
          if (_showIpDisplay)
            Positioned.fill(
              child: IPDisplayWidget(
                ipAddress: _networkInfo!.ipAddress,
                port: AppConstants.getPortForCamera(_selection.cameraNumber),
                onBack: () {
                  setState(() {
                    _showIpDisplay = false;
                  });
                },
              ),
            ),

          // Controls overlay (shown when not displaying IP)
          if (!_showIpDisplay)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: StreamControlsWidget(
                selection: _selection,
                onCameraNumberChanged: (cameraNumber) {
                  setState(() {
                    _selection = _selection.copyWith(cameraNumber: cameraNumber);
                  });
                },
                onQualityChanged: (quality) {
                  setState(() {
                    _selection = _selection.copyWith(quality: quality);
                  });
                },
                onStartStream: _startStream,
                onStopStream: _stopStream,
                isStreaming: _streamState == StreamState.streaming ||
                    _streamState == StreamState.ready,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTopBar() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.black.withValues(alpha: 0.7),
            Colors.transparent,
          ],
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // App title
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Mobistream',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (_networkInfo != null)
                    Text(
                      'IP: ${_networkInfo!.ipAddress}',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                      ),
                    ),
                ],
              ),

              // Help button
              IconButton(
                icon: Icon(Icons.help_outline, color: Colors.white, size: 28),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const HelpScreen()),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
