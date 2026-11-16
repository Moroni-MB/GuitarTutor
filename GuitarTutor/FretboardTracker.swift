//
//  FretboardTracker.swift
//  GuitarTutor
//
//  Created by Moroni Montoya Bernal on 11/11/26.
//


import Foundation
import Vision
import CoreVideo
import ImageIO

final class FretboardTracker {

    private var trackingRequest: VNTrackObjectRequest?
    private let sequenceHandler = VNSequenceRequestHandler()
    
    private var missedFrames = 0
    private let maxMissedFrames = 5
    private let confidenceThreshold: VNConfidence = 0.4

    private(set) var isTracking = false

    // Initialize tracking with a normalized Vision rectangle.
    // Vision uses a bottom-left coordinate origin.
    func startTracking(rect: CGRect) {

        guard rect.width > 0,
              rect.height > 0 else {
            return
        }

        let observation = VNDetectedObjectObservation(
            boundingBox: rect
        )

        let request = VNTrackObjectRequest(
            detectedObjectObservation: observation
        )

        request.trackingLevel = .accurate

        trackingRequest = request
        isTracking = true
        missedFrames = 0
    }

    // Process the next camera frame.
    
    func track(
        pixelBuffer: CVPixelBuffer,
        orientation: CGImagePropertyOrientation = .up
    ) -> CGRect? {

        guard let request = trackingRequest,
              isTracking else {
            return nil
        }

        do {
            try sequenceHandler.perform(
                [request],
                on: pixelBuffer,
                orientation: orientation
            )

            guard let observation =
                request.results?.first as? VNDetectedObjectObservation
            else {
                missedFrames += 1

                if missedFrames >= maxMissedFrames {
                    stopTracking()
                }

                return nil
            }

            if observation.confidence < confidenceThreshold {
                missedFrames += 1

                if missedFrames >= maxMissedFrames {
                    stopTracking()
                }

                return nil
            }

            // A reliable tracking result was found.
            missedFrames = 0

            return observation.boundingBox

        } catch {
            print("Tracking error: \(error)")
            stopTracking()
            return nil
        }
    }

    func stopTracking() {
        trackingRequest = nil
        isTracking = false
        missedFrames = 0
    }
}
