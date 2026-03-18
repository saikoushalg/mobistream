/// Application-wide constants.
class AppConstants {
  // Prevent instantiation
  AppConstants._();

  /// Base SRT port for Camera 1
  static const int baseSrtPort = 9000;

  /// Maximum number of cameras supported
  static const int maxCameras = 8;

  /// Default quality preset
  static const int defaultQualityIndex = 0;

  /// Default camera number
  static const int defaultCameraNumber = 1;

  /// Get the SRT port for a given camera number (1-indexed)
  static int getPortForCamera(int cameraNumber) {
    if (cameraNumber < 1 || cameraNumber > maxCameras) {
      throw ArgumentError('Camera number must be between 1 and $maxCameras');
    }
    return baseSrtPort + (cameraNumber - 1);
  }

  /// SRT mode parameter - phone acts as listener (server)
  static const String srtMode = 'listener';

  /// SRT URL format template
  static const String srtUrlFormat = 'srt://{ip}:{port}?mode={mode}';
}
