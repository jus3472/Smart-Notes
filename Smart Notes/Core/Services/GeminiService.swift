import Foundation

class GeminiService {
    private let apiKey = Secrets.geminiAPIKey
    private let model = "gemini-2.5-flash"

    struct Response: Codable {
        let candidates: [Candidate]
    }

    struct Candidate: Codable {
        let output: String?
        let content: Content?
    }

    struct Content: Codable {
        let parts: [Part]
    }

    struct Part: Codable {
        let text: String?
    }

    // MARK: - Summarization
    func summarize(_ text: String) async throws -> String {
        let url = URL(string:
            "https://generativelanguage.googleapis.com/v1beta/models/\(model):generateContent?key=\(apiKey)"
        )!

        let requestBody: [String: Any] = [
            "contents": [
                [
                    "parts": [
                        ["text":
                        """
                        You are SmartNotes, an intelligent academic note assistant.

                        Task:
                        Create a **very concise study summary** of the following
                        content.

                        Requirements:
                        - Focus ONLY on the 3–6 most important ideas.
                        - Each idea must be a single short bullet point.
                        - Prefer high-level concepts over detailed explanations.
                        - DO NOT include any preface like "Here's a summary of the provided content".
                        - DO NOT say things like "Today's Topic" unless it is explicitly in the content.
                        - Return the result as plain Markdown bullet points, e.g.:
                            - First key idea...
                            - Second key idea...
                        
                        Content to summarize:
                        \(text)
                        """
                        ]
                    ]
                ]
            ]
        ]

        let data = try JSONSerialization.data(withJSONObject: requestBody)

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = data

        let (responseData, _) = try await URLSession.shared.data(for: request)

        if let raw = try? JSONSerialization.jsonObject(with: responseData) {
            print("🔥 DEBUG Gemini summarize response:", raw)
        }

        let decoded = try JSONDecoder().decode(Response.self, from: responseData)

        if let output = decoded.candidates.first?.output {
            return output
        }

        return decoded.candidates.first?.content?.parts.first?.text ?? ""
    }

    // MARK: - Speaker Diarization (text-based)
    func diarize(_ text: String) async throws -> String {
        let url = URL(string:
            "https://generativelanguage.googleapis.com/v1beta/models/\(model):generateContent?key=\(apiKey)"
        )!

        // 여기서는 "화자 라벨이 포함된 transcript"를 그대로 텍스트로 리턴하게 할 거야.
        // 예시 출력:
        // Professor: Today we'll review dynamic programming...
        // Student: Could you explain the recurrence again?
        let requestBody: [String: Any] = [
            "contents": [
                [
                    "parts": [
                        ["text":
                        """
                        You are SmartNotes, an intelligent academic note assistant.

                        Task:
                        Perform speaker diarization on the following transcript of a lecture or meeting.
                        The transcript may contain a professor/teacher, one or more students, or the user.

                        Requirements:
                        - Infer speaker turns based on language patterns and context.
                        - Whenever the speaker changes, start a new line.
                        - Use simple speaker labels like:
                          - Professor:
                          - Student:
                          - User:
                          - Unknown: (if you are unsure)
                        - Do not invent new content. Only reorganize and label what is already said.
                        - Keep the original sentence order.
                        - Return only the labeled transcript as plain text.

                        Transcript:
                        \(text)
                        """
                        ]
                    ]
                ]
            ]
        ]

        let data = try JSONSerialization.data(withJSONObject: requestBody)

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = data

        let (responseData, _) = try await URLSession.shared.data(for: request)

        if let raw = try? JSONSerialization.jsonObject(with: responseData) {
            print("🎙️ DEBUG Gemini diarize response:", raw)
        }

        let decoded = try JSONDecoder().decode(Response.self, from: responseData)

        if let output = decoded.candidates.first?.output {
            return output
        }

        return decoded.candidates.first?.content?.parts.first?.text ?? ""
    }
    
    // MARK: - Action Item Extraction
    func extractActionItems(fromSummary summary: String) async throws -> [String] {
        let url = URL(string:
            "https://generativelanguage.googleapis.com/v1beta/models/\(model):generateContent?key=\(apiKey)"
        )!

        let requestBody: [String: Any] = [
            "contents": [
                [
                    "parts": [
                        ["text":
                        """
                        You are SmartNotes, an intelligent academic note assistant.

                        Task:
                        From the following summary of a lecture or meeting,
                        generate concrete action items or follow-up tasks for the user.

                        Important:
                        - Even if the speaker did not explicitly tell the user to do something,
                          infer helpful study or follow-up tasks from the concepts mentioned.
                        - For example:
                          - "Review dynamic programming and practice 2 example problems."
                          - "Summarize today's lecture in your own words."
                          - "Re-read chapter 3 on Markov decision processes."
                        - If assignments, exams, deadlines, project requirements, or TODOs
                          are mentioned directly, include them as action items.
                        
                        Requirements:
                        - Return between 1 and 10 action items.
                        - Each action item MUST be a short, clear imperative sentence
                          (e.g., "Review chapter 5 on dynamic programming").
                        - Focus on tasks that help the user remember, apply, or prepare
                          (review, practice, summarize, read, email, prepare, implement, etc.).
                        - Do NOT restate the theory itself. Turn it into "do" tasks.
                        - Format:
                          One action item per line.
                          No bullets, no numbering, just plain text.

                        Summary:
                        \(summary)
                        """
                        ]
                    ]
                ]
            ]
        ]

        let data = try JSONSerialization.data(withJSONObject: requestBody)

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = data

        let (responseData, _) = try await URLSession.shared.data(for: request)

        if let raw = try? JSONSerialization.jsonObject(with: responseData) {
            print("📝 DEBUG Gemini actionItems response:", raw)
        }

        let decoded = try JSONDecoder().decode(Response.self, from: responseData)

        let rawText: String
        if let output = decoded.candidates.first?.output {
            rawText = output
        } else {
            rawText = decoded.candidates.first?.content?.parts.first?.text ?? ""
        }

        let trimmed = rawText.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty {
            return []
        }

        // 한 줄당 하나의 action item → 최대 10개만
        let allItems = trimmed
            .split(separator: "\n")
            .map { String($0).trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }

        return Array(allItems.prefix(10))
    }

}
