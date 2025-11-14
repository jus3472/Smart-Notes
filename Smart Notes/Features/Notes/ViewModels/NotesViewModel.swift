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
    
    func notes(in folder: SNFolder?) -> [SNNote] {
        guard let folder = folder else { return notes }
        return notes.filter { $0.folderId == folder.id }
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
}
