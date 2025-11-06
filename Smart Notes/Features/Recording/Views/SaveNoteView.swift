// Features/Recording/Views/SaveNoteView.swift
import SwiftUI

struct SaveNoteView: View {
    @Environment(\.dismiss) var dismiss
    let transcribedText: String
    @State private var noteTitle = ""
    
    var body: some View {
        NavigationView {
            Form {
                TextField("Note Title", text: $noteTitle)
                
                Section("Transcribed Text") {
                    Text(transcribedText)
                        .frame(minHeight: 200)
                }
            }
            .navigationTitle("Save Note")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveNote()
                    }
                }
            }
        }
    }
    
    func saveNote() {
        let context = PersistenceController.shared.container.viewContext
        let newNote = Note(context: context)
        newNote.id = UUID()
        newNote.title = noteTitle.isEmpty ? "Untitled Note" : noteTitle
        newNote.content = transcribedText
        newNote.createdAt = Date()
        newNote.updatedAt = Date()
        
        do {
            try context.save()
            dismiss()
        } catch {
            print("Error saving note: \(error)")
        }
    }
}
