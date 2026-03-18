/// Stream quality configuration presets.
class StreamConfig {
  final String name;
  final int resolutionWidth;
  final int resolutionHeight;
  final int videoBitrate;
  final int audioBitrate;
  final int fps;

  const StreamConfig({
    required this.name,
    required this.resolutionWidth,
    required this.resolutionHeight,
    required this.videoBitrate,
    required this.audioBitrate,
    required this.fps,
  });

  /// Good quality - balanced for most devices and networks
  static const StreamConfig good = StreamConfig(
    name: "Good",
    resolutionWidth: 720,
    resolutionHeight: 1280,
    videoBitrate: 2000000, // 2 Mbps
    audioBitrate: 128000, // 128 kbps
    fps: 30,
  );

  /// Better quality - for faster networks and mid-range devices
  static const StreamConfig better = StreamConfig(
    name: "Better",
    resolutionWidth: 1080,
    resolutionHeight: 1920,
    videoBitrate: 4000000, // 4 Mbps
    audioBitrate: 192000, // 192 kbps
    fps: 30,
  );

  /// Best quality - requires 5GHz WiFi and flagship device
  static const StreamConfig best = StreamConfig(
    name: "Best",
    resolutionWidth: 1080,
    resolutionHeight: 1920,
    videoBitrate: 8000000, // 8 Mbps
    audioBitrate: 192000, // 192 kbps
    fps: 60,
  );

  /// All available quality presets
  static const List<StreamConfig> all = [good, better, best];

  @override
  String toString() => name;
}
