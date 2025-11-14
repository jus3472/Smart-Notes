// FoldersViewModel.swift
import SwiftUI
import FirebaseAuth
import FirebaseFirestore

final class FoldersViewModel: ObservableObject {
    @Published var folders: [SNFolder] = []
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
        listener = service.listenFolders(uid: uid) { [weak self] folders in
            DispatchQueue.main.async {
                self?.folders = folders
            }
        }
    }
    
    func refresh() {
        listener?.remove()
        startListening()
    }
    
    func addFolder(name: String) {
        guard let uid = auth.currentUser?.uid else { return }
        service.addFolder(uid: uid, name: name)
    }
    
    func deleteFolder(at offsets: IndexSet) {
        guard let uid = auth.currentUser?.uid else { return }
        for index in offsets {
            let folder = folders[index]
            service.deleteFolder(uid: uid, folderId: folder.id)
        }
    }
}
