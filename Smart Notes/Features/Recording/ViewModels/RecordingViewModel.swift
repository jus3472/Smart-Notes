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

    // MARK: - Published States
    @Published var recordingState: RecordingState = .idle
    @Published var transcribedText: String = ""
    @Published var recordingTime: String = "00:00"
    @Published var currentAudioLevel: Float = 0.0
    @Published var aiSummary: String = ""
    @Published var isProcessing = false

    // MARK: - Internal States
    private let liveService = LiveSpeechRecorderService()

    private var timer: Timer?
    private var seconds = 0
    private var cancellables = Set<AnyCancellable>()

    @Published var isPaused: Bool = false   // ⭐ 추가: UI 업데이트 제어용

    init() {

        // MARK: STT Binding (pause-safe)
        liveService.$transcribedText
            .receive(on: RunLoop.main)
            .sink { [weak self] newValue in
                guard let self = self else { return }

                // ⭐ Pause 상태일 때는 UI 업데이트 무시
                if self.isPaused { return }

                // Resume 중에는 LiveService가 append하여 push
                self.transcribedText = newValue
            }
            .store(in: &cancellables)

        liveService.$audioLevel
            .receive(on: RunLoop.main)
            .assign(to: \.currentAudioLevel, on: self)
            .store(in: &cancellables)
    }

    // MARK: - Recording Control
    func startRecording() {
        isPaused = false
        liveService.requestAuthorization()
        liveService.start()
        startTimer(reset: true)
        recordingState = .recording
    }

    func pauseRecording() {
        isPaused = true         // ⭐ pause 상태
        liveService.pause()
        stopTimer()
        recordingState = .paused
    }

    func resumeRecording() {
        isPaused = false
        liveService.resume()
        startTimer(reset: false)
        recordingState = .recording
    }

    func stopRecording() {
        isPaused = false
        liveService.stop()
        stopTimer()
        recordingTime = "00:00"
        recordingState = .idle
    }

    // MARK: - Timer
    private func startTimer(reset: Bool = true) {
        if reset { seconds = 0 }
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            self.seconds += 1
            self.updateTimer()
        }
    }

    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }

    private func updateTimer() {
        let m = seconds / 60
        let s = seconds % 60
        recordingTime = String(format: "%02d:%02d", m, s)
    }

    // MARK: - Save Summary
    @MainActor
    func generateSummaryAndSave(title: String, folderId: String?) async throws {
        guard let uid = Auth.auth().currentUser?.uid else { return }

        isProcessing = true
        defer { isProcessing = false }

        let gemini = GeminiService()
        let summary = try await gemini.summarize(self.transcribedText)
        self.aiSummary = summary

        let fullContent = """
        📌 Summary:
        \(summary)
        """

        FirebaseNoteService.shared.addNote(
            uid: uid,
            title: title,
            content: fullContent,
            folderId: folderId   // store in chosen folder
        )
    }
}
