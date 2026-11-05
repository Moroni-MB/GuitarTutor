struct PitchDetector{
    static func detectPitch(
        samples: [Float],
        sampleRate: Float
    ) -> Float? {
        guard samples.count > 0 else { return nil }
        
        let average = samples.reduce(0, +) / Float(samples.count)
        
        let centeredSamples = samples.map { $0 - average }
        
        let energy = centeredSamples.reduce(0) {
            $0 + ($1 * $1)
        }
        
        if energy < 0.001 {
            return nil
        }
        
        let minimumFrequency: Float = 70
        let maximumFrequency: Float = 400

        let minimumLag = Int(sampleRate / maximumFrequency)
        let maximumLag = Int(sampleRate / minimumFrequency)
        
        var bestLag = 0
        var bestScore: Float = 0
        
        guard centeredSamples.count > maximumLag else {
            return nil
        }
        
        for lag in minimumLag...maximumLag {
            var score: Float = 0

            for index in 0..<(centeredSamples.count - lag) {
                score += centeredSamples[index] *
                         centeredSamples[index + lag]
            }

            if score > bestScore {
                bestScore = score
                bestLag = lag
            }
        }
        
        guard bestLag > 0 else {
            return nil
        }
        let frequency = sampleRate / Float(bestLag)
        return frequency
    }
}

//
//  PitchDetector.swift
//  GuitarTutor
//
//  Created by Moroni Montoya Bernal on 10/27/26.
//

