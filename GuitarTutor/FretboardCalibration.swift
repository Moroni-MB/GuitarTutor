//
//  FretboardCalibration.swift
//  GuitarTutor
//
//  Created by Moroni Montoya Bernal on 11/9/26.
//


import Foundation
import CoreGraphics

// Represents one corner of the fretboard.
struct FretboardPoint: Identifiable {
    let id: Int
    var position: CGPoint
}

// Stores the four corners of the fretboard.
// Coordinates are normalized between 0 and 1.
struct FretboardCalibration {

    var points: [FretboardPoint] = [
        FretboardPoint(
            id: 0,
            position: CGPoint(x: 0.20, y: 0.35)
        ),
        FretboardPoint(
            id: 1,
            position: CGPoint(x: 0.80, y: 0.35)
        ),
        FretboardPoint(
            id: 2,
            position: CGPoint(x: 0.80, y: 0.65)
        ),
        FretboardPoint(
            id: 3,
            position: CGPoint(x: 0.20, y: 0.65)
        )
    ]

    // Convert a normalized point to screen coordinates.
    func screenPosition(
        for point: CGPoint,
        in size: CGSize
    ) -> CGPoint {

        CGPoint(
            x: point.x * size.width,
            y: point.y * size.height
        )
    }

    // Convert a screen point into normalized coordinates.
    func normalizedPosition(
        for point: CGPoint,
        in size: CGSize
    ) -> CGPoint {

        guard size.width > 0, size.height > 0 else {
            return .zero
        }

        return CGPoint(
            x: min(max(point.x / size.width, 0), 1),
            y: min(max(point.y / size.height, 0), 1)
        )
    }

    // Update one of the four corners.
    mutating func updatePoint(
        id: Int,
        position: CGPoint
    ) {

        guard let index = points.firstIndex(
            where: { $0.id == id }
        ) else {
            return
        }

        points[index].position = position
    }

    // Restore the default calibration region.
    mutating func reset() {
        self = FretboardCalibration()
    }
    
    
    var boundingRect: CGRect {

        guard points.count == 4 else {
            return .zero
        }

        let xs = points.map { $0.position.x }
        let ys = points.map { $0.position.y }

        guard let minX = xs.min(),
              let maxX = xs.max(),
              let minY = ys.min(),
              let maxY = ys.max() else {
            return .zero
        }

        return CGRect(
            x: minX,
            y: minY,
            width: maxX - minX,
            height: maxY - minY
        )
    }
}
