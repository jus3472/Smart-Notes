// FirebaseNoteService.swift
import Foundation
import FirebaseFirestore
import FirebaseStorage

final class FirebaseNoteService {
    static let shared = FirebaseNoteService()
    private let db = FirebaseManager.shared.db
    private let storage = FirebaseManager.shared.storage
    
    private init() {}
    
    // MARK: - Collections
    private func userDoc(uid: String) -> DocumentReference {
        db.collection("users").document(uid)
    }
    
    private func foldersCollection(uid: String) -> CollectionReference {
        userDoc(uid: uid).collection("folders")
    }
    
    private func notesCollection(uid: String) -> CollectionReference {
        userDoc(uid: uid).collection("notes")
    }
    
    private func recordingsCollection(uid: String) -> CollectionReference {
        userDoc(uid: uid).collection("recordings")
    }
    
    // MARK: - Folders
    func listenFolders(
        uid: String,
        handler: @escaping ([SNFolder]) -> Void
    ) -> ListenerRegistration {
        foldersCollection(uid: uid)
            .order(by: "createdAt", descending: false)
            .addSnapshotListener { snapshot, _ in
                let folders = snapshot?.documents.compactMap { doc in
                    try? doc.data(as: SNFolder.self)
                } ?? []
                handler(folders)
            }
    }
    
    func addFolder(uid: String, name: String, completion: ((Error?) -> Void)? = nil) {
        let id = UUID().uuidString
        let folder = SNFolder(
            id: id,
            name: name,
            createdAt: Date(),
            updatedAt: Date()
        )

        do {
            try foldersCollection(uid: uid)
                .document(id)
                .setData(from: folder)
            completion?(nil)
        } catch {
            completion?(error)
        }
    }
    
    func deleteFolder(uid: String, folderId: String, completion: ((Error?) -> Void)? = nil) {
        foldersCollection(uid: uid).document(folderId).delete(completion: completion)
    }
    
    // MARK: - Notes
    func listenNotes(
        uid: String,
        handler: @escaping ([SNNote]) -> Void
    ) -> ListenerRegistration {
        notesCollection(uid: uid)
            .order(by: "updatedAt", descending: true)
            .addSnapshotListener { snapshot, _ in
                let notes = snapshot?.documents.compactMap { doc in
                    try? doc.data(as: SNNote.self)
                } ?? []
                handler(notes)
            }
    }
    
    func addNote(
        uid: String,
        title: String,
        content: String,
        folderId: String? = nil,
        audioUrl: String? = nil,
        completion: ((Error?) -> Void)? = nil
    ) {
        let id = UUID().uuidString
        let note = SNNote(
            id: id,
            title: title.isEmpty ? "Untitled Note" : title,
            content: content,
            folderId: folderId,
            audioUrl: audioUrl,
            createdAt: Date(),
            updatedAt: Date()
        )

        do {
            try notesCollection(uid: uid).document(id).setData(from: note)
            completion?(nil)
        } catch {
            completion?(error)
        }
    }
    
    func deleteNote(uid: String, noteId: String, completion: ((Error?) -> Void)? = nil) {
        notesCollection(uid: uid).document(noteId).delete(completion: completion)
    }
    
    // MARK: - Recordings + Storage
    func uploadRecording(
        uid: String,
        fileURL: URL,
        completion: @escaping (Result<String, Error>) -> Void
    ) {
        let recordingId = UUID().uuidString
        let ref = storage.reference().child("recordings/\(uid)/\(recordingId).m4a")
        
        ref.putFile(from: fileURL) { _, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            ref.downloadURL { url, error in
                if let error = error {
                    completion(.failure(error))
                } else if let url = url {
                    completion(.success(url.absoluteString))
                }
            }
        }
    }
}
