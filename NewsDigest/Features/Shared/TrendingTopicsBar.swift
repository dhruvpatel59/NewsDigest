internal import SwiftUI


struct TrendingTopicsBar: View {
    @Binding var selectedTopic: String?
    let onSelect: (String?) -> Void
    
    private let impactLight = UIImpactFeedbackGenerator(style: .light)
    
    private let topics = [
        "AI", "Elections", "Climate", "Space",
        "Markets", "Crypto", "Health", "Movies"
    ]
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                chipButton(label: "All", isSelected: selectedTopic == nil) {
                    selectedTopic = nil
                    onSelect(nil)
                }
                
                ForEach(topics, id: \.self) { topic in
                    chipButton(label: topic, isSelected: selectedTopic == topic) {
                        selectedTopic = topic
                        onSelect(topic)
                    }
                }
            }
            .padding(.vertical, 4)
        }
    }
    
    private func chipButton(label: String, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button {
            impactLight.impactOccurred()
            action()
        } label: {
            Text(label)
                .font(.subheadline)
                .fontWeight(isSelected ? .bold : .medium)
                .foregroundColor(isSelected ? .white : .primary)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(isSelected ? Color.accentColor : Color(.systemGray5))
                .cornerRadius(20)
        }
        .buttonStyle(.plain)
    }
}

