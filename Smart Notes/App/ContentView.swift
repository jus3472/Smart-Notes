//
//  ContentView.swift
//  Smart Notes
//
//  Created by Justin Jiang on 11/3/25.
//

import SwiftUI

struct ContentView: View {
    @StateObject var speechService = SpeechRecognizerService()
    
    var body: some View {
        VStack(spacing: 30) {
            Text("Smart Notes")
                .font(.title)
                .bold()
            
            
            ScrollView {
                Text(speechService.transcribedText.isEmpty ? "Say something..." : speechService.transcribedText)
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .border(.gray)
                    .font(.body)
            }
            .frame(height: 200)
            
            
            Button(action: {
                if speechService.isTranscribing {
                    speechService.stopTranscribing()
                    let textToSave = speechService.transcribedText
                    if !textToSave.isEmpty {
                        print("Transcribed text: \(textToSave)")
                    }
                } else {
                    speechService.requestAuthorization()
                    speechService.startTranscribing()
                    print("Started recording...")
                }
            }) {
                Text(speechService.isTranscribing ? "Stop Recording" : "Start Recording")
                    .frame(width: 200, height: 50)
                    .background(speechService.isTranscribing ? Color.red : Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
        }
        .padding()
    }
}

#Preview {
    ContentView()
}
