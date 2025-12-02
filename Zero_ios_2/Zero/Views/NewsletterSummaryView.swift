import SwiftUI
import SafariServices

/// Newsletter-specific summary view that displays key links and topics
/// Designed to integrate seamlessly with StructuredSummaryView
struct NewsletterSummaryView: View {
    let keyLinks: [EmailCard.NewsletterLink]
    let keyTopics: [String]?
    let lineLimit: Int?

    var body: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.section) {
            // Key Links Section
            if !keyLinks.isEmpty {
                VStack(alignment: .leading, spacing: 12) {
                    // Section header
                    HStack(spacing: 6) {
                        Image(systemName: "link.circle.fill")
                            .font(.subheadline)
                            .foregroundColor(.blue.opacity(DesignTokens.Opacity.textTertiary))
                        Text("KEY LINKS")
                            .font(.subheadline.bold())
                            .foregroundColor(.white.opacity(DesignTokens.Opacity.textSecondary))
                    }

                    // Links
                    ForEach(keyLinks) { link in
                        NewsletterLinkCard(link: link)
                    }
                }
            }

            // Key Topics Section
            if let topics = keyTopics, !topics.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    // Section header
                    HStack(spacing: 6) {
                        Image(systemName: "tag.fill")
                            .font(.subheadline)
                            .foregroundColor(.purple.opacity(DesignTokens.Opacity.textTertiary))
                        Text("TOPICS")
                            .font(.subheadline.bold())
                            .foregroundColor(.white.opacity(DesignTokens.Opacity.textSecondary))
                    }

                    // Topic chips
                    NewsletterFlowLayout(spacing: 8) {
                        ForEach(topics, id: \.self) { topic in
                            TopicChip(topic: topic)
                        }
                    }
                }
            }
        }
    }
}

// MARK: - Newsletter Link Card

private struct NewsletterLinkCard: View {
    let link: EmailCard.NewsletterLink
    @State private var isPressed = false

