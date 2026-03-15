import AVFoundation
import UIKit
import Observation

@Observable
final class CameraService: NSObject, @unchecked Sendable {
    var isAuthorized = false
    var latestFrame: UIImage?

    @ObservationIgnored nonisolated(unsafe) private var captureSession: AVCaptureSession?
    @ObservationIgnored nonisolated(unsafe) private var videoOutput: AVCaptureVideoDataOutput?
    @ObservationIgnored private let ciContext = CIContext()
    @ObservationIgnored private let sessionQueue = DispatchQueue(
        label: "com.eyeguide.camera"
    )

    var isRunning: Bool {
        captureSession?.isRunning ?? false
    }

    func requestAuthorization() async {
        let status = AVCaptureDevice.authorizationStatus(for: .video)
        switch status {
        case .authorized:
            isAuthorized = true
        case .notDetermined:
            isAuthorized = await AVCaptureDevice.requestAccess(for: .video)
        default:
            isAuthorized = false
        }
    }

    nonisolated func startSession() {
        sessionQueue.async { [self] in
            configureAndStart()
        }
    }

    nonisolated func stopSession() {
        sessionQueue.async { [self] in
            captureSession?.stopRunning()
        }
    }

    nonisolated private func configureAndStart() {
        guard captureSession == nil else {
            captureSession?.startRunning()
            return
        }

        let session = AVCaptureSession()
        session.sessionPreset = .high

        guard let device = AVCaptureDevice.default(
            .builtInWideAngleCamera, for: .video, position: .back
        ),
              let input = try? AVCaptureDeviceInput(device: device),
              session.canAddInput(input) else {
            return
        }
        session.addInput(input)

        let output = AVCaptureVideoDataOutput()
        output.setSampleBufferDelegate(self, queue: sessionQueue)
        output.alwaysDiscardsLateVideoFrames = true

        guard session.canAddOutput(output) else { return }
        session.addOutput(output)

        if let connection = output.connection(with: .video) {
            if #available(iOS 17.0, *) {
                if connection.isVideoRotationAngleSupported(90) {
                    connection.videoRotationAngle = 90
                }
            } else {
                if connection.isVideoOrientationSupported {
                    connection.videoOrientation = .portrait
                }
            }
        }

        captureSession = session
        videoOutput = output
        session.startRunning()
    }

    func captureCurrentFrame() -> String? {
        guard let image = latestFrame else { return nil }

        let maxWidth: CGFloat = 640
        let targetImage: UIImage
        if image.size.width > maxWidth {
            let scale = maxWidth / image.size.width
            let newSize = CGSize(width: maxWidth, height: image.size.height * scale)
            let renderer = UIGraphicsImageRenderer(size: newSize)
            targetImage = renderer.image { _ in
                image.draw(in: CGRect(origin: .zero, size: newSize))
            }
        } else {
            targetImage = image
        }

        guard let jpegData = targetImage.jpegData(compressionQuality: 0.6) else { return nil }
        return jpegData.base64EncodedString()
    }
}

extension CameraService: AVCaptureVideoDataOutputSampleBufferDelegate {
    nonisolated func captureOutput(
        _ output: AVCaptureOutput,
        didOutput sampleBuffer: CMSampleBuffer,
        from connection: AVCaptureConnection
    ) {
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
        let ciImage = CIImage(cvPixelBuffer: pixelBuffer)
        guard let cgImage = ciContext.createCGImage(ciImage, from: ciImage.extent) else { return }
        let uiImage = UIImage(cgImage: cgImage)

        Task { @MainActor [weak self] in
            self?.latestFrame = uiImage
        }
    }
}
