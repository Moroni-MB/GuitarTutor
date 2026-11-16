//
//  CameraManager.swift
//  GuitarTutor
//
//  Created by Moroni Montoya Bernal on 11/5/26.
//



import AVFoundation
import Combine
import Foundation
import ImageIO

final class CameraManager: NSObject, ObservableObject {

    @Published var landmarks: [HandLandmark] = []
    @Published var isRunning = false
    @Published var errorMessage: String?
    
    @Published private(set) var trackedRect: CGRect?
    @Published private(set) var isTracking = false

    let session = AVCaptureSession()

    private let sessionQueue = DispatchQueue(
        label: "com.guitartutor.camera.session"
    )

    private let visionQueue = DispatchQueue(
        label: "com.guitartutor.camera.vision",
        qos: .userInitiated
    )

    private let detector = HandPoseDetector()
    private let fretboardTracker = FretboardTracker()

    private var frameCounter = 0
    private var isConfigured = false

    // First test: native landscape-right camera orientation.
    // We will verify this on the physical iPhone.
    private let captureRotation: CGFloat = 0

    func startCamera() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {

        case .authorized:
            configureAndStart()

        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) {
                [weak self] granted in

                if granted {
                    self?.configureAndStart()
                } else {
                    DispatchQueue.main.async {
                        self?.errorMessage =
                            "Camera permission was denied."
                    }
                }
            }

        default:
            DispatchQueue.main.async {
                self.errorMessage =
                    "Enable camera access in Settings."
            }
        }
    }

    private func configureAndStart() {
        sessionQueue.async { [weak self] in
            guard let self else { return }

            if !self.isConfigured {
                self.session.beginConfiguration()
                self.session.sessionPreset = .vga640x480

                guard let device = AVCaptureDevice.default(
                    .builtInWideAngleCamera,
                    for: .video,
                    position: .front
                ),
                let input = try? AVCaptureDeviceInput(
                    device: device
                ),
                self.session.canAddInput(input) else {

                    self.session.commitConfiguration()
                    self.showError("Front camera unavailable.")
                    return
                }

                self.session.addInput(input)

                let output = AVCaptureVideoDataOutput()
                output.alwaysDiscardsLateVideoFrames = true

                output.setSampleBufferDelegate(
                    self,
                    queue: self.visionQueue
                )

                guard self.session.canAddOutput(output) else {
                    self.session.commitConfiguration()
                    self.showError("Video output unavailable.")
                    return
                }

                self.session.addOutput(output)

                if let connection = output.connection(
                    with: .video
                ) {
                    if connection.isVideoRotationAngleSupported(
                        self.captureRotation
                    ) {
                        connection.videoRotationAngle =
                            self.captureRotation
                    }

                    if connection.isVideoMirroringSupported {
                        connection.automaticallyAdjustsVideoMirroring = false
                        connection.isVideoMirrored = false
                    }
                }

                self.session.commitConfiguration()
                self.isConfigured = true
            }

            guard !self.session.isRunning else { return }

            self.session.startRunning()

            DispatchQueue.main.async {
                self.isRunning = true
                self.errorMessage = nil
            }
        }
    }

    private func showError(_ message: String) {
        DispatchQueue.main.async {
            self.errorMessage = message
            self.isRunning = false
        }
    }

    func stopCamera() {

        sessionQueue.async { [weak self] in
            guard let self else { return }

            if self.session.isRunning {
                self.session.stopRunning()
            }

            self.stopObjectTracking()

            DispatchQueue.main.async {
                self.isRunning = false
                self.landmarks = []
            }
        }
    }
    
    
    
    func startObjectTracking(rect: CGRect) {

        visionQueue.async { [weak self] in
            guard let self else { return }

            self.fretboardTracker.startTracking(
                rect: rect
            )

            // Read the tracker state on the Vision queue.
            let trackingStarted =
                self.fretboardTracker.isTracking

            DispatchQueue.main.async { [weak self] in
                guard let self else { return }

                self.isTracking = trackingStarted
                self.trackedRect =
                    trackingStarted ? rect : nil
            }
        }
    }


    func stopObjectTracking() {

        visionQueue.async { [weak self] in
            guard let self else { return }

            self.fretboardTracker.stopTracking()

            DispatchQueue.main.async {
                self.isTracking = false
                self.trackedRect = nil
            }
        }
    }

}

extension CameraManager:
    AVCaptureVideoDataOutputSampleBufferDelegate {

    
    
    func captureOutput(
        _ output: AVCaptureOutput,
        didOutput sampleBuffer: CMSampleBuffer,
        from connection: AVCaptureConnection
    ) {
        frameCounter += 1

        // Process every third camera frame.
        guard frameCounter % 3 == 0 else {
            return
        }

        guard let pixelBuffer =
            CMSampleBufferGetImageBuffer(sampleBuffer)
        else {
            return
        }

        // Step 1: Detect hand landmarks.
        let points = detector.detect(
            pixelBuffer: pixelBuffer,
            orientation: .up
        )

        // Step 2: Track the calibrated object.
        let trackedRegion: CGRect?

        if fretboardTracker.isTracking {
            trackedRegion = fretboardTracker.track(
                pixelBuffer: pixelBuffer,
                orientation: .up
            )
        } else {
            trackedRegion = nil
        }

        // Capture state on the Vision processing queue.
        let trackingActive = fretboardTracker.isTracking

        // Step 3: Publish results to SwiftUI.
        DispatchQueue.main.async { [weak self] in
            guard let self else { return }

            self.landmarks = points
            self.trackedRect = trackedRegion
            self.isTracking = trackingActive
        }
    }
}