    var body: some View {
        Button {
            openLink()
        } label: {
            VStack(alignment: .leading, spacing: 6) {
                // Title
                Text(link.title)
                    .font(.body.bold())
                    .foregroundColor(.white)
                    .lineLimit(nil)
                    .multilineTextAlignment(.leading)

                // Description (if available)
                if let description = link.description, !description.isEmpty {
                    Text(description)
                        .font(.caption)
                        .foregroundColor(.white.opacity(DesignTokens.Opacity.textSubtle))
                        .lineLimit(nil)
                        .multilineTextAlignment(.leading)
                }

                // URL preview
                HStack(spacing: 4) {
                    Image(systemName: "arrow.up.right.square")
                        .font(.caption2)
                        .foregroundColor(.blue.opacity(DesignTokens.Opacity.textDisabled))
                    Text(cleanURL(link.url))
                        .font(.caption2)
                        .foregroundColor(.blue.opacity(DesignTokens.Opacity.textDisabled))
                        .lineLimit(nil)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(DesignTokens.Spacing.component)
            .background(
                RoundedRectangle(cornerRadius: DesignTokens.Radius.chip)
                    .fill(isPressed ? Color.blue.opacity(0.15) : Color.white.opacity(0.08))
            )
            .overlay(
                RoundedRectangle(cornerRadius: DesignTokens.Radius.chip)
                    .strokeBorder(Color.blue.opacity(DesignTokens.Opacity.overlayMedium), lineWidth: 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in isPressed = true }
                .onEnded { _ in isPressed = false }
        )
    }

    private func openLink() {
        guard let url = URL(string: link.url) else {
            Logger.error("Invalid newsletter link URL: \(link.url)", category: .ui)
            return
        }

        // Get the current window scene
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let viewController = windowScene.windows.first?.rootViewController else {
            // Fallback to external Safari
            UIApplication.shared.open(url)
            Logger.warning("Could not find view controller, opening in external Safari", category: .ui)
            return
        }

        // Present SFSafariViewController
        let config = SFSafariViewController.Configuration()
        config.entersReaderIfAvailable = true  // Enable reader mode for articles
        config.barCollapsingEnabled = true

        let safari = SFSafariViewController(url: url, configuration: config)
        safari.dismissButtonStyle = .done
        safari.preferredControlTintColor = .systemPurple

        // Find the topmost presented view controller
        var topController = viewController
        while let presented = topController.presentedViewController {
            topController = presented
        }

        topController.present(safari, animated: true)
        HapticService.shared.lightImpact()
        Logger.info("Newsletter link tapped: \(link.title)", category: .ui)
    }

    /// Extract domain from URL for display
    private func cleanURL(_ urlString: String) -> String {
        guard let url = URL(string: urlString),
              let host = url.host else {
            return urlString
        }

        // Remove www. prefix if present
        let cleanHost = host.hasPrefix("www.") ? String(host.dropFirst(4)) : host
        return cleanHost
    }
}

// MARK: - Topic Chip

private struct TopicChip: View {
    let topic: String

    var body: some View {
        Text(topic)
            .font(.caption.bold())
            .foregroundColor(.white.opacity(DesignTokens.Opacity.textSecondary))
            .padding(.horizontal, DesignTokens.Spacing.component)
            .padding(.vertical, 6)
            .background(
                Capsule()
                    .fill(Color.purple.opacity(DesignTokens.Opacity.overlayLight))
            )
            .overlay(
                Capsule()
                    .strokeBorder(Color.purple.opacity(0.4), lineWidth: 1)
            )
    }
}

// MARK: - Flow Layout for Topic Chips

/// Custom layout that wraps chips to next line when needed
private struct NewsletterFlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = FlowResult(
            in: proposal.replacingUnspecifiedDimensions().width,
            subviews: subviews,
            spacing: spacing
        )
        return result.size
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = FlowResult(
            in: bounds.width,
            subviews: subviews,
            spacing: spacing
        )
        for (index, subview) in subviews.enumerated() {
            subview.place(at: result.positions[index], proposal: .unspecified)
        }
    }

    struct FlowResult {
        var size: CGSize = .zero
        var positions: [CGPoint] = []

        init(in maxWidth: CGFloat, subviews: Subviews, spacing: CGFloat) {
            var currentX: CGFloat = 0
            var currentY: CGFloat = 0
            var lineHeight: CGFloat = 0

            for subview in subviews {
                let size = subview.sizeThatFits(.unspecified)

                if currentX + size.width > maxWidth && currentX > 0 {
                    // Move to next line
                    currentX = 0
                    currentY += lineHeight + spacing
                    lineHeight = 0
                }

                positions.append(CGPoint(x: currentX, y: currentY))
                currentX += size.width + spacing
                lineHeight = max(lineHeight, size.height)
            }

            self.size = CGSize(
                width: maxWidth,
                height: currentY + lineHeight
            )
        }
    }
}

// MARK: - Convenience Initializers

extension NewsletterSummaryView {
    /// Create from EmailCard (only shows if newsletter has keyLinks)
    init?(card: EmailCard, lineLimit: Int? = nil) {
        // Only create view if card has newsletter data
        guard let links = card.keyLinks, !links.isEmpty else {
            return nil
        }

        self.keyLinks = links
        self.keyTopics = card.keyTopics
        self.lineLimit = lineLimit
    }
}

// MARK: - Integration Extension

extension StructuredSummaryView {
    /// Enhanced newsletter-aware view that shows newsletter UI when appropriate
    static func newsletterAware(card: EmailCard, lineLimit: Int? = nil) -> some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.section) {
            // Standard structured summary
            StructuredSummaryView(card: card, lineLimit: lineLimit)

            // Newsletter-specific UI (if applicable)
            if let newsletterView = NewsletterSummaryView(card: card, lineLimit: lineLimit) {
                newsletterView
            }
        }
    }
}

// MARK: - Preview

#Preview("Newsletter with Links") {
    ScrollView {
        VStack(spacing: 20) {
            // Example newsletter
            NewsletterSummaryView(
                keyLinks: [
                    EmailCard.NewsletterLink(
                        id: "1",
                        title: "Next-Gen AI Model Rumors Heat Up",
                        url: "https://techcrunch.com/ai-analysis",
                        description: "Leading AI company hints at next-generation model with improved reasoning capabilities."
                    ),
                    EmailCard.NewsletterLink(
                        id: "2",
                        title: "EU AI Act Takes Effect",
                        url: "https://techcrunch.com/eu-ai-act",
                        description: "New regulations require transparency in AI-generated content and model training data."
                    ),
                    EmailCard.NewsletterLink(
                        id: "3",
                        title: "GitHub Copilot X Upgrade",
                        url: "https://techcrunch.com/copilot-x",
                        description: "Voice-to-code, AI code reviews, and context-aware suggestions."
                    )
                ],
                keyTopics: ["Artificial Intelligence", "AI Models", "EU Regulation", "GitHub Copilot", "Machine Learning"],
                lineLimit: nil
            )
            .padding()
        }
    }
    .background(
        LinearGradient(
            colors: [Color.blue, Color.purple],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    )
}

#Preview("Newsletter with Topics Only") {
    ScrollView {
        VStack(spacing: 20) {
            NewsletterSummaryView(
                keyLinks: [],
                keyTopics: ["Tech", "Startups", "AI", "Funding", "Innovation"],
                lineLimit: nil
            )
            .padding()
        }
    }
    .background(
        LinearGradient(
            colors: [Color.blue, Color.purple],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    )
}
