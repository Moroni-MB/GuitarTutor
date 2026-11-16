//
//  CameraPracticeView.swift
//  GuitarTutor
//
//  Created by Moroni Montoya Bernal on 11/5/26.
//



import SwiftUI

struct CameraPracticeView: View {

    @StateObject private var camera = CameraManager()
    
    @State private var calibration = FretboardCalibration()
    @State private var isCalibrating = false
    @State private var calibrationRequestID = 0

    var body: some View {

        GeometryReader { geometry in

            let isLandscape =
                geometry.size.width > geometry.size.height

            Group {
                if isLandscape {
                    landscapeLayout
                } else {
                    portraitLayout
                }
            }
            .frame(
                width: geometry.size.width,
                height: geometry.size.height
            )
        }
        .onAppear {
            camera.startCamera()
        }
        .onDisappear {
            camera.stopCamera()
        }
    }

    // MARK: - Camera Preview

    
    private func cameraView(isLandscape: Bool) -> some View {

        GeometryReader { geometry in

            let width = geometry.size.width
            let height = geometry.size.height

            ZStack(alignment: .topLeading) {

                // Rotate the preview and its landmarks together.
                CameraPreview(
                    session: camera.session,
                    landmarks: camera.landmarks,
                    trackedRect: camera.trackedRect,
                    calibration: calibration,
                    isLandscape: isLandscape,
                    calibrationRequestID: calibrationRequestID,
                    onCalibrationConverted: { rect in
                        guard let rect else {
                            print("Calibration conversion failed")
                            return
                        }

                        camera.startObjectTracking(rect: rect)
                        isCalibrating = false
                    }
                )
                .frame(
                    width: isLandscape ? height : width,
                    height: isLandscape ? width : height
                )
                .rotationEffect(
                    .degrees(isLandscape ? 90 : 0)
                )
                .position(
                    x: width / 2,
                    y: height / 2
                )
                if isCalibrating {
                    FretboardCalibrationOverlay(
                        calibration: $calibration
                    )
                }

                HStack(spacing: 6) {
                    Circle()
                        .fill(
                            camera.landmarks.isEmpty
                                ? Color.orange
                                : Color.green
                        )
                        .frame(width: 9, height: 9)

                    Text(
                        camera.landmarks.isEmpty
                            ? "Searching for hand"
                            : "Hand detected"
                    )
                    .font(.caption)
                    .foregroundStyle(Color.white)
                }
                .padding(10)
                .background(
                    Color.black.opacity(0.65),
                    in: RoundedRectangle(cornerRadius: 10)
                )
                .padding(12)
            }
            .frame(width: width, height: height)
            .clipped()
            .clipShape(
                RoundedRectangle(cornerRadius: 16)
            )
        }
    }


    // MARK: - Practice Controls

    private var practiceControls: some View {

        VStack(alignment: .leading, spacing: 12) {

            Text("Guitar Tutor")
                .font(.title2)
                .bold()

            VStack(alignment: .leading, spacing: 8) {

                Text("GUIDED PRACTICE")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Text("C Major")
                    .font(.largeTitle)
                    .bold()

                Text("Position your fingers on the fretboard.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .padding()
            .frame(
                maxWidth: .infinity,
                alignment: .leading
            )
            .background(
                Color.secondary.opacity(0.1),
                in: RoundedRectangle(cornerRadius: 14)
            )
            
            Button {
                isCalibrating.toggle()
            } label: {
                Label(
                    isCalibrating
                        ? "Finish Calibration"
                        : "Calibrate Fretboard",
                    systemImage: "viewfinder"
                )
            }
            .buttonStyle(.borderedProminent)

            Button {
                calibration.reset()
                isCalibrating = true
            } label: {
                Label(
                    "Reset Calibration",
                    systemImage: "arrow.counterclockwise"
                )
            }
            .buttonStyle(.bordered)
            
            Button {
                if camera.isTracking {
                    camera.stopObjectTracking()
                } else {
                    calibrationRequestID += 1
                }
            } label: {
                Label(
                    camera.isTracking
                        ? "Stop Tracking"
                        : "Start Tracking",
                    systemImage: "viewfinder"
                )
            }
            .buttonStyle(.borderedProminent)

            Label(
                camera.landmarks.isEmpty
                    ? "No hand detected"
                    : "Tracking \(camera.landmarks.count) landmarks",
                systemImage: "hand.raised"
            )
            .font(.subheadline)

            if let error = camera.errorMessage {
                Text(error)
                    .font(.caption)
                    .foregroundStyle(Color.red)
            }

            Text("Audio feedback coming next")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(
            maxWidth: .infinity,
            alignment: .leading
        )
    }

    // MARK: - Landscape Layout

    private var landscapeLayout: some View {

        GeometryReader { geometry in

            let controlsWidth = min(
                250,
                geometry.size.width * 0.35
            )

            HStack(spacing: 12) {

                cameraView(isLandscape: true)

                ScrollView {
                    practiceControls
                }
                .frame(
                    width: controlsWidth,
                    height: geometry.size.height
                )
            }
        }
        .padding(8)
    }

    // MARK: - Portrait Layout

    
    private var portraitLayout: some View {

        GeometryReader { geometry in

            VStack(spacing: 12) {

                cameraView(isLandscape: false)
                    .frame(
                        height: min(
                            300,
                            geometry.size.height * 0.48
                        )
                    )

                ScrollView {
                    practiceControls
                }
                .frame(maxHeight: .infinity)
            }
            .frame(
                width: geometry.size.width,
                height: geometry.size.height
            )
        }
        .padding(8)
    }
}
