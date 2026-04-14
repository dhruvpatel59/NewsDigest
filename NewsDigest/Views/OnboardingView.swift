internal import SwiftUI

struct OnboardingView: View {
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @State private var currentPage = 0
    
    let impactMed = UIImpactFeedbackGenerator(style: .medium)
    
    private let pages: [(icon: String, title: String, subtitle: String)] = [
        (
            "newspaper.fill",
            "Your News, Your Way",
            "Get real-time headlines from your country, powered by your location. Stay informed with what matters most to you."
        ),
        (
            "square.grid.2x2.fill",
            "Explore Every Topic",
            "From Technology to Sports, browse curated categories or search any keyword to discover stories across the globe."
        ),
        (
            "bookmark.fill",
            "Save for Later",
            "Tap the heart on any article to save it offline. Build your personal reading library and never lose a story."
        )
    ]
    
    var body: some View {
        ZStack {
            // Unified dark background
            Color.black.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Page content
                TabView(selection: $currentPage) {
                    ForEach(0..<pages.count, id: \.self) { index in
                        onboardingPage(for: index)
                            .tag(index)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .animation(.easeInOut(duration: 0.3), value: currentPage)
                
                // Bottom controls
                VStack(spacing: 24) {
                    // Custom page indicator
                    HStack(spacing: 8) {
                        ForEach(0..<pages.count, id: \.self) { index in
                            Capsule()
                                .fill(index == currentPage ? Color.white : Color.white.opacity(0.3))
                                .frame(width: index == currentPage ? 24 : 8, height: 8)
                                .animation(.spring(response: 0.3), value: currentPage)
                        }
                    }
                    
                    // Action button
                    Button {
                        impactMed.impactOccurred()
                        if currentPage < pages.count - 1 {
                            currentPage += 1
                        } else {
                            withAnimation { hasCompletedOnboarding = true }
                        }
                    } label: {
                        Text(currentPage == pages.count - 1 ? "Get Started" : "Continue")
                            .font(.body)
                            .fontWeight(.semibold)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(Color.white)
                            .foregroundColor(.black)
                            .cornerRadius(14)
                    }
                    .padding(.horizontal, 24)
                    
                    // Skip option (hidden on last page)
                    if currentPage < pages.count - 1 {
                        Button {
                            impactMed.impactOccurred()
                            withAnimation { hasCompletedOnboarding = true }
                        } label: {
                            Text("Skip")
                                .font(.subheadline)
                                .foregroundColor(.white.opacity(0.6))
                        }
                    } else {
                        // Maintain spacing
                        Text(" ")
                            .font(.subheadline)
                    }
                }
                .padding(.bottom, 40)
            }
        }
    }
    
    private func onboardingPage(for index: Int) -> some View {
        let page = pages[index]
        
        return VStack(spacing: 32) {
            Spacer()
            
            // Icon with subtle glow
            ZStack {
                Circle()
                    .fill(Color.accentColor.opacity(0.15))
                    .frame(width: 140, height: 140)
                
                Circle()
                    .fill(Color.accentColor.opacity(0.08))
                    .frame(width: 180, height: 180)
                
                Image(systemName: page.icon)
                    .font(.system(size: 52, weight: .medium))
                    .foregroundColor(.accentColor)
            }
            
            VStack(spacing: 12) {
                Text(page.title)
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                
                Text(page.subtitle)
                    .font(.body)
                    .foregroundColor(.white.opacity(0.65))
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
                    .padding(.horizontal, 32)
            }
            
            Spacer()
            Spacer()
        }
    }
}

#Preview {
    OnboardingView()
}
