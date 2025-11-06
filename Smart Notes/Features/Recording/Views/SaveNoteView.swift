// SaveNoteView.swift
import SwiftUI

struct SaveNoteView: View {
    @Environment(\.dismiss) var dismiss
    let transcribedText: String
    let onSave: () -> Void // 1. 저장이 성공했을 때 호출할 클로저
    
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
                        onSave() // 2. 저장 로직 실행 후 onSave 클로저 호출
                        dismiss()
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
            // 3. dismiss()는 버튼 액션에서 처리하므로 여기서 제거
        } catch {
            print("Error saving note: \(error)")
        }
    }
}
