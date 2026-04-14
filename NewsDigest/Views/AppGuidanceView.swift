internal import SwiftUI

struct AppGuidanceView: View {
    @Environment(\.dismiss) var dismiss
    let impactMed = UIImpactFeedbackGenerator(style: .medium)
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea().premiumBackground()
                
                ScrollView {
                    VStack(spacing: 24) {
                        headerSection
                        
                        VStack(spacing: 16) {
                            GuidanceCard(
                                title: "Master the Swipe",
                                description: "Swipe any article card RIGHT to quickly bookmark it, or LEFT to share it with your network.",
                                icon: "hand.draw.fill",
                                color: .accentColor,
                                gestures: ["arrow.right": "Bookmark", "arrow.left": "Share"]
                            )
                            
                            GuidanceCard(
                                title: "AI Summaries",
                                description: "Tap the sparkle icon on any article card to get an instant, AI-powered brief. Perfect for busy mornings!",
                                icon: "sparkles",
                                color: .purple,
                                gestures: [:]
                            )
                            
                            GuidanceCard(
                                title: "Read Later",
                                description: "Tap the clock icon to add articles to your personal library. They'll be waiting for you in your Profile.",
                                icon: "clock.badge.checkmark.fill",
                                color: .blue,
                                gestures: [:]
                            )
                            
                            GuidanceCard(
                                title: "Audio Briefings",
                                description: "Tap the audio icon in any AI Summary to hear your news. You can even change the speaker's voice using the dropdown menu!",
                                icon: "speaker.wave.3.fill",
                                color: .pink,
                                gestures: [:]
                            )
                            
                            GuidanceCard(
                                title: "Hyper-Local Search",
                                description: "Want local news? Tap the location pin in the Digest header to manually search for any city. The AI will personalize the impact explicitly for that area.",
                                icon: "location.magnifyingglass",
                                color: .green,
                                gestures: [:]
                            )
                            
                            GuidanceCard(
                                title: "Deep Dive",
                                description: "Use the Broadcasters tab to follow specific RSS feeds from world-class news organizations or add your own.",
                                icon: "antenna.radiowaves.left.and.right",
                                color: .orange,
                                gestures: [:]
                            )
                        }
                        
                        dismissButton
                            .padding(.top, 20)
                    }
                    .padding(20)
                }
            }
            .navigationTitle("App Guidance")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        impactMed.impactOccurred()
                        dismiss()
                    }
                    .fontWeight(.bold)
                }
            }
        }
    }
    
    private var headerSection: some View {
        VStack(spacing: 12) {
            Image(systemName: "lightbulb.fill")
                .font(.system(size: 48))
                .foregroundColor(.yellow)
                .shadow(color: .yellow.opacity(0.4), radius: 15)
            
            Text("How to Master News Digest")
                .font(.title2)
                .fontWeight(.bold)
                .multilineTextAlignment(.center)
            
            Text("Become a power user with these simple gestures and features.")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 20)
        }
        .padding(.vertical, 32)
    }
    
    private var dismissButton: some View {
        Button {
            impactMed.impactOccurred()
            dismiss()
        } label: {
            Text("Got it, let's read!")
                .fontWeight(.bold)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(Color.accentColor)
                .foregroundColor(.white)
                .cornerRadius(16)
        }
    }
}

struct GuidanceCard: View {
    let title: String
    let description: String
    let icon: String
    let color: Color
    let gestures: [String: String]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundColor(color)
                    .padding(10)
                    .background(color.opacity(0.1))
                    .clipShape(Circle())
                
                Text(title)
                    .font(.headline)
                    .fontWeight(.bold)
            }
            
            Text(description)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .lineLimit(nil)
            
            if !gestures.isEmpty {
                HStack(spacing: 20) {
                    ForEach(gestures.sorted(by: { $0.key < $1.key }), id: \.key) { key, val in
                        HStack(spacing: 4) {
                            Image(systemName: key)
                                .font(.caption2)
                            Text(val)
                                .font(.caption2)
                                .fontWeight(.bold)
                        }
                        .foregroundColor(color)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(color.opacity(0.1))
                        .cornerRadius(6)
                    }
                }
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .glassPanel()
    }
}

#Preview {
    AppGuidanceView()
}
