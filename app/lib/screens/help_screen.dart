import 'package:flutter/material.dart';

/// Help screen with OBS setup instructions for WHIP streaming.
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
              '''Use your phone as a wireless camera for OBS Studio using WHIP streaming.

Simple, reliable streaming (10-100ms latency) - no cloud services needed!''',
              Icons.video_camera_front,
              theme,
            ),
            const SizedBox(height: 24),

            _buildSection(
              'WHIP Streaming',
              '''Mobistream uses WHIP (WebRTC-HTTP ingestion protocol) for ultra-low latency streaming.

How it works:
• Your phone streams via WHIP protocol
• OBS 30+ connects directly using native WHIP support
• No browser sources needed
• Direct P2P connection
• Latency: 10-100ms (depending on network)''',
              Icons.info_outline,
              theme,
            ),
            const SizedBox(height: 24),

            _buildSection(
              'OBS Setup (WHIP)',
              '''Step-by-Step:
1. Start the WHIP server (run whip_server.exe)
2. In Mobistream, set your camera name (e.g., "Main")
3. Tap "Start Stream"
4. Copy the WHIP URL displayed (e.g., http://localhost:8080/whip/Main)
5. In OBS 30+: Sources → + → WHIP
6. Paste the WHIP URL
7. Click OK
8. Video appears in OBS preview!

Tips:
• Requires OBS Studio 30.0 or higher
• No browser source needed
• Native WHIP support in OBS
• Direct WebRTC connection''',
              Icons.settings,
              theme,
            ),
            const SizedBox(height: 24),

            _buildSection(
              'Multi-Camera Setup',
              '''Want multiple phones as cameras?

Each phone should use a unique camera name:
• Phone 1 → Name: "Main" → URL: /whip/Main
• Phone 2 → Name: "Wide" → URL: /whip/Wide
• Phone 3 → Name: "Close" → URL: /whip/Close

Each phone will have its own WHIP URL:
• Phone 1: http://localhost:8080/whip/Main
• Phone 2: http://localhost:8080/whip/Wide
• Phone 3: http://localhost:8080/whip/Close

In OBS, add multiple WHIP sources, one for each camera. Switch between them using scenes!''',
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
• Ensure WHIP server is running (whip_server.exe)
• Check for "🚀 WHIP Server starting" message
• Ensure phone and PC are on same network
• Try 5GHz WiFi for better performance

Video not showing?
• Check WHIP server logs for errors
• Verify OBS version is 30.0+
• Test WHIP URL: curl http://localhost:8080/health
• Refresh WHIP source in OBS

High latency?
• Use 5GHz WiFi instead of 2.4GHz
• Move closer to router
• Check network congestion

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
              '''• OBS Studio 30.0 or higher (for WHIP support)
• WHIP server running on PC (whip_server.exe)
• Phone and computer on same network
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
