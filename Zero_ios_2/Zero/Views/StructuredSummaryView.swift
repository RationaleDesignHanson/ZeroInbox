import SwiftUI

/// Structured summary view that parses and displays email summaries in organized sections
/// with visual coherence to the primary action shown on the card
struct StructuredSummaryView: View {
    let summary: String
    let primaryAction: String?  // e.g., "Sign & Send" from card.hpa
    let lineLimit: Int?

    init(summary: String, primaryAction: String? = nil, lineLimit: Int? = nil) {
        self.summary = summary
        self.primaryAction = primaryAction
        self.lineLimit = lineLimit
    }

    private var sections: [SummarySection] {
        SummaryParser.parse(summary, primaryAction: primaryAction)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // If summary is empty, show placeholder
            if summary.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                Text("No summary available")
                    .font(DesignTokens.Typography.cardSummary)
                    .foregroundColor(.white.opacity(0.5))
                    .italic()
                    .frame(maxWidth: .infinity, alignment: .leading)
            } else {
                // Display order matches web demo: Actions → Why → Context
                let actionsSection = sections.first { $0.title == "Actions" }
                let whySection = sections.first { $0.title == "Why" }
                let contextSection = sections.first { $0.title == "Context" }
                let otherSections = sections.filter { $0.title != "Actions" && $0.title != "Why" && $0.title != "Context" }

                // 1. Actions section (shown first, most prominent)
                if let actions = actionsSection {
                    SectionCard(section: actions, lineLimit: intelligentLineLimit, isActions: true)
                }

                // 2. Why section (second, explains importance)
                if let why = whySection {
                    InfoCard(content: why.content, lineLimit: intelligentLineLimit, opacity: 0.80, isItalic: true)
                }

                // 3. Context section (third, additional details)
                if let context = contextSection {
                    InfoCard(content: context.content, lineLimit: intelligentLineLimit, opacity: 0.70, isItalic: false)
                }

                // 4. Any other sections (rare, shown last)
                ForEach(otherSections) { section in
                    SectionCard(section: section, lineLimit: intelligentLineLimit, isActions: false)
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

// MARK: - Single Info Card (Why or Context)

private struct InfoCard: View {
    let content: String
    let lineLimit: Int?
    var opacity: Double = 0.85
    var isItalic: Bool = false

    var body: some View {
        Text((try? AttributedString(markdown: content)) ?? AttributedString(content))
            .font(.system(size: opacity > 0.75 ? 14 : 13))  // 14px for Why, 13px for Context
            .foregroundColor(.white.opacity(opacity))
            .italic(isItalic)
            .lineSpacing(5)
            .lineLimit(lineLimit)
            .textSelection(.enabled)
            .frame(maxWidth: .infinity, alignment: .leading)
    }
}

// MARK: - Section Card

private struct SectionCard: View {
    let section: SummarySection
    let lineLimit: Int?
    var isActions: Bool = false

    var body: some View {
        // Vertical layout for sections like Actions
        VStack(alignment: .leading, spacing: isActions ? 8 : 6) {
            // Section header (only for Actions and other sections, not Why/Context)
            HStack(spacing: 6) {
                Text(section.title.uppercased())
                    .font(DesignTokens.Typography.cardSectionHeader)
                    .foregroundColor(.white)
                    .fontWeight(.bold)
            }

            // Section content with markdown rendering
            // Actions: 15px, white (100% opacity), matches web demo
            // Other sections: 14px, 85% opacity
            Text((try? AttributedString(markdown: section.content)) ?? AttributedString(section.content))
                .font(.system(size: isActions ? 15 : 14))
                .foregroundColor(.white.opacity(isActions ? 1.0 : 0.85))
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
