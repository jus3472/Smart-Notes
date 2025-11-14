import SwiftUI

struct CoreDataNoteRowView: View {
    let note: Note   // CoreData Note
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(note.title ?? "Untitled")
                .font(.headline)

            Text(note.content ?? "")
                .font(.caption)
                .lineLimit(2)
                .foregroundColor(.gray)

            if let date = note.updatedAt {
                Text(date, style: .date)
                    .font(.caption2)
                    .foregroundColor(.gray)
            }
        }
        .padding(.vertical, 4)
    }
}
