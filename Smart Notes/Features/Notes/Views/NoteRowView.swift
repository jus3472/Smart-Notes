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
                
                // 👇 Markdown 제거하여 깔끔한 미리보기 제공
                Text(note.content.markdownToPlain())
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
            .buttonStyle(.borderless)
        }
        .padding(.vertical, 4)
    }
}

extension String {

    /// Removes basic Markdown formatting characters like **, *, _, ~~ etc.
    func markdownToPlain() -> String {
        var s = self
        
        // Bold: **text**
        s = s.replacingOccurrences(of: #"(\*\*)(.*?)\1"#, with: "$2", options: .regularExpression)
        
        // Italic: *text* or _text_
        s = s.replacingOccurrences(of: #"\*(.*?)\*"#, with: "$1", options: .regularExpression)
        s = s.replacingOccurrences(of: #"\_(.*?)\_"#, with: "$1", options: .regularExpression)
        
        // Strikethrough: ~~text~~
        s = s.replacingOccurrences(of: #"\~\~(.*?)\~\~"#, with: "$1", options: .regularExpression)
        
        // Inline code: `code`
        s = s.replacingOccurrences(of: #"`(.*?)`"#, with: "$1", options: .regularExpression)
        
        // Remove excessive whitespace
        s = s.replacingOccurrences(of: "\n\n", with: "\n")
        
        return s
    }
}
