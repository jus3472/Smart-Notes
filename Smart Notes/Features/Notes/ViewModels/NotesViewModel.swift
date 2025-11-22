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
    
    /// "Notes" (folder == nil) shows ONLY notes with no folderId.
    /// A specific folder shows only notes whose folderId == folder.id.
    func notes(in folder: SNFolder?) -> [SNNote] {
        if let folder = folder {
            // Notes in a specific folder
            return notes.filter { $0.folderId == folder.id }
        } else {
            // Root "Notes" = unfiled notes only
            return notes.filter { $0.folderId == nil }
        }
    }
    
    /// All starred notes across all folders
    var starredNotes: [SNNote] {
        notes.filter { ($0.isStarred ?? false) == true }
    }
    
    func delete(at offsets: IndexSet, in folder: SNFolder?) {
        guard let uid = auth.currentUser?.uid else { return }
        let targetNotes = notes(in: folder)
        for index in offsets {
            let note = targetNotes[index]
            service.deleteNote(uid: uid, noteId: note.id)
        }
    }
    
    /// Delete a specific note (used in Starred view)
    func delete(note: SNNote) {
        guard let uid = auth.currentUser?.uid else { return }
        service.deleteNote(uid: uid, noteId: note.id)
    }
    
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
    
    /// Update title/content of an existing note (preserving other fields like isStarred, folderId)
    func updateNote(_ note: SNNote, title: String, content: String) {
        guard let uid = auth.currentUser?.uid else { return }
        
        // Start from the latest version we have in memory to avoid overwriting fields
        var current = notes.first(where: { $0.id == note.id }) ?? note
        
        let trimmedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        current.title = trimmedTitle.isEmpty ? "Untitled Note" : trimmedTitle
        current.content = content
        current.updatedAt = Date()
        
        service.updateNote(uid: uid, note: current)
    }
    
    /// Move a note to another folder (or to "Notes" / no folder).
    /// When `folder == nil`, the note becomes an unfiled "Notes" note.
    func move(_ note: SNNote, to folder: SNFolder?) {
        guard let uid = auth.currentUser?.uid else { return }
        
        var current = notes.first(where: { $0.id == note.id }) ?? note
        current.folderId = folder?.id      // nil = "Notes" (unfiled)
        current.updatedAt = Date()
        
        service.updateNote(uid: uid, note: current)
    }
    
    func toggleStar(_ note: SNNote) {
        guard let uid = auth.currentUser?.uid else { return }
        
        var current = notes.first(where: { $0.id == note.id }) ?? note
        let newValue = !(current.isStarred ?? false)
        current.isStarred = newValue
        service.updateNote(uid: uid, note: current)
    }
}
