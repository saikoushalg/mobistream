import Flutter
import UIKit
import AVFoundation
import VideoToolbox

@main
@objc class AppDelegate: FlutterAppDelegate {
  private var rtspServer: RtspServer?
  private let METHOD_CHANNEL_NAME = "mobistream/rtsp"

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    setupMethodChannel()
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  private func setupMethodChannel() {
    guard let controller = window?.rootViewController as? FlutterViewController else {
      print("Failed to get FlutterViewController")
      return
    }

    let methodChannel = FlutterMethodChannel(name: METHOD_CHANNEL_NAME,
                                            binaryMessenger: controller.binaryMessenger)

    methodChannel.setMethodCallHandler { [weak self] (call: FlutterMethodCall, result: @escaping FlutterResult) in
      guard let self = self else {
        result(FlutterError(code: "UNAVAILABLE", message: "AppDelegate unavailable", details: nil))
        return
      }

      switch call.method {
      case "startRtspServer":
        guard let args = call.arguments as? [String: Any],
              let port = args["port"] as? Int,
              let width = args["width"] as? Int,
              let height = args["height"] as? Int,
              let fps = args["fps"] as? Int,
              let bitrate = args["bitrate"] as? Int else {
          result(FlutterError(code: "INVALID_ARGS", message: "Missing required arguments", details: nil))
          return
        }

        let cameraId = args["cameraId"] as? Int ?? 0

        self.startRtspServer(port: port, width: width, height: height, fps: fps, bitrate: bitrate, cameraId: cameraId) { success, actualPort in
          if success {
            result(["success": true, "port": actualPort as Any])
          } else {
            result(["success": false])
          }
        }

      case "stopRtspServer":
        self.stopRtspServer()
        result(nil)

      default:
        result(FlutterMethodNotImplemented)
      }
    }
  }

  private func startRtspServer(
    port: Int,
    width: Int,
    height: Int,
    fps: Int,
    bitrate: Int,
    cameraId: Int,
    completion: @escaping (Bool, Int?) -> Void
  ) {
    rtspServer = RtspServer(
      port: port,
      width: width,
      height: height,
      fps: fps,
      bitrate: bitrate,
      cameraId: cameraId
    )

    rtspServer?.start { success, actualPort in
      completion(success, actualPort)
    }
  }

  private func stopRtspServer() {
    rtspServer?.stop()
    rtspServer = nil
  }
}

// MARK: - RTSP Server

class RtspServer: NSObject {
  private var port: Int
  private var width: Int
  private var height: Int
  private var fps: Int
  private var bitrate: Int
  private var cameraId: Int

  private var captureSession: AVCaptureSession?
  private var videoOutput: AVCaptureVideoDataOutput?
  private var serverSocket: ServerSocket?
  private var isStreaming = false
  private var compressionSession: VTCompressionSessionRef?

  init(port: Int, width: Int, height: Int, fps: Int, bitrate: Int, cameraId: Int) {
    self.port = port
    self.width = width
    self.height = height
    self.fps = fps
    self.bitrate = bitrate
    self.cameraId = cameraId
    super.init()
  }

  func start(completion: @escaping (Bool, Int?) -> Void) {
    DispatchQueue.global(qos: .userInitiated).async { [weak self] in
      guard let self = self else {
        completion(false, nil)
        return
      }

      do {
        // Create server socket
        self.serverSocket = try ServerSocket(port: self.port)
        let actualPort = self.serverSocket?.port ?? self.port

        print("RTSP Server listening on port \(actualPort)")

        // Setup camera
        self.setupCamera { success in
          if success {
            self.isStreaming = true
            completion(true, actualPort)

            // Wait for client connections
            self.waitForClient()
          } else {
            completion(false, nil)
          }
        }
      } catch {
        print("Failed to start RTSP server: \(error)")
        completion(false, nil)
      }
    }
  }

  private func setupCamera(completion: @escaping (Bool) -> Void) {
    captureSession = AVCaptureSession()
    captureSession?.sessionPreset = .high

    // Get camera device
    guard let camera = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back) else {
      print("Failed to get camera")
      completion(false)
      return
    }

