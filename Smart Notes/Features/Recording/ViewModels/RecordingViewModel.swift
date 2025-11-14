// RecordingViewModel.swift
import SwiftUI
import Combine

enum RecordingState {
    case idle
    case recording
    case paused
}

class RecordingViewModel: ObservableObject {
    @Published var recordingState: RecordingState = .idle
    @Published var transcribedText = ""
    @Published var recordingTime = "00:00"
    
    // 1. AudioRecorderService의 오디오 레벨을 받아올 @Published 변수 추가
    @Published var currentAudioLevel: Float = 0.0
    
    private let speechService = SpeechRecognizerService()
    private let audioRecorder = AudioRecorderService() // ✅ AudioRecorderService 인스턴스 사용
    private var timer: Timer?
    private var seconds = 0
    private var cancellables = Set<AnyCancellable>() // ✅ Combine 구독 관리를 위한 Set
    
    init() {
        // 2. AudioRecorderService의 audioLevel을 currentAudioLevel에 바인딩
        audioRecorder.$audioLevel
            .assign(to: \.currentAudioLevel, on: self)
            .store(in: &cancellables)
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
        audioRecorder.startRecording() // ✅ 녹음 시작 시 AudioRecorderService 시작
        startTimer()
        recordingState = .recording
    }
    
    private func pauseRecording() {
        speechService.stopTranscribing()
        audioRecorder.pauseRecording() // ✅ 녹음 일시정지 시 AudioRecorderService 일시정지
        pauseTimer()
        recordingState = .paused
    }
    
    private func resumeRecording() {
        speechService.startTranscribing()
        audioRecorder.resumeRecording() // ✅ 녹음 재개 시 AudioRecorderService 재개
        resumeTimer()
        recordingState = .recording
    }
    func resetRecording() {
            speechService.stopTranscribing()
            audioRecorder.stopRecording()
            
            // 1. stopTimer() 대신 이 두 줄로 수정합니다.
            timer?.invalidate()
            timer = nil
            
            seconds = 0
            recordingTime = "00:00"
            transcribedText = ""
            recordingState = .idle
            currentAudioLevel = 0.0 // 오디오 레벨 초기화
        }
    
    // --- 타이머 로직은 기존과 동일 ---
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
