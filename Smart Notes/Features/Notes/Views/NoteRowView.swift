// NoteRowView.swift
import SwiftUI

struct NoteRowView: View {
    let note: SNNote
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(note.title)
                .font(.headline)
            Text(note.content)
                .font(.subheadline)
                .lineLimit(2)
                .foregroundStyle(.secondary)
        }
        .padding(.vertical, 4)
    }
}
