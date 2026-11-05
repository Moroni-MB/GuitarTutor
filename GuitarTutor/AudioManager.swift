import AVFoundation
import Combine

// This class controls microphone input and audio processing
// Observable Object allows SwiftUI to react when the values in the class change
final class AudioManager: ObservableObject {
    @Published var errorMessage: String?
    @Published var isListening = false
    @Published var audioLevel: Float = 0
    @Published var detectedFrequency: Float = 0
    @Published var detectedNote: String = "--"

    private let audioEngine = AVAudioEngine() // AVAudioEngine gives access to live audio
    

    // Start listening to the phone's microphone
    func startListening() {
        requestRecordPermission { [weak self] granted in
            guard granted else {
                self?.errorMessage = "Microphone access was denied. Keep in mind that the app uses the microphone to coach your guitar playing. Please enable it in settings."
                return
            }

            DispatchQueue.main.async {
                do {
                    try self?.configureAudio()
                } catch {
                    self?.errorMessage = "Failed to configure audio: \(error.localizedDescription)"
                    self?.isListening = false
                    self?.audioLevel = 0
                }
            }
        }
    }

    // Ask for permissions to use the microphone
    private func requestRecordPermission(completion: @escaping (Bool) -> Void) {
        if #available(iOS 17.0, *) {
            AVAudioApplication.requestRecordPermission(completionHandler: completion)
        } else {
            AVAudioSession.sharedInstance().requestRecordPermission(completion)
        }
    }

    private func configureAudio() throws {
        let session = AVAudioSession.sharedInstance()

        try session.setCategory(.record, mode: .measurement)
        try session.setActive(true)

        let inputNode = audioEngine.inputNode
        let format = inputNode.outputFormat(forBus: 0)

        inputNode.removeTap(onBus: 0)

        // Runs everytime the microphone picks up new audio
        inputNode.installTap(
            onBus: 0,
            bufferSize: 1_024,
            format: format
        ) { [weak self] buffer, _ in
            guard let channelData = buffer.floatChannelData?[0] else {
                return
            }

            let frameCount = Int(buffer.frameLength)
            
            let samples = Array(
                UnsafeBufferPointer(
                    start: channelData,
                    count: frameCount
                )
            )
            
            if let frequency = PitchDetector.detectPitch(
                samples: samples,
                sampleRate: Float(format.sampleRate)
            ) {
                // Use the frequency here
                let note = GuitarNote.getNote(frequency: frequency)
                DispatchQueue.main.async {
                    self?.detectedFrequency = frequency
                    self?.detectedNote = note
                }
            }
            
            var sum: Float = 0

            for index in 0..<frameCount {
                sum += channelData[index] * channelData[index]
            }

            // Calculates volume
            let rms = sqrt(sum / Float(max(frameCount, 1)))
            let decibels = 20 * log10(max(rms, 0.00001))

            let normalizedLevel = max(
                0,
                min(1, (decibels + 60) / 60)
            )

            DispatchQueue.main.async {
                self?.audioLevel = normalizedLevel
            }
        }

        audioEngine.prepare()
        try audioEngine.start()

        isListening = true
    }

    func stopListening() {
        audioEngine.stop()
        audioEngine.inputNode.removeTap(onBus: 0)

        try? AVAudioSession.sharedInstance().setActive(false)

        isListening = false
        audioLevel = 0
        detectedFrequency = 0
        detectedNote = "--"
    }
}//
//  AudioManager.swift
//  GuitarTutor
//
//  Created by Moroni Montoya Bernal on 9/22/26.
//
