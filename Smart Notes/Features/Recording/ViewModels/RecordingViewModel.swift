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
    @Published var transcribedText: String = ""
    @Published var recordingTime: String = "00:00"
    @Published var currentAudioLevel: Float = 0.0
    @Published var aiSummary: String = ""
    
    private let liveService = LiveSpeechRecorderService()
    private var timer: Timer?
    private var seconds = 0
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        // 서비스의 값들을 뷰모델로 전달
        liveService.$transcribedText
            .receive(on: RunLoop.main)
            .assign(to: \.transcribedText, on: self)
            .store(in: &cancellables)
        
        liveService.$audioLevel
            .receive(on: RunLoop.main)
            .assign(to: \.currentAudioLevel, on: self)
            .store(in: &cancellables)
        
        print("🔑 Gemini API Key:", Secrets.geminiAPIKey)

    }
    
    // Firebase 업로드용 파일 URL
    func getRecordingFileURL() -> URL? {
        return liveService.finalRecordingURL
    }
    
    func handleMainButtonTap() {
        switch recordingState {
        case .idle:
            startRecording()
        case .recording:
            stopRecording()
        case .paused:
            // 이 구조에서는 일단 pause/resume 없이 가도 됨
            break
        }
    }
    
    func startRecording() {
        liveService.requestAuthorization()
        liveService.start()
        startTimer()
        recordingState = .recording
    }
    
    func stopRecording() {
        liveService.stop()
        stopTimer()
        recordingState = .idle
    }
    
    func resetRecording() {
        stopRecording()
        seconds = 0
        recordingTime = "00:00"
        transcribedText = ""
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
    
    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }
    
    private func updateTimerDisplay() {
        let minutes = seconds / 60
        let seconds = seconds % 60
        recordingTime = String(format: "%02d:%02d", minutes, seconds)
    }
    
    // MARK: - AI Summary (그대로 사용 가능)
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
