import SwiftUI

struct DetailNoteView: View {
    let note: SNNote
    
    @EnvironmentObject var notesViewModel: NotesViewModel
    @StateObject private var foldersViewModel = FoldersViewModel()
    
    @State private var showMoveAlert = false
    @State private var moveAlertMessage = ""
    
    @State private var currentFolderId: String?
    
    // Editing state
    @State private var isEditing = false
    @State private var editedTitle: String
    @State private var editedContent: String
    
    init(note: SNNote) {
        self.note = note
        _currentFolderId = State(initialValue: note.folderId)
        _editedTitle = State(initialValue: note.title)
        _editedContent = State(initialValue: note.content)
    }
    
    // MARK: - Full Transcript 판별
    private var isFullTranscriptNote: Bool {
        // 제목에 Recording 포함되면 우선 Full Transcript로 간주
        if note.title.contains("Recording") {
            return true
        }

        // 폴더 이름으로도 한 번 더 체크
        let effectiveFolderId = currentFolderId ?? note.folderId
        guard let folderId = effectiveFolderId else { return false }
        
        if let folder = foldersViewModel.folders.first(where: { $0.id == folderId }) {
            return folder.name.trimmingCharacters(in: .whitespacesAndNewlines)
                .lowercased() == "full transcript".lowercased()
        }
        return false
    }
    
    // MARK: - Diarization Segment 모델
    private struct DiarizedSegment: Identifiable {
        let id = UUID()
        let speaker: String
        let text: String
    }
    
    // MARK: - diarized 텍스트 파싱
    private var diarizedSegments: [DiarizedSegment] {
        editedContent
            .split(separator: "\n")
            .compactMap { line in
                let trimmed = line.trimmingCharacters(in: .whitespacesAndNewlines)
                guard !trimmed.isEmpty else { return nil }
                
                // "Speaker: text" 형식 파싱
                let parts = trimmed.split(separator: ":", maxSplits: 1)
                guard parts.count == 2 else {
                    return DiarizedSegment(speaker: "Unknown", text: trimmed)
                }
                
                let speaker = parts[0].trimmingCharacters(in: .whitespaces)
                let text = parts[1].trimmingCharacters(in: .whitespaces)
                
                return DiarizedSegment(speaker: speaker, text: text)
            }
    }
    
    private func bubbleColor(for speaker: String) -> Color {
        switch speaker {
        case "Professor": return .blue.opacity(0.12)
        case "Student":   return .green.opacity(0.12)
        case "User":      return .purple.opacity(0.12)
        default:          return .gray.opacity(0.08)
        }
    }
    
    private func labelColor(for speaker: String) -> Color {
        switch speaker {
        case "Professor": return .blue
        case "Student":   return .green
        case "User":      return .purple
        default:          return .gray
        }
    }
    
    // MARK: - Full Transcript용 diarization 뷰
    @ViewBuilder
    private var diarizedContentView: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Full Transcript")
                .font(.headline)
                .padding(.bottom, 4)
            
            ForEach(diarizedSegments) { seg in
                HStack(alignment: .top, spacing: 8) {
                    Text(seg.speaker)
                        .font(.caption2.bold())
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(labelColor(for: seg.speaker).opacity(0.1))
                        .foregroundColor(labelColor(for: seg.speaker))
                        .clipShape(Capsule())
                    
                    Text(seg.text)
                        .font(.body)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .padding(10)
                .background(bubbleColor(for: seg.speaker))
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
        }
    }
    
    // MARK: - Summary + Action Items 파싱
    private func parseSummaryAndActions(from content: String) -> (summary: String, actions: [String]) {
        var text = content
        
        // "📌 Summary:" 제거
        if let range = text.range(of: "📌 Summary:") {
            text.removeSubrange(range)
        } else if let range = text.range(of: "Summary:") {
            text.removeSubrange(range)
        }
        
        // "✅ Action Items:" 기준으로 split
        let components = text.components(separatedBy: "✅ Action Items:")
        
        // Summary 부분 정리
        let rawSummary = components.first ?? ""
        let summary = rawSummary
            .trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Action part
        var actions: [String] = []
        if components.count > 1 {
            let rawActions = components[1]
            let lines = rawActions
                .split(whereSeparator: \.isNewline)
                .map { String($0).trimmingCharacters(in: .whitespacesAndNewlines) }
                .filter { !$0.isEmpty }
            
            for line in lines {
                var item = line
                if item.hasPrefix("- [ ]") {
                    item = String(item.dropFirst(5))
                } else if item.hasPrefix("-") {
                    item = String(item.dropFirst(1))
                }
                item = item.trimmingCharacters(in: .whitespacesAndNewlines)
                if !item.isEmpty {
                    actions.append(item)
                }
            }
        }
        
        return (summary, actions)
    }
    
