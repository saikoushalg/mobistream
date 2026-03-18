import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Native camera preview widget using platform views.
///
/// Displays the native camera surface from:
/// - Android: SurfaceView with Camera2 feed
/// - iOS: UIView with AVCaptureVideoPreviewLayer
///
/// This provides lower latency than the Flutter camera package
/// as it directly displays the encoder surface.
class NativeCameraPreview extends StatelessWidget {
  /// Camera type: 'front' or 'back'
  final String cameraType;

  const NativeCameraPreview({
    super.key,
    this.cameraType = 'back',
  });

  @override
  Widget build(BuildContext context) {
    // Use different platform view types based on platform
    if (defaultTargetPlatform == TargetPlatform.android) {
      return AndroidView(
        viewType: 'com.stream.app/srt_camera_preview',
        creationParams: {'cameraType': cameraType},
        creationParamsCodec: const StandardMessageCodec(),
        gestureRecognizers: const <Factory<OneSequenceGestureRecognizer>>{},
      );
    } else if (defaultTargetPlatform == TargetPlatform.iOS) {
      return UiKitView(
        viewType: 'com.stream.app/srt_camera_preview',
        creationParams: {'cameraType': cameraType},
        creationParamsCodec: const StandardMessageCodec(),
        gestureRecognizers: const <Factory<OneSequenceGestureRecognizer>>{},
      );
    }

    // Fallback for other platforms (web, desktop)
    return const ColoredBox(
      color: Colors.black,
      child: Center(
        child: Text(
          'Native camera preview not supported on this platform',
          style: TextStyle(color: Colors.white),
        ),
      ),
    );
  }
}
