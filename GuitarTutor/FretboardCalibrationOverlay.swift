//
//  FretboardCalibrationOverlay.swift
//  GuitarTutor
//
//  Created by Moroni Montoya Bernal on 11/9/26.
//

import SwiftUI

struct FretboardCalibrationOverlay: View {

    // Shares calibration data with CameraPracticeView.
    @Binding var calibration: FretboardCalibration

    var body: some View {

        GeometryReader { geometry in

            let size = geometry.size

            ZStack {

                // MARK: - Fretboard Boundary

                // Draw a quadrilateral connecting
                // the four calibration points.
                Path { path in

                    guard calibration.points.count == 4 else {
                        return
                    }

                    let positions = calibration.points.map {
                        calibration.screenPosition(
                            for: $0.position,
                            in: size
                        )
                    }

                    path.move(to: positions[0])
                    path.addLine(to: positions[1])
                    path.addLine(to: positions[2])
                    path.addLine(to: positions[3])
                    path.closeSubpath()
                }
                .stroke(
                    Color.green,
                    style: StrokeStyle(
                        lineWidth: 2,
                        dash: [6, 4]
                    )
                )
                .allowsHitTesting(false)

                // MARK: - Draggable Corner Handles

                ForEach(calibration.points) { point in

                    let position = calibration.screenPosition(
                        for: point.position,
                        in: size
                    )

                    Circle()
                        .fill(Color.green)
                        .frame(width: 22, height: 22)

                        // Larger invisible touch area.
                        .frame(width: 44, height: 44)
                        .contentShape(Circle())

                        // Display corner number.
                        .overlay {
                            Text("\(point.id + 1)")
                                .font(.caption2)
                                .bold()
                                .foregroundStyle(Color.black)
                                .allowsHitTesting(false)
                        }

                        // Position the handle.
                        .position(position)

                        // Allow dragging in the overlay's
                        // coordinate system.
                        .gesture(
                            DragGesture(
                                minimumDistance: 0,
                                coordinateSpace: .named(
                                    "fretboardOverlay"
                                )
                            )
                            .onChanged { value in

                                let normalized =
                                    calibration.normalizedPosition(
                                        for: value.location,
                                        in: size
                                    )

                                calibration.updatePoint(
                                    id: point.id,
                                    position: normalized
                                )
                            }
                        )
                }
            }

            // Ensure the overlay fills the camera area.
            .frame(
                width: size.width,
                height: size.height
            )

            // Coordinate system used by DragGesture.
            .coordinateSpace(name: "fretboardOverlay")
        }
    }
}
