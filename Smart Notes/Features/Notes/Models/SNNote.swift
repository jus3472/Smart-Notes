import Foundation

struct SNNote: Identifiable, Codable {
    var id: String = UUID().uuidString
    var title: String
    var content: String
    var folderId: String?
    var audioUrl: String?
    var createdAt: Date = Date()
    var updatedAt: Date = Date()
    
    // Optional for backward compatibility with existing Firestore docs
    var isStarred: Bool? = false
}
