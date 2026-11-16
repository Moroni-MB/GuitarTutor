import Foundation

struct PitchDetector {
    // YIN-style normalized difference function for monophonic guitar notes.
    // Input should contain at least 4096 samples at 44.1/48 kHz.
    static func detectPitch(samples: [Float], sampleRate: Float) -> Float? {
        guard samples.count >= 2048, sampleRate > 0 else { return nil }
        let minimumFrequency: Float = 75
        let maximumFrequency: Float = 380
        let minLag = max(2, Int(sampleRate / maximumFrequency))
        let maxLag = min(Int(sampleRate / minimumFrequency), samples.count / 2)
        guard maxLag > minLag else { return nil }

        let mean = samples.reduce(Float.zero, +) / Float(samples.count)
        let centered = samples.map { $0 - mean }
        let comparisonCount = samples.count - maxLag
        var difference = [Float](repeating: 0, count: maxLag + 1)
        for lag in 1...maxLag {
            var total: Float = 0
            for i in 0..<comparisonCount {
                let delta = centered[i] - centered[i + lag]
                total += delta * delta
            }
            difference[lag] = total
        }

        var normalized = [Float](repeating: 1, count: maxLag + 1)
        var runningSum: Float = 0
        for lag in 1...maxLag {
            runningSum += difference[lag]
            normalized[lag] = runningSum > 0
                ? difference[lag] * Float(lag) / runningSum : 1
        }

        let threshold: Float = 0.15
        var candidate: Int?
        var lag = minLag
        while lag <= maxLag {
            if normalized[lag] < threshold {
                while lag + 1 <= maxLag && normalized[lag + 1] < normalized[lag] {
                    lag += 1
                }
                candidate = lag
                break
            }
            lag += 1
        }
        guard let bestLag = candidate, normalized[bestLag] < threshold else { return nil }

        // Parabolic interpolation improves frequency precision between integer lags.
        var refinedLag = Float(bestLag)
        if bestLag > 1 && bestLag < maxLag {
            let left = normalized[bestLag - 1]
            let center = normalized[bestLag]
            let right = normalized[bestLag + 1]
            let denominator = 2 * (left - 2 * center + right)
            if abs(denominator) > 0.000001 {
                refinedLag += (left - right) / denominator
            }
        }
        let frequency = sampleRate / refinedLag
        return frequency.isFinite && frequency >= minimumFrequency && frequency <= maximumFrequency
            ? frequency : nil
    }
}
