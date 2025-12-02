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

    // MARK: - Save Summary + Optional Full Transcript with Diarization
    @MainActor
    func generateSummaryAndSave(
        title: String,
        folderId: String?,
        saveFullTranscript: Bool
    ) async throws {
        guard let uid = Auth.auth().currentUser?.uid else { return }

        isProcessing = true
        defer { isProcessing = false }

        let gemini = GeminiService()

        // 1) 최종 transcript (라이브 텍스트 그대로)
        let finalTranscript = self.transcribedText

        // 2) 요약 생성
        let summary = try await gemini.summarize(finalTranscript)
        self.aiSummary = summary

        // 3) 액션 아이템 추출 (최대 10개)
        let actionItems = try await gemini.extractActionItems(fromSummary: summary)
        let limitedItems = Array(actionItems.prefix(10))

        // =========================
        // (A) 요약 노트 저장 (사용자가 고른 폴더)
        // =========================

        var actionBlock = ""
        if !limitedItems.isEmpty {
            let bulletLines = limitedItems
                .map { "- [ ] \($0)" }
                .joined(separator: "\n")

            actionBlock = """

            ✅ Action Items:
            \(bulletLines)
            """
        }

        let summaryContent = """
        📌 Summary:
        \(summary)\(actionBlock)
        """

        FirebaseNoteService.shared.addNote(
            uid: uid,
            title: title,          // 사용자가 입력한 제목
            content: summaryContent,
            folderId: folderId     // 사용자가 선택한 폴더
        )

        // =========================
        // (B) Full Transcript 노트 저장 (옵션 + Diarization)
        // =========================
        guard saveFullTranscript else {
            // 사용자가 "No" 선택한 경우 → 여기서 끝
            return
        }

        // 3) Gemini로 speaker diarization 적용
        let diarizedTranscript = try await gemini.diarize(finalTranscript)

        // 4) 날짜 + "Recording" 형식으로 제목 생성
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm"
        let dateString = formatter.string(from: Date())
        let transcriptTitle = "\(dateString) Recording"

        // 5) "Full Transcription" 폴더 id 가져오기 (없으면 생성)
        let fullTranscriptionFolderId = try await FirebaseNoteService.shared
            .getOrCreateFolderId(uid: uid, name: "Full Transcript")

        // 6) diarized transcript만 단독으로 저장
        FirebaseNoteService.shared.addNote(
            uid: uid,
            title: transcriptTitle,
            content: diarizedTranscript,   // 🔥 화자 라벨이 붙은 버전
            folderId: fullTranscriptionFolderId
        )
    }

}
