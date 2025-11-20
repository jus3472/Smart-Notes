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

    func summarize(_ text: String) async throws -> String {
        let url = URL(string:
            "https://generativelanguage.googleapis.com/v1beta/models/\(model):generateContent?key=\(apiKey)"
        )!

        let requestBody: [String: Any] = [
            "contents": [
                [
                    "parts": [
                        ["text": "Summarize concisely:\n\n\(text)"]
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

        // JSON이 어떻게 오든 대응할 수 있게 2단계 파싱
        if let raw = try? JSONSerialization.jsonObject(with: responseData) {
            print("🔥 DEBUG Gemini response:", raw)
        }

        let decoded = try JSONDecoder().decode(Response.self, from: responseData)

        // ① 가장 기본적인 구조: output 직접 제공
        if let output = decoded.candidates.first?.output {
            return output
        }

        // ② content.parts 방식
        return decoded.candidates.first?.content?.parts.first?.text ?? ""
    }
}
