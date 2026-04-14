import Foundation

struct User: Identifiable, Codable {
    var id = UUID()
    var name: String
    var email: String
    var hashedPassword: String 
    var industry: String?
}

