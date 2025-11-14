import Foundation
import FirebaseFirestore

struct SNFolder: Identifiable, Codable {
    var id: String = UUID().uuidString
    var name: String
    var createdAt: Date = Date()
    var updatedAt: Date = Date()
}
