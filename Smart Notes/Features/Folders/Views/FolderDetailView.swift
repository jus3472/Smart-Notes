import SwiftUI

struct FolderDetailView: View {
    let folder: SNFolder?
    @EnvironmentObject var notesViewModel: NotesViewModel
    
    var body: some View {
        List {
            ForEach(notesViewModel.notes(in: folder)) { note in
                NavigationLink {
                    DetailNoteView(note: note)   // 상세 화면
                } label: {
                    NoteRowView(note: note)     // 리스트 UI
                }
            }
            .onDelete { indexSet in
                // Delete from Firestore via NotesViewModel
                notesViewModel.delete(at: indexSet, in: folder)
            }
        }
        .navigationTitle(folder?.name ?? "Notes")
        .navigationBarTitleDisplayMode(.large)
    }
}
