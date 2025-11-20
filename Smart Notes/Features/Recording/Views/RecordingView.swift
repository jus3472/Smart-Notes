//
//  RecordingView.swift
//

import SwiftUI
import FirebaseAuth

struct RecordingView: View {
    @StateObject private var viewModel = RecordingViewModel()

    var body: some View {
        NavigationView {
            VStack(spacing: 20) {

                // Waveform
                AudioWaveformView(viewModel: viewModel)
                    .frame(height: 100)
                    .padding()

                // Transcription text
                ScrollView {
                    Text(viewModel.transcribedText.isEmpty
                         ? "Start recording to see transcription..."
                         : viewModel.transcribedText)
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                .background(Color.gray.opacity(0.1))
                .cornerRadius(10)
                .padding()

                Text(viewModel.recordingTime)
                    .font(.largeTitle)
                    .monospacedDigit()

                // RECORD / STOP + SAVE
                HStack(spacing: 40) {
                    Spacer()

                    // 🎤 Start / Stop Recording
                    Button(action: {
                        if viewModel.recordingState == .idle {
                            viewModel.startRecording()
                        } else if viewModel.recordingState == .recording {
                            viewModel.stopRecording()
                        }
                    }) {
                        Image(systemName:
                                viewModel.recordingState == .idle
                                ? "record.circle"
                                : "stop.circle.fill"
                        )
                        .resizable()
                        .frame(width: 70, height: 70)
                        .foregroundColor(
                            viewModel.recordingState == .idle ? .red : .gray
                        )
                    }

                    // 💾 SAVE SUMMARY (AI)
     
                    Button {
                        Task {
                            await viewModel.saveSummaryNote()
                        }
                    } label: {
                        Image(systemName: "checkmark.circle.fill")
                            .resizable()
                            .frame(width: 50, height: 50)
                            .foregroundColor(.green)
                    }
                    .disabled(viewModel.transcribedText.isEmpty ||
                              viewModel.recordingState != .idle)


                    Spacer()
                }
                .padding()

                // AI Summary Preview
                if !viewModel.aiSummary.isEmpty {
                    Text(viewModel.aiSummary)
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color.yellow.opacity(0.15))
                        .cornerRadius(8)
                        .padding(.horizontal)
                }
            }
            .navigationTitle("Recording")
        }
    }
}

