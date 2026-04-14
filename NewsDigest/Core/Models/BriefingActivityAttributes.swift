import ActivityKit
import Foundation

struct BriefingActivityAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        var summaryPoints: [String]
        var progress: Double // 0.0 to 1.0
    }

    var articleTitle: String
    var newsSource: String
}

