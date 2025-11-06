import SwiftUI
import Combine

class RecordingViewModel: ObservableObject {
    @Published var isRecording = false
    @Published var isPaused = false
    @Published var transcribedText = ""
    @Published var recordingTime = "00:00"
    
    private let speechService = SpeechRecognizerService()
    private let audioRecorder = AudioRecorderService()
    private var timer: Timer?
    private var seconds = 0
    
    init() {
        setupBindings()
    }
    
    private func setupBindings() {
        speechService.$transcribedText
            .assign(to: &$transcribedText)
        
        speechService.$isTranscribing
            .assign(to: &$isRecording)
    }
    
    func toggleRecording() {
        if isRecording {
            stopRecording()
        } else {
            startRecording()
        }
    }
    
    private func startRecording() {
        speechService.requestAuthorization()
        speechService.startTranscribing()
        startTimer()
    }
    
    private func stopRecording() {
        speechService.stopTranscribing()
        stopTimer()
    }
    
    func togglePause() {
        isPaused.toggle()
        // 일시정지 로직 구현
    }
    
    private func startTimer() {
        seconds = 0
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            self.seconds += 1
            let minutes = self.seconds / 60
            let seconds = self.seconds % 60
            self.recordingTime = String(format: "%02d:%02d", minutes, seconds)
        }
    }
    
    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }
}
