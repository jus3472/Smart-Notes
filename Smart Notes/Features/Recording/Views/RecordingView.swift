//
//  RecordingView.swift
//

import SwiftUI
import FirebaseAuth

struct RecordingView: View {
    @StateObject private var viewModel = RecordingViewModel()
    
    // 🔥 Firebase 업로드 후 audioUrl 저장
    @State private var uploadResultAudioURL: String? = nil
    
    @State private var showingSaveDialog = false
    
    
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
                
                HStack(spacing: 40) {
                    Spacer()
                    
                    // 🎤 녹음/일시정지/재생 버튼
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
                        .foregroundColor(viewModel.recordingState == .idle ? .red : .gray)
                    }

                    
                    // 💾 저장 버튼 → Firebase 업로드 → SaveNoteView 열기
                    Button(action: uploadAndOpenSaveView) {
                        Image(systemName: "checkmark.circle.fill")
                            .resizable()
                            .frame(width: 50, height: 50)
                            .foregroundColor(.green)
                    }
                    .disabled(viewModel.recordingState != .paused)

                    
                    Spacer()
                }
                .padding()
                
                Button("Generate Summary") {
                    viewModel.generateAISummary()
                }
                .buttonStyle(.borderedProminent)
                .padding(.top, 10)

                // ✅ AI 요약 결과 표시
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
            .sheet(isPresented: $showingSaveDialog) {
                SaveNoteView(
                    transcribedText: viewModel.transcribedText,
                    audioUrl: uploadResultAudioURL,
                    onSave: {
                        viewModel.resetRecording()
                    }
                )
            }
        }
    }
    
    // MARK: - Firebase 업로드 로직
    private func uploadAndOpenSaveView() {
        guard let fileURL = viewModel.getRecordingFileURL(),
              let uid = Auth.auth().currentUser?.uid else {
            print("❌ No file URL or uid")
            return
        }
        
        FirebaseNoteService.shared.uploadRecording(uid: uid, fileURL: fileURL) { result in
            switch result {
            case .success(let url):
                DispatchQueue.main.async {
                    self.uploadResultAudioURL = url
                    self.showingSaveDialog = true
                }
                
            case .failure(let error):
                print("❌ Upload failed:", error.localizedDescription)
            }
        }
    }
    
    // UI Helpers
    private var mainButtonIcon: String {
        switch viewModel.recordingState {
        case .idle: return "record.circle"
        case .recording: return "pause.circle.fill"
        case .paused: return "play.circle.fill"
        }
    }
    
    private var mainButtonColor: Color {
        switch viewModel.recordingState {
        case .idle: return .gray
        case .recording, .paused: return .blue
        }
    }
}
