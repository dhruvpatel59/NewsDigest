internal import SwiftUI


struct ShareableArticleCard: View {
    let article: Article
    var aiSummary: String? = nil
    var analysis: Pulse360Analysis? = nil // Support for the pulse chart
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                HStack(spacing: 6) {
                    Image(systemName: "sparkles")
                        .foregroundColor(.blue)
                    Text("Pulse AI Insight")
                        .font(.system(size: 12, weight: .bold))
                        .kerning(1)
                        .foregroundColor(.blue)
                }
                Spacer()
                Text(article.newsSite.uppercased())
                    .font(.system(size: 10, weight: .black))
                    .foregroundColor(.white.opacity(0.4))
            }
            .padding(.horizontal, 24)
            .padding(.top, 24)
            .padding(.bottom, 16)

            if let urlString = article.image_url, let url = URL(string: urlString) {
                AsyncImage(url: url) { phase in
                    if let image = phase.image {
                        image.resizable().aspectRatio(contentMode: .fill)
                    } else {
                        Color.blue.opacity(0.1)
                    }
                }
                .frame(width: 400, height: 180)
                .clipped()
            }
            
            VStack(alignment: .leading, spacing: 20) {
                Text(article.title)
                    .font(.system(size: 22, weight: .bold, design: .serif))
                    .foregroundColor(.white)
                    .lineLimit(2)
                
                if let summary = aiSummary {
                    VStack(alignment: .leading, spacing: 14) {
                        let lines = summary.components(separatedBy: "\n").prefix(3)
                        ForEach(Array(lines.enumerated()), id: \.offset) { _, line in
                            HStack(alignment: .top, spacing: 12) {
                                Circle().fill(Color.blue).frame(width: 5, height: 5).padding(.top, 7)
                                Text(line.replacingOccurrences(of: "*", with: "").trimmingCharacters(in: .whitespaces))
                                    .font(.system(size: 14, weight: .medium, design: .rounded))
                                    .foregroundColor(.white.opacity(0.9))
                                    .lineLimit(2)
                            }
                        }
                    }
                    .padding(16)
                    .background(Color.white.opacity(0.05))
                    .cornerRadius(12)
                }
                
                if let analysis = analysis {
                    PerspectivePulseView(analysis: analysis)
                        .environment(\.colorScheme, .dark) 
                }
            }
            .padding(24)
            
            HStack {
                Text("Downloaded on Pulse News")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(.white.opacity(0.3))
                Spacer()
                Image(systemName: "applelogo") // Placeholder for app icon
                    .font(.system(size: 12))
                    .foregroundColor(.white.opacity(0.2))
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 24)
        }
        .frame(width: 400)
        .background(Color.black)
        .cornerRadius(32)
    }
}

struct ArticleImageSharer {
    
    @MainActor
    static func share(_ article: Article, aiSummary: String? = nil, analysis: Pulse360Analysis? = nil) {
        print("--- Pulse AI: Preparing Social Insight Card ---") // Debug log
        
        let shareView = ShareableArticleCard(article: article, aiSummary: aiSummary, analysis: analysis)
        let renderer = ImageRenderer(content: shareView)
        renderer.scale = 3.0
        
        guard let image = renderer.uiImage else {
            print("--- Pulse AI Error: Image rendering failed ---")
            return
        }
        
        let scenes = UIApplication.shared.connectedScenes
        let windowScene = scenes.first { $0.activationState == .foregroundActive } as? UIWindowScene
        let window = windowScene?.windows.first { $0.isKeyWindow }
        
        guard let rootVC = window?.rootViewController else {
            print("--- Pulse AI Error: Could not find root View Controller ---")
            return
        }
        
        var topVC = rootVC
        while let presented = topVC.presentedViewController {
            topVC = presented
        }
        
        let activityVC = UIActivityViewController(activityItems: [image], applicationActivities: nil)
        
        if let popover = activityVC.popoverPresentationController {
            popover.sourceView = topVC.view
            popover.sourceRect = CGRect(x: UIScreen.main.bounds.width / 2, y: UIScreen.main.bounds.height / 2, width: 0, height: 0)
            popover.permittedArrowDirections = []
        }
        
        topVC.present(activityVC, animated: true)
    }
}

