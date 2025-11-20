import Foundation

enum Secrets {
    static var geminiAPIKey: String {
        return Bundle.main.object(forInfoDictionaryKey: "GEMINI_API_KEY") as? String ?? ""
    }
}
