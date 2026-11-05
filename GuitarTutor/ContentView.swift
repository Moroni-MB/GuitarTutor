import SwiftUI

// This is the UI for the app
struct ContentView: View {
    @StateObject private var audioManager = AudioManager()

    var body: some View {
        VStack(spacing: 24) {
            if let errorMessage = audioManager.errorMessage {
                Text(errorMessage)
                    .foregroundColor(.red)
                    .multilineTextAlignment(.center)
            }
            
            Text("GuitarTutor")
                .font(.largeTitle)
                .bold()

            Text(audioManager.isListening
                 ? "Listening..."
                 : "Microphone is off")
            
            Text(audioManager.detectedNote).font(.system(size:56, weight: .bold))
            Text("\(audioManager.detectedFrequency, specifier: "%.1f") Hz").foregroundStyle(.secondary)

            ProgressView(value: Double(audioManager.audioLevel))
                .padding(.horizontal)

            Button(audioManager.isListening ? "Stop Listening" : "Start Listening") {
                if audioManager.isListening {
                    audioManager.stopListening()
                } else {
                    audioManager.startListening()
                }
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
    }
}
