import SwiftUI

struct ProvideAccessCodeModal: View {
    let card: EmailCard
    @Binding var isPresented: Bool

    @State private var accessCode = ""
    @State private var codeType = ""

    var body: some View {
        VStack(spacing: 0) {
            ModalHeader(isPresented: $isPresented)

            // Scrollable content
            ScrollView {
                VStack(alignment: .center, spacing: DesignTokens.Spacing.card) {
                    // Header
                    VStack(spacing: 8) {
                        Image(systemName: "key.fill")
                            .font(.system(size: 48))
                            .foregroundColor(.yellow)

                        Text("Access Code")
                            .font(.title.bold())
                            .foregroundColor(DesignTokens.Colors.textPrimary)

                        Text(codeType)
                            .font(.subheadline)
                            .foregroundColor(DesignTokens.Colors.textSubtle)
                    }
                    .frame(maxWidth: .infinity)

                    Divider()
                        .background(Color.white.opacity(DesignTokens.Opacity.overlayMedium))

                    // Large Access Code Display
                    VStack(spacing: 16) {
                        // Code display box
                        Text(formatAccessCode(accessCode))
                            .font(.system(size: 48, weight: .bold, design: .monospaced))
                            .foregroundColor(.white)
                            .tracking(8)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 32)
                            .padding(.horizontal, 24)
                            .background(
                                RoundedRectangle(cornerRadius: DesignTokens.Radius.card)
                                    .fill(Color.blue.opacity(0.15))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: DesignTokens.Radius.card)
                                            .strokeBorder(Color.blue, lineWidth: 2)
                                    )
                            )

                        // Code type label
                        HStack(spacing: 6) {
                            Image(systemName: "info.circle")
                                .font(.caption)
                            Text(codeType)
                                .font(.caption)
                        }
                        .foregroundColor(DesignTokens.Colors.textSubtle)
                    }
                    .padding(.vertical, 8)

                    // Copy Button
                    CopyableButton(text: accessCode, label: "Copy Code", style: .primary)

                    // Context information
                    if !card.summary.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Request Details")
                                .font(.headline)
                                .foregroundColor(DesignTokens.Colors.textPrimary)

                            Text(card.summary)
                                .font(.subheadline)
                                .foregroundColor(DesignTokens.Colors.textSecondary)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding()
                        .background(Color.white.opacity(DesignTokens.Opacity.glassUltraLight))
                        .cornerRadius(DesignTokens.Radius.button)
                    }

