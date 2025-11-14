import SwiftUI

struct NewsletterSummaryModal: View {
    let card: EmailCard
    let context: [String: Any]
    @Binding var isPresented: Bool

    @State private var summary: String? = nil
    @State private var keyLinks: [EmailCard.NewsletterLink] = []
    @State private var isLoading = true
    @State private var errorMessage: String?
    @State private var showError = false

    var newsletterTitle: String {
        card.title
    }

    var newsletterSender: String {
        card.company?.name ?? "Newsletter"
    }

    var body: some View {
        VStack(spacing: 0) {
            // Custom header
            HStack {
                Spacer()
                Button {
                    isPresented = false
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(DesignTokens.Colors.textSubtle)
                        .font(.title2)
                }
            }
            .padding()

            ScrollView {
                VStack(alignment: .leading, spacing: DesignTokens.Spacing.card) {
                    // Header
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Image(systemName: "newspaper.circle.fill")
                                .font(.largeTitle)
                                .foregroundColor(.purple)

                            VStack(alignment: .leading, spacing: 4) {
                                Text("Newsletter Summary")
                                    .font(.title2.bold())
                                    .foregroundColor(DesignTokens.Colors.textPrimary)

                                Text(newsletterSender)
                                    .font(.subheadline)
                                    .foregroundColor(DesignTokens.Colors.textSubtle)
                            }
                        }
                    }

                    Divider()
                        .background(Color.white.opacity(DesignTokens.Opacity.overlayMedium))

                    // Loading or Summary Content
                    if isLoading {
                        VStack(spacing: 16) {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .purple))
                                .scaleEffect(1.2)

                            Text("Generating AI summary...")
                                .font(.subheadline)
                                .foregroundColor(DesignTokens.Colors.textSubtle)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 40)
                    } else if let error = errorMessage {
                        // Error state
                        VStack(spacing: 12) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .font(.largeTitle)
                                .foregroundColor(.orange)

                            Text("Summary Unavailable")
                                .font(.headline)
                                .foregroundColor(DesignTokens.Colors.textPrimary)

                            Text(error)
                                .font(.subheadline)
                                .foregroundColor(DesignTokens.Colors.textSecondary)
                                .multilineTextAlignment(.center)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 40)
                    } else {
                        // Summary content
                        VStack(alignment: .leading, spacing: 20) {
                            // AI-generated summary
                            if let summaryText = summary {
                                VStack(alignment: .leading, spacing: 12) {
                                    HStack {
                                        Image(systemName: "sparkles")
                                            .foregroundColor(.purple)
                                        Text("Key Highlights")
                                            .font(.headline)
                                            .foregroundColor(DesignTokens.Colors.textPrimary)
                                    }

                                    Text(summaryText)
                                        .font(.body)
                                        .foregroundColor(DesignTokens.Colors.textSecondary)
                                        .lineSpacing(6)
                                        .padding(DesignTokens.Spacing.section)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                        .background(
                                            LinearGradient(
                                                gradient: Gradient(colors: [
                                                    Color.purple.opacity(DesignTokens.Opacity.glassLight),
                                                    Color.blue.opacity(DesignTokens.Opacity.glassUltraLight)
                                                ]),
                                                startPoint: .topLeading,
                                                endPoint: .bottomTrailing
                                            )
                                        )
                                        .cornerRadius(DesignTokens.Radius.button)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: DesignTokens.Radius.button)
                                                .strokeBorder(Color.purple.opacity(DesignTokens.Opacity.overlayMedium), lineWidth: 1)
                                        )
                                }
                            }

                            // Key links section
                            if !keyLinks.isEmpty {
                                Divider()
                                    .background(Color.white.opacity(DesignTokens.Opacity.overlayMedium))

                                VStack(alignment: .leading, spacing: 12) {
                                    HStack {
                                        Image(systemName: "link.circle.fill")
                                            .foregroundColor(.blue)
                                        Text("Featured Links")
                                            .font(.headline)
                                            .foregroundColor(DesignTokens.Colors.textPrimary)
                                    }

                                    ForEach(keyLinks) { link in
                                        LinkRow(link: link)
                                    }
                                }
                            }
                        }
                    }

                    if !isLoading {
                        Divider()
                            .background(Color.white.opacity(DesignTokens.Opacity.overlayMedium))

                        // Action buttons
                        VStack(spacing: 12) {
                            Button {
                                readFullEmail()
                            } label: {
                                HStack {
                                    Image(systemName: "envelope.open.text")
                                    Text("Read Full Email")
                                        .font(.headline)
                                }
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.blue)
                                .foregroundColor(DesignTokens.Colors.textPrimary)
                                .cornerRadius(DesignTokens.Radius.button)
                            }

                            Button {
                                saveForLater()
                            } label: {
                                HStack {
                                    Image(systemName: "bookmark")
                                    Text("Save for Later")
                                        .font(.headline)
                                }
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.purple.opacity(DesignTokens.Opacity.overlayMedium))
                                .foregroundColor(DesignTokens.Colors.textPrimary)
                                .cornerRadius(DesignTokens.Radius.button)
                            }
                        }
                        .padding(.top, 20)
                    }

                    if showError, let error = errorMessage {
                        HStack {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundColor(.red)
                            Text(error)
                                .foregroundColor(.red)
                                .font(.caption)
                        }
                        .padding()
                        .background(Color.red.opacity(DesignTokens.Opacity.glassLight))
                        .cornerRadius(DesignTokens.Radius.chip)
                    }
                }
                .padding(DesignTokens.Spacing.card)
            }
        }
        .onAppear {
            fetchNewsletterSummary()
        }
    }

    func fetchNewsletterSummary() {
        isLoading = true

        Logger.info("Fetching newsletter summary for: \(card.title)", category: .action)

        // Call SummarizationService to generate summary
        SummarizationService.shared.summarizeNewsletter(card: card) { result in
            DispatchQueue.main.async {
                self.isLoading = false

                switch result {
                case .success(let newsletterSummary):
                    self.summary = newsletterSummary.summary
                    self.keyLinks = newsletterSummary.links
                    Logger.info("Newsletter summary received: \(newsletterSummary.summary.prefix(100))...", category: .action)

                case .failure(let error):
                    self.errorMessage = error.localizedDescription
                    self.showError = true
                    Logger.error("Newsletter summarization failed: \(error.localizedDescription)", category: .action)

                    // Show fallback: use card summary as backup
                    if !card.summary.isEmpty {
                        self.summary = card.summary
                        Logger.info("Using card summary as fallback", category: .action)
                    }
                }
            }
        }
    }

    func readFullEmail() {
        Logger.info("Opening full newsletter email", category: .action)

        // TODO: Open email in native mail app or in-app web view
        // EmailCard doesn't have extraInfo property yet
        // For now, just dismiss the modal

        // Analytics
        AnalyticsService.shared.log("newsletter_full_email_opened")

        isPresented = false
    }

    func saveForLater() {
        Logger.info("Saving newsletter for later", category: .action)

        let impact = UINotificationFeedbackGenerator()
        impact.notificationOccurred(.success)

        // Analytics
        AnalyticsService.shared.log("newsletter_saved")

        isPresented = false
    }
}

