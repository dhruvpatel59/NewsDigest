import SwiftUI

// MARK: - Styled Section Header
struct SectionHeaderView: View {
    let title: String
    let icon: String
    var actionIcon: String? = nil
    var onAction: (() -> Void)? = nil
    
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.subheadline)
                .foregroundColor(.accentColor)
            
            Text(title)
                .font(.headline)
                .fontWeight(.bold)
                .foregroundColor(.primary)
            
            // Subtle line extending to the right
            Rectangle()
                .fill(Color.accentColor.opacity(0.15))
                .frame(height: 1)
            
            if let actionIcon = actionIcon {
                Button {
                    onAction?()
                } label: {
                    Image(systemName: actionIcon)
                        .font(.body.weight(.black))
                        .foregroundColor(.accentColor)
                        .padding(12)
                        .background(
                            Circle()
                                .fill(Color.accentColor.opacity(0.15))
                                .shadow(color: Color.accentColor.opacity(0.2), radius: 4, x: 0, y: 2)
                        )
                }
            }
        }
        .padding(.vertical, 4)
    }
}
