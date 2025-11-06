import SwiftUI

struct NoteRowView: View {
    let note: Note
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(note.title ?? "Untitled")
                .font(.headline)
            Text(note.content ?? "")
                .font(.caption)
                .lineLimit(2)
                .foregroundColor(.gray)
            Text(note.createdAt ?? Date(), style: .date)
                .font(.caption2)
                .foregroundColor(.gray)
        }
        .padding(.vertical, 8)
    }
}
