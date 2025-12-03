// SNNote.swift
import Foundation

struct SNNote: Identifiable, Codable {
    var id: String = UUID().uuidString
    var title: String
    var content: String
    var folderId: String?
    var audioUrl: String?
    var createdAt: Date = Date()
    var updatedAt: Date = Date()
    
    var isStarred: Bool? = false
    
    // soft delete support
    var isDeleted: Bool? = false
    var deletedAt: Date?
    var originalFolderId: String?
    
    var tags: [String] = [] 
}
