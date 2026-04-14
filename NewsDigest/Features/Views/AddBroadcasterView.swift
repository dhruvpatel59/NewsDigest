internal import SwiftUI

struct AddBroadcasterView: View {
    @ObservedObject var store: BroadcasterStore
    @Environment(\.dismiss) var dismiss
    
    @State private var broadcasterName = ""
    @State private var rssURL = ""
    @State private var isValidating = false
    @State private var validationError: String? = nil
    
    let impactMed = UIImpactFeedbackGenerator(style: .medium)
    let impactHeavy = UIImpactFeedbackGenerator(style: .heavy)
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()
                
                VStack(spacing: 24) {
                    headerView
                    
                    VStack(alignment: .leading, spacing: 12) {
                        CustomTextField(title: "Broadcaster Name", text: $broadcasterName, icon: "pencil")
                        CustomTextField(title: "RSS Feed URL", text: $rssURL, icon: "link")
                            .autocapitalization(.none)
                            .keyboardType(.URL)
                    }
                    
                    if let error = validationError {
                        Text(error)
                            .font(.caption)
                            .foregroundColor(.red)
                            .transition(.opacity)
                    }
                    
                    Spacer()
                    
                    saveButton
                }
                .padding(24)
            }
            .navigationTitle("New Source")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }
}

extension AddBroadcasterView {
    
    private var headerView: some View {
        VStack(spacing: 12) {
            Image(systemName: "rss.circle.fill")
                .font(.system(size: 48))
                .foregroundColor(.accentColor)
            
            Text("Follow a New Source")
                .font(.title3)
                .fontWeight(.bold)
            
            Text("Paste any valid RSS or Atom feed URL to add it to your broadcasters list.")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
    }
    
    private var saveButton: some View {
        Button {
            validateAndSave()
        } label: {
            HStack {
                if isValidating {
                    ProgressView()
                        .tint(.white)
                        .padding(.trailing, 8)
                }
                Text(isValidating ? "Analyzing Feed..." : "Add Broadcaster")
                    .fontWeight(.bold)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(broadcasterName.isEmpty || rssURL.isEmpty ? Color.gray.opacity(0.3) : Color.accentColor)
            .foregroundColor(.white)
            .cornerRadius(12)
        }
        .disabled(broadcasterName.isEmpty || rssURL.isEmpty || isValidating)
    }
    
    private func validateAndSave() {
        impactMed.impactOccurred()
        isValidating = true
        validationError = nil
        
        Task {
            let success = await store.validateAndAdd(url: rssURL, name: broadcasterName)
            
            if success {
                impactHeavy.impactOccurred()
                dismiss()
            } else {
                validationError = "Invalid RSS Feed. Please check the URL and try again."
                isValidating = false
            }
        }
    }
}

struct CustomTextField: View {
    let title: String
    @Binding var text: String
    let icon: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(.secondary)
            
            HStack {
                Image(systemName: icon)
                    .foregroundColor(.accentColor)
                TextField("Enter \(title.lowercased())", text: $text)
            }
            .padding()
            .background(Color(uiColor: .secondarySystemGroupedBackground))
            .cornerRadius(12)
        }
    }
}

#Preview {
    AddBroadcasterView(store: BroadcasterStore())
}

