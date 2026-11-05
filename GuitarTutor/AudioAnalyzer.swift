import Foundation

struct AudioAnalyzer {

    // Calculate the RMS amplitude of audio samples.
    static func calculateRMS(
        samples: [Float]
    ) -> Float {

        guard !samples.isEmpty else {
            return 0
        }

        var sumOfSquares: Float = 0

        for sample in samples {
            sumOfSquares += sample * sample
        }

        let mean = sumOfSquares / Float(samples.count)

        return sqrt(mean)
    }

    // Decide whether the signal is loud enough to analyze.
    static func hasMeaningfulAudio(
        rms: Float,
        threshold: Float = 0.01
    ) -> Bool {
        return rms >= threshold
    }
}


//
//  AudioAnalyzer.swift
//  GuitarTutor
//
//  Created by Moroni Montoya Bernal on 11/4/26.
//

