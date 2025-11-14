// FolderDetailView.swift
import SwiftUI

struct FolderDetailView: View {
    @EnvironmentObject var notesViewModel: NotesViewModel
    
    let folder: SNFolder?   // nil이면 All Notes
    
    var body: some View {
        let notes = notesViewModel.notes(in: folder)
        
        List {
            ForEach(notes) { note in
                NoteRowView(note: note)
            }
            .onDelete { offsets in
                notesViewModel.delete(at: offsets, in: folder)
            }
        }
        .navigationTitle(folder?.name ?? "All Notes")
    }
}
