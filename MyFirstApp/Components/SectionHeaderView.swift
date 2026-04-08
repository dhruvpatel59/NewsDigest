import SwiftUI

// MARK: - Styled Section Header
struct SectionHeaderView: View {
    let title: String
    let icon: String
    
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
                .fill(Color.accentColor.opacity(0.2))
                .frame(height: 1)
        }
        .padding(.vertical, 4)
    }
}
