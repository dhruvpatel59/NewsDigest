internal import SwiftUI

struct PremiumBackgroundModifier: ViewModifier {
    func body(content: Content) -> some View {
        ZStack {
            LinearGradient(
                gradient: Gradient(colors: [Color.accentColor.opacity(0.15), Color(uiColor: .systemGroupedBackground)]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            content
        }
    }
}

struct GlassPanelModifier: ViewModifier {
    var cornerRadius: CGFloat
    
    func body(content: Content) -> some View {
        content
            .background(.ultraThinMaterial)
            .cornerRadius(cornerRadius)
            .shadow(color: Color.black.opacity(0.08), radius: 10, x: 0, y: 5)
    }
}

extension View {
    func premiumBackground() -> some View {
        self.modifier(PremiumBackgroundModifier())
    }
    
    func glassPanel(cornerRadius: CGFloat = 16) -> some View {
        self.modifier(GlassPanelModifier(cornerRadius: cornerRadius))
    }
}

