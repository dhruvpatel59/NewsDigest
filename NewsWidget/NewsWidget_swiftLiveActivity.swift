import ActivityKit
import WidgetKit
import SwiftUI

struct BriefingActivityAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        var summaryPoints: [String]
        var progress: Double // 0.0 to 1.0
    }

    var articleTitle: String
    var newsSource: String
}

struct NewsWidget_swiftLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: BriefingActivityAttributes.self) { context in
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Image(systemName: "sparkles")
                        .foregroundColor(.cyan)
                    Text(context.attributes.newsSource.uppercased())
                        .font(.caption2)
                        .fontWeight(.heavy)
                        .foregroundColor(.secondary)
                    Spacer()
                    Image(systemName: "waveform")
                        .symbolEffect(.variableColor.iterative, options: .repeating)
                        .foregroundColor(.cyan)
                }
                
                Text(context.attributes.articleTitle)
                    .font(.headline)
                    .lineLimit(1)
                
                VStack(alignment: .leading, spacing: 4) {
                    ForEach(context.state.summaryPoints.prefix(3), id: \.self) { point in
                        HStack(alignment: .top, spacing: 6) {
                            Text("•")
                                .foregroundColor(.cyan)
                            Text(point)
                                .font(.caption)
                                .foregroundColor(.primary.opacity(0.8))
                                .lineLimit(1)
                        }
                    }
                }
                
                ProgressView(value: context.state.progress)
                    .tint(.cyan)
                    .scaleEffect(x: 1, y: 0.5, anchor: .center)
            }
            .padding()
            .activityBackgroundTint(Color.black.opacity(0.8))
            .activitySystemActionForegroundColor(Color.white)

        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    HStack {
                        Image(systemName: "sparkles")
                            .foregroundColor(.cyan)
                        Text("PULSE AI")
                            .font(.caption2)
                            .fontWeight(.bold)
                    }
                }
                DynamicIslandExpandedRegion(.trailing) {
                    Label("Direct", systemImage: "waveform")
                        .font(.caption2)
                        .foregroundColor(.cyan)
                        .symbolEffect(.variableColor.iterative)
                }
                DynamicIslandExpandedRegion(.center) {
                    Text(context.attributes.articleTitle)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .lineLimit(1)
                }
                DynamicIslandExpandedRegion(.bottom) {
                    VStack(alignment: .leading, spacing: 4) {
                        ForEach(context.state.summaryPoints.prefix(3), id: \.self) { point in
                            Text("• \(point)")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                                .lineLimit(1)
                        }
                    }
                    .padding(.top, 4)
                }
            } compactLeading: {
                Image(systemName: "sparkles")
                    .foregroundColor(.cyan)
            } compactTrailing: {
                Image(systemName: "waveform")
                    .foregroundColor(.cyan)
                    .symbolEffect(.variableColor.iterative)
            } minimal: {
                Image(systemName: "waveform")
                    .foregroundColor(.cyan)
            }
            .widgetURL(URL(string: "pulsenews://open"))
            .keylineTint(Color.cyan)
        }
    }
}

