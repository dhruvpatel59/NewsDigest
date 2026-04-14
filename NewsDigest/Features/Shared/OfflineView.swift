internal import SwiftUI

struct OfflineView: View {
    let onRetry: () -> Void
    let impactMed = UIImpactFeedbackGenerator(style: .medium)
    
    var body: some View {
        VStack(spacing: 24) {
            ZStack {
                Circle()
                    .fill(Color.accentColor.opacity(0.1))
                    .frame(width: 120, height: 120)
                
                Circle()
                    .stroke(Color.accentColor.opacity(0.2), lineWidth: 2)
                    .frame(width: 140, height: 140)
                    .scaleEffect(1.1)
                
                Image(systemName: "wifi.slash")
                    .font(.system(size: 52, weight: .medium))
                    .foregroundColor(.accentColor)
            }
            .padding(.bottom, 8)
            
            VStack(spacing: 12) {
                Text("No Connection")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                
                Text("Your device is currently offline. Please check your internet settings and try again.")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
            }
            
            Button {
                impactMed.impactOccurred()
                onRetry()
            } label: {
                HStack(spacing: 12) {
                    Image(systemName: "arrow.clockwise")
                        .font(.headline)
                    Text("Try Again")
                        .fontWeight(.bold)
                }
                .padding(.vertical, 14)
                .padding(.horizontal, 32)
                .background(Color.accentColor)
                .foregroundColor(.white)
                .cornerRadius(16)
                .shadow(color: Color.accentColor.opacity(0.3), radius: 10, x: 0, y: 5)
            }
        }
        .padding(32)
        .glassPanel()
        .padding(.horizontal, 24)
        .transition(.opacity.combined(with: .scale))
    }
}

#Preview {
    ZStack {
        Color.black.ignoresSafeArea()
        OfflineView(onRetry: {})
    }
}

