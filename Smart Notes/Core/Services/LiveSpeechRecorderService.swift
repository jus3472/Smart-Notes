// LiveSpeechRecorderService.swift

import Foundation
import AVFoundation
import Speech
import Combine

class LiveSpeechRecorderService: NSObject, ObservableObject {
    // MARK: - Published properties
    @Published var transcribedText: String = ""
    @Published var isRecording: Bool = false
    @Published var audioLevel: Float = 0.0  // 0.0 ~ 1.0 (waveform 용)
    
    // 최종 녹음 파일 URL (Firebase 업로드용)
    private(set) var finalRecordingURL: URL?
    
    // MARK: - Private properties
    private let audioEngine = AVAudioEngine()
    private let speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US"))
    
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    
    private var audioFile: AVAudioFile?   // 실시간 파일 쓰기용
    private let session = AVAudioSession.sharedInstance()
    
    // MARK: - Authorization
    func requestAuthorization() {
        SFSpeechRecognizer.requestAuthorization { status in
            DispatchQueue.main.async {
                switch status {
                case .authorized:
                    print("✅ Speech recognition authorized")
                default:
                    print("❌ Speech recognition not authorized: \(status)")
                }
            }
        }
    }
    
    // MARK: - Start Recording + Live STT
    func start() {
        if isRecording { return }
        isRecording = true
        transcribedText = ""
        audioLevel = 0.0
        finalRecordingURL = nil
        
        // 1) Audio Session 설정
        do {
            try session.setCategory(.playAndRecord,
                                    mode: .default,
                                    options: [.duckOthers])

            try session.setActive(true, options: .notifyOthersOnDeactivation)
        } catch {
            print("❌ Audio session setup failed: \(error.localizedDescription)")
        }
        
        // 2) Speech Recognition Request 생성
        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        recognitionRequest?.shouldReportPartialResults = true
        
        // 3) 저장할 파일 URL 생성
        let filename = UUID().uuidString + ".m4a"
        let url = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent(filename)
        
        // 4) AVAudioEngine input tap 설정
        let inputNode = audioEngine.inputNode
        inputNode.removeTap(onBus: 0)
        
        let format = inputNode.outputFormat(forBus: 0)
        
        do {
            // AVAudioFile 생성 (실시간으로 buffer를 써 넣음)
            audioFile = try AVAudioFile(forWriting: url,
                                        settings: format.settings)
            print("🎧 Will record to file:", url)
        } catch {
            print("❌ Failed to create AVAudioFile:", error.localizedDescription)
        }
        
        inputNode.installTap(onBus: 0,
                             bufferSize: 1024,
                             format: format) { [weak self] buffer, _ in
            guard let self = self else { return }
            
            // ① STT용으로 buffer append
            self.recognitionRequest?.append(buffer)
            
            // ② 파일로 쓰기
            if let file = self.audioFile {
                do {
                    try file.write(from: buffer)
                } catch {
                    print("❌ Failed to write buffer to file:", error.localizedDescription)
                }
            }
            
            // ③ audioLevel 계산 (waveform)
            self.updateAudioLevel(from: buffer)
        }
        
        // 5) AudioEngine 시작
        audioEngine.prepare()
        do {
            try audioEngine.start()
            print("✅ Audio engine started")
        } catch {
            print("❌ Audio engine couldn't start:", error.localizedDescription)
        }
        
        // 6) Speech Recognition Task 시작
        guard let recognizer = speechRecognizer, let request = recognitionRequest else {
            print("❌ Speech recognizer or request is nil")
            return
        }
        
        recognitionTask = recognizer.recognitionTask(with: request) { [weak self] result, error in
            guard let self = self else { return }
            
            if let result = result {
                DispatchQueue.main.async {
                    self.transcribedText = result.bestTranscription.formattedString
                }
            }
            
            if let error = error {
                print("❌ Recognition error:", error.localizedDescription)
                self.stop()
            } else if result?.isFinal == true {
                self.stop()
            }
        }
    }
    
    // MARK: - Stop Recording + STT
    func stop() {
        if !isRecording { return }
        isRecording = false
        
        // tap 제거
        let inputNode = audioEngine.inputNode
        inputNode.removeTap(onBus: 0)
        
        // 오디오 엔진 종료
        audioEngine.stop()
        audioEngine.reset()
        
        // STT 정상 종료
        recognitionRequest?.endAudio()
        recognitionTask = nil
        recognitionRequest = nil
        
        // 파일 URL 저장
        if let file = audioFile {
            finalRecordingURL = file.url
            print("✅ Final recording file URL:", file.url)
        }
        audioFile = nil
        
        // 세션 비활성화
        try? session.setActive(false)
    }

    
    // MARK: - Audio Level 계산
    private func updateAudioLevel(from buffer: AVAudioPCMBuffer) {
        guard let channelData = buffer.floatChannelData?[0] else { return }
        let frameLength = Int(buffer.frameLength)
        if frameLength == 0 { return }
        
        // 간단한 RMS 계산
        var sum: Float = 0.0
        for i in 0..<frameLength {
            let sample = channelData[i]
            sum += sample * sample
        }
        let rms = sqrt(sum / Float(frameLength))  // 0 ~ 1 근처
        
        // 적당히 스케일링해서 0~1 클램핑
        let level = min(max(rms * 5, 0.0), 1.0)  // multiplier는 UI 보면서 조절
        
        DispatchQueue.main.async {
            self.audioLevel = level
        }
    }
}
