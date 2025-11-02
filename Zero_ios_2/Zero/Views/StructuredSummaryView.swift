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
                    .font(.body)
                    .foregroundColor(.white.opacity(0.5))
                    .italic()
                    .frame(maxWidth: .infinity, alignment: .leading)
            } else {
                // Group Why and Context into single box, show other sections separately
                let whySection = sections.first { $0.title == "Why" }
                let contextSection = sections.first { $0.title == "Context" }
                let otherSections = sections.filter { $0.title != "Why" && $0.title != "Context" }

                // Combined Why + Context box (if both exist)
                if let why = whySection, let context = contextSection {
                    CombinedInfoCard(whySection: why, contextSection: context, lineLimit: intelligentLineLimit)
                } else if let why = whySection {
                    // Only Why exists
                    InfoCard(content: why.content, lineLimit: intelligentLineLimit)
                } else if let context = contextSection {
                    // Only Context exists
                    InfoCard(content: context.content, lineLimit: intelligentLineLimit)
                }

                // Other sections (Actions, etc.)
                ForEach(otherSections) { section in
                    SectionCard(section: section, lineLimit: intelligentLineLimit)
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

// MARK: - Combined Info Card (Why + Context)

private struct CombinedInfoCard: View {
    let whySection: SummarySection
    let contextSection: SummarySection
    let lineLimit: Int?

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Why content (no label)
            Text((try? AttributedString(markdown: whySection.content)) ?? AttributedString(whySection.content))
                .font(.body)
                .foregroundColor(.white.opacity(0.9))
                .lineSpacing(4)
                .lineLimit(lineLimit)
                .textSelection(.enabled)

            // Context content (no label, spaced below)
            Text((try? AttributedString(markdown: contextSection.content)) ?? AttributedString(contextSection.content))
                .font(.body)
                .foregroundColor(.white.opacity(0.9))
                .lineSpacing(4)
                .lineLimit(lineLimit)
                .textSelection(.enabled)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(EdgeInsets(top: 12, leading: 12, bottom: 12, trailing: 12))
        .background(Color.white.opacity(0.05))
        .cornerRadius(8)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .strokeBorder(Color.white.opacity(0.1), lineWidth: 1)
        )
    }
}

// MARK: - Single Info Card (Why or Context only)

private struct InfoCard: View {
    let content: String
    let lineLimit: Int?

    var body: some View {
        Text((try? AttributedString(markdown: content)) ?? AttributedString(content))
            .font(.body)
            .foregroundColor(.white.opacity(0.9))
            .lineSpacing(4)
            .lineLimit(lineLimit)
            .textSelection(.enabled)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(EdgeInsets(top: 12, leading: 12, bottom: 12, trailing: 12))
            .background(Color.white.opacity(0.05))
            .cornerRadius(8)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .strokeBorder(Color.white.opacity(0.1), lineWidth: 1)
            )
    }
}

// MARK: - Section Card

private struct SectionCard: View {
    let section: SummarySection
    let lineLimit: Int?

    var body: some View {
        // Vertical layout for sections like Actions
        VStack(alignment: .leading, spacing: 8) {
            // Section header
            HStack(spacing: 6) {
                Text(section.title.uppercased())
                    .font(.subheadline.bold())
                    .foregroundColor(.white.opacity(0.9))
            }

            // Section content with markdown rendering
            Text((try? AttributedString(markdown: section.content)) ?? AttributedString(section.content))
                .font(.body)
                .foregroundColor(.white.opacity(0.9))
                .lineSpacing(8)
                .lineLimit(lineLimit)
                .textSelection(.enabled)
        }
        .padding(EdgeInsets(top: 12, leading: 12, bottom: 12, trailing: 12))
        .background(backgroundOpacity)
        .cornerRadius(8)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .strokeBorder(section.color.opacity(0.2), lineWidth: 1)
        )
    }

    /// Actions section gets slightly more emphasis
    private var backgroundOpacity: Color {
        Color.white.opacity(section.isActions ? 0.12 : 0.05)
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
