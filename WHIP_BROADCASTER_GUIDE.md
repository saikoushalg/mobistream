# Flutter WHIP Broadcaster Implementation

## File: `lib/whip_broadcaster.dart`

```dart
import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

// Main WHIP Streamer Screen
class WHIPBroadcasterScreen extends StatefulWidget {
  const WHIPBroadcasterScreen({super.key});

  @override
  State<WHIPBroadcasterScreen> createState() => _WHIPBroadcasterScreenState();
}

class _WHIPBroadcasterScreenState extends State<WHIPBroadcasterScreen> {
  final _streamIdController = TextEditingController(text: 'cam1');
  final _serverIpController = TextEditingController(text: '192.168.1.45');

  bool _isStreaming = false;
  String _statusMessage = 'Ready to stream';

  @override
  void initState() {
    super.initState();
    _loadSettings();
    _initializeWakelock();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _streamIdController.text = prefs.getString('whip_stream_id') ?? 'cam1';
      _serverIpController.text = prefs.getString('whip_server_ip') ?? '192.168.1.45';
    });
  }

  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('whip_stream_id', _streamIdController.text);
    await prefs.setString('whip_server_ip', _serverIpController.text);
  }

  Future<void> _initializeWakelock() async {
    await WakelockPlus.enable();
  }

  void _toggleStreaming() {
    if (_isStreaming) {
      setState(() {
        _isStreaming = false;
        _statusMessage = 'Streaming stopped';
      });
    } else {
      _saveSettings();
      setState(() {
        _isStreaming = true;
        _statusMessage = 'Starting stream...';
      });
    }
  }

  @override
  void dispose() {
    _streamIdController.dispose();
    _serverIpController.dispose();
    WakelockPlus.disable();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('WHIP Broadcaster'),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
      ),
      body: _isStreaming
          ? WHIPStreamWidget(
              streamId: _streamIdController.text,
              serverIp: _serverIpController.text,
              onStatusChanged: (status) {
                setState(() {
                  _statusMessage = status;
                });
              },
              onStreamStopped: () {
                setState(() {
                  _isStreaming = false;
                });
              },
            )
          : _buildConfigScreen(),
    );
  }

  Widget _buildConfigScreen() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Icon(
            Icons.videocam,
            color: Colors.purple,
            size: 64,
          ),
          const SizedBox(height: 24),

          const Text(
            'WHIP Live Streaming',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),

          Text(
            _statusMessage,
            style: const TextStyle(
              fontSize: 14,
              color: Colors.white70,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),

          TextField(
            controller: _streamIdController,
            style: const TextStyle(color: Colors.white),
            decoration: _buildInputDecoration('Stream ID', 'e.g., cam1, cam2, cam3'),
          ),
          const SizedBox(height: 16),

          TextField(
            controller: _serverIpController,
            style: const TextStyle(color: Colors.white),
            decoration: _buildInputDecoration('Server IP', 'e.g., 192.168.1.45'),
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 24),

          FilledButton.icon(
            onPressed: _toggleStreaming,
            style: FilledButton.styleFrom(
              backgroundColor: Colors.purple,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            icon: const Icon(Icons.play_arrow, size: 24),
            label: const Text(
              'Start Streaming',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),

          const SizedBox(height: 24),

          _buildInfoCard(),
        ],
      ),
    );
  }

  InputDecoration _buildInputDecoration(String label, String hint) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: Colors.white70),
      hintText: hint,
      hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.38)),
      filled: true,
      fillColor: Colors.white.withValues(alpha: 0.1),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.2)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Colors.purple, width: 2),
      ),
    );
  }

  Widget _buildInfoCard() {
    final whipUrl = 'http://${_serverIpController.text}:8888/whip/${_streamIdController.text}';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.info_outline, color: Colors.purple, size: 20),
              SizedBox(width: 8),
              Text(
                'WHIP Endpoint',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            whipUrl,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 12,
              fontFamily: 'monospace',
            ),
          ),
        ],
      ),
    );
  }
}

// WHIP Stream Widget - handles actual WebRTC streaming
class WHIPStreamWidget extends StatefulWidget {
  final String streamId;
  final String serverIp;
  final Function(String) onStatusChanged;
  final VoidCallback onStreamStopped;

  const WHIPStreamWidget({
    super.key,
    required this.streamId,
    required this.serverIp,
    required this.onStatusChanged,
    required this.onStreamStopped,
  });

  @override
  State<WHIPStreamWidget> createState() => _WHIPStreamWidgetState();
}

class _WHIPStreamWidgetState extends State<WHIPStreamWidget> {
  MediaStream? _localStream;
  RTCPeerConnection? _peerConnection;
  bool _isConnected = false;
  String _connectionState = 'Connecting...';

  @override
  void initState() {
    super.initState();
    _initializeStream();
  }

  Future<void> _initializeStream() async {
    try {
      widget.onStatusChanged('Initializing camera...');

      // Get user media
      final constraints = {
        'audio': true,
        'video': {
          'mandatory': {
            'minWidth': '1280',
            'minHeight': '720',
            'minFrameRate': '30',
          },
          'facingMode': 'user',
          'optional': [
            {'minWidth': '1920'},
            {'minHeight': '1080'},
          ],
        },
      };

      _localStream = await navigator.mediaDevices.getUserMedia(constraints);
      widget.onStatusChanged('Camera initialized');

      // Create peer connection
      final configuration = <String, dynamic>{
        'iceServers': <dynamic>[], // No STUN for local network
      };

      _peerConnection = await createPeerConnection(configuration);

      // Add tracks
      if (_localStream != null) {
        _localStream!.getTracks().forEach((track) {
          _peerConnection!.addTrack(track, _localStream!);
        });
      }

      // Handle ICE candidates (no trickling for local WHIP)
      _peerConnection!.onIceCandidate = (candidate) {
        debugPrint('ICE candidate: ${candidate.candidate}');
      };

      // Handle ICE connection state
      _peerConnection!.onIceConnectionState = (state) {
        debugPrint('ICE connection state: $state');
        setState(() {
          _connectionState = state;
        });

        if (state == 'connected' || state == 'completed') {
          widget.onStatusChanged('Connected to MediaMTX server');
          setState(() {
            _isConnected = true;
          });
        } else if (state == 'failed' || state == 'disconnected') {
          widget.onStatusChanged('Connection failed');
        }
      };

      // Create offer
      widget.onStatusChanged('Creating WebRTC offer...');
      final offer = await _peerConnection!.createOffer();

      await _peerConnection!.setLocalDescription(offer);

      // Send WHIP POST request
      final whipUrl = 'http://${widget.serverIp}:8888/whip/${widget.streamId}';

      widget.onStatusChanged('Connecting to WHIP server...');

      final response = await http.post(
        Uri.parse(whipUrl),
        headers: {'Content-Type': 'application/sdp'},
        body: offer.sdp,
      );

      if (response.statusCode == 201) {
        // Set remote description
        final answer = RTCSessionDescription(response.body, 'answer');
        await _peerConnection!.setRemoteDescription(answer);

        widget.onStatusChanged('WHIP connection established!');
      } else {
        widget.onStatusChanged('WHIP request failed: ${response.statusCode}');
        debugPrint('WHIP error: ${response.body}');
      }
    } catch (e) {
      widget.onStatusChanged('Error: $e');
      debugPrint('Stream initialization error: $e');
    }
  }

  Future<void> _stopStream() async {
    await _localStream?.dispose();
    await _peerConnection?.close();
    widget.onStreamStopped();
  }

  @override
  void dispose() {
    _localStream?.dispose();
    _peerConnection?.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Camera preview
        if (_localStream != null)
          Center(
            child: AspectRatio(
              aspectRatio: 16 / 9,
              child: RTCVideoView(_localStream!),
            ),
          )
        else
          const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(color: Colors.purple),
                SizedBox(height: 16),
                Text(
                  'Initializing camera...',
                  style: TextStyle(color: Colors.white70),
                ),
              ],
            ),
          ),

        // Top status bar
        _buildTopBar(),

        // Connection status indicator
        _buildStatusIndicator(),

        // Bottom controls
        _buildBottomControls(),
      ],
    );
  }

  Widget _buildTopBar() {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: Container(
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
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Streaming',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        widget.streamId,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                if (_isConnected)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.green.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.green, width: 1),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.circle, color: Colors.green, size: 8),
                        SizedBox(width: 4),
                        Text(
                          'LIVE',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatusIndicator() {
    return Positioned(
      top: 80,
      left: 16,
      right: 16,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.7),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          _connectionState,
          style: const TextStyle(color: Colors.white70, fontSize: 12),
        ),
      ),
    );
  }

  Widget _buildBottomControls() {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
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
              icon: const Icon(Icons.stop, size: 24),
              label: const Text(
                'Stop Streaming',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
```

