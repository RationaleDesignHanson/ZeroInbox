import SwiftUI

struct AuthErrorSection: View {
    let error: AppError
    let onDismiss: () -> Void
    let onReconnect: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundColor(.red)
                Text("Authentication Error")
                    .font(.headline)
                    .foregroundColor(.white)
            }

            Text(error.message)
                .font(.subheadline)
                .foregroundColor(.white.opacity(DesignTokens.Opacity.textTertiary))

            if let suggestion = error.suggestion {
                Text(suggestion)
                    .font(.caption)
                    .foregroundColor(.white.opacity(DesignTokens.Opacity.textDisabled))
                    .padding(.top, 4)
            }

            HStack(spacing: 12) {
                Button(action: onReconnect) {
                    Text("Reconnect")
                        .font(.subheadline)
                        .foregroundColor(.white)
                        .padding(.vertical, 8)
                        .padding(.horizontal, 16)
                        .background(Color.purple)
                        .cornerRadius(DesignTokens.Radius.chip)
                }

                Button(action: onDismiss) {
                    Text("Dismiss")
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(DesignTokens.Opacity.textSubtle))
                        .padding(.vertical, 8)
                        .padding(.horizontal, 16)
                        .background(Color.white.opacity(DesignTokens.Opacity.glassLight))
                        .cornerRadius(DesignTokens.Radius.chip)
                }
            }
            .padding(.top, 8)
        }
        .padding()
        .background(Color.red.opacity(DesignTokens.Opacity.overlayLight))
        .cornerRadius(DesignTokens.Radius.button)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.red.opacity(DesignTokens.Opacity.overlayStrong), lineWidth: 1)
        )
    }
}

#Preview {
    ZStack {
        LinearGradient(
            colors: [
                Color(red: 0.1, green: 0.1, blue: 0.3),
                Color(red: 0.2, green: 0.1, blue: 0.4)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .ignoresSafeArea()

        AuthErrorSection(
            error: AppError(
                message: "Unable to connect to your email account",
                suggestion: "Please check your internet connection and try again. If the problem persists, you may need to re-authenticate your account."
            ),
            onDismiss: {},
            onReconnect: {}
        )
        .padding()
    }
}
