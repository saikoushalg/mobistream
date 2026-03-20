import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../config/stream_config.dart';
import '../services/stream_service.dart';
import '../services/whip_stream_service.dart';
import 'camera_settings_screen.dart';
import 'help_screen.dart';

/// Main screen with camera preview and streaming controls.
class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  final WHIPStreamService _streamService = WHIPStreamService();

  StreamState _streamState = StreamState.idle;
  String? _currentCameraName;

  @override
  void initState() {
    super.initState();
    _initialize();
    _streamService.stateStream.listen(_onStreamStateChanged);
  }

  Future<void> _initialize() async {
    // Get camera name
    final prefs = await SharedPreferences.getInstance();
    _currentCameraName = prefs.getString('camera_name') ?? 'Camera';
    setState(() {});

    // Enable wakelock to keep screen on
    await WakelockPlus.enable();
  }

  void _onStreamStateChanged(StreamState state) {
    setState(() {
      _streamState = state;
    });
  }

  Future<void> _startStream() async {
    try {
      await _streamService.startStream(
        port: 8080,
        config: StreamConfig.good,
        cameraNumber: 1,
      );
    } catch (e) {
      _showError('Failed to start stream: $e');
    }
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
          // Video preview placeholder
          if (_streamState == StreamState.streaming)
            Container(
              color: Colors.black,
              child: const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.videocam,
                      color: Colors.purple,
                      size: 64,
                    ),
                    SizedBox(height: 16),
                    Text(
                      'Streaming to OBS',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Check your OBS preview',
                      style: TextStyle(
                        color: Colors.white60,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else if (_streamState == StreamState.starting)
            Container(
              color: Colors.black,
              child: const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(color: Colors.purple),
                    SizedBox(height: 16),
                    Text(
                      'Connecting...',
                      style: TextStyle(color: Colors.white54),
                    ),
                  ],
                ),
              ),
            )
          else
            Container(
              color: Colors.black,
              child: const Center(
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

          // Streaming controls (shown when streaming)
          if (_streamState == StreamState.streaming)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: _buildStreamingControls(),
            ),

          // Start stream button (shown when idle)
          if (_streamState == StreamState.idle)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: _buildIdleControls(),
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
              // App title and camera name
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Mobistream',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (_currentCameraName != null)
                      Text(
                        '$_currentCameraName',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                        ),
                      ),
                  ],
                ),
              ),

              // Settings, help, and stop buttons
              Row(
                children: [
                  // Stop button when streaming (always visible in top bar)
                  if (_streamState == StreamState.streaming)
                    FilledButton.icon(
                      onPressed: _stopStream,
                      style: FilledButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                      icon: const Icon(Icons.stop, size: 18),
                      label: const Text('Stop', style: TextStyle(fontSize: 14)),
                    ),

                  // Settings button (only when not streaming)
                  if (_streamState != StreamState.streaming)
                    IconButton(
                      icon: const Icon(Icons.settings, color: Colors.white, size: 24),
                      onPressed: () async {
                        final result = await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const CameraSettingsScreen(),
                          ),
                        );
                        if (result != null && result is bool && result) {
                          // Reload camera name
                          final prefs = await SharedPreferences.getInstance();
                          setState(() {
                            _currentCameraName = prefs.getString('camera_name') ?? 'Camera';
                          });
                        }
                      },
                    ),

                  // Help button
                  IconButton(
                    icon: const Icon(Icons.help_outline, color: Colors.white, size: 24),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const HelpScreen()),
                      );
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStreamingControls() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.bottomCenter,
          end: Alignment.topCenter,
          colors: [
            Colors.black.withValues(alpha: 0.9),
            Colors.transparent,
          ],
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Streaming indicator
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.green.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.green, width: 1),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: Colors.green,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'LIVE',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Stop button
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: _stopStream,
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  icon: const Icon(Icons.stop),
                  label: const Text(
                    'Stop Streaming',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildIdleControls() {
    final streamUrl = _streamService.getObsStreamUrl('', 8080);

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.bottomCenter,
          end: Alignment.topCenter,
          colors: [
            Colors.black.withValues(alpha: 0.9),
            Colors.transparent,
          ],
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Stream URL display
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.white24, width: 1),
                ),
                child: Column(
                  children: [
                    const Text(
                      'WHIP Stream URL:',
                      style: TextStyle(color: Colors.white70, fontSize: 12),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      streamUrl,
                      style: const TextStyle(
                        color: Colors.white,
                        fontFamily: 'monospace',
                        fontSize: 14,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                      icon: const Icon(Icons.copy, size: 16),
                      label: const Text('Copy URL'),
                      onPressed: () {
                        Clipboard.setData(ClipboardData(text: streamUrl));
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('URL copied to clipboard'),
                            duration: Duration(seconds: 2),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Start stream button
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: _startStream,
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.purple,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  icon: const Icon(Icons.play_arrow),
                  label: const Text(
                    'Start Stream',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
