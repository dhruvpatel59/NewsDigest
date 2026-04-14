internal import SwiftUI

// MARK: - Shimmer Loading Skeleton
struct ShimmerModifier: ViewModifier {
    @State private var phase: CGFloat = 0
    
    func body(content: Content) -> some View {
        content
            .overlay(
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color.white.opacity(0.0),
                        Color.white.opacity(0.3),
                        Color.white.opacity(0.0)
                    ]),
                    startPoint: .leading,
                    endPoint: .trailing
                )
                .offset(x: phase)
                .onAppear {
                    withAnimation(
                        .linear(duration: 1.5)
                        .repeatForever(autoreverses: false)
                    ) {
                        phase = 350
                    }
                }
            )
            .mask(content)
    }
}

extension View {
    func shimmer() -> some View {
        self.modifier(ShimmerModifier())
    }
}

struct SkeletonCardView: View {
    var body: some View {
        HStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 10) {
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color(uiColor: .systemGray5))
                    .frame(width: 80, height: 12)
                
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color(uiColor: .systemGray5))
                    .frame(height: 16)
                
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color(uiColor: .systemGray5))
                    .frame(width: 200, height: 14)
                
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color(uiColor: .systemGray5))
                    .frame(width: 140, height: 14)
            }
            
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(uiColor: .systemGray5))
                .frame(width: 80, height: 80)
        }
        .padding()
        .glassPanel()
        .shimmer()
    }
}