    do {
      let input = try AVCaptureDeviceInput(device: camera)

      if (captureSession?.canAddInput(input)) ?? false {
        captureSession?.addInput(input)
      }

      // Setup video output
      videoOutput = AVCaptureVideoDataOutput()
      videoOutput?.setSampleBufferDelegate(self, queue: DispatchQueue(label: "videoQueue"))

      if (captureSession?.canAddOutput(videoOutput!)) ?? false {
        captureSession?.addOutput(videoOutput!)
      }

      // Setup H.264 encoder
      setupEncoder()

      captureSession?.startRunning()
      completion(true)

    } catch {
      print("Failed to setup camera: \(error)")
      completion(false)
    }
  }

  private func setupEncoder() {
    let encoderSpecification: CFDictionary = [
      kVTCompressionPropertyKey_ProfileLevel: kVTProfileLevel_H264_Main_AutoLevel,
      kVTCompressionPropertyKey_RealTime: true,
      kVTCompressionPropertyKey_AllowFrameReordering: false
    ] as CFDictionary

    VTCompressionSessionCreate(
      allocator: kCFAllocatorDefault,
      width: width,
      height: height,
      codecType: kCMVideoCodecType_H264,
      encoderSpecification: encoderSpecification,
      imageBufferAttributes: nil,
      compressedDataAllocator: nil,
      outputCallback: compressionOutputCallback,
      refcon: Unmanaged.passUnretained(self).toOpaque(),
      compressionSessionOut: &compressionSession
    )

    if let session = compressionSession {
      VTSessionSetProperty(session, key: kVTCompressionPropertyKey_MaxKeyFrameInterval, value: Int32(fps) * 2)
      VTSessionSetProperty(session, key: kVTCompressionPropertyKey_AverageBitRate, value: bitrate)
      VTCompressionSessionPrepareToEncodeFrames(session)
    }
  }

  private let compressionOutputCallback: VTCompressionOutputCallback = { (
    outputCallbackRefCon,
    sourceFrameRefCon,
    status,
    infoFlags,
    sampleBuffer
  ) in
    guard let sampleBuffer = sampleBuffer else {
      return
    }

    // In a real implementation, you would packetize this as RTP and send via RTSP
    // For now, this is a placeholder
    print("Encoded frame: \(sampleBuffer)")
  }

  private func waitForClient() {
    guard let socket = serverSocket else { return }

    while isStreaming {
      do {
        let clientSocket = try socket.acceptClient()
        print("RTSP client connected: \(clientSocket.address)")

        // Handle RTSP handshake
        handleRtspClient(clientSocket)
      } catch {
        if isStreaming {
          print("Error accepting client: \(error)")
        }
      }
    }
  }

  private func handleRtspClient(_ client: ClientSocket) {
    // Simple RTSP handshake
    if let request = client.readRequest(),
       request.hasPrefix("SETUP") || request.hasPrefix("OPTIONS") {

      let response = """
      RTSP/1.0 200 OK
      CSeq: 1
      Transport: RTP/AVP;unicast;client_port=5000-5001
      Session: 123456

      """

      client.write(response)
      client.close()
    }
  }

  func stop() {
    isStreaming = false

    captureSession?.stopRunning()
    captureSession = nil

    if let session = compressionSession {
      VTCompressionSessionInvalidate(session)
      compressionSession = nil
    }

    serverSocket?.close()
    serverSocket = nil
  }
}

// MARK: - AVCaptureVideoDataOutputSampleBufferDelegate

extension RtspServer: AVCaptureVideoDataOutputSampleBufferDelegate {
  func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
    // Encode frame
    guard let imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else {
      return
    }

    if let session = compressionSession {
      VTCompressionSessionEncodeFrame(
        session,
        imageBuffer: imageBuffer,
        presentationTimeStamp: CMSampleBufferGetPresentationTimeStamp(sampleBuffer),
        duration: CMSampleBufferGetDuration(sampleBuffer),
        frameProperties: nil,
        sourceFrameRefcon: nil,
        infoFlagsOut: nil
      )
    }
  }
}

// MARK: - Simple Socket Implementations

class ServerSocket {
  private var fd: Int32 = -1
  var port: Int { 0 } // Placeholder

  init(port: Int) throws {
    // Placeholder - would use POSIX sockets or Network framework
  }

  func acceptClient() throws -> ClientSocket {
    // Placeholder
    return ClientSocket(fd: 0, address: "")
  }

  func close() {
    if fd != -1 {
      close(fd)
      fd = -1
    }
  }
}

class ClientSocket {
  private var fd: Int32
  let address: String

  init(fd: Int32, address: String) {
    self.fd = fd
    self.address = address
  }

  func readRequest() -> String? {
    // Placeholder
    return nil
  }

  func write(_ string: String) {
    // Placeholder
  }

  func close() {
    if fd != -1 {
      Darwin.close(fd)
      fd = -1
    }
  }
}
