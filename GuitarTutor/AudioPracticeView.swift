import SwiftUI

struct AudioPracticeView: View {
    @StateObject private var audioManager = AudioManager()

    var body: some View {
        VStack(spacing: 20) {
            Text("GuitarTutor").font(.largeTitle.bold())
            Text("Guided open-string practice").foregroundStyle(.secondary)

            Picker("Target string", selection: $audioManager.selectedString) {
                ForEach(GuitarNote.openStrings.indices, id: \.self) { index in
                    Text(GuitarNote.openStrings[index].name).tag(index)
                }
            }
            .pickerStyle(.segmented)

            Text("Target: \(GuitarNote.openStrings[audioManager.selectedString].name)  •  \(GuitarNote.openStrings[audioManager.selectedString].frequency, specifier: "%.2f") Hz")
                .font(.subheadline)

            Text(audioManager.isListening ? "Listening..." : "Microphone is off")
                .foregroundStyle(.secondary)
            Text(audioManager.detectedNote).font(.system(size: 64, weight: .bold))
            Text("\(audioManager.detectedFrequency, specifier: "%.1f") Hz")
            Text("\(audioManager.centsOff, specifier: "%+.1f") cents")
                .foregroundStyle(.secondary)
            ProgressView(value: Double(audioManager.audioLevel))
            Text(audioManager.feedback).multilineTextAlignment(.center)

            if let error = audioManager.errorMessage {
                Text(error).foregroundStyle(.red).multilineTextAlignment(.center)
            }

            Button(audioManager.isListening ? "Stop Listening" : "Start Listening") {
                if audioManager.isListening { audioManager.stopListening() }
                else { audioManager.startListening() }
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
    }
}
