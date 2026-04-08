import UIKit

/// A singleton to manage haptic feedback efficiently.
/// Reuses generators to avoid the overhead of repeated allocations.
class HapticManager {
    static let shared = HapticManager()
    
    private let lightGenerator = UIImpactFeedbackGenerator(style: .light)
    private let mediumGenerator = UIImpactFeedbackGenerator(style: .medium)
    private let heavyGenerator = UIImpactFeedbackGenerator(style: .heavy)
    private let selectionGenerator = UISelectionFeedbackGenerator()
    private let notificationGenerator = UINotificationFeedbackGenerator()
    
    private init() {
        prepare()
    }
    
    func prepare() {
        lightGenerator.prepare()
        mediumGenerator.prepare()
        heavyGenerator.prepare()
        selectionGenerator.prepare()
        notificationGenerator.prepare()
    }
    
    func trigger(_ style: UIImpactFeedbackGenerator.FeedbackStyle) {
        switch style {
        case .light: lightGenerator.impactOccurred()
        case .medium: mediumGenerator.impactOccurred()
        case .heavy: heavyGenerator.impactOccurred()
        case .soft: UIImpactFeedbackGenerator(style: .soft).impactOccurred() // Rarely used, can allocate
        case .rigid: UIImpactFeedbackGenerator(style: .rigid).impactOccurred() // Rarely used
        @unknown default: break
        }
    }
    
    func selectionChanged() {
        selectionGenerator.selectionChanged()
    }
    
    func notificationOccurred(_ type: UINotificationFeedbackGenerator.FeedbackType) {
        notificationGenerator.notificationOccurred(type)
    }
}
