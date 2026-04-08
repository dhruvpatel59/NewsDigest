import WidgetKit
import SwiftUI

// 1. The Timeline Provider fetches our Spaceflight API in the background!
struct Provider: TimelineProvider {
    func placeholder(in context: Context) -> SimpleEntry {
        SimpleEntry(date: Date(), title: "SpaceX launches new rocket", summary: "A new paradigm in space exploration begins today.")
    }

    func getSnapshot(in context: Context, completion: @escaping (SimpleEntry) -> ()) {
        let entry = SimpleEntry(date: Date(), title: "Loading latest news...", summary: "Fetching from Satellite...")
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<Entry>) -> ()) {
        let url = URL(string: "https://api.spaceflightnewsapi.net/v4/articles/?limit=1")!
        let task = URLSession.shared.dataTask(with: url) { data, _, _ in
            guard let data = data,
                  let response = try? JSONDecoder().decode(SpaceflightResponseWidget.self, from: data),
                  let topArticle = response.results.first else {
                let entry = SimpleEntry(date: Date(), title: "No Signal", summary: "Unable to connect to network.")
                completion(Timeline(entries: [entry], policy: .atEnd))
                return
            }
            
            let entry = SimpleEntry(date: Date(), title: topArticle.title, summary: topArticle.summary)
            // Refresh widget every 30 minutes!
            let nextUpdate = Calendar.current.date(byAdding: .minute, value: 30, to: Date())!
            completion(Timeline(entries: [entry], policy: .after(nextUpdate)))
        }
        task.resume()
    }
}

// 2. We define the properties local to the Widget
struct SimpleEntry: TimelineEntry {
    let date: Date
    let title: String
    let summary: String
}

// 3. We design our sleek Glassmorphism Widget UI
struct NewsWidget_swiftEntryView : View {
    var entry: Provider.Entry

    var body: some View {
        ZStack {
            LinearGradient(
                gradient: Gradient(colors: [Color.blue.opacity(0.8), Color.black]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: "globe.americas.fill")
                        .foregroundColor(.white)
                    Text("Top Story")
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .textCase(.uppercase)
                }
                Spacer()
                Text(entry.title)
                    .font(.headline)
                    .foregroundColor(.white)
                    .lineLimit(2)
                
                Text(entry.summary)
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.8))
                    .lineLimit(2)
            }
            .padding()
        }
    }
}

// 4. Register the Widget with iOS
struct NewsWidget_swift: Widget {
    let kind: String = "NewsWidget_swift"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            NewsWidget_swiftEntryView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("Top Spaceflight News")
        .description("Displays the #1 trending spaceflight article live.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

// Helper Model for Background Decoding
struct SpaceflightResponseWidget: Decodable {
    let results: [ArticleRef]
}
struct ArticleRef: Decodable {
    let title: String
    let summary: String
}

#Preview(as: .systemMedium) {
    NewsWidget_swift()
} timeline: {
    SimpleEntry(date: .now, title: "Preview Article", summary: "This is what the widget looks like.")
}
