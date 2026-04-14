import SwiftUI

struct AIInsightsListView: View {
    @EnvironmentObject var insightStore: AIInsightStore
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea().premiumBackground()
                
                if insightStore.entries.isEmpty {
                    emptyState
                } else {
                    ScrollView {
                        LazyVStack(spacing: 16) {
                            ForEach(insightStore.entries) { entry in
                                InsightLibraryRow(entry: entry)
                            }
                        }
                        .padding()
                    }
                }
            }
            .navigationTitle("AI Insights Library")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Close") { dismiss() }
                }
            }
        }
    }
    
    private var emptyState: some View {
        VStack(spacing: 20) {
            Image(systemName: "sparkles.rectangle.stack")
                .font(.system(size: 60))
                .foregroundColor(.blue.opacity(0.3))
            
            Text("Your Library is Empty")
                .font(.headline)
            
            Text("Summaries you generate will appear here for quick access and sharing.")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
        }
    }
}

struct InsightLibraryRow: View {
    let entry: AIInsightEntry
    @EnvironmentObject var insightStore: AIInsightStore
    @ObservedObject private var audioService = AudioBriefingService.shared
    @State private var showFullContent = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header: Source + Date
            HStack {
                Text(entry.article.newsSite.uppercased())
                    .font(.system(size: 10, weight: .black))
                    .foregroundColor(.blue)
                
                Spacer()
                
                Text(entry.generatedAt.formatted(date: .abbreviated, time: .shortened))
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            
            Text(entry.article.title)
                .font(.subheadline.bold())
                .foregroundColor(.white)
                .lineLimit(2)
            
            if showFullContent {
                Text(entry.summary)
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.8))
                    .padding(.vertical, 8)
                    .transition(.opacity)
            }
            
            // Actions
            HStack(spacing: 16) {
                Button {
                    withAnimation { showFullContent.toggle() }
                } label: {
                    Label(showFullContent ? "Less" : "Read", systemImage: showFullContent ? "chevron.up" : "doc.text.magnifyingglass")
                        .font(.caption2.bold())
                }
                
                Spacer()
                
                // PERSONA SELECTOR
                Menu {
                    ForEach(AudioPersona.available) { persona in
                        Button {
                            audioService.selectedPersona = persona
                        } label: {
                            HStack {
                                Text(persona.name)
                                Spacer()
                                Image(systemName: persona.icon)
                            }
                        }
                    }
                } label: {
                    Image(systemName: audioService.selectedPersona.icon)
                        .font(.caption)
                        .padding(8)
                        .background(Color.blue.opacity(0.1))
                        .clipShape(Circle())
                        .foregroundColor(.blue)
                }
                
                // AUDIO BUTTON
                Button {
                    audioService.speak(article: entry.article, summary: entry.summary)
                } label: {
                    Image(systemName: (audioService.isPlaying && audioService.currentlyReadingArticleID == entry.article.id) ? "speaker.wave.3.fill" : "speaker.wave.2")
                        .font(.caption)
                        .padding(8)
                        .background(Color.blue.opacity(0.1))
                        .clipShape(Circle())
                        .symbolEffect(.bounce, value: audioService.isPlaying)
                }
                
                Button {
                    ArticleImageSharer.share(entry.article, aiSummary: entry.summary)
                } label: {
                    Image(systemName: "square.and.arrow.up")
                        .font(.caption)
                        .padding(8)
                        .background(Color.blue.opacity(0.1))
                        .clipShape(Circle())
                }
                
                Button(role: .destructive) {
                    withAnimation {
                        // If we are currently reading this specific insight, stop the audio
                        if audioService.currentlyReadingArticleID == entry.article.id {
                            audioService.stop()
                        }
                        insightStore.deleteInsight(id: entry.id)
                    }
                } label: {
                    Image(systemName: "trash")
                        .font(.caption)
                        .foregroundColor(.red.opacity(0.7))
                        .padding(8)
                        .background(Color.red.opacity(0.1))
                        .clipShape(Circle())
                }
            }
        }
        .padding()
        .background(Color.white.opacity(0.03))
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.white.opacity(0.05), lineWidth: 1)
        )
    }
}
