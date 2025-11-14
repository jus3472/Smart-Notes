// AudioRecorderService.swift
import Foundation
import AVFoundation
import Combine
class AudioRecorderService: NSObject, ObservableObject, AVAudioRecorderDelegate {
    private var audioRecorder: AVAudioRecorder?
    private var audioSession = AVAudioSession.sharedInstance()
    private var meterTimer: Timer?

    @Published var audioLevel: Float = 0.0
    
    // 🔥 녹음된 최종 파일 URL (업로드용)
    private(set) var finalRecordingURL: URL?

    override init() {
        super.init()
        setupAudioSession()
    }

    private func setupAudioSession() {
        do {
            try audioSession.setCategory(.record, mode: .measurement, options: .duckOthers)
            try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
        } catch {
            print("Failed to setup audio session: \(error.localizedDescription)")
        }
    }

    func startRecording() {
        // 기존 녹음 중지
        audioRecorder?.stop()

        // 🔥 새로운 파일 경로 생성
        let filename = UUID().uuidString + ".m4a"
        let url = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent(filename)

        do {
            let settings: [String : Any] = [
                AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
                AVSampleRateKey: 12000,
                AVNumberOfChannelsKey: 1,
                AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
            ]

            audioRecorder = try AVAudioRecorder(url: url, settings: settings)
            audioRecorder?.delegate = self
            audioRecorder?.isMeteringEnabled = true
            audioRecorder?.prepareToRecord()
            audioRecorder?.record()
            startMetering()

            print("🎤 Recording started at:", url)

        } catch {
            print("Failed to start recording: \(error.localizedDescription)")
        }
    }

    func stopRecording() {
        guard let recorder = audioRecorder else { return }

        recorder.stop()
        meterTimer?.invalidate()
        meterTimer = nil
        audioLevel = 0.0

        // 🔥 파일 생성이 완료될 때까지 약간 대기
        let recordedURL = recorder.url
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            if FileManager.default.fileExists(atPath: recordedURL.path) {
                print("✅ File exists, ready for upload:", recordedURL)
                self.finalRecordingURL = recordedURL
            } else {
                print("❌ File does NOT exist yet")
            }
        }

        // ❗ audioRecorder를 여기서 nil으로 만들면 안 됨!!
        // audioRecorder = nil
    }

    func pauseRecording() {
        audioRecorder?.pause()
        meterTimer?.invalidate()
        meterTimer = nil
    }

    func resumeRecording() {
        audioRecorder?.record()
        startMetering()
    }

    private func startMetering() {
        meterTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            self.audioRecorder?.updateMeters()

            if let power = self.audioRecorder?.averagePower(forChannel: 0) {
                let normalized = pow(10, power / 20)
                DispatchQueue.main.async { self.audioLevel = normalized }
            }
        }
    }

    func audioRecorderDidFinishRecording(_ recorder: AVAudioRecorder, successfully flag: Bool) {
        if !flag { print("Recording finished unsuccessfully.") }

        stopRecording()
    }

    // 업로드용 파일 URL 전달
    func getFileURL() -> URL? {
        return finalRecordingURL
    }
}
