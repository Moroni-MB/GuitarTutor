//
//  CameraPreview.swift
//  GuitarTutor
//
//  Created by Moroni Montoya Bernal on 11/5/26.
//


import SwiftUI
import AVFoundation
import UIKit

final class CameraPreviewUIView: UIView {
    private let trackingLayer = CAShapeLayer()
    private var currentTrackedRect: CGRect?

    override class var layerClass: AnyClass {
        AVCaptureVideoPreviewLayer.self
    }

    var previewLayer: AVCaptureVideoPreviewLayer {
        layer as! AVCaptureVideoPreviewLayer
    }

    private let landmarkLayer = CAShapeLayer()
    private var currentLandmarks: [HandLandmark] = []

    override init(frame: CGRect) {
        super.init(frame: frame)

        previewLayer.videoGravity = .resizeAspectFill

        landmarkLayer.fillColor = UIColor.systemGreen.cgColor
        landmarkLayer.strokeColor = UIColor.white.cgColor
        landmarkLayer.lineWidth = 1

        previewLayer.addSublayer(landmarkLayer)
        
        trackingLayer.strokeColor = UIColor.systemYellow.cgColor
        trackingLayer.fillColor = UIColor.clear.cgColor
        trackingLayer.lineWidth = 3

        previewLayer.addSublayer(trackingLayer)
    }
    
    
    func updateTrackedRect(_ rect: CGRect?) {
        currentTrackedRect = rect
        drawTrackedRect()
    }

    private func drawTrackedRect() {

        guard let rect = currentTrackedRect else {
            trackingLayer.path = nil
            return
        }

        // Vision uses bottom-left coordinates.
        // Convert into capture-device top-left coordinates.
        let topLeft = CGPoint(
            x: rect.minX,
            y: 1 - rect.maxY
        )

        let bottomRight = CGPoint(
            x: rect.maxX,
            y: 1 - rect.minY
        )

        let p1 = previewLayer.layerPointConverted(
            fromCaptureDevicePoint: topLeft
        )

        let p2 = previewLayer.layerPointConverted(
            fromCaptureDevicePoint: bottomRight
        )

        let displayRect = CGRect(
            x: min(p1.x, p2.x),
            y: min(p1.y, p2.y),
            width: abs(p2.x - p1.x),
            height: abs(p2.y - p1.y)
        )

        CATransaction.begin()
        CATransaction.setDisableActions(true)

        trackingLayer.frame = previewLayer.bounds
        trackingLayer.path =
            UIBezierPath(rect: displayRect).cgPath

        CATransaction.commit()
    }


    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configurePreview() {
        guard let connection = previewLayer.connection else {
            return
        }

        if connection.isVideoRotationAngleSupported(0) {
            connection.videoRotationAngle = 0
        }

        if connection.isVideoMirroringSupported {
            connection.automaticallyAdjustsVideoMirroring = false
            connection.isVideoMirrored = true
        }
    }

    func updateLandmarks(_ landmarks: [HandLandmark]) {
        currentLandmarks = landmarks
        drawLandmarks()
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        // Match the overlay to the preview's actual bounds.
        landmarkLayer.frame = previewLayer.bounds

        configurePreview()
        drawLandmarks()
        drawTrackedRect()
    }

    private func drawLandmarks() {
        let path = UIBezierPath()

        for point in currentLandmarks {

            // Convert Vision's bottom-left origin
            // into a top-left normalized coordinate.
            let capturePoint = CGPoint(
                x: point.x,
                y: 1 - point.y
            )

            // Preview layer handles scaling,
            // cropping, and display mirroring.
            let position = previewLayer.layerPointConverted(
                fromCaptureDevicePoint: capturePoint
            )

            let circle = CGRect(
                x: position.x - 4,
                y: position.y - 4,
                width: 8,
                height: 8
            )

            path.append(
                UIBezierPath(ovalIn: circle)
            )
        }

        CATransaction.begin()
        CATransaction.setDisableActions(true)
        landmarkLayer.path = path.cgPath
        CATransaction.commit()
    }
    
    
    func visionBoundingRect(
        from calibration: FretboardCalibration,
        isLandscape: Bool
    ) -> CGRect? {

        guard calibration.points.count == 4,
              bounds.width > 0,
              bounds.height > 0 else {
            return nil
        }

        let visionPoints = calibration.points.map { point in

            // Coordinates in the visible camera container.
            let displayedX = point.position.x
            let displayedY = point.position.y

            // Undo the clockwise 90-degree display rotation.
            let localX: CGFloat
            let localY: CGFloat

            if isLandscape {
                localX = displayedY
                localY = 1 - displayedX
            } else {
                localX = displayedX
                localY = displayedY
            }

            let layerPoint = CGPoint(
                x: localX * bounds.width,
                y: localY * bounds.height
            )

            let capturePoint =
                previewLayer.captureDevicePointConverted(
                    fromLayerPoint: layerPoint
                )

            // Convert to Vision's bottom-left origin.
            return CGPoint(
                x: capturePoint.x,
                y: 1 - capturePoint.y
            )
        }

        let xs = visionPoints.map(\.x)
        let ys = visionPoints.map(\.y)

        guard let minX = xs.min(),
              let maxX = xs.max(),
              let minY = ys.min(),
              let maxY = ys.max() else {
            return nil
        }

        let rect = CGRect(
            x: minX,
            y: minY,
            width: maxX - minX,
            height: maxY - minY
        )

        // Reject invalid tracking regions.
        guard rect.width > 0,
              rect.height > 0,
              rect.minX >= 0,
              rect.minY >= 0,
              rect.maxX <= 1,
              rect.maxY <= 1 else {
            return nil
        }

        return rect
    }
}


struct CameraPreview: UIViewRepresentable {

    let session: AVCaptureSession
    let landmarks: [HandLandmark]
    let trackedRect: CGRect?

    let calibration: FretboardCalibration
    let isLandscape: Bool
    let calibrationRequestID: Int

    let onCalibrationConverted: (CGRect?) -> Void

    // MARK: - Coordinator

    class Coordinator {
        var lastRequestID = 0
    }

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    // MARK: - Create Camera View

    func makeUIView(
        context: Context
    ) -> CameraPreviewUIView {

        let view = CameraPreviewUIView()

        view.previewLayer.session = session
        view.configurePreview()

        return view
    }

    // MARK: - Update Camera View

    func updateUIView(
        _ uiView: CameraPreviewUIView,
        context: Context
    ) {

        uiView.configurePreview()

        uiView.updateLandmarks(landmarks)
        uiView.updateTrackedRect(trackedRect)

        // Only process new calibration requests.
        guard context.coordinator.lastRequestID
                != calibrationRequestID else {
            return
        }

        context.coordinator.lastRequestID =
            calibrationRequestID

        let rect = uiView.visionBoundingRect(
            from: calibration,
            isLandscape: isLandscape
        )

        DispatchQueue.main.async {
            onCalibrationConverted(rect)
        }
    }
}

