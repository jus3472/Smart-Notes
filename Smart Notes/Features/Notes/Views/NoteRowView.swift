// NoteRowView.swift
import SwiftUI

struct NoteRowView: View {
    let note: SNNote
    @EnvironmentObject var notesViewModel: NotesViewModel
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(note.title)
                    .font(.headline)
                
                Text(note.content)
                    .font(.subheadline)
                    .lineLimit(2)
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
            
            Button {
                notesViewModel.toggleStar(note)
            } label: {
                Image(systemName: (note.isStarred ?? false) ? "star.fill" : "star")
                    .foregroundColor((note.isStarred ?? false) ? .yellow : .gray)
            }
            // Important so the star tap doesn’t interfere with the row navigation
            .buttonStyle(.borderless)
        }
        .padding(.vertical, 4)
    }
}
