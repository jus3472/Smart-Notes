// NoteEditorView.swift
import SwiftUI
import CoreData

struct NoteEditorView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) var dismiss
    
    // HomeView에서 전달받은 Note 객체
    @ObservedObject var note: Note
    
    // TextEditor와 바인딩될 로컬 @State 변수
    @State private var editorText: String
    
    // note 객체의 content로 @State 변수 초기화
    init(note: Note) {
        self.note = note
        _editorText = State(initialValue: note.content ?? "")
    }
    
    var body: some View {
        VStack {
            // 텍스트 에디터 UI
            TextEditor(text: $editorText)
                .padding()
                .frame(minHeight: 300)
                .border(Color.gray.opacity(0.2), width: 1)
                .padding()
        }
        .navigationTitle(note.title ?? "Edit Note")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                // 'Save' 버튼
                Button("Save") {
                    // 1. 알럿 없이 바로 저장 함수 호출
                    saveChanges()
                    // 2. 저장 후 뷰 닫기
                    dismiss()
                }
            }
        }
        // 3. .alert(...) 모디파이어가 제거되었습니다.
    }
    
    private func saveChanges() {
        // Note 객체 업데이트 및 저장
        note.content = editorText
        note.updatedAt = Date() // 수정된 시간 업데이트
        
        do {
            try viewContext.save()
            print("Note updated successfully.")
        } catch {
            print("Error saving updated note: \(error)")
        }
    }
}
