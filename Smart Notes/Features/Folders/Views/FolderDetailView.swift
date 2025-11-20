import SwiftUI

struct FolderDetailView: View {
    let folder: SNFolder?
    @EnvironmentObject var notesViewModel: NotesViewModel
    
    var body: some View {
        List {
            ForEach(notesViewModel.notes(in: folder)) { note in
                NavigationLink {
                    DetailNoteView(note: note)   // 🔥 상세 화면으로 이동
                } label: {
                    NoteRowView(note: note)     // 기존 리스트 UI 그대로 사용
                }
            }
        }
        .navigationTitle(folder?.name ?? "All Notes")
        .navigationBarTitleDisplayMode(.large)
    }
}
