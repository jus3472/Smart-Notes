// FolderDetailView.swift
import SwiftUI

struct FolderDetailView: View {
    let folder: SNFolder?
    @EnvironmentObject var notesViewModel: NotesViewModel
    
    private var notesInFolder: [SNNote] {
        notesViewModel.notes(in: folder)
    }
    
    var body: some View {
        Group {
            if notesInFolder.isEmpty {
                // Empty state
                VStack(spacing: 8) {
                    Image(systemName: "note.text")
                        .font(.system(size: 32))
                        .foregroundColor(.secondary)
                    
                    Text("No notes here yet")
                        .font(.headline)
                    
                    Text("Notes you create will appear in this folder.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
                .padding(.top, 80)
            } else {
                List {
                    ForEach(notesInFolder) { note in
                        NavigationLink {
                            DetailNoteView(note: note)
                        } label: {
                            NoteRowView(note: note)
                        }
                    }
                    .onDelete { offsets in
                        notesViewModel.delete(at: offsets, in: folder)
                    }
                }
                .listStyle(.insetGrouped)
            }
        }
        .navigationTitle(folder?.name ?? "Notes")
        .navigationBarTitleDisplayMode(.large)
    }
}
