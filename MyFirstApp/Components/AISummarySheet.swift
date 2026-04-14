import SwiftUI

// MARK: - AI Summary Sheet
// A high-performance, Apple-standard design for the Pulse News AI engine.
// Focuses on typography, depth, and staggered animations.

struct AISummarySheet: View {
    let article: Article
    let onReadFullArticle: () -> Void
    
    @State private var summaryText: String? = nil
    @State private var perspectiveAnalysis: Pulse360Analysis? = nil
    @State private var isLoading = true
    @State private var errorMessage: String? = nil
    @State private var animateContent = false
    @ObservedObject private var audioService = AudioBriefingService.shared
    
    @EnvironmentObject var networkMonitor: NetworkMonitor
    
    var body: some View {
        ZStack {
            // Background Layer: Premium Adaptive Background
            Color(uiColor: .systemBackground).ignoresSafeArea()
            
            // Subtle adaptive gradient for depth
            LinearGradient(
                colors: [Color.blue.opacity(0.12), Color.clear],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            ).ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Drag Indicator
                Capsule()
                    .fill(Color.secondary.opacity(0.3))
                    .frame(width: 36, height: 5)
                    .padding(.top, 12)
                
                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 32) {
                        
                        // Header Section
                        VStack(alignment: .leading, spacing: 12) {
                            HStack(spacing: 12) {
                                ZStack {
                                    Circle()
                                        .fill(Color.blue.opacity(0.1))
                                        .frame(width: 40, height: 40)
                                    
                                    Image(systemName: "sparkles")
                                        .foregroundStyle(
                                            LinearGradient(
                                                colors: [.blue, .cyan],
                                                startPoint: .topLeading,
                                                endPoint: .bottomTrailing
                                            )
                                        )
                                        .font(.title2.bold())
                                }
                                
                                Text("Pulse AI Insight")
                                    .font(.subheadline.bold())
                                    .foregroundColor(.blue)
                                    .kerning(1.2)
                                    .textCase(.uppercase)
                                
                                Spacer()
                                
                                if summaryText != nil {
                                    HStack(spacing: 8) {
                                        // Persona Selector
                                        Menu {
                                            ForEach(AudioPersona.available) { persona in
                                                Button {
                                                    AudioBriefingService.shared.selectedPersona = persona
                                                } label: {
                                                    HStack {
                                                        Text(persona.name)
                                                        Spacer()
                                                        Image(systemName: persona.icon)
                                                    }
                                                }
                                            }
                                        } label: {
                                            HStack(spacing: 4) {
                                                Image(systemName: AudioBriefingService.shared.selectedPersona.icon)
                                                    .font(.system(size: 14))
                                                Image(systemName: "chevron.down")
                                                    .font(.system(size: 8, weight: .bold))
                                            }
                                            .foregroundColor(.blue)
                                            .padding(.horizontal, 10)
                                            .padding(.vertical, 8)
                                            .background(Capsule().fill(Color.blue.opacity(0.1)))
                                        }
                                        
                                        // Audio Briefing Button
                                        Button {
                                            AudioBriefingService.shared.speak(article: article, summary: summaryText ?? "")
                                        } label: {
                                            Image(systemName: AudioBriefingService.shared.isPlaying ? "speaker.wave.3.fill" : "speaker.wave.2")
                                                .font(.system(size: 16, weight: .bold))
                                                .foregroundColor(AudioBriefingService.shared.isPlaying ? .blue : .blue.opacity(0.8))
                                                .padding(10)
                                                .background(Circle().fill(Color.blue.opacity(0.1)))
                                                .symbolEffect(.bounce, value: AudioBriefingService.shared.isPlaying)
                                        }
                                        
                                        // Share Button
                                        Button {
                                            ArticleImageSharer.share(article, aiSummary: summaryText)
                                        } label: {
                                            Image(systemName: "square.and.arrow.up")
                                                .font(.system(size: 16, weight: .bold))
                                                .foregroundColor(.blue.opacity(0.8))
                                                .padding(10)
                                                .background(Circle().fill(Color.blue.opacity(0.1)))
                                        }
                                    }
                                    .transition(.scale.combined(with: .opacity))
                                }
                            }
                            
                            Text(article.title)
                                .font(.system(size: 24, weight: .bold, design: .serif))
                                .foregroundColor(.primary)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        .padding(.top, 20)
                        
                        // Divider
                        Rectangle()
                            .fill(LinearGradient(colors: [.blue.opacity(0.2), .clear], startPoint: .leading, endPoint: .trailing))
                            .frame(height: 1)
                        
                        // Main Content Area
                        Group {
                            if let error = errorMessage {
                                errorState(msg: error)
                            } else if isLoading {
                                loadingState
                            } else {
                                VStack(spacing: 32) {
                                    if let summary = summaryText {
                                        let points = summary.components(separatedBy: "\n").map { $0.replacingOccurrences(of: "• ", with: "") }
                                        successState(points: points)
                                    }
                                    
                                    if let analysis = perspectiveAnalysis {
                                        PerspectivePulseView(analysis: analysis)
                                            .transition(.move(edge: .bottom).combined(with: .opacity))
                                    }
                                }
                            }
                        }
                        
                        // Layout Spacer: Ensures list content clears the floating button
                        Spacer(minLength: 120)
                    }
                    .padding(.horizontal, 24)
                }
            }
        }
        .task {
            await fetchSummary()
        }
    }
    
    // MARK: - Subviews
    
    private func successState(points: [String]) -> some View {
        VStack(alignment: .leading, spacing: 28) {
            ForEach(Array(points.enumerated()), id: \.offset) { index, bullet in
                HStack(alignment: .top, spacing: 16) {
                    Circle()
                        .fill(Color.blue)
                        .frame(width: 6, height: 6)
                        .padding(.top, 8)
                    
                    Text(bullet)
                        .font(.system(size: 17, weight: .medium, design: .rounded))
                        .lineSpacing(6)
                        .foregroundColor(.primary.opacity(0.9))
                }
                .opacity(animateContent ? 1 : 0)
                .offset(y: animateContent ? 0 : 20)
                .animation(.spring(response: 0.6, dampingFraction: 0.7).delay(Double(index) * 0.1), value: animateContent)
            }
        }
        .onAppear {
            animateContent = true
        }
    }
    
    private var loadingState: some View {
        VStack(alignment: .leading, spacing: 24) {
            ForEach(0..<3, id: \.self) { _ in
                VStack(alignment: .leading, spacing: 8) {
                    RoundedRectangle(cornerRadius: 4).fill(Color.white.opacity(0.1)).frame(height: 16)
                    RoundedRectangle(cornerRadius: 4).fill(Color.white.opacity(0.1)).frame(width: 250, height: 16)
                }
            }
        }
        .shimmer()
    }
    
    private func errorState(msg: String) -> some View {
        VStack(spacing: 16) {
            Image(systemName: "bolt.slash.fill")
                .font(.system(size: 44))
                .foregroundColor(.secondary)
            Text(msg)
                .font(.callout)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
    }
    
    private func fetchSummary() async {
        do {
            isLoading = true
            errorMessage = nil
            
            // Single consolidated request to avoid 429 rate limits
            let analysis = try await AISummarizerService.shared.generateFullInsight(article: article)
            
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                self.summaryText = analysis.summaryPoints.joined(separator: "\n")
                self.perspectiveAnalysis = analysis
                self.isLoading = false
            }
        } catch {
            withAnimation {
                errorMessage = error.localizedDescription
                isLoading = false
            }
        }
    }
}
