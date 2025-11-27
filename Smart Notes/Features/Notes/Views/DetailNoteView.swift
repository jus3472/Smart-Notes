import SwiftUI

struct DetailNoteView: View {
    let note: SNNote
    
    @EnvironmentObject var notesViewModel: NotesViewModel
    @StateObject private var foldersViewModel = FoldersViewModel()
    
    @State private var showMoveAlert = false
    @State private var moveAlertMessage = ""
    
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
                
                // MARK: - Title
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
                
                // MARK: - Date
                Text("Updated: \(note.updatedAt.formatted(date: .abbreviated, time: .shortened))")
                    .font(.subheadline)
                    .foregroundColor(.gray)
                
                Divider()
                
                // MARK: - Content
                if isEditing {
                    TextEditor(text: $editedContent)
                        .font(.body)
                        .frame(minHeight: 220)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                        )
                } else {
                    // 👇 Markdown → AttributedString 렌더링
                    Text(editedContent.markdownToAttributed())
                        .font(.body)
                        .padding(.top, 4)
                }
                
                Divider()
                
                // MARK: - Audio info
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
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            
            // MARK: Edit/Save button
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(isEditing ? "Save" : "Edit") {
                    if isEditing { saveEdits() }
                    else { isEditing = true }
                }
            }
            
            // MARK: Move menu
            ToolbarItem(placement: .navigationBarTrailing) {
                Menu {
                    if currentFolderId != nil {
                        Button("Notes") { moveTo(folder: nil) }
                    }
                    
                    let available = foldersViewModel.folders.filter { $0.id != currentFolderId }
                    if !available.isEmpty {
                        Section("Folders") {
                            ForEach(available) { folder in
                                Button(folder.name) {
                                    moveTo(folder: folder)
                                }
                            }
                        }
                    }
                } label: {
                    Label("Move", systemImage: "folder")
                }
                .disabled(isEditing)
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
    
    // MARK: - Move
    private func moveTo(folder: SNFolder?) {
        var updatedNote = note
        updatedNote.title = editedTitle
        updatedNote.content = editedContent
        
        notesViewModel.move(updatedNote, to: folder)
        currentFolderId = folder?.id
        
        moveAlertMessage = "This note has been moved to \"\(folder?.name ?? "Notes")\"."
        showMoveAlert = true
    }
}

extension String {
    func markdownToAttributed() -> AttributedString {
        if let attributed = try? AttributedString(
            markdown: self,
            options: .init(interpretedSyntax: .inlineOnlyPreservingWhitespace)
        ) {
            return attributed
        }
        return AttributedString(self)
    }
}
