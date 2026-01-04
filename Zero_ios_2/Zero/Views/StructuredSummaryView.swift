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
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.element) {
            // If summary is empty, show placeholder
            if summary.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                Text("No summary available")
                    .font(DesignTokens.Typography.cardSummary)
                    .foregroundColor(textColorPlaceholder)
                    .italic()
                    .frame(maxWidth: .infinity, alignment: .leading)
            } else {
                // Action-oriented display with all three sections
                let actionsSection = sections.first { $0.title == "Actions" }
                let whySection = sections.first { $0.title == "Why" }
                let contextSection = sections.first { $0.title == "Context" }

                // Display SUGGESTED ACTIONS section with arrow
                if let actions = actionsSection, !actions.content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    SectionCard(
                        section: SummarySection(title: "SUGGESTED ACTIONS", icon: actions.icon, color: actions.color, content: actions.content),
                        lineLimit: intelligentLineLimit,
                        sectionType: .actions,
                        cardType: cardType
                    )
                }

                // Display WHY THIS MATTERS section (separate from context)
                if let why = whySection, !why.content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    SectionCard(
                        section: SummarySection(title: "WHY THIS MATTERS", icon: why.icon, color: why.color, content: why.content),
                        lineLimit: intelligentLineLimit,
                        sectionType: .why,
                        cardType: cardType
                    )
                }

                // Display CONTEXT section
                if let context = contextSection, !context.content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    SectionCard(
                        section: SummarySection(title: "CONTEXT", icon: context.icon, color: context.color, content: context.content),
                        lineLimit: intelligentLineLimit,
                        sectionType: .context,
                        cardType: cardType
                    )
                }

                // Fallback: If no sections found, show raw summary
                if actionsSection == nil && whySection == nil && contextSection == nil {
                    Text((try? AttributedString(markdown: summary)) ?? AttributedString(summary))
                        .font(DesignTokens.Typography.aiAnalysisContextText)
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

// MARK: - Section Type

private enum SectionType {
    case actions
    case why
    case context

    var isActions: Bool { self == .actions }
}

// MARK: - Section Card

private struct SectionCard: View {
    let section: SummarySection
    let lineLimit: Int?
    var sectionType: SectionType = .context
    var cardType: CardType = .mail

    // Conditional text colors
    private var headerColor: Color {
        cardType == .ads ?
            DesignTokens.Colors.adsTextSecondary :
            Color.white.opacity(DesignTokens.Opacity.textTertiary)
    }

    private var contentColor: Color {
        cardType == .ads ?
            (sectionType.isActions ? DesignTokens.Colors.adsTextPrimary : DesignTokens.Colors.adsTextSecondary) :
            Color.white.opacity(sectionType.isActions ? 1.0 : DesignTokens.Opacity.textSecondary)
    }

    private var arrowColor: Color {
        cardType == .ads ?
            DesignTokens.Colors.adsTextPrimary :
            Color.white.opacity(DesignTokens.Opacity.textSecondary)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: sectionType.isActions ? DesignTokens.Spacing.inline : DesignTokens.Spacing.tight) {
            // Section header with optional arrow for actions
            HStack(spacing: DesignTokens.Spacing.tight) {
                Text(section.title)
                    .font(DesignTokens.Typography.aiAnalysisSectionHeader)
                    .foregroundColor(headerColor)
                    .tracking(0.5)

                Spacer()

                // Arrow indicator for SUGGESTED ACTIONS
                if sectionType == .actions {
                    Image(systemName: "arrow.right")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(arrowColor)
                }
            }

            // Section content with markdown rendering
            Text((try? AttributedString(markdown: section.content)) ?? AttributedString(section.content))
                .font(sectionType.isActions ?
                    DesignTokens.Typography.aiAnalysisActionText :
                    (sectionType == .why ?
                        DesignTokens.Typography.aiAnalysisWhyText :
                        DesignTokens.Typography.aiAnalysisContextText))
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
