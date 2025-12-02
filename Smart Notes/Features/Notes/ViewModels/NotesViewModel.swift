// NotesViewModel.swift
import SwiftUI
import FirebaseAuth
import FirebaseFirestore

final class NotesViewModel: ObservableObject {
    @Published var notes: [SNNote] = []
    private var listener: ListenerRegistration?
    
    private let service = FirebaseNoteService.shared
    private let auth = FirebaseManager.shared.auth
    
    init() {
        startListening()
    }
    
    deinit {
        listener?.remove()
    }
    
    private func startListening() {
        guard let uid = auth.currentUser?.uid else { return }
        listener = service.listenNotes(uid: uid) { [weak self] notes in
            DispatchQueue.main.async {
                self?.notes = notes
            }
        }
    }
    
    func refresh() {
        listener?.remove()
        startListening()
    }
    
    // MARK: - Filtering helpers
    
    /// Notes for a given folder. `folder == nil` means root "Notes".
    /// Deleted notes are always filtered out here.
    func notes(in folder: SNFolder?) -> [SNNote] {
        if let folder = folder {
            return notes.filter {
                $0.folderId == folder.id && !($0.isDeleted ?? false)
            }
        } else {
            // Root "Notes" → notes with no folderId and not deleted
            return notes.filter {
                $0.folderId == nil && !($0.isDeleted ?? false)
            }
        }
    }
    
    /// All deleted notes (for Recently Deleted)
    var deletedNotes: [SNNote] {
        notes
            .filter { $0.isDeleted ?? false }
            .sorted {
                let lhsDate = $0.deletedAt ?? $0.updatedAt
                let rhsDate = $1.deletedAt ?? $1.updatedAt
                return lhsDate > rhsDate
            }
    }
    
    // MARK: - CRUD
    
    func addNote(
        title: String,
        content: String,
        folderId: String? = nil,
        audioUrl: String? = nil
    ) {
        guard let uid = auth.currentUser?.uid else { return }
        service.addNote(
            uid: uid,
            title: title,
            content: content,
            folderId: folderId,
            audioUrl: audioUrl
        )
    }
    
    /// Soft delete via swipe in a given folder
    func delete(at offsets: IndexSet, in folder: SNFolder?) {
        let targetNotes = notes(in: folder)
        for index in offsets {
            let note = targetNotes[index]
            delete(note)
        }
    }
    
    /// Soft delete a single note (keeps original folder for restore)
    func delete(_ note: SNNote) {
        moveToRecentlyDeleted(note, keepOriginalFolder: true)
    }
    
    /// Soft delete all notes in a folder when the folder itself is deleted.
    /// These notes restore to the root "Notes" (not the deleted folder).
    func deleteNotes(inFolder folder: SNFolder) {
        let notesInFolder = notes.filter {
            $0.folderId == folder.id && !($0.isDeleted ?? false)
        }
        for note in notesInFolder {
            moveToRecentlyDeleted(note, keepOriginalFolder: false)
        }
    }
    
    /// Permanently remove from Firestore (used from Recently Deleted)
    func deleteForever(_ note: SNNote) {
        guard let uid = auth.currentUser?.uid else { return }
        service.deleteNote(uid: uid, noteId: note.id)
    }
    
    /// Restore a deleted note back to its original folder (if still tracked),
    /// or to root "Notes" when originalFolderId is nil.
    func restore(_ note: SNNote) {
        guard let uid = auth.currentUser?.uid else { return }
        
        var updated = note
        updated.isDeleted = false
        updated.deletedAt = nil
        
        // Restore to original folder; if nil → root Notes
        updated.folderId = note.originalFolderId
        updated.originalFolderId = nil
        
        updated.updatedAt = Date()
        
        // Note stays unstarred after restore
        updated.isStarred = false
        
        service.updateNote(uid: uid, note: updated)
    }
    
    /// Internal helper: mark note as deleted and move to Recently Deleted.
    /// - keepOriginalFolder:
    ///   - true  → restore will go back to that folder (normal note delete)
    ///   - false → restore will go to root "Notes" (folder was deleted)
    private func moveToRecentlyDeleted(_ note: SNNote, keepOriginalFolder: Bool) {
        guard let uid = auth.currentUser?.uid else { return }
        guard !(note.isDeleted ?? false) else { return } // already deleted
        
        var updated = note
        updated.isDeleted = true
        updated.deletedAt = Date()
        updated.updatedAt = Date()
        
        // Remember where it came from (optional)
        if keepOriginalFolder {
            updated.originalFolderId = note.folderId
        } else {
            updated.originalFolderId = nil
        }
        
        // In trash we don't associate it with a folder
        updated.folderId = nil
        
        // Clear star when deleted
        updated.isStarred = false
        
        service.updateNote(uid: uid, note: updated)
    }
    
    // MARK: - Move between folders
    
    func move(_ note: SNNote, to folder: SNFolder?) {
        guard let uid = auth.currentUser?.uid else { return }
        var updated = note
        
        // Do not allow moving deleted notes from normal UI
        guard !(updated.isDeleted ?? false) else { return }
        
        updated.folderId = folder?.id      // nil = "Notes" (unfiled)
        updated.updatedAt = Date()
        service.updateNote(uid: uid, note: updated)
    }
    
    // MARK: - Star / Favorite
    
    func toggleStar(_ note: SNNote) {
        // No starring in Recently Deleted
        guard !(note.isDeleted ?? false) else { return }
        guard let uid = auth.currentUser?.uid else { return }
        
        var current = notes.first(where: { $0.id == note.id }) ?? note
        let newValue = !(current.isStarred ?? false)
        current.isStarred = newValue
        // Do NOT change updatedAt so sort remains by real edits
        service.updateNote(uid: uid, note: current)
    }
    
    // MARK: - Edit note text
    
    func updateNote(
        _ note: SNNote,
        title: String,
        content: String
    ) {
        guard let uid = auth.currentUser?.uid else { return }
        
        var updated = note
        updated.title = title
        updated.content = content
        updated.updatedAt = Date()
        
        service.updateNote(uid: uid, note: updated)
    }
}
