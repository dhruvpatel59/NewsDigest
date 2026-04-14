internal import SwiftUI


struct SwipeableCardModifier: ViewModifier {
    let onBookmark: () -> Void
    let onShare: () -> Void
    let isBookmarked: Bool
    
    @State private var offset: CGFloat = 0
    @State private var feedbackIcon: String? = nil
    
    private let threshold: CGFloat = 60 // Lowered for better sensitivity
    private let impactLight = UIImpactFeedbackGenerator(style: .medium)
    
    func body(content: Content) -> some View {
        content
            .offset(x: offset)
            .overlay(alignment: .center) {
                if let icon = feedbackIcon {
                    Image(systemName: icon)
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(.white)
                        .padding(16)
                        .background(icon == "heart.fill" || icon == "heart.slash.fill" ? Color.red : Color.accentColor)
                        .clipShape(Circle())
                        .shadow(radius: 8)
                        .transition(.scale.combined(with: .opacity))
                }
            }
            .highPriorityGesture( // Ensure we beat the ScrollView
                DragGesture(minimumDistance: 15) // Lowered minimum distance
                    .onChanged { value in
                        let horizontal = abs(value.translation.width)
                        let vertical = abs(value.translation.height)
                        guard horizontal > vertical else { return }
                        
                        let drag = value.translation.width
                        let resistance: CGFloat = abs(drag) > threshold ? 0.4 : 1.0
                        offset = drag * resistance
                    }
                    .onEnded { value in
                        let horizontal = abs(value.translation.width)
                        let vertical = abs(value.translation.height)
                        
                        if horizontal > vertical {
                            if value.translation.width > threshold {
                                impactLight.impactOccurred()
                                triggerFeedback(icon: isBookmarked ? "heart.slash.fill" : "heart.fill")
                                onBookmark()
                            } else if value.translation.width < -threshold {
                                impactLight.impactOccurred()
                                triggerFeedback(icon: "square.and.arrow.up")
                                onShare()
                            }
                        }
                        
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            offset = 0
                        }
                    }
            )
    }
    
    private func triggerFeedback(icon: String) {
        withAnimation(.spring(response: 0.25)) {
            feedbackIcon = icon
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
            withAnimation(.easeOut(duration: 0.2)) {
                feedbackIcon = nil
            }
        }
    }
}

extension View {
    func swipeActions(
        isBookmarked: Bool,
        onBookmark: @escaping () -> Void,
        onShare: @escaping () -> Void
    ) -> some View {
        self.modifier(SwipeableCardModifier(
            onBookmark: onBookmark,
            onShare: onShare,
            isBookmarked: isBookmarked
        ))
    }
}

struct SwipeTipCard: View {
    @AppStorage("hasSeenSwipeTip") private var hasSeenSwipeTip = false
    
    var body: some View {
        if !hasSeenSwipeTip {
            HStack(spacing: 12) {
                Image(systemName: "hand.draw.fill")
                    .font(.title3)
                    .foregroundColor(.accentColor)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("Swipe on any article")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                    
                    Text("Swipe left to save, right to share")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Button {
                    withAnimation { hasSeenSwipeTip = true }
                } label: {
                    Image(systemName: "xmark")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(6)
                        .background(Color.secondary.opacity(0.15))
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)
            }
            .padding(14)
            .background(.ultraThinMaterial)
            .cornerRadius(14)
            .transition(.opacity.combined(with: .move(edge: .top)))
        }
    }
}

