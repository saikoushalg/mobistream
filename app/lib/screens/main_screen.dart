import 'dart:async';
import 'package:flutter/material.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import '../config/stream_config.dart';
import '../config/app_constants.dart';
import '../services/network_info.dart';
import '../services/stream_service.dart';
import '../services/webrtc_stream_service.dart';
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
  final WebRtcStreamService _streamService = WebRtcStreamService();

  StreamSelection _selection = const StreamSelection(
    cameraNumber: AppConstants.defaultCameraNumber,
    quality: StreamConfig.good,
    streamName: 'cam1',
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
    await _streamService.initializeRenderer();

    // Get network info
    final networkInfo = await _networkInfoService.getConnectionInfo();
    if (networkInfo == null) {
      _showError('Failed to get WiFi IP. Please check your connection.');
      return;
    }

    setState(() {
      _networkInfo = networkInfo;
    });

    // Try auto-discovery
    _discoverMediaMtx();

    // Enable wakelock to keep screen on
    await WakelockPlus.enable();
  }

  Future<void> _discoverMediaMtx() async {
    final ip = await _networkInfoService.discoverMediaMtx();
    if (ip != null && mounted) {
      setState(() {
        _selection = _selection.copyWith(mediaMtxIp: ip);
      });
      _showSuccess('MediaMTX discovered at $ip');
    }
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

    if (_selection.mediaMtxIp.isEmpty) {
      _showError('Please enter MediaMTX IP address');
      return;
    }

    await _streamService.startStream(
      port: AppConstants.mediaMtxWhipPort,
      config: _selection.quality,
      cameraNumber: _selection.cameraNumber,
      mediaMtxIp: _selection.mediaMtxIp,
      streamName: _selection.streamName,
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

  void _showSuccess(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
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
          // Camera preview using WebRTC renderer
          if (_streamService.localRenderer != null &&
              _streamService.localRenderer!.srcObject != null)
            Positioned.fill(
              child: RTCVideoView(
                _streamService.localRenderer!,
                objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
              ),
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
                ipAddress: _selection.mediaMtxIp,
                port: 8889, // Default MediaMTX WHEP/HLS/etc port
                streamName: _selection.streamName,
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
                    _selection = _selection.copyWith(
                      cameraNumber: cameraNumber,
                      streamName: 'cam$cameraNumber',
                    );
                  });
                },
                onQualityChanged: (quality) {
                  setState(() {
                    _selection = _selection.copyWith(quality: quality);
                  });
                },
                onMediaMtxIpChanged: (ip) {
                  setState(() {
                    _selection = _selection.copyWith(mediaMtxIp: ip);
                  });
                },
                onStreamNameChanged: (name) {
                  setState(() {
                    _selection = _selection.copyWith(streamName: name);
                  });
                },
                onDiscover: _discoverMediaMtx,
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
