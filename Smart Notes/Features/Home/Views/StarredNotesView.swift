import SwiftUI

struct StarredNotesView: View {
    @EnvironmentObject var notesViewModel: NotesViewModel
    
    private var starredNotes: [SNNote] {
        notesViewModel.notes.filter {
            ($0.isStarred ?? false) && !($0.isDeleted ?? false)
        }
    }
    
    var body: some View {
        Group {
            if starredNotes.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "star")
                        .font(.system(size: 32))
                        .foregroundColor(.secondary)
                    
                    Text("No starred notes yet")
                        .font(.headline)
                    
                    Text("Tap the star icon on a note to keep it here.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
                .padding(.top, 80)
            } else {
                List {
                    ForEach(starredNotes) { note in
                        NavigationLink {
                            DetailNoteView(note: note)
                        } label: {
                            NoteRowView(note: note)
                        }
                    }
                    // allow deleting from Starred → moves to Recently Deleted
                    .onDelete { offsets in
                        let notesToDelete = offsets.map { starredNotes[$0] }
                        notesToDelete.forEach { notesViewModel.delete($0) }
                    }
                }
                .listStyle(.insetGrouped)
            }
        }
        .navigationTitle("Starred")
        .navigationBarTitleDisplayMode(.large)
    }
}
