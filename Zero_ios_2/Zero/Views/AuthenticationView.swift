import SwiftUI
import AuthenticationServices

/// Authentication view for signing in with email providers
struct AuthenticationView: View {
    @State private var isAuthenticating = false
    @State private var errorMessage: String?
    @State private var authenticatedEmail: String?

    var onAuthenticated: (String) -> Void

    var body: some View {
        VStack(spacing: 30) {
            Spacer()

            // Logo/Title
            VStack(spacing: 10) {
                Image(systemName: "envelope.circle.fill")
                    .font(.system(size: 80))
                    .foregroundColor(.blue)

                Text("Zero")
                    .font(.system(size: 40, weight: .bold))

                Text("Email Made Simple")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }

            Spacer()

            // Authentication Buttons
            VStack(spacing: 15) {
                // Gmail Sign In
                Button(action: {
                    Task {
                        await authenticateWithGmail()
                    }
                }) {
                    HStack {
                        Image(systemName: "envelope.fill")
                        Text("Continue with Gmail")
                            .fontWeight(.semibold)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(DesignTokens.Radius.button)
                }
                .disabled(isAuthenticating)

                // Outlook Sign In (Coming Soon)
                Button(action: {
                    // TODO: Implement Outlook authentication
                }) {
                    HStack {
                        Image(systemName: "envelope.badge.fill")
                        Text("Continue with Outlook")
                            .fontWeight(.semibold)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.gray.opacity(DesignTokens.Opacity.overlayMedium))
                    .foregroundColor(.gray)
                    .cornerRadius(DesignTokens.Radius.button)
                }
                .disabled(true)

                // iCloud Manual Setup
                Button(action: {
                    // TODO: Show iCloud manual setup sheet
                }) {
                    HStack {
                        Image(systemName: "cloud.fill")
                        Text("Set Up iCloud Mail")
                            .fontWeight(.semibold)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.gray.opacity(DesignTokens.Opacity.overlayMedium))
                    .foregroundColor(.gray)
                    .cornerRadius(DesignTokens.Radius.button)
                }
                .disabled(true)
            }
            .padding(.horizontal, 30)

            // Error Message
            if let errorMessage = errorMessage {
                Text(errorMessage)
                    .font(.caption)
                    .foregroundColor(.red)
                    .padding()
                    .background(Color.red.opacity(DesignTokens.Opacity.glassLight))
                    .cornerRadius(DesignTokens.Radius.chip)
                    .padding(.horizontal)
            }

            // Loading Indicator
            if isAuthenticating {
                ProgressView()
                    .padding()
            }

            Spacer()

            // Privacy Notice
            Text("Your emails are processed securely and never shared")
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
                .padding(.bottom, 20)
        }
    }

    // MARK: - Authentication

    @MainActor
    private func authenticateWithGmail() async {
        isAuthenticating = true
        errorMessage = nil

        do {
            // Get window for presentation anchor
            guard let window = getKeyWindow() else {
                throw APIError.authenticationFailed
            }

            let email = try await EmailAPIService.shared.authenticateGmail(
                presentationAnchor: window
            )

            authenticatedEmail = email
            onAuthenticated(email)

        } catch {
            errorMessage = error.localizedDescription
            isAuthenticating = false
        }
    }

    private func getKeyWindow() -> UIWindow? {
        return UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap { $0.windows }
            .first { $0.isKeyWindow }
    }
}

// MARK: - Preview

struct AuthenticationView_Previews: PreviewProvider {
    static var previews: some View {
        AuthenticationView { email in
            Logger.info("Authenticated: \(email)", category: .app)
        }
    }
}
