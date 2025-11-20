import Foundation

class GeminiService {
    private let apiKey = Secrets.geminiAPIKey
    private let model = "gemini-1.5-flash"
    
    struct GeminiResponse: Codable {
        let candidates: [GeminiCandidate]
    }

    struct GeminiCandidate: Codable {
        let content: GeminiContent
    }

    struct GeminiContent: Codable {
        let parts: [GeminiPart]
    }

    struct GeminiPart: Codable {
        let text: String?
    }


    func summarize(_ text: String) async throws -> String {
        let url = URL(string:"https://generativelanguage.googleapis.com/v1beta/models/\(model):generateContent?key=\(apiKey)")!

        let body: [String: Any] = [
            "contents": [
                ["parts": [["text": text]]]
            ]
        ]

        let data = try JSONSerialization.data(withJSONObject: body)
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = data

        let (responseData, _) = try await URLSession.shared.data(for: request)
        let decoded = try JSONDecoder().decode(GeminiResponse.self, from: responseData)

        return decoded.candidates.first?.content.parts.first?.text ?? ""
    }
}
