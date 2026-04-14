import Foundation

struct AudioPersona: Identifiable, Hashable {
    let id: String
    let name: String
    let icon: String // SF Symbol
    let languageCode: String
    let accentDescription: String
    
    static let available: [AudioPersona] = [
        AudioPersona(
            id: "ava", 
            name: "The Analyst", 
            icon: "chart.bar.fill", 
            languageCode: "en-US", 
            accentDescription: "Clear American professional"
        ),
        AudioPersona(
            id: "daniel", 
            name: "The Correspondent", 
            icon: "microphone.fill", 
            languageCode: "en-GB", 
            accentDescription: "Authoritative British reporter"
        ),
        AudioPersona(
            id: "samantha", 
            name: "The Morning Anchor", 
            icon: "sun.max.fill", 
            languageCode: "en-US", 
            accentDescription: "Warm and engaging narrator"
        ),
        AudioPersona(
            id: "rishi", 
            name: "The Global Delegate", 
            icon: "globe.central.south.asia.fill", 
            languageCode: "en-IN", 
            accentDescription: "Sophisticated Indian global perspective"
        )
    ]
}

