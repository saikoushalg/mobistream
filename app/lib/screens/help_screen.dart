import 'package:flutter/material.dart';

/// Help screen with OBS setup instructions for RTSP streaming.
class HelpScreen extends StatelessWidget {
  const HelpScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: Colors.grey[900],
      appBar: AppBar(
        title: const Text('Setup Guide'),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSection(
              'Welcome to Mobistream!',
              '''Use your phone as a wireless camera for OBS Studio using WebRTC streaming.

Low latency (<200ms) video and audio streaming to OBS via MediaMTX!''',
              Icons.video_camera_front,
              theme,
            ),
            const SizedBox(height: 24),

            _buildSection(
              'WebRTC Streaming',
              '''Mobistream uses WebRTC and MediaMTX for high-quality, low-latency video and audio.

How it works:
• You run MediaMTX on your computer (same as OBS)
• Your phone streams to MediaMTX using WHIP
• OBS pulls the stream from MediaMTX using WHEP
• No cloud services needed, works over local network''',
              Icons.info_outline,
              theme,
            ),
            const SizedBox(height: 24),

            _buildSection(
              'OBS Setup (WHEP)',
              '''Step-by-Step:
1. Run MediaMTX on your PC (port 8889)
2. In Mobistream, enter your PC's IP address
3. Tap "Start Streaming"
4. In OBS: Add Source → Browser Source
5. URL: Paste the WHEP URL displayed (e.g., http://192.168.1.5:8889/cam1/whep)
6. Width/Height: Set according to selected quality
7. Click OK
8. Video appears in OBS preview!

Tips:
• MediaMTX must be running before you start streaming
• Ensure your firewall allows MediaMTX ports (8889)''',
              Icons.settings,
              theme,
            ),
            const SizedBox(height: 24),

            _buildSection(
              'Multi-Camera Setup',
              '''Want multiple phones as cameras?

Each phone should have a different "Stream Name":
• Phone 1 → Stream Name: "cam1"
• Phone 2 → Stream Name: "cam2"

Each phone will have its own WHEP URL:
• Phone 1: http://192.168.1.5:8889/cam1/whep
• Phone 2: http://192.168.1.5:8889/cam2/whep

In OBS, add multiple Browser Sources, one for each camera.''',
              Icons.devices,
              theme,
            ),
            const SizedBox(height: 24),

            _buildSection(
              'Quality Presets',
              '''Good (720p, 30fps, 2Mbps)
   Best for most devices and networks

Better (1080p, 30fps, 4Mbps)
   For mid-range phones and fast WiFi

Best (1080p, 60fps, 8Mbps)
   For flagship phones on 5GHz WiFi only''',
              Icons.high_quality,
              theme,
            ),
            const SizedBox(height: 24),

            _buildSection(
              'Troubleshooting',
              '''Connection issues?
• Ensure phone and PC are on same WiFi network
• Check firewall allows connections on port 9000-9007
• Try 5GHz WiFi for better performance

Video not showing?
• Test MJPEG URL in browser first
• Check URL matches exactly
• Restart Mobistream and OBS

High latency?
• Use 5GHz WiFi instead of 2.4GHz
• Move closer to router
• Lower quality setting

Camera preview not working?
• Check camera permissions in Settings
• Restart the app
• Try closing other camera apps''',
              Icons.troubleshoot,
              theme,
            ),
            const SizedBox(height: 24),

            _buildSection(
              'Requirements',
              '''• OBS Studio (any version)
• Phone and computer on same WiFi network
• WiFi: 5GHz recommended for best quality
• iOS 14+ or Android 5.0+''',
              Icons.check_circle,
              theme,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(String title, String content, IconData icon, ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: theme.colorScheme.primary, size: 28),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: theme.textTheme.titleLarge?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            content,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: Colors.white70,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}