// Link row component
struct LinkRow: View {
    let link: EmailCard.NewsletterLink

    var body: some View {
        Button {
            openLink()
        } label: {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: "link")
                        .font(.caption)
                        .foregroundColor(.blue)

                    Text(link.title)
                        .font(.subheadline.bold())
                        .foregroundColor(DesignTokens.Colors.textPrimary)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)

                    Spacer()

                    Image(systemName: "arrow.up.right")
                        .font(.caption)
                        .foregroundColor(DesignTokens.Colors.textSubtle)
                }

                if let description = link.description {
                    Text(description)
                        .font(.caption)
                        .foregroundColor(DesignTokens.Colors.textTertiary)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                }
            }
            .padding(DesignTokens.Spacing.component)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.white.opacity(DesignTokens.Opacity.glassUltraLight))
            .cornerRadius(DesignTokens.Radius.button)
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .strokeBorder(Color.blue.opacity(DesignTokens.Opacity.overlayLight), lineWidth: 1)
            )
        }
    }

    func openLink() {
        if let url = URL(string: link.url) {
            UIApplication.shared.open(url)

            Logger.info("Newsletter link opened: \(link.title) - \(link.url)", category: .action)

            // Analytics
            AnalyticsService.shared.log("newsletter_link_clicked")
        }
    }
}
