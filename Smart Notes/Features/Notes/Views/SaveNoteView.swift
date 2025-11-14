import SwiftUI

struct SaveNoteView: View {
    @Environment(\.dismiss) private var dismiss
    
    @EnvironmentObject var notesViewModel: NotesViewModel
    
    let transcribedText: String
    var audioUrl: String? = nil
    let onSave: () -> Void            // ← 반드시 있어야 함
    
    @State private var noteTitle = ""
    
    var body: some View {
        NavigationView {
            Form {
                TextField("Note Title", text: $noteTitle)
                
                Section("Transcription") {
                    TextEditor(text: .constant(transcribedText))
                        .frame(minHeight: 200)
                }
            }
            .navigationTitle("Save Note")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveNote()
                    }
                    .bold()
                }
            }
        }
    }
    
    private func saveNote() {
        notesViewModel.addNote(
            title: noteTitle.isEmpty ? "Untitled Note" : noteTitle,
            content: transcribedText,
            folderId: nil,
            audioUrl: audioUrl
        )
        
        onSave()    // ← 녹음 reset 수행
        dismiss()
    }
}
