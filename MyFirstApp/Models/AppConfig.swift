import Foundation

// MARK: - App Configuration & SECRETS
// Centralized configuration to keep hardcoded tokens out of active Service memory.
// In a full production environment, these should be strictly populated via Info.plist / .xcconfig.

enum AppConfig {
    static let gnewsAPIKey = PulseSecrets.gnewsKey
    static let geminiAPIKey = PulseSecrets.geminiKey
}
