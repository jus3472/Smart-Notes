// AudioRecorderService.swift
import Foundation
import AVFoundation
import Combine

class AudioRecorderService: NSObject, ObservableObject, AVAudioRecorderDelegate {
    private var audioRecorder: AVAudioRecorder?
    private var audioSession = AVAudioSession.sharedInstance()
    private var meterTimer: Timer?
    
    // 1. 현재 오디오 레벨을 외부에 발행(Publish)할 @Published 변수
    @Published var audioLevel: Float = 0.0 // 0.0 (조용) ~ 1.0 (최대 볼륨)
    
    // 2. 녹음 파일 저장 경로 (임시 파일)
    private var recordingURL: URL {
        let filename = UUID().uuidString + ".m4a"
        return FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0].appendingPathComponent(filename)
    }

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
        // 기존 녹음 인스턴스가 있다면 정리
        if audioRecorder?.isRecording == true {
            audioRecorder?.stop()
        }
        
        // 3. 음량 측정 설정을 포함한 녹음 설정
        let settings = [
            AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
            AVSampleRateKey: 12000,
            AVNumberOfChannelsKey: 1,
            AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue,
            AVEncoderBitRateKey: 32000,
            AVLinearPCMIsFloatKey: true,
            AVLinearPCMIsBigEndianKey: false,
            AVLinearPCMIsNonInterleaved: false
        ] as [String : Any]
        
        do {
            audioRecorder = try AVAudioRecorder(url: recordingURL, settings: settings)
            audioRecorder?.delegate = self
            audioRecorder?.isMeteringEnabled = true // ✅ 음량 측정 활성화
            audioRecorder?.prepareToRecord()
            audioRecorder?.record()
            startMetering() // ✅ 미터링 타이머 시작
            print("Recording started at: \(recordingURL)")
        } catch {
            print("Failed to start recording: \(error.localizedDescription)")
            stopRecording()
        }
    }
    
    func stopRecording() {
        audioRecorder?.stop()
        meterTimer?.invalidate() // ✅ 미터링 타이머 중지
        meterTimer = nil
        audioLevel = 0.0 // 음량 초기화
        audioRecorder = nil
        print("Recording stopped.")
    }
    
    func pauseRecording() {
        audioRecorder?.pause()
        meterTimer?.invalidate() // ✅ 미터링 타이머 중지
        meterTimer = nil
        print("Recording paused.")
    }
    
    func resumeRecording() {
        audioRecorder?.record()
        startMetering() // ✅ 미터링 타이머 재시작
        print("Recording resumed.")
    }
    
    // 4. 음량 측정 타이머 시작
    private func startMetering() {
        meterTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            self?.audioRecorder?.updateMeters()
            if let peakPower = self?.audioRecorder?.averagePower(forChannel: 0) {
                // Core Audio Power to UI friendly 0-1.0 scale
                // -160 dBFS is silence, 0 dBFS is max. Normalize to 0-1.0.
                let normalizedPower = pow(10, peakPower / 20)
                DispatchQueue.main.async {
                    self?.audioLevel = normalizedPower // 5. @Published 변수에 음량 업데이트
                }
            }
        }
    }
    
    // MARK: - AVAudioRecorderDelegate
    func audioRecorderDidFinishRecording(_ recorder: AVAudioRecorder, successfully flag: Bool) {
        if !flag {
            print("Recording finished unsuccessfully.")
        }
        stopRecording()
    }
}
