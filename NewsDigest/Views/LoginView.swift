internal import SwiftUI

struct LoginView: View {
    @EnvironmentObject var authStore: AuthStore
    
    @State private var email = ""
    @State private var password = ""
    @State private var showSignUp = false
    @State private var showError = false
    
    @FocusState private var focusedField: Field?
    let impactMed = UIImpactFeedbackGenerator(style: .medium)
    
    enum Field { case email, password }
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea().premiumBackground()
                
                ScrollView {
                    VStack(spacing: 0) {
                        brandHeader
                        authForm
                        loginButton
                        signUpRouter
                    }
                    .padding(.top, 100)
                }
            }
            .colorScheme(.dark)
            .navigationDestination(isPresented: $showSignUp) {
                SignUpView()
            }
        }
    }
}

// MARK: - Subcomponents
extension LoginView {
    
    private var brandHeader: some View {
        VStack(spacing: 16) {
            Image(systemName: "newspaper.fill")
                .font(.system(size: 64))
                .foregroundColor(.accentColor)
                .shadow(color: .accentColor.opacity(0.4), radius: 20)
            
            Text("News Digest")
                .font(.system(size: 40, weight: .bold, design: .rounded))
            
            Text("Sign in to your premium feed")
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(.secondary)
        }
        .padding(.bottom, 60)
    }
    
    private var authForm: some View {
        VStack(spacing: 0) {
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
                    .textContentType(.password)
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
                Text("Invalid credentials. Please try again.")
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(.red)
                    .padding(.bottom, 12)
            }
        }
    }
    
    private var loginButton: some View {
        Button {
            impactMed.impactOccurred()
            focusedField = nil
            let success = authStore.login(email: email, passwordRaw: password)
            if !success {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                    showError = true
                }
            }
        } label: {
            Text("Sign In")
                .font(.body)
                .fontWeight(.semibold)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(Color.accentColor)
                .foregroundColor(.white)
                .cornerRadius(12)
        }
        .padding(.horizontal, 24)
        .padding(.bottom, 16)
    }
    
    private var signUpRouter: some View {
        Button {
            impactMed.impactOccurred()
            showSignUp = true
        } label: {
            HStack(spacing: 4) {
                Text("Don't have an account?")
                    .foregroundColor(.secondary)
                Text("Create one")
                    .fontWeight(.semibold)
                    .foregroundColor(.accentColor)
            }
            .font(.subheadline)
        }
        .padding(.top, 8)
    }
}

#Preview {
    LoginView()
        .environmentObject(AuthStore())
}
