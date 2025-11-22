// DetailNoteView.swift
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
    
    // Editing state
    @State private var isEditing = false
    @State private var editedTitle: String
    @State private var editedContent: String
    
    init(note: SNNote) {
        self.note = note
        _currentFolderId = State(initialValue: note.folderId)
        _editedTitle = State(initialValue: note.title)
        _editedContent = State(initialValue: note.content)
    }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                
                // Title (editable)
                if isEditing {
                    TextField("Title", text: $editedTitle)
                        .font(.system(size: 28, weight: .bold))
                        .textFieldStyle(.plain)
                        .padding(.vertical, 4)
                } else {
                    Text(editedTitle)
                        .font(.largeTitle)
                        .fontWeight(.bold)
                }
                
                // Date (still based on original note.updatedAt)
                Text("Updated: \(note.updatedAt.formatted(date: .abbreviated, time: .shortened))")
                    .font(.subheadline)
                    .foregroundColor(.gray)
                
                Divider()
                
                // Content (editable)
                if isEditing {
                    TextEditor(text: $editedContent)
                        .font(.body)
                        .frame(minHeight: 220)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                        )
                } else {
                    Text(editedContent)
                        .font(.body)
                        .padding(.top, 4)
                }
                
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
            // EDIT / SAVE button
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(isEditing ? "Save" : "Edit") {
                    if isEditing {
                        saveEdits()
                    } else {
                        isEditing = true
                    }
                }
            }
            
            // MOVE menu
            ToolbarItem(placement: .navigationBarTrailing) {
                Menu {
                    // Only show "Notes" if the note is NOT already in "Notes"
                    if currentFolderId != nil {
                        Button("Notes") {
                            moveTo(folder: nil)
                        }
                    }
                    
                    // Only show other folders (exclude currentFolderId)
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
                .disabled(isEditing)   // avoid moving while mid-edit
            }
        }
        .alert("Note moved", isPresented: $showMoveAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(moveAlertMessage)
        }
    }
    
    // MARK: - Save edits
    private func saveEdits() {
        notesViewModel.updateNote(
            note,
            title: editedTitle,
            content: editedContent
        )
        isEditing = false
    }
    
    // MARK: - Move Logic
    private func moveTo(folder: SNFolder?) {
        // Use the latest edited title/content when moving, so we don't overwrite them.
        var updatedNote = note
        updatedNote.title = editedTitle
        updatedNote.content = editedContent
        
        notesViewModel.move(updatedNote, to: folder)
        
        // Update local state so the menu reflects the NEW folder immediately
        currentFolderId = folder?.id
        
        // Clear feedback
        let targetName = folder?.name ?? "Notes"
        moveAlertMessage = "This note has been moved to \"\(targetName)\"."
        showMoveAlert = true
    }
}
