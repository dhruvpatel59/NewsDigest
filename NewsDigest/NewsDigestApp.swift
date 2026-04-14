import SwiftUI

enum StorageKeys {
    static let isDarkMode = "isDarkModeEnabled"
    static let hasCompletedOnboarding = "hasCompletedOnboarding"
}

@main
struct NewsDigestApp: App {
    @StateObject private var authStore = AuthStore()
    @AppStorage(StorageKeys.isDarkMode) private var isDarkModeEnabled = false
    @AppStorage(StorageKeys.hasCompletedOnboarding) private var hasCompletedOnboarding = false
    
    var body: some Scene {
        WindowGroup {
            if !hasCompletedOnboarding {
                OnboardingView()
            } else if authStore.isAuthenticated {
                MainTabView()
                    .environmentObject(authStore)
                    .preferredColorScheme(isDarkModeEnabled ? .dark : .light)
            } else {
                LoginView()
                    .environmentObject(authStore)
                    .preferredColorScheme(isDarkModeEnabled ? .dark : .light)
            }
        }
    }
}
