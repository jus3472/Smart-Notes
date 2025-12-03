//
//  LiveSpeechRecorderService.swift
//

import Foundation
import AVFoundation
import Speech
import Combine

class LiveSpeechRecorderService: NSObject, ObservableObject {

    // MARK: - Published
    @Published var transcribedText: String = ""
    @Published var isRecording: Bool = false
    @Published var audioLevel: Float = 0.0

    // MARK: - Private
    private let audioEngine = AVAudioEngine()
    private let speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US"))
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?

    private var audioFile: AVAudioFile?
    private let session = AVAudioSession.sharedInstance()

    private(set) var finalRecordingURL: URL?
    
    private var isPaused = false
    private var isResuming = false

    private var accumulatedText: String = ""  // 전체 누적 STT

    // MARK: - Authorization
    func requestAuthorization() {
        SFSpeechRecognizer.requestAuthorization { status in
            print("Speech Authorization:", status.rawValue)
        }
    }

    // MARK: - START
    func start() {
        print("🎙 START")
        isRecording = true
        isPaused = false
        isResuming = false

        accumulatedText = ""
        transcribedText = ""

        setupAudioSession()
        setupRecognitionRequest()
        setupAudioFile()
        setupAudioTap()

        startAudioEngine()
        startRecognitionTask()
    }

    // MARK: - PAUSE
    func pause() {
        print("⏸ PAUSE")
        isPaused = true  // STT 업데이트 무시

        audioEngine.pause()
        recognitionRequest?.endAudio()
        recognitionTask = nil
        recognitionRequest = nil

        // ✅ 지금 화면에 보이는 텍스트를 그대로 누적본으로 저장
        accumulatedText = transcribedText

        DispatchQueue.main.async {
            // ✅ accumulatedText가 항상 최신값이라, 여기서 날아가는 일 없음
            self.transcribedText = self.accumulatedText
        }

        isRecording = false
        isResuming = false
    }


    // MARK: - RESUME
    func resume() {
        print("▶️ RESUME")

        guard !isRecording else { return }
        isRecording = true
        isPaused = false
        isResuming = true  // append mode

        setupRecognitionRequest()
        startRecognitionTask()

        let inputNode = audioEngine.inputNode
        let format = inputNode.outputFormat(forBus: 0)

        inputNode.removeTap(onBus: 0)
        inputNode.installTap(onBus: 0,
                             bufferSize: 1024,
                             format: format) { [weak self] buffer, _ in
            guard let self = self else { return }
            self.recognitionRequest?.append(buffer)
            try? self.audioFile?.write(from: buffer)
            self.updateAudioLevel(from: buffer)
        }

        startAudioEngine()
    }

    // MARK: - STOP
    func stop() {
        print("🛑 STOP")
        isPaused = false
        isResuming = false
        isRecording = false

        audioEngine.inputNode.removeTap(onBus: 0)
        audioEngine.stop()
        audioEngine.reset()

        recognitionRequest?.endAudio()
        recognitionTask = nil
        recognitionRequest = nil

        if let file = audioFile {
            finalRecordingURL = file.url
        }
        audioFile = nil

        try? session.setActive(false)
    }

    // MARK: - Audio Session
    private func setupAudioSession() {
        try? session.setCategory(.playAndRecord, mode: .default,
                                 options: [.duckOthers, .allowBluetooth, .defaultToSpeaker])
        try? session.setActive(true)
    }

    // MARK: - Recognition Request
    private func setupRecognitionRequest() {
        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        recognitionRequest?.shouldReportPartialResults = true
    }

    // MARK: - Recognition Task
    private func startRecognitionTask() {
        guard let recognizer = speechRecognizer,
              let request = recognitionRequest else { return }

        recognitionTask = recognizer.recognitionTask(with: request) { [weak self] result, error in
            guard let self = self else { return }

            if let result = result {
                let newText = result.bestTranscription.formattedString

                DispatchQueue.main.async {

                    // 🔥 pause 상태에서는 STT 업데이트 무시
                    if self.isPaused { return }

                    if self.isResuming {
                        self.transcribedText = self.accumulatedText + " " + newText
                    } else {
                        self.transcribedText = newText
                    }
                }
            }

            // final or error
            if error != nil || result?.isFinal == true {
                self.accumulatedText = self.transcribedText
                self.isResuming = false
            }
        }
    }

    // MARK: - Audio File
    private func setupAudioFile() {
        let filename = UUID().uuidString + ".m4a"
        let url = FileManager.default.urls(for: .documentDirectory,
                                           in: .userDomainMask)[0]
            .appendingPathComponent(filename)

        let inputNode = audioEngine.inputNode
        let format = inputNode.outputFormat(forBus: 0)

        audioFile = try? AVAudioFile(forWriting: url, settings: format.settings)
    }

    // MARK: - Tap
    private func setupAudioTap() {
        let inputNode = audioEngine.inputNode
        inputNode.removeTap(onBus: 0)

        let format = inputNode.outputFormat(forBus: 0)

        inputNode.installTap(onBus: 0,
                             bufferSize: 1024,
                             format: format) { [weak self] buffer, _ in
            guard let self = self else { return }
            self.recognitionRequest?.append(buffer)
            try? self.audioFile?.write(from: buffer)
            self.updateAudioLevel(from: buffer)
        }
    }

    // MARK: Engine Start
    private func startAudioEngine() {
        try? audioEngine.start()
    }

    // MARK: Audio Level (RMS)
    private func updateAudioLevel(from buffer: AVAudioPCMBuffer) {
        guard let channelData = buffer.floatChannelData?[0] else { return }

        let frameLength = Int(buffer.frameLength)
        if frameLength == 0 { return }

        var sum: Float = 0
        for i in 0..<frameLength { sum += channelData[i] * channelData[i] }

        let rms = sqrt(sum / Float(frameLength))
        let level = min(max(rms * 5, 0.0), 1.0)

        DispatchQueue.main.async {
            self.audioLevel = level
        }
    }
}