                    // Sender info
                    if let sender = card.sender {
                        HStack(spacing: 12) {
                            // TODO: AvatarBadge not in Xcode project - using placeholder
                            Text(sender.initial)
                                .font(.caption.bold())
                                .foregroundColor(.white)
                                .frame(width: 32, height: 32)
                                .background(
                                    LinearGradient(
                                        colors: [.blue, .cyan],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .cornerRadius(DesignTokens.Radius.chip)

                            VStack(alignment: .leading, spacing: 4) {
                                Text("Requested by")
                                    .font(.caption)
                                    .foregroundColor(DesignTokens.Colors.textSubtle)
                                Text(sender.name)
                                    .font(.subheadline.bold())
                                    .foregroundColor(DesignTokens.Colors.textPrimary)
                            }

                            Spacer()
                        }
                        .padding()
                        .background(Color.white.opacity(DesignTokens.Opacity.glassUltraLight))
                        .cornerRadius(DesignTokens.Radius.button)
                    }

                    // Info message
                    HStack(alignment: .top, spacing: 8) {
                        Image(systemName: "info.circle")
                            .foregroundColor(.blue)
                            .font(.caption)
                        Text("This access code can be shared with delivery drivers, guests, or service providers who need temporary access.")
                            .font(.caption)
                            .foregroundColor(DesignTokens.Colors.textSubtle)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .padding()
                    .background(Color.blue.opacity(DesignTokens.Opacity.glassLight))
                    .cornerRadius(DesignTokens.Radius.button)
                }
                .padding(DesignTokens.Spacing.card)
            }
        }
        .onAppear {
            detectAccessCode()
        }
    }

    func detectAccessCode() {
        // Try to extract access code from card context
        if let action = card.suggestedActions?.first(where: { $0.actionId == "provide_access_code" }),
           let context = action.context,
           let code = context["access_code"] ?? context["code"] {
            accessCode = code
        } else {
            // Try to extract from email content
            accessCode = extractCodeFromContent()
        }

        // Detect code type
        codeType = detectCodeType()
    }

    func extractCodeFromContent() -> String {
        let text = card.title + " " + card.summary + " " + (card.body ?? "")

        // Common code patterns
        let patterns = [
            "gate code:? (\\d{4,8})",
            "access code:? (\\d{4,8})",
            "code:? (\\d{4,8})",
            "pin:? (\\d{4,8})",
            "passcode:? (\\d{4,8})",
            "entry code:? (\\d{4,8})",
            "#(\\d{4,8})"
        ]

        for pattern in patterns {
            if let regex = try? NSRegularExpression(pattern: pattern, options: [.caseInsensitive]),
               let match = regex.firstMatch(in: text, range: NSRange(text.startIndex..., in: text)),
               match.numberOfRanges > 1,
               let range = Range(match.range(at: 1), in: text) {
                return String(text[range])
            }
        }

        // Fallback: Look for 4-8 digit numbers
        if let regex = try? NSRegularExpression(pattern: "\\b(\\d{4,8})\\b"),
           let match = regex.firstMatch(in: text, range: NSRange(text.startIndex..., in: text)),
           let range = Range(match.range, in: text) {
            return String(text[range])
        }

        return "N/A"
    }

    func detectCodeType() -> String {
        let text = (card.title + " " + card.summary).lowercased()

        if text.contains("gate") {
            return "Gate Access Code"
        } else if text.contains("building") || text.contains("door") {
            return "Building Entry Code"
        } else if text.contains("wifi") || text.contains("wi-fi") {
            return "WiFi Password"
        } else if text.contains("parking") {
            return "Parking Code"
        } else if text.contains("delivery") {
            return "Delivery Access Code"
        } else if text.contains("guest") {
            return "Guest Access Code"
        } else if text.contains("locker") || text.contains("mailbox") {
            return "Locker/Mailbox Code"
        } else if text.contains("storage") {
            return "Storage Unit Code"
        }

        return "Access Code"
    }

    func formatAccessCode(_ code: String) -> String {
        // Add spacing between digits for readability
        let cleaned = code.filter { $0.isNumber || $0.isLetter }

        if cleaned.count <= 4 {
            return cleaned.map { String($0) }.joined(separator: " ")
        } else if cleaned.count <= 8 {
            // Format as groups of 4: "1234 5678"
            let chunks = cleaned.enumerated().map { index, char -> String in
                if index > 0 && index % 4 == 0 {
                    return " " + String(char)
                }
                return String(char)
            }
            return chunks.joined()
        } else {
            // For longer codes, just add space every 4 characters
            let chunks = cleaned.enumerated().map { index, char -> String in
                if index > 0 && index % 4 == 0 {
                    return " " + String(char)
                }
                return String(char)
            }
            return chunks.joined()
        }
    }

}

// MARK: - Preview

#Preview("Provide Access Code Modal") {
    ProvideAccessCodeModal(
        card: EmailCard(
            id: "preview",
            type: .mail,
            state: .seen,
            priority: .medium,
            hpa: "provide_access_code",
            timeAgo: "2h",
            title: "Delivery Arriving Today",
            summary: "Your Amazon package is arriving today between 2-4 PM. The driver will need the gate access code: 4821",
            body: "Hi there,\n\nYour delivery is on its way! Please provide the gate code so the driver can access your building.\n\nGate Code: 4821\n\nThank you!",
            metaCTA: "View",
            suggestedActions: [
                EmailAction(
                    actionId: "provide_access_code",
                    displayName: "Provide Access Code",
                    actionType: .inApp,
                    isPrimary: true,
                    context: ["access_code": "4821", "code_type": "gate"]
                )
            ],
            sender: SenderInfo(
                name: "Amazon Delivery",
                initial: "A",
                email: "delivery@amazon.com"
            )
        ),
        isPresented: .constant(true)
    )
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(
        LinearGradient(
            colors: [
                Color(red: 0.1, green: 0.1, blue: 0.2),
                Color(red: 0.05, green: 0.05, blue: 0.15)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    )
}
