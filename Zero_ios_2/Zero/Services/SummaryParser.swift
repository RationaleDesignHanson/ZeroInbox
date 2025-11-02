import SwiftUI

// MARK: - Summary Section Model

struct SummarySection: Identifiable {
    let id = UUID()
    let title: String
    let icon: String
    let color: Color
    let content: String
    let isActions: Bool  // Special flag for actions section

    init(title: String, icon: String, color: Color, content: String, isActions: Bool = false) {
        self.title = title
        self.icon = icon
        self.color = color
        self.content = content
        self.isActions = isActions
    }
}

// MARK: - Section Configuration

struct SectionConfig {
    let name: String
    let icon: String
    let color: Color
    let patterns: [String]
    let isActions: Bool

    static let knownSections: [SectionConfig] = [
        SectionConfig(
            name: "Actions",
            icon: "⚡️",
            color: .orange,
            patterns: [
                "\\*\\*Actions?:?\\*\\*",   // **Actions:**
                "Actions?:",                 // Actions:
                "TODO:?",                    // TODO:
                "TASKS?:?",                  // TASKS:
                "⚡️.*Actions?"             // ⚡️ Actions
            ],
            isActions: true
        ),
        SectionConfig(
            name: "Why",
            icon: "💡",
            color: .blue,
            patterns: [
                "\\*\\*Why:?\\*\\*",        // **Why:**
                "Why:",                      // Why:
                "REASON:?",                  // REASON:
                "💡.*Why"                   // 💡 Why
            ],
            isActions: false
        ),
        SectionConfig(
            name: "Context",
            icon: "📋",
            color: .purple,
            patterns: [
                "\\*\\*Context:?\\*\\*",    // **Context:**
                "Context:",                  // Context:
                "DETAILS:?",                 // DETAILS:
                "INFO:?",                    // INFO:
                "ABOUT:?",                   // ABOUT:
                "📋.*Context"               // 📋 Context
            ],
            isActions: false
        ),
        SectionConfig(
            name: "Details",
            icon: "📝",
            color: .green,
            patterns: [
                "\\*\\*Details?:?\\*\\*",   // **Details:**
                "Details?:",                 // Details:
                "📝.*Details?"              // 📝 Details
            ],
            isActions: false
        )
    ]
}

// MARK: - Summary Parser

class SummaryParser {

    /// Parse summary text into structured sections with fallback
    static func parse(_ text: String, primaryAction: String? = nil) -> [SummarySection] {
        let trimmedText = text.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !trimmedText.isEmpty else {
            return []
        }

        // Attempt to parse sections
        var sections = attemptParse(trimmedText, primaryAction: primaryAction)

        // Fallback: If no sections were parsed, return entire text as one section
        if sections.isEmpty {
            Logger.info("Summary parsing failed, using fallback (single Summary section)", category: .ui)
            return [SummarySection(
                title: "Summary",
                icon: "📄",
                color: .gray,
                content: trimmedText,
                isActions: false
            )]
        }

        // Reorder: Actions always first
        sections.sort { lhs, rhs in
            if lhs.isActions { return true }
            if rhs.isActions { return false }
            return false  // Keep other sections in original order
        }

        Logger.info("Parsed \(sections.count) sections from summary", category: .ui)
        return sections
    }

    /// Attempt to parse sections using regex patterns
    private static func attemptParse(_ text: String, primaryAction: String?) -> [SummarySection] {
        var sections: [SummarySection] = []
        var processedRanges: [Range<String.Index>] = []

        // Try to extract each known section
        for config in SectionConfig.knownSections {
            if let result = extractSection(config, from: text, alreadyProcessed: processedRanges) {
                sections.append(result.section)
                processedRanges.append(result.range)
            }
        }

        return sections
    }

    /// Extract a section matching the given config
    private static func extractSection(
        _ config: SectionConfig,
        from text: String,
        alreadyProcessed: [Range<String.Index>]
    ) -> (section: SummarySection, range: Range<String.Index>)? {

        for pattern in config.patterns {
            guard let regex = try? NSRegularExpression(pattern: pattern, options: [.caseInsensitive]) else {
                continue
            }

            let nsRange = NSRange(text.startIndex..., in: text)
            guard let match = regex.firstMatch(in: text, options: [], range: nsRange),
                  let matchRange = Range(match.range, in: text) else {
                continue
            }

            // Skip if this range overlaps with already processed sections
            if alreadyProcessed.contains(where: { $0.overlaps(matchRange) }) {
                continue
            }

            // Extract content after the header until next section or end
            let contentStart = matchRange.upperBound
            let content = extractContentAfterHeader(from: text, startingAt: contentStart, excluding: alreadyProcessed)

            guard !content.isEmpty else {
                continue
            }

            let section = SummarySection(
                title: config.name,
                icon: config.icon,
                color: config.color,
                content: content,
                isActions: config.isActions
            )

            // Calculate the range that includes header + content
            let endIndex = text.index(contentStart, offsetBy: content.count, limitedBy: text.endIndex) ?? text.endIndex
            let fullRange = matchRange.lowerBound..<endIndex

            return (section, fullRange)
        }

        return nil
    }

    /// Extract content after a section header until the next section or end of text
    private static func extractContentAfterHeader(
        from text: String,
        startingAt start: String.Index,
        excluding: [Range<String.Index>]
    ) -> String {
        var end = text.endIndex

        // Find the start of the next section
        for config in SectionConfig.knownSections {
            for pattern in config.patterns {
                guard let regex = try? NSRegularExpression(pattern: pattern, options: [.caseInsensitive]) else {
                    continue
                }

                let searchRange = NSRange(start..<text.endIndex, in: text)
                if let match = regex.firstMatch(in: text, options: [], range: searchRange),
                   let matchRange = Range(match.range, in: text),
                   matchRange.lowerBound > start,
                   matchRange.lowerBound < end {
                    end = matchRange.lowerBound
                }
            }
        }

        let content = String(text[start..<end])
        return content.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    /// Get text that hasn't been assigned to any section
    private static func getUnparsedText(from text: String, processedRanges: [Range<String.Index>]) -> String {
        guard !processedRanges.isEmpty else {
            return text
        }

        var unparsedParts: [String] = []
        var currentIndex = text.startIndex

        // Sort ranges by start index
        let sortedRanges = processedRanges.sorted { $0.lowerBound < $1.lowerBound }

        for range in sortedRanges {
            // Add text before this range
            if currentIndex < range.lowerBound {
                let part = String(text[currentIndex..<range.lowerBound])
                    .trimmingCharacters(in: .whitespacesAndNewlines)
                if !part.isEmpty {
                    unparsedParts.append(part)
                }
            }
            currentIndex = range.upperBound
        }

        // Add any remaining text after the last range
        if currentIndex < text.endIndex {
            let part = String(text[currentIndex..<text.endIndex])
                .trimmingCharacters(in: .whitespacesAndNewlines)
            if !part.isEmpty {
                unparsedParts.append(part)
            }
        }

        return unparsedParts.joined(separator: "\n\n")
    }
}
