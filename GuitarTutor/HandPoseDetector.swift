
import Foundation
import Vision
import CoreVideo
import ImageIO

struct HandLandmark: Identifiable {
    let id: String
    let x: CGFloat
    let y: CGFloat
    let confidence: Float
}

final class HandPoseDetector {

    private let request = VNDetectHumanHandPoseRequest()

    init() {
        request.maximumHandCount = 1
    }

    func detect(
        pixelBuffer: CVPixelBuffer,
        orientation: CGImagePropertyOrientation = .up
    ) -> [HandLandmark] {

        let handler = VNImageRequestHandler(
            cvPixelBuffer: pixelBuffer,
            orientation: orientation,
            options: [:]
        )

        do {
            try handler.perform([request])

            guard let observation = request.results?.first else {
                return []
            }

            let points = try observation.recognizedPoints(.all)

            return points.compactMap { name, point in
                guard point.confidence > 0.4 else {
                    return nil
                }

                return HandLandmark(
                    id: String(describing: name),
                    x: point.location.x,
                    y: point.location.y,
                    confidence: point.confidence
                )
            }

        } catch {
            print("Vision hand detection error: \(error)")
            return []
        }
    }
}
