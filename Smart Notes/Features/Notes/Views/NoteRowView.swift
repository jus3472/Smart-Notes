// NoteRowView.swift
import SwiftUI

struct NoteRowView: View {
    let note: SNNote
    @EnvironmentObject var notesViewModel: NotesViewModel
    
    /// When false, the star button is hidden (used in Recently Deleted)
    var showStar: Bool = true
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(note.title)
                    .font(.headline)
                
                Text(note.content.markdownToPlain())
                    .font(.subheadline)
                    .lineLimit(2)
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
            
            if showStar && !(note.isDeleted ?? false) {
                Button {
                    notesViewModel.toggleStar(note)
                } label: {
                    Image(systemName: (note.isStarred ?? false) ? "star.fill" : "star")
                        .foregroundColor((note.isStarred ?? false) ? .yellow : .gray)
                }
                .buttonStyle(.borderless)
            }
        }
        .padding(.vertical, 4)
    }
}

// markdownToPlain extension unchanged
extension String {
    func markdownToPlain() -> String {
        var s = self
        
        s = s.replacingOccurrences(of: #"(\*\*)(.*?)\1"#, with: "$2", options: .regularExpression)
        s = s.replacingOccurrences(of: #"\*(.*?)\*"#, with: "$1", options: .regularExpression)
        s = s.replacingOccurrences(of: #"\_(.*?)\_"#, with: "$1", options: .regularExpression)
        s = s.replacingOccurrences(of: #"\~\~(.*?)\~\~"#, with: "$1", options: .regularExpression)
        s = s.replacingOccurrences(of: #"`(.*?)`"#, with: "$1", options: .regularExpression)
        s = s.replacingOccurrences(of: "\n\n", with: "\n")
        
        return s
    }
}
