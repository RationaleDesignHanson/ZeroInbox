import SwiftUI

/// Account Verification Modal
/// Handles verify_account, verify_device, verify_social_account actions
struct AccountVerificationModal: View {
    let card: EmailCard
    @Binding var isPresented: Bool
    let verificationType: VerificationType
    let verifyUrl: String?

    @State private var isVerifying = false
    @State private var showSuccess = false
    @State private var extractedCode: String?

    enum VerificationType {
        case account, device, social

        var title: String {
            switch self {
            case .account: return "Verify Account"
            case .device: return "Verify Device"
            case .social: return "Verify Social Account"
            }
        }

        var icon: String {
            switch self {
            case .account: return "checkmark.shield.fill"
            case .device: return "iphone.and.arrow.forward"
            case .social: return "person.crop.circle.badge.checkmark"
            }
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Spacer()
                Button {
                    isPresented = false
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.white.opacity(0.6))
                        .font(.title2)
                }
            }
            .padding(.horizontal)
            .padding(.top, 20)

            ScrollView {
                VStack(spacing: 24) {
                    // Icon
                    ZStack {
                        Circle()
                            .fill(LinearGradient(
                                colors: [.blue.opacity(0.3), .purple.opacity(0.3)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ))
                            .frame(width: 100, height: 100)

                        Image(systemName: verificationType.icon)
                            .font(.system(size: 50))
                            .foregroundColor(.white)
                    }

                    // Title
                    Text(verificationType.title)
                        .font(.title.bold())
                        .foregroundColor(.white)

                    // Sender info
                    if let sender = card.sender {
                        VStack(spacing: 8) {
                            Text("From")
                                .font(.caption)
                                .foregroundColor(.white.opacity(0.6))
                            Text(sender.name)
                                .font(.headline)
                                .foregroundColor(.white)
                            if !sender.email.isEmpty {
                                Text(sender.email)
                                    .font(.caption)
                                    .foregroundColor(.white.opacity(0.8))
                            }
                        }
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.white.opacity(0.1))
                        .cornerRadius(12)
                    }

                    // Verification code if found
                    if let code = extractedCode {
                        VStack(spacing: 12) {
                            Text("Verification Code")
                                .font(.caption)
                                .foregroundColor(.white.opacity(0.6))

                            Text(code)
                                .font(.system(size: 32, weight: .bold, design: .monospaced))
                                .foregroundColor(.white)
                                .padding()
                                .background(Color.white.opacity(0.15))
                                .cornerRadius(12)

                            Button {
                                UIPasteboard.general.string = code
                                HapticManager.impact(style: .medium)
                            } label: {
                                HStack {
                                    Image(systemName: "doc.on.doc")
                                    Text("Copy Code")
                                }
                                .font(.subheadline.bold())
                                .foregroundColor(.white)
                                .padding(.vertical, 12)
                                .padding(.horizontal, 24)
                                .background(Color.white.opacity(0.2))
                                .cornerRadius(10)
                            }
                        }
                    }

                    // Instructions
                    VStack(alignment: .leading, spacing: 12) {
                        ForEach(verificationSteps, id: \.self) { step in
                            HStack(alignment: .top, spacing: 12) {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.green)
                                Text(step)
                                    .font(.subheadline)
                                    .foregroundColor(.white.opacity(0.9))
                                Spacer()
                            }
                        }
                    }
                    .padding()
                    .background(Color.white.opacity(0.05))
                    .cornerRadius(12)

                    // Actions
                    VStack(spacing: 12) {
                        if let url = verifyUrl {
                            Button {
                                if let urlObj = URL(string: url) {
                                    UIApplication.shared.open(urlObj)
                                }
                            } label: {
                                HStack {
                                    Image(systemName: "arrow.right.circle.fill")
                                    Text("Open Verification Link")
                                        .font(.headline)
                                }
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(LinearGradient(
                                    colors: [.blue, .purple],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                ))
                                .cornerRadius(12)
                            }
                        }

                        Button {
                            markAsVerified()
                        } label: {
                            HStack {
                                Image(systemName: showSuccess ? "checkmark.circle.fill" : "checkmark.shield.fill")
                                Text(showSuccess ? "Verified!" : "Mark as Verified")
                                    .font(.headline)
                            }
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(showSuccess ? Color.green : Color.white.opacity(0.2))
                            .cornerRadius(12)
                        }
                        .disabled(showSuccess)
                    }
                }
                .padding()
            }
        }
        .background(
            LinearGradient(
                colors: [Color.blue.opacity(0.3), Color.purple.opacity(0.3)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
        )
        .onAppear {
            extractVerificationCode()
        }
    }

    private var verificationSteps: [String] {
        switch verificationType {
        case .account:
            return [
                "Click the verification link above or copy the code",
                "Complete verification on the website or app",
                "Mark as verified once complete"
            ]
        case .device:
            return [
                "Open the verification link on this device",
                "Authorize the device in your account settings",
                "Mark as verified once complete"
            ]
        case .social:
            return [
                "Click the link to verify your social account",
                "Grant the necessary permissions",
                "Mark as verified once complete"
            ]
        }
    }

    private func extractVerificationCode() {
        // Try to extract verification code from card summary or title
        let text = "\(card.title) \(card.summary)"

        // Look for common patterns: 6-digit codes, codes with hyphens, etc.
        let patterns = [
            "\\b\\d{6}\\b",           // 6-digit code
            "\\b\\d{4}-\\d{4}\\b",    // 1234-5678
            "\\b[A-Z0-9]{6}\\b",      // ABC123
            "\\b[A-Z0-9]{4}-[A-Z0-9]{4}\\b" // AB12-CD34
        ]

        for pattern in patterns {
            if let regex = try? NSRegularExpression(pattern: pattern),
               let match = regex.firstMatch(in: text, range: NSRange(text.startIndex..., in: text)) {
                if let range = Range(match.range, in: text) {
                    extractedCode = String(text[range])
                    break
                }
            }
        }
    }

    private func markAsVerified() {
        isVerifying = true

        HapticManager.notification(type: .success)

        withAnimation {
            showSuccess = true
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            isPresented = false
        }
    }
}