## Integration with Existing App

Add this to your `lib/main.dart`:

```dart
import 'package:flutter/material.dart';
import 'whip_broadcaster.dart';

void main() {
  runApp(const MobistreamWHIP());
}

class MobistreamWHIP extends StatelessWidget {
  const MobistreamWHIP({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Mobistream WHIP',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark(),
      home: const WHIPBroadcasterScreen(),
    );
  }
}
```

## OBS Setup Instructions

1. **Add Browser Source in OBS:**
   - Sources → + → Browser
   - Local File: Check the box
   - File: Select `whep_player.html`
   - Width: 1920, Height: 1080
   - **URL Parameters:** `?stream=cam1&server=192.168.1.45`

2. **For Multiple Cameras:**
   - Camera 1: Browser Source with `?stream=cam1`
   - Camera 2: Browser Source with `?stream=cam2`
   - Camera 3: Browser Source with `?stream=cam3`

## Usage Flow

1. **Start MediaMTX server** on your PC
2. **Open app on phone** → Enter stream ID (e.g., "cam1")
3. **Tap "Start Streaming"**
4. **In OBS** → Browser source will auto-connect via WHEP
5. **Video appears** with ultra-low latency!

## Troubleshooting

**Stream doesn't connect:**
- Verify MediaMTX is running: `curl http://localhost:8888`
- Check server IP is correct
- Ensure phone and PC on same network
- Check firewall allows port 8888

**Video appears but no audio:**
- Check microphone permissions in app
- Verify audio track is being sent in WebRTC
- Check OBS audio monitoring

**Connection drops:**
- The browser source auto-reconnects
- Check MediaMTX logs for errors
- Ensure stable WiFi connection
