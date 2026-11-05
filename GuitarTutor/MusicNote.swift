import Foundation

struct MusicNote {
    let name: String
    let octave: Int
    let frequency: Double
    let centsOff: Double

    static func fromFrequency(
        _ frequency: Double
    ) -> MusicNote? {

        guard frequency.isFinite,
              frequency > 0 else {
            return nil
        }

        let noteNames = [
            "C", "C#", "D", "D#", "E", "F",
            "F#", "G", "G#", "A", "A#", "B"
        ]

        let midiValue = 69.0 +
            12.0 * log2(frequency / 440.0)

        guard midiValue >= 0,
              midiValue <= 127 else {
            return nil
        }

        let midiNote = Int(midiValue.rounded())

        let noteIndex = midiNote % 12
        let octave = midiNote / 12 - 1

        let centsOff = (midiValue - Double(midiNote)) * 100

        return MusicNote(
            name: noteNames[noteIndex],
            octave: octave,
            frequency: frequency,
            centsOff: centsOff
        )
    }
}


//
//  MusicNote.swift
//  GuitarTutor
//
//  Created by Moroni Montoya Bernal on 11/4/26.
//

