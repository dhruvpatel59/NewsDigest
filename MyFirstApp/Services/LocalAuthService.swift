import Foundation
import Combine

// MARK: - User Model
struct PulseUser: Codable, Identifiable {
    let id: UUID
    let email: String
    let passwordHash: String // In a real app, this would be BCrypt or similar
    var createdAt: Date
}

// MARK: - Local Auth Service
class LocalAuthService: ObservableObject {
    static let shared = LocalAuthService()
    
    private let userStorageKey = "Pulse_Authorized_Users"
    private let currentSessionKey = "Pulse_Active_User_ID"
    private let maxAllowableUsers = 3
    
    @Published var currentUser: PulseUser?
    
    init() {
        loadSession()
        seedAdmin()
    }
    
    // MARK: - Core Logic
    
    private func seedAdmin() {
        let adminEmail = "dhruv1405patel@gmail.com"
        var users = getAllUsers()
        
        if !users.contains(where: { $0.email == adminEmail }) {
            let admin = PulseUser(
                id: UUID(),
                email: adminEmail,
                passwordHash: "dhruv123456", // Pre-set per your request
                createdAt: Date()
            )
            users.append(admin)
            saveUsers(users)
            print("--- Auth: Seeded Admin Account Successfully ---")
        }
    }
    
    func login(email: String, password: String) -> Bool {
        let users = getAllUsers()
        if let foundUser = users.first(where: { $0.email.lowercased() == email.lowercased() && $0.passwordHash == password }) {
            currentUser = foundUser
            saveSession(id: foundUser.id)
            return true
        }
        return false
    }
    
    func signUp(email: String, password: String) throws -> Bool {
        var users = getAllUsers()
        
        // 1. Check if user already exists
        if users.contains(where: { $0.email.lowercased() == email.lowercased() }) {
            throw AuthError.userExists
        }
        
        // 2. THE WHITELIST LOCK: Check if quota is full
        if users.count >= maxAllowableUsers {
            throw AuthError.quotaFull
        }
        
        // 3. Register the user
        let newUser = PulseUser(
            id: UUID(),
            email: email.lowercased(),
            passwordHash: password,
            createdAt: Date()
        )
        users.append(newUser)
        saveUsers(users)
        
        currentUser = newUser
        saveSession(id: newUser.id)
        return true
    }
    
    func logout() {
        currentUser = nil
        UserDefaults.standard.removeObject(forKey: currentSessionKey)
    }
    
    var isRegistrationOpen: Bool {
        return getAllUsers().count < maxAllowableUsers
    }
    
    // MARK: - Persistence Helpers
    
    private func getAllUsers() -> [PulseUser] {
        guard let data = UserDefaults.standard.data(forKey: userStorageKey),
              let users = try? JSONDecoder().decode([PulseUser].self, from: data) else {
            return []
        }
        return users
    }
    
    private func saveUsers(_ users: [PulseUser]) {
        if let data = try? JSONEncoder().encode(users) {
            UserDefaults.standard.set(data, forKey: userStorageKey)
        }
    }
    
    private func saveSession(id: UUID) {
        UserDefaults.standard.set(id.uuidString, forKey: currentSessionKey)
    }
    
    private func loadSession() {
        if let idString = UserDefaults.standard.string(forKey: currentSessionKey),
           let id = UUID(uuidString: idString) {
            let users = getAllUsers()
            currentUser = users.first(where: { $0.id == id })
        }
    }
}

enum AuthError: Error, LocalizedError {
    case userExists
    case quotaFull
    case invalidCredentials
    
    var errorDescription: String? {
        switch self {
        case .userExists: return "This email is already registered."
        case .quotaFull: return "Access Denied: The 3-user pilot quota is full."
        case .invalidCredentials: return "Invalid email or password."
        }
    }
}
