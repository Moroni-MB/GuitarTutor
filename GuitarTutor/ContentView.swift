//
//  ContentView.swift
//  GuitarTutor
//
//  Created by Moroni Montoya Bernal on 11/5/26.
//


import SwiftUI

struct ContentView: View {

    var body: some View {
        TabView {

            AudioPracticeView()
                .tabItem {
                    Label(
                        "Audio Practice",
                        systemImage: "waveform"
                    )
                }

            CameraPracticeView()
                .tabItem {
                    Label(
                        "Camera Practice",
                        systemImage: "camera"
                    )
                }
        }
    }
}
