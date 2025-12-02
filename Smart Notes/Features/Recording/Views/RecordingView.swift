// RecordingView.swift
import SwiftUI
import FirebaseAuth

struct RecordingView: View {
    @StateObject private var viewModel = RecordingViewModel()
    @StateObject private var foldersViewModel = FoldersViewModel()   // load folders

    @State private var showTitlePrompt = false
    @State private var noteTitleInput = ""

    @State private var showSaveAlert = false
    @State private var saveMessage = ""

    @State private var showFolderPicker = false   // new: show folder chooser
    
    @State private var showFullTranscriptionPrompt = false
    @State private var saveFullTranscript = false

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
                        // 기존: showTitlePrompt = true
                        // 변경: 먼저 full transcription 저장 여부부터 물어보기
                        showFullTranscriptionPrompt = true
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
        .confirmationDialog("Save full transcription too?",
                            isPresented: $showFullTranscriptionPrompt,
                            titleVisibility: .visible) {

            Button("Yes, save full transcription") {
                saveFullTranscript = true   // 👉 이 플래그를 나중에 전달
                showTitlePrompt = true      // 다음 단계: 노트 제목 입력으로 진행
            }

            Button("No, only summary") {
                saveFullTranscript = false
                showTitlePrompt = true
            }

            Button("Cancel", role: .cancel) {
                // 아무 것도 안 하고 종료
                saveFullTranscript = false
            }
        }
        // MARK: Title Input
        .alert("Enter Note Title", isPresented: $showTitlePrompt) {
            TextField("Note title", text: $noteTitleInput)
            Button("Next") {
                // after title, show folder picker
                if !noteTitleInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    showFolderPicker = true
                }
            }
            Button("Cancel", role: .cancel) {}
        }

        // MARK: Folder Picker
        .confirmationDialog("Choose Folder", isPresented: $showFolderPicker, titleVisibility: .visible) {

            // Option 1: Notes (루트)
            Button("Notes") {
                saveNote(in: nil)
            }

            // ⭐ Full Transcript 폴더는 제외한 나머지 폴더만 보여주기
            let userFolders = foldersViewModel.folders.filter {
                $0.name.trimmingCharacters(in: .whitespacesAndNewlines)
                    .lowercased() != "full transcript".lowercased()
            }

            // Option 2: user-created folders
            ForEach(userFolders) { folder in
                Button(folder.name) {
                    saveNote(in: folder)
                }
            }

            Button("Cancel", role: .cancel) {}
        }

        // MARK: Save Alert
        .alert("Status", isPresented: $showSaveAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(saveMessage)
        }
    }

    // MARK: Save Logic with folder
    func saveNote(in folder: SNFolder?) {
        let trimmedTitle = noteTitleInput.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedTitle.isEmpty else { return }

        Task {
            do {
                try await viewModel.generateSummaryAndSave(
                    title: trimmedTitle,
                    folderId: folder?.id,
                    saveFullTranscript: saveFullTranscript   // ⭐ 새 파라미터
                )

                let locationName = folder?.name ?? "Notes"
                saveMessage = "Your '\(trimmedTitle)' note has been saved in \"\(locationName)\"."
                showSaveAlert = true

                // reset
                noteTitleInput = ""
                saveFullTranscript = false   // ⭐ 다음 사용을 위해 초기화
            } catch {
                saveMessage = "Failed to save note."
                showSaveAlert = true
            }
        }
    }

}
