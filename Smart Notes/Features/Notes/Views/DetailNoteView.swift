import SwiftUI

struct DetailNoteView: View {
    let note: SNNote
    
    @EnvironmentObject var notesViewModel: NotesViewModel
    @StateObject private var foldersViewModel = FoldersViewModel()
    
    @State private var showMoveAlert = false
    @State private var moveAlertMessage = ""
    
    // Track the note's current folder for the Move menu.
    // nil = "Notes" (unfiled)
    @State private var currentFolderId: String?
    
    init(note: SNNote) {
        self.note = note
        _currentFolderId = State(initialValue: note.folderId)
    }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                
                // Title
                Text(note.title)
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                // Date
                Text("Updated: \(note.updatedAt.formatted(date: .abbreviated, time: .shortened))")
                    .font(.subheadline)
                    .foregroundColor(.gray)
                
                Divider()
                
                // Content
                Text(note.content)
                    .font(.body)
                    .padding(.top, 4)
                
                Divider()
                
                // If audio exists
                if let url = note.audioUrl {
                    Text("Associated Recording:")
                        .font(.headline)
                    
                    Text(url)
                        .font(.footnote)
                        .foregroundColor(.blue)
                        .underline()
                }
            }
            .padding()
        }
        .navigationTitle("Note Details")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Menu {
                    // ✅ Only show "Notes" if the note is NOT already in "Notes"
                    if currentFolderId != nil {
                        Button("Notes") {
                            moveTo(folder: nil)
                        }
                    }
                    
                    // ✅ Only show other folders (exclude currentFolderId)
                    let availableFolders = foldersViewModel.folders.filter { folder in
                        folder.id != currentFolderId
                    }
                    
                    if !availableFolders.isEmpty {
                        Section("Folders") {
                            ForEach(availableFolders) { folder in
                                Button(folder.name) {
                                    moveTo(folder: folder)
                                }
                            }
                        }
                    }
                } label: {
                    Label("Move", systemImage: "folder")
                }
            }
        }
        .alert("Note moved", isPresented: $showMoveAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(moveAlertMessage)
        }
    }
    
    // MARK: - Move Logic
    private func moveTo(folder: SNFolder?) {
        // Update in Firestore
        notesViewModel.move(note, to: folder)
        
        // Update local state so the menu reflects the NEW folder immediately
        currentFolderId = folder?.id
        
        // Clear feedback
        let targetName = folder?.name ?? "Notes"
        moveAlertMessage = "This note has been moved to \"\(targetName)\"."
        showMoveAlert = true
        
        // Thanks to the updated notes(in:) logic:
        // - If we moved to a folder, it disappears from "Notes"
        // - If we moved to "Notes", it disappears from the previous folder
    }
}
