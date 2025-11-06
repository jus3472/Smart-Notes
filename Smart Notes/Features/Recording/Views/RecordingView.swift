import SwiftUI

struct RecordingView: View {
    @StateObject private var viewModel = RecordingViewModel()
    @State private var showingSaveDialog = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // 파형 뷰 (placeholder)
                AudioWaveformView()
                    .frame(height: 100)
                    .padding()
                
                // 전사된 텍스트
                ScrollView {
                    Text(viewModel.transcribedText.isEmpty ? "Start recording to see transcription..." : viewModel.transcribedText)
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .background(Color.gray.opacity(0.1))
                .cornerRadius(10)
                .padding()
                
                // 녹음 시간 표시
                Text(viewModel.recordingTime)
                    .font(.largeTitle)
                    .monospacedDigit()
                
                // 컨트롤 버튼들
                HStack(spacing: 40) {
                    // 녹음 버튼
                    Button(action: {
                        viewModel.toggleRecording()
                    }) {
                        Image(systemName: viewModel.isRecording ? "stop.circle.fill" : "record.circle")
                            .resizable()
                            .frame(width: 70, height: 70)
                            .foregroundColor(viewModel.isRecording ? .red : .gray)
                    }
                    
                    // 일시정지 버튼
                    Button(action: {
                        viewModel.togglePause()
                    }) {
                        Image(systemName: viewModel.isPaused ? "play.circle.fill" : "pause.circle.fill")
                            .resizable()
                            .frame(width: 50, height: 50)
                            .foregroundColor(.blue)
                    }
                    .disabled(!viewModel.isRecording)
                    
                    // 저장 버튼
                    Button(action: {
                        showingSaveDialog = true
                    }) {
                        Image(systemName: "checkmark.circle.fill")
                            .resizable()
                            .frame(width: 50, height: 50)
                            .foregroundColor(.green)
                    }
                    .disabled(viewModel.transcribedText.isEmpty)
                }
                .padding()
            }
            .navigationTitle("Recording")
            .sheet(isPresented: $showingSaveDialog) {
                SaveNoteView(transcribedText: viewModel.transcribedText)
            }
        }
    }
}
