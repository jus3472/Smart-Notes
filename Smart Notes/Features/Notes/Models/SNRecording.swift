import Foundation
struct SNRecording: Identifiable, Codable {
    var id: String = UUID().uuidString
    var audioUrl: String
    var transcript: String?
    var duration: Double
    var createdAt: Date = Date()
    var noteId: String?
}
