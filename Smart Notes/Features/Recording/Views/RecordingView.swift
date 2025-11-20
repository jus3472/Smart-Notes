//
//  RecordingView.swift
//

import SwiftUI
import FirebaseAuth

struct RecordingView: View {
    @StateObject private var viewModel = RecordingViewModel()

    @State private var showTitlePrompt = false
    @State private var noteTitleInput = ""

    @State private var showSaveAlert = false
    @State private var saveMessage = ""

    var body: some View {
        NavigationView {
            VStack(spacing: 20) {

                // MARK: Waveform
                AudioWaveformView(viewModel: viewModel)
                    .frame(height: 100)
                    .padding()

                // MARK: Transcription
                ScrollView {
                    Text(
                        viewModel.transcribedText.isEmpty
                        ? "Start recording to see transcription..."
                        : viewModel.transcribedText
                    )
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                .frame(height: 200)
                .background(Color.gray.opacity(0.1))
                .cornerRadius(10)
                .padding()

                // MARK: Timer
                Text(viewModel.recordingTime)
                    .font(.largeTitle)
                    .monospacedDigit()

                // MARK: Buttons
                HStack(spacing: 40) {
                    Spacer()

                    // RECORD / PAUSE / RESUME BUTTON
                    Button {
                        switch viewModel.recordingState {
                        case .idle:
                            viewModel.startRecording()

                        case .recording:
                            viewModel.pauseRecording()

                        case .paused:
                            viewModel.resumeRecording()
                        }
                    } label: {
                        Image(
                            systemName:
                                viewModel.recordingState == .idle ? "record.circle" :
                                viewModel.recordingState == .recording ? "pause.circle.fill" :
                                "play.circle.fill"
                        )
                        .resizable()
                        .frame(width: 70, height: 70)
                        .foregroundColor(
                            viewModel.recordingState == .idle ? .red :
                            viewModel.recordingState == .recording ? .orange :
                            .green
                        )
                    }

                    // SAVE BUTTON
                    Button {
                        viewModel.stopRecording()
                        showTitlePrompt = true
                    } label: {
                        Image(systemName: "checkmark.circle.fill")
                            .resizable()
                            .frame(width: 70, height: 70)
                            .foregroundColor(
                                viewModel.recordingState == .paused ? .green : .gray
                            )
                    }
                    .disabled(viewModel.recordingState != .paused)

                    Spacer()
                }
                .padding()

                // MARK: AI Summary Loading
                if viewModel.isProcessing {
                    ProgressView("Generating summary...")
                        .padding()
                }

                if !viewModel.aiSummary.isEmpty {
                    Text(viewModel.aiSummary)
                        .padding()
                        .background(Color.yellow.opacity(0.15))
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .cornerRadius(8)
                        .padding(.horizontal)
                }
            }
            .navigationTitle("Recording")
        }
        // MARK: Title Input
        .alert("Enter Note Title", isPresented: $showTitlePrompt) {
            TextField("Note title", text: $noteTitleInput)
            Button("Save") { saveNote() }
            Button("Cancel", role: .cancel) {}
        }

        // MARK: Save Alert
        .alert("Status", isPresented: $showSaveAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(saveMessage)
        }
    }

    // MARK: Save Logic
    func saveNote() {
        guard !noteTitleInput.isEmpty else { return }

        Task {
            do {
                try await viewModel.generateSummaryAndSave(title: noteTitleInput)
                saveMessage = "Your '\(noteTitleInput)' note has been saved."
                showSaveAlert = true
            } catch {
                saveMessage = "Failed to save note."
                showSaveAlert = true
            }
        }
    }
}
