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
              '''Use your phone as a wireless camera for OBS Studio using HTTP MJPEG streaming.

Simple, reliable streaming (100-800ms latency) - no cloud services needed!''',
              Icons.video_camera_front,
              theme,
            ),
            const SizedBox(height: 24),

            _buildSection(
              'HTTP MJPEG Streaming',
              '''Mobistream uses HTTP MJPEG streaming for simple, reliable video.

How it works:
• Your phone becomes an HTTP server
• OBS connects directly to your phone
• No cloud services needed
• Latency: 100-800ms (depending on network)''',
              Icons.info_outline,
              theme,
            ),
            const SizedBox(height: 24),

            _buildSection(
              'OBS Setup (HTTP MJPEG)',
              '''Step-by-Step:
1. In Mobistream, tap "Start Streaming"
2. Note the MJPEG URL displayed (e.g., http://192.168.1.100:9000/stream)
3. In OBS: Add Source → Media Source
4. Uncheck "Local File"
5. Input: Paste the MJPEG URL
6. Click OK
7. Video appears in OBS preview!

Tips:
• Works with any OBS version
• No special plugins needed
• Test URL in browser first''',
              Icons.settings,
              theme,
            ),
            const SizedBox(height: 24),

            _buildSection(
              'Multi-Camera Setup',
              '''Want multiple phones as cameras?

Each phone should select a different "Camera Number":
• Phone 1 → Camera 1 → Port 9000
• Phone 2 → Camera 2 → Port 9001
• Phone 3 → Camera 3 → Port 9002

Each phone will have its own MJPEG URL:
• Phone 1: http://192.168.1.100:9000/stream
• Phone 2: http://192.168.1.100:9001/stream
• Phone 3: http://192.168.1.100:9002/stream

In OBS, add multiple Media Sources, one for each camera.''',
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
