import AVFoundation
import Combine
import Foundation

final class AudioManager: ObservableObject {
    @Published var errorMessage: String?
    @Published var isListening = false
    @Published var audioLevel: Float = 0
    @Published var detectedFrequency: Float = 0
    @Published var detectedNote: String = "--"
    @Published var centsOff: Float = 0
    @Published var feedback = "Play one open string"
    @Published var selectedString = 0

    private let audioEngine = AVAudioEngine()
    private let processingQueue = DispatchQueue(label: "GuitarTutor.audio.processing")
    private var pendingSamples: [Float] = [] // Access only on processingQueue
    private var recentNotes: [String] = []   // Access only on processingQueue
    private var generation = 0               // Access only on main thread
    private let windowSize = 4096
    private let hopSize = 2048

    func startListening() {
        requestRecordPermission { [weak self] granted in
            DispatchQueue.main.async {
                guard let self else { return }
                guard granted else {
                    self.errorMessage = "Microphone permission denied. Enable it in Settings."
                    return
                }
                do { try self.configureAudio() }
                catch { self.errorMessage = "Audio setup failed: \(error.localizedDescription)" }
            }
        }
    }

    private func requestRecordPermission(completion: @escaping (Bool) -> Void) {
        if #available(iOS 17.0, *) {
            AVAudioApplication.requestRecordPermission(completionHandler: completion)
        } else {
            AVAudioSession.sharedInstance().requestRecordPermission(completion)
        }
    }

    private func configureAudio() throws {
        guard !isListening else { return }
        errorMessage = nil
        let session = AVAudioSession.sharedInstance()
        try session.setCategory(.record, mode: .measurement)
        try session.setActive(true)
        let input = audioEngine.inputNode
        let format = input.outputFormat(forBus: 0)
        guard format.commonFormat == .pcmFormatFloat32 else {
            throw NSError(domain: "GuitarTutor", code: 1,
                          userInfo: [NSLocalizedDescriptionKey: "Expected Float32 microphone audio"])
        }
        generation += 1
        let currentGeneration = generation
        processingQueue.async { [weak self] in
            self?.pendingSamples.removeAll()
            self?.recentNotes.removeAll()
        }
        input.removeTap(onBus: 0)
        input.installTap(onBus: 0, bufferSize: 2048, format: format) { [weak self] buffer, _ in
            guard let self, let channel = buffer.floatChannelData?[0] else { return }
            let samples = Array(UnsafeBufferPointer(start: channel, count: Int(buffer.frameLength)))
            let sampleRate = Float(format.sampleRate)
            self.processingQueue.async { [weak self] in
                self?.consume(samples: samples, sampleRate: sampleRate, generation: currentGeneration)
            }
        }
        do {
            audioEngine.prepare()
            try audioEngine.start()
            isListening = true
        } catch {
            input.removeTap(onBus: 0)
            try? session.setActive(false)
            throw error
        }
    }

    private func consume(samples: [Float], sampleRate: Float, generation: Int) {
        pendingSamples.append(contentsOf: samples)
        while pendingSamples.count >= windowSize {
            let window = Array(pendingSamples.prefix(windowSize))
            pendingSamples.removeFirst(hopSize)
            let rms = AudioAnalyzer.calculateRMS(samples: window)
            let db = 20 * log10(max(rms, 0.00001))
            let level = max(0, min(1, (db + 60) / 60))
            let frequency = AudioAnalyzer.hasMeaningfulAudio(rms: rms)
                ? PitchDetector.detectPitch(samples: window, sampleRate: sampleRate) : nil
            let note = frequency.flatMap { GuitarNote.fromFrequency($0) }
            if let note {
                recentNotes.append(note.name)
                if recentNotes.count > 3 { recentNotes.removeFirst() }
            } else {
                recentNotes.removeAll()
            }
            let stable = note != nil && recentNotes.count == 3 && recentNotes.allSatisfy { $0 == note!.name }
            DispatchQueue.main.async { [weak self] in
                guard let self, self.isListening, self.generation == generation else { return }
                self.audioLevel = level
                guard stable, let note else {
                    self.detectedNote = "--"
                    self.detectedFrequency = 0
                    self.centsOff = 0
                    self.feedback = rms < 0.01 ? "Waiting for a guitar note" : "Listening for a stable note..."
                    return
                }
                self.detectedNote = note.name
                self.detectedFrequency = note.frequency
                self.centsOff = note.centsOff
                let expected = GuitarNote.openStrings[self.selectedString].name
                self.feedback = note.name == expected
                    ? (abs(note.centsOff) <= 15 ? "Correct note!" : "Correct note, but check your tuning")
                    : "Detected \(note.name). Try the \(expected) string."
            }
        }
    }

    func stopListening() {
        generation += 1
        audioEngine.stop()
        audioEngine.inputNode.removeTap(onBus: 0)
        try? AVAudioSession.sharedInstance().setActive(false)
        isListening = false
        audioLevel = 0
        detectedFrequency = 0
        detectedNote = "--"
        centsOff = 0
        feedback = "Play one open string"
        processingQueue.async { [weak self] in
            self?.pendingSamples.removeAll()
            self?.recentNotes.removeAll()
        }
    }
}
