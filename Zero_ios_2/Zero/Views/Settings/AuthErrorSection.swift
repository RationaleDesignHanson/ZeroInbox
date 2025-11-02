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
                .foregroundColor(.white.opacity(0.8))

            if let suggestion = error.suggestion {
                Text(suggestion)
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.6))
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
                        .cornerRadius(8)
                }

                Button(action: onDismiss) {
                    Text("Dismiss")
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.7))
                        .padding(.vertical, 8)
                        .padding(.horizontal, 16)
                        .background(Color.white.opacity(0.1))
                        .cornerRadius(8)
                }
            }
            .padding(.top, 8)
        }
        .padding()
        .background(Color.red.opacity(0.2))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.red.opacity(0.5), lineWidth: 1)
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
