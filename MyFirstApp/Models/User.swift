import Foundation

struct User: Identifiable, Codable {
    var id = UUID()
    var name: String
    var email: String
    // Secure property for storing hashed version of the user password
    var hashedPassword: String 
}
