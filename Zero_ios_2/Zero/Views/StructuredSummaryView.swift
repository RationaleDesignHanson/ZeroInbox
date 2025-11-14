import SwiftUI

/// Structured summary view that parses and displays email summaries in organized sections
/// with visual coherence to the primary action shown on the card
struct StructuredSummaryView: View {
    let summary: String
    let primaryAction: String?  // e.g., "Sign & Send" from card.hpa
    let lineLimit: Int?
    let cardType: CardType  // Card type for conditional styling

    init(summary: String, primaryAction: String? = nil, lineLimit: Int? = nil, cardType: CardType = .mail) {
        self.summary = summary
        self.primaryAction = primaryAction
        self.lineLimit = lineLimit
        self.cardType = cardType
    }

    private var sections: [SummarySection] {
        SummaryParser.parse(summary, primaryAction: primaryAction)
    }

    // Conditional text colors based on card type
    private var textColorPrimary: Color {
        cardType == .ads ? DesignTokens.Colors.adsTextPrimary : Color.white.opacity(DesignTokens.Opacity.textSecondary)
    }

    private var textColorPlaceholder: Color {
        cardType == .ads ? DesignTokens.Colors.adsTextSubtle : Color.white.opacity(DesignTokens.Opacity.overlayStrong)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // If summary is empty, show placeholder
            if summary.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                Text("No summary available")
                    .font(DesignTokens.Typography.cardSummary)
                    .foregroundColor(textColorPlaceholder)
                    .italic()
                    .frame(maxWidth: .infinity, alignment: .leading)
            } else {
                // Action-oriented display with context - show Actions + Context sections
                let actionsSection = sections.first { $0.title == "Actions" }
                let contextSection = sections.first { $0.title == "Context" }
                let whySection = sections.first { $0.title == "Why" }

                // Merge Why into Context if both exist
                let finalContext: SummarySection? = {
                    if let context = contextSection {
                        if let why = whySection {
                            // Merge why into context
                            let combined = "\(why.content)\n\n\(context.content)"
                            return SummarySection(title: "Context", icon: "📋", color: .purple, content: combined)
                        }
                        return context
                    } else if let why = whySection {
                        // Use Why as Context if Context doesn't exist
                        return SummarySection(title: "Context", icon: "📋", color: .purple, content: why.content)
                    }
                    return nil
                }()

                // Display Actions section
                if let actions = actionsSection, !actions.content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    SectionCard(section: actions, lineLimit: intelligentLineLimit, isActions: true, cardType: cardType)
                }

                // Display Context section
                if let context = finalContext, !context.content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    SectionCard(section: context, lineLimit: intelligentLineLimit, isActions: false, cardType: cardType)
                }

                // Fallback: If no sections found, show raw summary
                if actionsSection == nil && finalContext == nil {
                    Text((try? AttributedString(markdown: summary)) ?? AttributedString(summary))
                        .font(.system(size: 14))
                        .foregroundColor(textColorPrimary)
                        .lineSpacing(4)
                        .lineLimit(intelligentLineLimit)
                        .textSelection(.enabled)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
        }
    }

    /// Dynamic line limit - always returns nil to show full content
    /// Cards will expand vertically to accommodate all text
    private var intelligentLineLimit: Int? {
        // If parent explicitly set a line limit, respect it
        if let explicitLimit = lineLimit {
            return explicitLimit
        }

        // Otherwise, no limit - show all content
        return nil
    }
}

// MARK: - Section Card

private struct SectionCard: View {
    let section: SummarySection
    let lineLimit: Int?
    var isActions: Bool = false
    var cardType: CardType = .mail

    var body: some View {
        // Conditional text colors
        let headerColor = cardType == .ads ? DesignTokens.Colors.adsTextPrimary : Color.white
        let contentColor = cardType == .ads ?
            (isActions ? DesignTokens.Colors.adsTextPrimary : DesignTokens.Colors.adsTextSecondary) :
            Color.white.opacity(isActions ? 1.0 : 0.85)

        // Vertical layout for sections like Actions
        VStack(alignment: .leading, spacing: isActions ? 8 : 6) {
            // Section header (only for Actions and other sections, not Why/Context)
            HStack(spacing: 6) {
                Text(section.title.uppercased())
                    .font(DesignTokens.Typography.cardSectionHeader)
                    .foregroundColor(headerColor)
                    .fontWeight(.bold)
            }

            // Section content with markdown rendering
            // Actions: 15px, primary text color
            // Other sections: 14px, secondary text color
            Text((try? AttributedString(markdown: section.content)) ?? AttributedString(section.content))
                .font(.system(size: isActions ? 15 : 14))
                .foregroundColor(contentColor)
                .lineSpacing(5)
                .lineLimit(lineLimit)
                .textSelection(.enabled)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

// MARK: - Convenience Initializers

extension StructuredSummaryView {
    /// Create from EmailCard with automatic primary action detection
    init(card: EmailCard, lineLimit: Int? = nil) {
        // Prefer AI-generated summary, fallback to summary field, final fallback to placeholder
        let aiSummary = card.aiGeneratedSummary
        let fallbackSummary = card.summary

        // Intelligent fallback logic with empty string detection
        if let ai = aiSummary, !ai.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            self.summary = ai
        } else if !fallbackSummary.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            self.summary = fallbackSummary
        } else {
            self.summary = ""  // Will show "No summary available" in the view
        }

        self.primaryAction = card.hpa  // Highest priority action
        self.lineLimit = lineLimit
        self.cardType = card.type

        // Debug logging to verify summary data
        Logger.info("📝 StructuredSummaryView init for card: \(card.id)", category: .ui)
        Logger.info("  - aiGeneratedSummary: \(aiSummary != nil ? "present (\(aiSummary!.count) chars)" : "nil")", category: .ui)
        Logger.info("  - fallback summary: \(fallbackSummary.isEmpty ? "empty" : "present (\(fallbackSummary.count) chars)")", category: .ui)
        Logger.info("  - using: \(aiSummary != nil && !aiSummary!.isEmpty ? "AI-generated" : !fallbackSummary.isEmpty ? "fallback" : "none")", category: .ui)
        if !self.summary.isEmpty {
            Logger.info("  - Summary preview: \(String(self.summary.prefix(100)))...", category: .ui)
        }
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: 20) {
        StructuredSummaryView(
            summary: """
            **Actions:**
            • Sign permission form by **Wednesday 5 PM**
            • Pay $25 trip fee online

            **Why:**
            Emma's class needs signed approval for Natural History Museum field trip this Friday.

            **Context:**
            • Trip includes dinosaur exhibits and planetarium show
            • Pack lunch and water bottle
            """,
            primaryAction: "Sign & Send",
            lineLimit: nil
        )

        StructuredSummaryView(
            summary: """
            **Actions:**
            • Pay $35 yearbook fee by **next Friday**

            **Why:**
            Last chance to order 2025 yearbook before prices increase.

            **Context:**
            • Pay online via school portal or send check with Lucas
            • Includes photo pages, club activities, and memories section
            """,
            primaryAction: "Pay Fee",
            lineLimit: 4
        )
    }
    .padding()
    .background(
        LinearGradient(
            colors: [Color.blue, Color.purple],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    )
}
