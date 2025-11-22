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
            return notes.filter { $0.folderId == folder.id }
        } else {
            return notes.filter { $0.folderId == nil }
        }
    }
    
    func delete(at offsets: IndexSet, in folder: SNFolder?) {
        guard let uid = auth.currentUser?.uid else { return }
        let targetNotes = notes(in: folder)
        for index in offsets {
            let note = targetNotes[index]
            service.deleteNote(uid: uid, noteId: note.id)
        }
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
    
    /// Update title/content of an existing note
    func updateNote(_ note: SNNote, title: String, content: String) {
        guard let uid = auth.currentUser?.uid else { return }
        
        let trimmedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        var updated = note
        updated.title = trimmedTitle.isEmpty ? "Untitled Note" : trimmedTitle
        updated.content = content
        updated.updatedAt = Date()
        
        service.updateNote(uid: uid, note: updated)
    }
    
    /// Move a note to another folder (or to "Notes" / no folder).
    /// When `folder == nil`, the note becomes an unfiled "Notes" note.
    func move(_ note: SNNote, to folder: SNFolder?) {
        guard let uid = auth.currentUser?.uid else { return }
        var updated = note
        updated.folderId = folder?.id      // nil = "Notes" (unfiled)
        updated.updatedAt = Date()
        service.updateNote(uid: uid, note: updated)
    }
}
