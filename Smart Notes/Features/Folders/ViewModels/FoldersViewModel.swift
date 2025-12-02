// FoldersViewModel.swift
import SwiftUI
import FirebaseAuth
import FirebaseFirestore

final class FoldersViewModel: ObservableObject {
    @Published var folders: [SNFolder] = []
    private var listener: ListenerRegistration?
    
    private let service = FirebaseNoteService.shared
    private let auth = FirebaseManager.shared.auth
    
    /// Make sure we only try to create the default "Notes" folder once
    private var hasEnsuredDefaultNotes = false
    
    init() {
        startListening()
        
    }
    
    deinit {
        listener?.remove()
    }
    
    private func startListening() {
        guard let uid = auth.currentUser?.uid else { return }
        
        listener = service.listenFolders(uid: uid) { [weak self] folders in
            guard let self = self else { return }
            
            DispatchQueue.main.async {
                // Always update local state with what Firestore sent
                self.folders = folders
                
                // Ensure default "Notes" folder exists
                self.ensureDefaultNotesFolderIfNeeded(uid: uid, currentFolders: folders)
            }
        }
    }
    
    /// Called whenever we get a new snapshot from Firestore.
    /// If there is no folder named "Notes", we create one.
    private func ensureDefaultNotesFolderIfNeeded(uid: String, currentFolders: [SNFolder]) {
        // If we've already ensured once and currently have a Notes folder, nothing to do.
        if currentFolders.contains(where: { $0.name == "Notes" }) {
            hasEnsuredDefaultNotes = true
            return
        }
        
        // Only try to create it once per session.
        guard !hasEnsuredDefaultNotes else { return }
        hasEnsuredDefaultNotes = true
        
        // Create the default base folder in Firestore.
        service.addFolder(uid: uid, name: "Notes")
        // When Firestore writes it, listenFolders will fire again
        // and update `folders` with the new "Notes" folder.
    }
    
    func refresh() {
        listener?.remove()
        hasEnsuredDefaultNotes = false
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
            
            // 🚫 Never delete the default "Notes" folder
            if folder.name == "Notes" {
                continue
            }
            
            service.deleteFolder(uid: uid, folderId: folder.id)
        }
    }
}
