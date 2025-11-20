//
//  RecordingViewModel.swift
//

import SwiftUI
import Combine
import FirebaseAuth

enum RecordingState {
    case idle
    case recording
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
        // Live service → ViewModel data binding
        liveService.$transcribedText
            .receive(on: RunLoop.main)
            .assign(to: \.transcribedText, on: self)
            .store(in: &cancellables)

        liveService.$audioLevel
            .receive(on: RunLoop.main)
            .assign(to: \.currentAudioLevel, on: self)
            .store(in: &cancellables)
    }

    // MARK: - Recording Controls
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

    @MainActor
    func saveSummaryNote() async {
        guard let uid = Auth.auth().currentUser?.uid else { return }

        // 1) AI Summary 생성
        let gemini = GeminiService()
        let summary = (try? await gemini.summarize(self.transcribedText))
                    ?? "Summary unavailable"

        // 2) Firestore 저장
        let fullContent = """
        📌 Summary:
        \(summary)
        """


        FirebaseNoteService.shared.addNote(
            uid: uid,
            title: "New Note",
            content: fullContent,
            folderId: nil,
            audioUrl: nil
        )

        // 3) 녹음 리셋
        self.resetRecording()

        print("✅ Note saved with summary!")
    }

}
