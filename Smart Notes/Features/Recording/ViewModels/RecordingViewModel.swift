//
//  RecordingViewModel.swift
//

import SwiftUI
import Combine
import FirebaseAuth

enum RecordingState {
    case idle
    case recording
    case paused
}

class RecordingViewModel: ObservableObject {
    @Published var recordingState: RecordingState = .idle
    @Published var transcribedText = ""
    @Published var recordingTime = "00:00"
    @Published var currentAudioLevel: Float = 0.0
    
    private let speechService = SpeechRecognizerService()
    private let audioRecorder = AudioRecorderService()
    
    private var timer: Timer?
    private var seconds = 0
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        audioRecorder.$audioLevel
            .assign(to: \.currentAudioLevel, on: self)
            .store(in: &cancellables)
    }
    
    // 🔥 Firebase 업로드를 위해 파일 URL 리턴
    func getRecordingFileURL() -> URL? {
        return audioRecorder.getFileURL()
    }
    
    func handleMainButtonTap() {
        switch recordingState {
        case .idle:
            startRecording()
        case .recording:
            pauseRecording()
        case .paused:
            resumeRecording()
        }
    }
    
    private func startRecording() {
        speechService.requestAuthorization()
        speechService.startTranscribing()
        audioRecorder.startRecording()
        startTimer()
        recordingState = .recording
    }
    
    private func pauseRecording() {
        speechService.stopTranscribing()
        audioRecorder.pauseRecording()
        pauseTimer()
        recordingState = .paused
    }
    
    private func resumeRecording() {
        speechService.startTranscribing()
        audioRecorder.resumeRecording()
        resumeTimer()
        recordingState = .recording
    }
    
    func resetRecording() {
        speechService.stopTranscribing()
        audioRecorder.stopRecording()
        
        timer?.invalidate()
        timer = nil
        
        seconds = 0
        recordingTime = "00:00"
        transcribedText = ""
        recordingState = .idle
        currentAudioLevel = 0.0
    }
    
    // MARK: - Timer
    private func startTimer() {
        seconds = 0
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            self.seconds += 1
            self.updateTimerDisplay()
        }
    }
    
    private func pauseTimer() {
        timer?.invalidate()
        timer = nil
    }
    
    private func resumeTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            self.seconds += 1
            self.updateTimerDisplay()
        }
    }
    
    private func updateTimerDisplay() {
        let minutes = seconds / 60
        let seconds = seconds % 60
        recordingTime = String(format: "%02d:%02d", minutes, seconds)
    }
    
    @Published var aiSummary: String = ""

    func generateAISummary() {
        Task {
            let gemini = GeminiService()

            do {
                let summary = try await gemini.summarize(self.transcribedText)
                await MainActor.run {
                    self.aiSummary = summary
                }
            } catch {
                await MainActor.run {
                    self.aiSummary = "⚠️ Summary failed: \(error.localizedDescription)"
                }
            }
        }
    }


}