    // MARK: - Summary 노트용 커스텀 뷰
    @ViewBuilder
    private var summaryNoteView: some View {
        let parsed = parseSummaryAndActions(from: editedContent)
        let rawSummary = parsed.summary
        let actions = parsed.actions

        // Summary 섹션으로 재구성
        let sections = buildSummarySections(from: rawSummary)

        // ❗️return 절 제거 → SwiftUI와 충돌 방지
        if sections.isEmpty && actions.isEmpty {
            Group {
                Text(editedContent.markdownToAttributed())
                    .font(.body)
                    .padding(.top, 4)
            }
        } else {
            // 아래는 Summary + Action Items 카드 UI
            VStack(alignment: .leading, spacing: 16) {

                // 📌 SUMMARY 카드
                if !sections.isEmpty {
                    VStack(alignment: .leading, spacing: 10) {
                        HStack(spacing: 6) {
                 
                            Text("Summary")
                                .font(.headline)
                        }

                        VStack(alignment: .leading, spacing: 12) {
                            ForEach(sections) { section in
                                VStack(alignment: .leading, spacing: 6) {
                                    Text(section.title)
                                        .font(.subheadline.bold())

                                    VStack(alignment: .leading, spacing: 4) {
                                        ForEach(section.bullets, id: \.self) { bullet in
                                            HStack(alignment: .top, spacing: 6) {
                                                Text("•")
                                                Text(bullet)
                                                    .frame(maxWidth: .infinity, alignment: .leading)
                                                    .font(.body)
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                    .padding(12)
                    .background(Color.yellow.opacity(0.15))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }

                // ✅ ACTION ITEMS 카드
                if !actions.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack(spacing: 6) {
                   
                            Text("Action Items")
                                .font(.headline)
                        }

                        VStack(alignment: .leading, spacing: 6) {
                            ForEach(actions, id: \.self) { item in
                                HStack(alignment: .top, spacing: 8) {
                                    Image(systemName: "square")
                                    Text(item)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                }
                            }
                        }
                    }
                    .padding(12)
                    .background(Color.green.opacity(0.12))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
            }
            .padding(.top, 4)
        }
    }


    // MARK: - Summary 섹션 모델
    private struct SummarySection: Identifiable {
        let id = UUID()
        let title: String
        let bullets: [String]
    }
    
    // MARK: - 간단한 인라인 Markdown 제거 (굵게 표시용 ** 등)
    private func stripInlineMarkdown(_ text: String) -> String {
        text
            .replacingOccurrences(of: "**", with: "")
            .replacingOccurrences(of: "__", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }


    // MARK: - "Here's a summary..." 같은 문장 제거 + Markdown 헤딩/불릿 파싱
    private func buildSummarySections(from rawSummary: String) -> [SummarySection] {
        if rawSummary.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return []
        }

        // 1) Gemini가 붙이는 군더더기 문장들 제거
        var text = rawSummary
            .replacingOccurrences(of: "Here's a summary of the provided content on", with: "")
            .replacingOccurrences(of: "Here’s a summary of the provided content on", with: "")
            .replacingOccurrences(of: "Here's a summary of the provided content:", with: "")
            .replacingOccurrences(of: "Here’s a summary of the provided content:", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)

        // 2) 줄 단위로 파싱
        let lines = text
            .split(whereSeparator: \.isNewline)
            .map { String($0).trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }

        var sections: [SummarySection] = []
        var currentTitle: String = "Overview"
        var currentBullets: [String] = []

        func flushSection() {
            guard !currentBullets.isEmpty else { return }
            sections.append(SummarySection(title: currentTitle, bullets: currentBullets))
            currentBullets = []
        }

        for line in lines {
            // ###, ## 로 시작하면 새로운 섹션 제목
            if line.hasPrefix("### ") || line.hasPrefix("## ") {
                flushSection()
                let dropped = line.hasPrefix("### ")
                    ? String(line.dropFirst(4))
                    : String(line.dropFirst(3))
                currentTitle = stripInlineMarkdown(dropped)
                continue
            }

            // 불릿 라인 (*, - 로 시작)
            if line.hasPrefix("* ") || line.hasPrefix("- ") {
                var bullet = line
                bullet.removeFirst(2)
                let cleanBullet = stripInlineMarkdown(bullet)
                currentBullets.append(cleanBullet)
                continue
            }

            // 그 외 문장은 직전 불릿에 붙이기 (설명 이어지는 경우)
            if currentBullets.isEmpty {
                currentBullets.append(line)
            } else {
                let last = currentBullets.removeLast()
                let merged = last + " " + line
                currentBullets.append(merged)
            }
        }

        flushSection()
        return sections
    }

    
    // MARK: - Body
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                
                // MARK: - Title
                if isEditing {
                    TextField("Title", text: $editedTitle)
                        .font(.system(size: 28, weight: .bold))
                        .textFieldStyle(.plain)
                        .padding(.vertical, 4)
                } else {
                    Text(editedTitle)
                        .font(.largeTitle)
                        .fontWeight(.bold)
                }
                
                // MARK: - Date
                Text("Updated: \(note.updatedAt.formatted(date: .abbreviated, time: .shortened))")
                    .font(.subheadline)
                    .foregroundColor(.gray)
                
                Divider()
                
                // MARK: - Content
                if isEditing {
                    TextEditor(text: $editedContent)
                        .font(.body)
                        .frame(minHeight: 220)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                        )
                } else {
                    if isFullTranscriptNote {
                        // 🔥 diarization 전용 레이아웃
                        diarizedContentView
                    } else {
                        // 🔥 Summary + Action Items 예쁜 레이아웃
                        summaryNoteView
                    }
                }
                
                Divider()
                
                // MARK: - Audio info
                if let url = note.audioUrl {
                    Text("Associated Recording:")
                        .font(.headline)
                    
                    Text(url)
                        .font(.footnote)
                        .foregroundColor(.blue)
                        .underline()
                }
            }
            .padding()
        }
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            
            // MARK: Edit/Save button
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(isEditing ? "Save" : "Edit") {
                    if isEditing { saveEdits() }
                    else { isEditing = true }
                }
            }
            
            // MARK: Move menu
            ToolbarItem(placement: .navigationBarTrailing) {
                Menu {
                    if currentFolderId != nil {
                        Button("Notes") { moveTo(folder: nil) }
                    }
                    
                    // Full Transcript 폴더는 이동 대상에서 제외 (원하면 유지)
                    let available = foldersViewModel.folders
                        .filter { $0.id != currentFolderId }
                        .filter {
                            $0.name.trimmingCharacters(in: .whitespacesAndNewlines)
                                .lowercased() != "full transcript".lowercased()
                        }
                    
                    if !available.isEmpty {
                        Section("Folders") {
                            ForEach(available) { folder in
                                Button(folder.name) {
                                    moveTo(folder: folder)
                                }
                            }
                        }
                    }
                } label: {
                    Label("Move", systemImage: "folder")
                }
                .disabled(isEditing)
            }
        }
        .alert("Note moved", isPresented: $showMoveAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(moveAlertMessage)
        }
    }
    
    // MARK: - Save edits
    private func saveEdits() {
        notesViewModel.updateNote(
            note,
            title: editedTitle,
            content: editedContent
        )
        isEditing = false
    }
    
    // MARK: - Move
    private func moveTo(folder: SNFolder?) {
        var updatedNote = note
        updatedNote.title = editedTitle
        updatedNote.content = editedContent
        
        notesViewModel.move(updatedNote, to: folder)
        currentFolderId = folder?.id
        
        moveAlertMessage = "This note has been moved to \"\(folder?.name ?? "Notes")\"."
        showMoveAlert = true
    }
}

// MARK: - Markdown Helper
extension String {
    func markdownToAttributed() -> AttributedString {
        if let attributed = try? AttributedString(
            markdown: self,
            options: .init(interpretedSyntax: .inlineOnlyPreservingWhitespace)
        ) {
            return attributed
        }
        return AttributedString(self)
    }
}
