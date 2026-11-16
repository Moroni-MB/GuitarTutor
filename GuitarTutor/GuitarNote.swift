import Foundation

struct GuitarNote {
    let name: String
    let frequency: Float
    let centsOff: Float

    static let openStrings: [(name: String, frequency: Float)] = [
        ("E2", 82.41), ("A2", 110.00), ("D3", 146.83),
        ("G3", 196.00), ("B3", 246.94), ("E4", 329.63)
    ]

    static func fromFrequency(_ frequency: Float) -> GuitarNote? {
        guard frequency.isFinite, frequency > 0 else { return nil }
        let midi = 69.0 + 12.0 * log2(Double(frequency) / 440.0)
        guard midi.isFinite, midi >= 0, midi <= 127 else { return nil }
        let rounded = Int(midi.rounded())
        let names = ["C", "C#", "D", "D#", "E", "F", "F#", "G", "G#", "A", "A#", "B"]
        return GuitarNote(name: "\(names[rounded % 12])\(rounded / 12 - 1)",
                          frequency: frequency,
                          centsOff: Float((midi - Double(rounded)) * 100.0))
    }
}
