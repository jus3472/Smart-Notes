// RecordingViewModel.swift
import SwiftUI
import Combine

// 1. 상태를 명확하게 관리하기 위한 Enum 정의
enum RecordingState {
    case idle
    case recording
    case paused
}

class RecordingViewModel: ObservableObject {
    // 2. 두 개의 Bool 대신 단일 상태(State) 변수 사용
    @Published var recordingState: RecordingState = .idle
    @Published var transcribedText = ""
    @Published var recordingTime = "00:00"
    
    private let speechService = SpeechRecognizerService()
    // private let audioRecorder = AudioRecorderService() // 코드에서 사용되지 않아 주석 처리
    private var timer: Timer?
    private var seconds = 0
    
    init() {
        // 3. speechService의 상태를 직접 바인딩하는 대신, VM이 상태를 관리하도록 setupBindings 제거
        // setupBindings()
    }
    
    // 4. 메인 버튼(녹음/일시정지/재개)을 처리하는 통합 함수
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
        startTimer()
        recordingState = .recording
    }
    
    // 5. 일시정지 로직 (SpeechService에 pause가 없다면 stop/start로 대체)
    private func pauseRecording() {
        speechService.stopTranscribing() // HACK: SpeechService에 pause 기능이 없다고 가정
        pauseTimer()
        recordingState = .paused
    }
    
    // 6. 재개 로직
    private func resumeRecording() {
        speechService.startTranscribing() // HACK: SpeechService에 resume 기능이 없다고 가정
        resumeTimer()
        recordingState = .recording
    }
    
    // 7. 녹음 완료 후 모든 상태를 초기화하는 함수
    func resetRecording() {
        speechService.stopTranscribing()
        timer?.invalidate()
        timer = nil
        seconds = 0
        recordingTime = "00:00"
        transcribedText = ""
        recordingState = .idle
    }
    
    // --- 타이머 로직 수정 ---
    
    private func startTimer() {
        seconds = 0
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            self.seconds += 1
            self.updateTimerDisplay()
        }
    }
    
    private func pauseTimer() {
        timer?.invalidate()
        timer = nil
    }
    
    private func resumeTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            self.seconds += 1
            self.updateTimerDisplay()
        }
    }
    
    private func updateTimerDisplay() {
        let minutes = self.seconds / 60
        let seconds = self.seconds % 60
        self.recordingTime = String(format: "%02d:%02d", minutes, seconds)
    }
}
