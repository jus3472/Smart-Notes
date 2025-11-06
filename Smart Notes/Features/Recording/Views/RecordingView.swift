// RecordingView.swift
import SwiftUI

struct RecordingView: View {
    @StateObject private var viewModel = RecordingViewModel()
    @State private var showingSaveDialog = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // ... (파형 뷰, 전사된 텍스트, 녹음 시간 표시는 동일) ...
                
                 AudioWaveformView()
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
                
                // --- 컨트롤 버튼 (수정된 부분) ---
                HStack(spacing: 40) {
                    Spacer() // 버튼들을 중앙으로 정렬하기 위한 Spacer
                    
                    // 1. 메인 녹음/일시정지/재개 버튼
                    Button(action: {
                        viewModel.handleMainButtonTap()
                    }) {
                        Image(systemName: mainButtonIcon)
                            .resizable()
                            .frame(width: 70, height: 70)
                            .foregroundColor(mainButtonColor)
                    }
                    
                    // 2. 저장 버튼
                    Button(action: {
                        showingSaveDialog = true
                    }) {
                        Image(systemName: "checkmark.circle.fill")
                            .resizable()
                            .frame(width: 50, height: 50)
                            .foregroundColor(.green)
                    }
                    // 3. '일시정지' 상태일 때만 활성화
                    .disabled(viewModel.recordingState != .paused)
                    
                    Spacer() // 버튼들을 중앙으로 정렬하기 위한 Spacer
                }
                .padding()
            }
            .navigationTitle("Recording")
            // 4. SaveNoteView가 닫힐 때가 아니라, '저장'이 성공했을 때만 리셋하도록 onSave 클로저 전달
            .sheet(isPresented: $showingSaveDialog) {
                SaveNoteView(
                    transcribedText: viewModel.transcribedText,
                    onSave: {
                        // 저장이 완료되면 ViewModel 상태를 리셋
                        viewModel.resetRecording()
                    }
                )
            }
        }
    }
    
    // --- View 로직 헬퍼 ---
    
    private var mainButtonIcon: String {
        switch viewModel.recordingState {
        case .idle:
            return "record.circle" // 시작
        case .recording:
            return "pause.circle.fill" // 일시정지
        case .paused:
            return "play.circle.fill" // 재개
        }
    }
    
    private var mainButtonColor: Color {
        switch viewModel.recordingState {
        case .idle:
            return .gray
        case .recording, .paused:
            return .blue // 일시정지/재개는 파란색으로 통일 (또는 .red)
        }
    }
}
