import SwiftUI

struct NoteRowView: View {
    let note: SNNote
    @EnvironmentObject var notesViewModel: NotesViewModel
    
    /// When false, the star button is hidden (used in Recently Deleted)
    var showStar: Bool = true
    
    var body: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 6) {
                // TITLE
                Text(note.title)
                    .font(.headline)
                
                // TAGS (최대 10개, 가로 스크롤)
                if !note.tags.isEmpty {
                    let limited = Array(note.tags.prefix(10))
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 6) {
                            ForEach(limited, id: \.self) { tag in
                                TagChip(text: tag)
                            }
                        }
                    }
                }
                
                // PREVIEW (📌 Summary: 제거 + markdown 제거)
                Text(note.createdAt.formatted(date: .abbreviated,time: .shortened))
                    .font(.caption)
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
        .padding(.vertical, 6)
    }
}

// MARK: - Tag Chip

struct TagChip: View {
    let text: String
    
    var body: some View {
        Text(text)
            .font(.caption)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(
                Capsule()
                    .fill(tagColor.opacity(0.15))
            )
            .foregroundColor(tagColor)
    }
    
    private var tagColor: Color {
        let colors: [Color] = [.blue, .green, .orange, .purple, .pink, .teal]
        let idx = abs(text.hashValue) % colors.count
        return colors[idx]
    }
}

// MARK: - Helpers

extension SNNote {
    /// 리스트에 보여줄 한 줄 요약
    var previewText: String {
        var plain = content.markdownToPlain()
        plain = plain.replacingOccurrences(of: "📌 Summary:", with: "")
        plain = plain.trimmingCharacters(in: .whitespacesAndNewlines)
        
        if let first = plain.components(separatedBy: .newlines).first {
            return first
        }
        return plain
    }
}

// 기존 markdownToPlain 그대로 사용
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
