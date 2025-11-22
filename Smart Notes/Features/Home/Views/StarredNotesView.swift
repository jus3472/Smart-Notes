import SwiftUI

struct StarredNotesView: View {
    @EnvironmentObject var notesViewModel: NotesViewModel
    
    var body: some View {
        List {
            ForEach(notesViewModel.starredNotes) { note in
                NavigationLink {
                    DetailNoteView(note: note)
                } label: {
                    NoteRowView(note: note)
                }
            }
            .onDelete(perform: delete)
        }
        .navigationTitle("Starred")
        .navigationBarTitleDisplayMode(.large)
    }
    
    private func delete(at offsets: IndexSet) {
        let targetNotes = notesViewModel.starredNotes
        for index in offsets {
            let note = targetNotes[index]
            notesViewModel.delete(note: note)
        }
    }
}
