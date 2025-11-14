// RecordingView.swift
import SwiftUI

struct RecordingView: View {
    @StateObject private var viewModel = RecordingViewModel()
    @State private var showingSaveDialog = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // 1. AudioWaveformView에 viewModel을 전달
                AudioWaveformView(viewModel: viewModel)
                    .frame(height: 100)
                    .padding()
                
                ScrollView {
                    Text(viewModel.transcribedText.isEmpty ? "Start recording to see transcription..." : viewModel.transcribedText)
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .background(Color.gray.opacity(0.1))
                .cornerRadius(10)
                .padding()
                
                Text(viewModel.recordingTime)
                    .font(.largeTitle)
                    .monospacedDigit()
                
                HStack(spacing: 40) {
                    Spacer()
                    
                    Button(action: {
                        viewModel.handleMainButtonTap()
                    }) {
                        Image(systemName: mainButtonIcon)
                            .resizable()
                            .frame(width: 70, height: 70)
                            .foregroundColor(mainButtonColor)
                    }
                    
                    Button(action: {
                        showingSaveDialog = true
                    }) {
                        Image(systemName: "checkmark.circle.fill")
                            .resizable()
                            .frame(width: 50, height: 50)
                            .foregroundColor(.green)
                    }
                    .disabled(viewModel.recordingState != .paused)
                    
                    Spacer()
                }
                .padding()
            }
            .navigationTitle("Recording")
            .sheet(isPresented: $showingSaveDialog) {
                SaveNoteView(
                    transcribedText: viewModel.transcribedText,
                    onSave: {
                        viewModel.resetRecording()
                    }
                )
            }
        }
    }
    
    private var mainButtonIcon: String {
        switch viewModel.recordingState {
        case .idle:
            return "record.circle"
        case .recording:
            return "pause.circle.fill"
        case .paused:
            return "play.circle.fill"
        }
    }
    
    private var mainButtonColor: Color {
        switch viewModel.recordingState {
        case .idle:
            return .gray
        case .recording, .paused:
            return .blue
        }
    }
}
