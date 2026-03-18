import Flutter
import UIKit
import AVFoundation

/**
 * PlatformView factory for native camera preview surface on iOS.
 */
class CameraPreviewFactory: NSObject, FlutterPlatformViewFactory {
    private var messenger: FlutterBinaryMessenger

    init(messenger: FlutterBinaryMessenger) {
        self.messenger = messenger
        super.init()
    }

    func create(withFrame frame: CGRect,
               viewIdentifier viewId: Int64,
               arguments args: Any?) -> FlutterPlatformView {
        return CameraPreviewView(frame: frame, arguments: args)
    }

    func createArgsCodec() -> FlutterMessageCodec & NSObjectProtocol {
        return FlutterStandardMessageCodec.sharedInstance()
    }
}

/**
 * Native camera preview view using AVCaptureVideoPreviewLayer.
 */
class CameraPreviewView: NSObject, FlutterPlatformView {
    private var _view: UIView
    private var previewLayer: AVCaptureVideoPreviewLayer?
    private var arguments: [String: Any]?

    init(frame: CGRect, arguments: Any?) {
        _view = UIView(frame: frame)
        self.arguments = arguments as? [String: Any]
        super.init()

        setupView()
    }

    private func setupView() {
        _view.backgroundColor = UIColor.black

        // Create preview layer
        let previewLayer = AVCaptureVideoPreviewLayer()
        previewLayer.videoGravity = .resizeAspectFill
        _view.layer.addSublayer(previewLayer)
        self.previewLayer = previewLayer

        // Set frame
        previewLayer.frame = _view.bounds
    }

    func view() -> UIView {
        return _view
    }

    func dispose() {
        // Cleanup if needed
    }

    companion object {
        static let viewType = "com.stream.app/srt_camera_preview"
    }
}
