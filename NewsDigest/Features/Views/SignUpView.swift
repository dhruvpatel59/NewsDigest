internal import SwiftUI

struct SignUpView: View {
    @EnvironmentObject var authStore: AuthStore
    @Environment(\.dismiss) var dismiss
    
    @State private var name = ""
    @State private var email = ""
    @State private var password = ""
    @State private var showError = false
    
    @FocusState private var focusedField: Field?
    let impactMed = UIImpactFeedbackGenerator(style: .medium)
    
    enum Field { case name, email, password }
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea().premiumBackground()
            
            ScrollView {
                VStack(spacing: 0) {
                    headerView
                    authForm
                    signUpButton
                }
                .padding(.top, 60)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .colorScheme(.dark)
    }
}

// MARK: - Subcomponents
extension SignUpView {
    
    private var headerView: some View {
        VStack(spacing: 12) {
            Image(systemName: "plus.circle.fill")
                .font(.system(size: 56))
                .foregroundColor(.accentColor)
                .shadow(color: .accentColor.opacity(0.4), radius: 15)
            
            Text("Create Account")
                .font(.system(size: 32, weight: .bold, design: .rounded))
            
            Text("Join our global community of readers")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .padding(.bottom, 60)
    }
    
    private var authForm: some View {
        VStack(spacing: 0) {
            // Name field
            HStack(spacing: 16) {
                Image(systemName: "person.fill")
                    .foregroundColor(.accentColor)
                    .frame(width: 24)
                TextField("Full Name", text: $name)
                    .textContentType(.name)
                    .focused($focusedField, equals: .name)
            }
            .padding()
            .background(Color.white.opacity(0.02))
            
            Divider().padding(.leading, 56).opacity(0.2)
            
            // Email field
            HStack(spacing: 16) {
                Image(systemName: "envelope.fill")
                    .foregroundColor(.accentColor)
                    .frame(width: 24)
                TextField("Email", text: $email)
                    .keyboardType(.emailAddress)
                    .autocapitalization(.none)
                    .textContentType(.emailAddress)
                    .focused($focusedField, equals: .email)
            }
            .padding()
            .background(Color.white.opacity(0.02))
            
            Divider().padding(.leading, 56).opacity(0.2)
            
            // Password field
            HStack(spacing: 16) {
                Image(systemName: "lock.fill")
                    .foregroundColor(.accentColor)
                    .frame(width: 24)
                SecureField("Password", text: $password)
                    .textContentType(.newPassword)
                    .focused($focusedField, equals: .password)
            }
            .padding()
            .background(Color.white.opacity(0.02))
        }
        .glassPanel()
        .padding(.horizontal, 24)
        .padding(.bottom, showError ? 12 : 32)
        .overlay(alignment: .bottom) {
            if showError {
                Text("Email already registered.")
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(.red)
                    .padding(.bottom, 12)
            }
        }
    }
    
    private var signUpButton: some View {
        VStack(spacing: 16) {
            if authStore.isRegistrationOpen {
                Button {
                    impactMed.impactOccurred()
                    focusedField = nil
                    let success = authStore.register(name: name, email: email, passwordRaw: password)
                    if !success {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                            showError = true
                        }
                    }
                } label: {
                    Text("Create Account")
                        .font(.body)
                        .fontWeight(.semibold)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(Color.accentColor)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                }
            } else {
                // Quota Full State
                VStack(spacing: 8) {
                    Text("Pilot Quota Full")
                        .font(.headline)
                        .foregroundColor(.orange)
                    Text("This research app is currently limited to 3 authorized users. Please contact the administrator for an invite.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding()
                .background(RoundedRectangle(cornerRadius: 12).stroke(Color.orange.opacity(0.3)))
            }
        }
        .padding(.horizontal, 24)
    }
}

#Preview {
    NavigationStack {
        SignUpView()
            .environmentObject(AuthStore())
    }
}
