internal import SwiftUI
import Charts

struct PerspectivePulseView: View {
    let analysis: Pulse360Analysis
    @State private var animate = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            // Title & Tone Badge
            HStack {
                Text("Pulse 360 Analysis")
                    .font(.headline.bold())
                    .foregroundColor(.white)
                Spacer()
                Text(analysis.analyticalTone.uppercased())
                    .font(.system(size: 10, weight: .black))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.blue.opacity(0.1))
                    .cornerRadius(4)
                    .foregroundColor(.blue)
            }
            
            // 2D Chart: Sentiment vs Bias
            VStack(alignment: .leading, spacing: 8) {
                Text("Perspective Mapping")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.6))
                
                Chart {
                    // Current Article Point
                    PointMark(
                        x: .value("Bias", analysis.biasScore),
                        y: .value("Sentiment", analysis.sentimentScore)
                    )
                    .foregroundStyle(analysis.sentimentColor.gradient)
                    .symbolSize(300)
                    
                    // Reference Axis - Center
                    RuleMark(x: .value("Middle", 0))
                        .lineStyle(StrokeStyle(lineWidth: 0.5, dash: [2]))
                        .foregroundStyle(.secondary.opacity(0.3))
                    RuleMark(y: .value("Middle", 0))
                        .lineStyle(StrokeStyle(lineWidth: 0.5, dash: [2]))
                        .foregroundStyle(.secondary.opacity(0.3))
                }
                .chartXScale(domain: -1...1)
                .chartYScale(domain: -1...1)
                .chartXAxis {
                    AxisMarks(values: [-1, 0, 1]) { value in
                        AxisGridLine()
                            .foregroundStyle(.secondary.opacity(0.2))
                        AxisValueLabel {
                            if let v = value.as(Double.self) {
                                if v < 0 { Text("Critical").font(.caption2) }
                                else if v > 0 { Text("Corporate").font(.caption2) }
                                else { Text("Neutral").font(.caption2) }
                            }
                        }
                    }
                }
                .chartYAxis {
                    AxisMarks(values: [-1, 0, 1]) { value in
                        AxisGridLine()
                            .foregroundStyle(.secondary.opacity(0.2))
                        AxisValueLabel {
                            if let v = value.as(Double.self) {
                                if v < 0 { Text("Neg").font(.caption2) }
                                else if v > 0 { Text("Pos").font(.caption2) }
                                else { Text("") }
                            }
                        }
                    }
                }
                .frame(height: 180)
                .padding()
                .background(Color.black.opacity(0.2))
                .cornerRadius(12)
            }
            
            // The Other Side Section
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: "hand.raised.fill")
                        .foregroundColor(.orange)
                    Text("The Other Side")
                        .font(.subheadline.bold())
                }
                
                Text(analysis.theOtherSide)
                    .font(.system(size: 15, weight: .medium, design: .serif))
                    .italic()
                    .foregroundColor(.white.opacity(0.8))
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.orange.opacity(0.05))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.orange.opacity(0.1), lineWidth: 1)
                    )
            }
            
            // Global Impact
            Label(analysis.globalImpact, systemImage: "globe.americas.fill")
                .font(.caption)
                .foregroundColor(.white.opacity(0.6))
        }
        .padding()
        .background(Color.white.opacity(0.03))
        .cornerRadius(20)
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(Color.white.opacity(0.05), lineWidth: 1)
        )
        .environment(\.colorScheme, .dark) // Forces the deep-dark minimalist aesthetic
    }
}
