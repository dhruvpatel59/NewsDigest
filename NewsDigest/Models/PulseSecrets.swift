import Foundation

/// Internal structure for sensitive API keys.
/// Keys are loaded from 'Secrets.plist' which must be excluded from version control.
struct PulseSecrets {
    private static let secrets: [String: String] = {
        guard let path = Bundle.main.path(forResource: "Secrets", ofType: "plist"),
              let dict = NSDictionary(contentsOfFile: path) as? [String: String] else {
            print("⚠️ SECURITY WARNING: 'Secrets.plist' not found. Features relying on API keys will be disabled.")
            return [:]
        }
        return dict
    }()
    
    // API Keys
    static var gnewsKey: String { secrets["GNEWS_API_KEY"] ?? "" }
    static var geminiKey: String { secrets["GEMINI_API_KEY"] ?? "" }
    static var groqKey: String { secrets["GROQ_API_KEY"] ?? "" }
    
    // Auth Configuration
    static var adminEmail: String { secrets["ADMIN_EMAIL"] ?? "guest@pulsenews.ai" }
    static var adminDefaultPassword: String { secrets["ADMIN_DEFAULT_PASSWORD"] ?? UUID().uuidString }
    static var authSalt: String { secrets["AUTH_SALT"] ?? "fallback_pulse_salt_2026" }
    
    // Verification
    static var hasValidKeys: Bool {
        !gnewsKey.isEmpty && !geminiKey.isEmpty
    }
}
