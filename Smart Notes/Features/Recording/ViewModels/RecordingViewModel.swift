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

    @Published var isPaused: Bool = false

    init() {

        // MARK: STT Binding (pause-safe)
        liveService.$transcribedText
            .receive(on: RunLoop.main)
            .sink { [weak self] newValue in
                guard let self = self else { return }

               
                if self.isPaused { return }

              
                if self.recordingState == .idle { return }

                
                if newValue.isEmpty && !self.transcribedText.isEmpty {
                    return
                }

               
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

      
        transcribedText = ""
        aiSummary = ""

        liveService.requestAuthorization()
        liveService.start()
        startTimer(reset: true)
        recordingState = .recording
    }

    func pauseRecording() {
        isPaused = true
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

       
        let finalTranscript = self.transcribedText

        
        let summary = try await gemini.summarize(finalTranscript)
        self.aiSummary = summary

        
        let actionItems = try await gemini.extractActionItems(fromSummary: summary)
        let limitedItems = Array(actionItems.prefix(10))

        let rawTags = try await gemini.extractTags(fromSummary: summary)
        let tags = Array(rawTags.prefix(10))
        
        print("🎯 TAGS TO SAVE:", tags)

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
            title: title,
            content: summaryContent,
            folderId: folderId,
            tags: tags
        )

        // =========================
        // (B) Full Transcript 노트 저장 (옵션 + Diarization)
        // =========================
        guard saveFullTranscript else {
            return
        }

        let diarizedTranscript = try await gemini.diarize(finalTranscript)

        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm"
        let dateString = formatter.string(from: Date())
        let transcriptTitle = "\(dateString) Recording"

        let fullTranscriptionFolderId = try await FirebaseNoteService.shared
            .getOrCreateFolderId(uid: uid, name: "Full Transcript")

        FirebaseNoteService.shared.addNote(
            uid: uid,
            title: transcriptTitle,
            content: diarizedTranscript,
            folderId: fullTranscriptionFolderId,
            tags: tags
        )
    }
}
