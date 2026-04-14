import SwiftUI

enum NewsCategory: String, CaseIterable, Identifiable {
    case general
    case world
    case nation
    case business
    case technology
    case entertainment
    case sports
    case science
    case health
    
    var id: String { rawValue }
    
    var displayName: String {
        rawValue.capitalized
    }
    
    var icon: String {
        switch self {
        case .general: return "newspaper.fill"
        case .world: return "globe.americas.fill"
        case .nation: return "flag.fill"
        case .business: return "chart.line.uptrend.xyaxis"
        case .technology: return "desktopcomputer"
        case .entertainment: return "film.fill"
        case .sports: return "sportscourt.fill"
        case .science: return "atom"
        case .health: return "heart.text.square.fill"
        }
    }
    
    // Refined, cohesive palette — all derived from the same cool-neutral family
    var tint: Color {
        switch self {
        case .general:       return Color(red: 0.35, green: 0.45, blue: 0.62)
        case .world:         return Color(red: 0.40, green: 0.50, blue: 0.65)
        case .nation:        return Color(red: 0.45, green: 0.42, blue: 0.58)
        case .business:      return Color(red: 0.32, green: 0.52, blue: 0.55)
        case .technology:    return Color(red: 0.42, green: 0.48, blue: 0.68)
        case .entertainment: return Color(red: 0.50, green: 0.45, blue: 0.60)
        case .sports:        return Color(red: 0.48, green: 0.40, blue: 0.55)
        case .science:       return Color(red: 0.35, green: 0.55, blue: 0.60)
        case .health:        return Color(red: 0.45, green: 0.50, blue: 0.58)
        }
    }
}
