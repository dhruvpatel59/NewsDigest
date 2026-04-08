import Foundation
import Combine
import SwiftUI
import CryptoKit

class AuthStore: ObservableObject {
    @Published var currentUser: User?
    @Published var isAuthenticated: Bool = false
    
    private let serviceName = "com.dhruvpatel.MyFirstApp.auth"
    private let usersAccount = "saved_users_database"
    private let sessionAccount = "current_user_session"
    private var salt: String { PulseSecrets.authSalt }
    private let maxUserLimit = 3
    
    init() {
        seedAdminAccount()
        checkSession()
    }
    
    private func seedAdminAccount() {
        let adminEmail = PulseSecrets.adminEmail.lowercased()
        var allUsers = fetchAllUsers()
        
        if !allUsers.contains(where: { $0.email == adminEmail }) {
            let admin = User(
                name: "Dhruv Patel",
                email: adminEmail,
                hashedPassword: hash(PulseSecrets.adminDefaultPassword)
            )
            allUsers.append(admin)
            saveAllUsers(allUsers)
        }
    }
    
    func checkSession() {
        if let data = KeychainManager.shared.read(service: serviceName, account: sessionAccount),
           let user = try? JSONDecoder().decode(User.self, from: data) {
            self.currentUser = user
            self.isAuthenticated = true
        }
    }
    
    func register(name: String, email: String, passwordRaw: String) -> Bool {
        var allUsers = fetchAllUsers()
        
        if allUsers.count >= maxUserLimit {
            return false
        }
        
        let newUser = User(name: name, email: email.lowercased(), hashedPassword: hash(passwordRaw))
        
        if allUsers.contains(where: { $0.email == newUser.email }) {
            return false
        }
        
        allUsers.append(newUser)
        saveAllUsers(allUsers)
        
        return login(email: email, passwordRaw: passwordRaw)
    }
    
    func login(email: String, passwordRaw: String) -> Bool {
        let allUsers = fetchAllUsers()
        let hashedInput = hash(passwordRaw)
        
        if let user = allUsers.first(where: { $0.email == email.lowercased() && $0.hashedPassword == hashedInput }) {
            self.currentUser = user
            self.isAuthenticated = true
            
            if let data = try? JSONEncoder().encode(user) {
                try? KeychainManager.shared.save(data, service: serviceName, account: sessionAccount)
            }
            return true
        }
        return false
    }
    
    var isRegistrationOpen: Bool {
        return fetchAllUsers().count < maxUserLimit
    }
    
    func logout() {
        self.currentUser = nil
        self.isAuthenticated = false
        KeychainManager.shared.delete(service: serviceName, account: sessionAccount)
    }
    
    private func hash(_ input: String) -> String {
        let saltedInput = input + salt
        let data = Data(saltedInput.utf8)
        let digest = SHA256.hash(data: data)
        return digest.compactMap { String(format: "%02x", $0) }.joined()
    }
    
    private func fetchAllUsers() -> [User] {
        if let data = KeychainManager.shared.read(service: serviceName, account: usersAccount),
           let users = try? JSONDecoder().decode([User].self, from: data) {
            return users
        }
        return []
    }
    
    private func saveAllUsers(_ users: [User]) {
        if let data = try? JSONEncoder().encode(users) {
            try? KeychainManager.shared.save(data, service: serviceName, account: usersAccount)
        }
    }
}
