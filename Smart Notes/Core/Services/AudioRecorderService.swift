import AVFoundation
import SwiftUI

class AudioRecorderService: NSObject, ObservableObject {
    @Published var isRecording = false
    @Published var isPaused = false
    
    private var audioRecorder: AVAudioRecorder?
    private var audioSession: AVAudioSession?
    
    override init() {
        super.init()
        setupAudioSession()
    }
    
    private func setupAudioSession() {
        audioSession = AVAudioSession.sharedInstance()
        do {
            try audioSession?.setCategory(.playAndRecord, mode: .default)
            try audioSession?.setActive(true)
        } catch {
            print("Failed to setup audio session: \(error)")
        }
    }
}
