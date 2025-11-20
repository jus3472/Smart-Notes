import Foundation

enum Secrets {
    static var geminiAPIKey: String {
        if let key = Bundle.main.object(forInfoDictionaryKey: "GEMINI_API_KEY") as? String {
            print("🔑 Loaded Gemini API Key:", key)
            return key
        } else {
            print("❌ GEMINI_API_KEY NOT FOUND in Info.plist")
            return ""
        }
    }
}
