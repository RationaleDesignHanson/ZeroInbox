import Foundation

/// Utility to format plain text emails with proper structure
/// Detects and formats: lists, paragraphs, quotes, signatures, code blocks
struct PlainTextFormatter {

    /// Format plain text email into structured HTML-like attributed text
    /// - Parameter text: Raw plain text email content
    /// - Returns: Formatted text with proper structure
    static func format(_ text: String) -> String {
        // Already HTML? Return as-is
        if text.contains("<") && text.contains(">") && text.contains("</") {
            return text
        }

        var result = ""
        let sections = splitIntoSections(text)

        for section in sections {
            switch section.type {
            case .numberedList:
                result += formatNumberedList(section.content)
            case .bulletedList:
                result += formatBulletedList(section.content)
            case .quote:
                result += formatQuote(section.content)
            case .signature:
                result += formatSignature(section.content)
            case .codeBlock:
                result += formatCodeBlock(section.content)
            case .paragraph:
                result += formatParagraph(section.content)
            }
            result += "\n\n"
        }

        return result.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    // MARK: - Section Detection

    enum SectionType {
        case numberedList
        case bulletedList
        case quote
        case signature
        case codeBlock
        case paragraph
    }

    struct Section {
        let type: SectionType
        let content: String
    }

    /// Split text into logical sections
    private static func splitIntoSections(_ text: String) -> [Section] {
        var sections: [Section] = []

        // Split by double line breaks (paragraph boundaries)
        let chunks = text.components(separatedBy: "\n\n")
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }

        for chunk in chunks {
            let lines = chunk.components(separatedBy: "\n")

            // Detect section type
            if isNumberedList(lines) {
                sections.append(Section(type: .numberedList, content: chunk))
            } else if isBulletedList(lines) {
                sections.append(Section(type: .bulletedList, content: chunk))
            } else if isQuote(chunk) {
                sections.append(Section(type: .quote, content: chunk))
            } else if isSignature(chunk, previousSections: sections) {
                sections.append(Section(type: .signature, content: chunk))
            } else if isCodeBlock(chunk) {
                sections.append(Section(type: .codeBlock, content: chunk))
            } else {
                sections.append(Section(type: .paragraph, content: chunk))
            }
        }

        return sections
    }

    // MARK: - Detection Helpers

    private static func isNumberedList(_ lines: [String]) -> Bool {
        guard lines.count > 1 else { return false }

        let listPatterns = [
            #"^\d+[\.)]\s+"#,  // 1. or 1)
            #"^\d+\.\s+"#       // 1.
        ]

        let matchingLines = lines.filter { line in
            listPatterns.contains { pattern in
                line.range(of: pattern, options: .regularExpression) != nil
            }
        }

        // At least 2 lines must match list pattern
        return matchingLines.count >= 2
    }

    private static func isBulletedList(_ lines: [String]) -> Bool {
        guard lines.count > 1 else { return false }

        let bulletPatterns = [
            #"^[-*•]\s+"#,      // - or * or •
            #"^[◦○▪▫]\s+"#      // Other bullet chars
        ]

        let matchingLines = lines.filter { line in
            bulletPatterns.contains { pattern in
                line.range(of: pattern, options: .regularExpression) != nil
            }
        }

        // At least 2 lines must match bullet pattern
        return matchingLines.count >= 2
    }

    private static func isQuote(_ text: String) -> Bool {
        let lines = text.components(separatedBy: "\n")

        // Check if lines start with > (email quote style)
        let quotedLines = lines.filter { $0.hasPrefix(">") }
        if quotedLines.count > lines.count / 2 {
            return true
        }

        // Check for "On [date], [name] wrote:" pattern
        let quoteHeaders = [
            "On .* wrote:",
            "^From:.*",
            "^Sent:.*",
            "^To:.*",
            "wrote:",
            "said:"
        ]

        for pattern in quoteHeaders {
            if text.range(of: pattern, options: .regularExpression) != nil {
                return true
            }
        }

        return false
    }

    private static func isSignature(_ text: String, previousSections: [Section]) -> Bool {
        let lines = text.components(separatedBy: "\n")

        // Common signature indicators
        let signaturePatterns = [
            "^--\\s*$",          // -- separator
            "^Best,?\\s*$",
            "^Thanks,?\\s*$",
            "^Regards,?\\s*$",
            "^Sincerely,?\\s*$",
            "^Cheers,?\\s*$",
            "^Sent from my",
            "^Get Outlook for"
        ]

        // Check first line for signature indicator
        if let firstLine = lines.first {
            for pattern in signaturePatterns {
                if firstLine.range(of: pattern, options: .regularExpression) != nil {
                    return true
                }
            }
        }

        // Signature is typically short and near the end
        let isShort = lines.count <= 5
        let isNearEnd = previousSections.count >= 2

        // Check for name-like patterns
        let hasNamePattern = lines.contains { line in
            // Simple heuristic: line with 2-3 words, capitalized
            let words = line.components(separatedBy: " ").filter { !$0.isEmpty }
            return words.count >= 2 && words.count <= 4 &&
                   words.allSatisfy { $0.first?.isUppercase == true }
        }

        return isShort && isNearEnd && hasNamePattern
    }

    private static func isCodeBlock(_ text: String) -> Bool {
        let lines = text.components(separatedBy: "\n")

        // Indented blocks (4+ spaces)
        let indentedLines = lines.filter { line in
            line.hasPrefix("    ") || line.hasPrefix("\t")
        }

        if indentedLines.count > lines.count / 2 {
            return true
        }

        // Code-like patterns
        let codePatterns = [
            "\\{.*\\}",           // Braces
            "function\\s+\\w+",   // function keyword
            "def\\s+\\w+",        // Python def
            "class\\s+\\w+",      // class keyword
            "import\\s+\\w+",     // import statement
            "=>",                 // Arrow function
            "\\[\\d+\\]"          // Log timestamps
        ]

        let hasCodePattern = codePatterns.contains { pattern in
            text.range(of: pattern, options: .regularExpression) != nil
        }

        return hasCodePattern && lines.count > 2
    }

    // MARK: - Formatters

    private static func formatNumberedList(_ text: String) -> String {
        let lines = text.components(separatedBy: "\n")
        var items: [String] = []

        for line in lines {
            // Remove number prefix (1. or 1) )
            let cleaned = line.replacingOccurrences(
                of: #"^\d+[\.)]\s*"#,
                with: "",
                options: .regularExpression
            )

            if !cleaned.isEmpty {
                items.append("  \(items.count + 1). \(cleaned)")
            }
        }

        return items.joined(separator: "\n")
    }

    private static func formatBulletedList(_ text: String) -> String {
        let lines = text.components(separatedBy: "\n")
        var items: [String] = []

        for line in lines {
            // Remove bullet prefix
            let cleaned = line.replacingOccurrences(
                of: #"^[-*•◦○▪▫]\s*"#,
                with: "",
                options: .regularExpression
            )

            if !cleaned.isEmpty {
                items.append("  • \(cleaned)")
            }
        }

        return items.joined(separator: "\n")
    }

    private static func formatQuote(_ text: String) -> String {
        let lines = text.components(separatedBy: "\n")

        // Remove > prefix and add quote formatting
        let cleanedLines = lines.map { line -> String in
            let cleaned = line.hasPrefix(">") ? String(line.dropFirst()).trimmingCharacters(in: .whitespaces) : line
            return "│ \(cleaned)"
        }

        return cleanedLines.joined(separator: "\n")
    }

    private static func formatSignature(_ text: String) -> String {
        // Add separator before signature
        let lines = text.components(separatedBy: "\n")

        // If it starts with --, keep it; otherwise add separator
        if lines.first?.hasPrefix("--") == true {
            return lines.joined(separator: "\n")
        } else {
            return "──────────\n" + lines.joined(separator: "\n")
        }
    }

    private static func formatCodeBlock(_ text: String) -> String {
        let lines = text.components(separatedBy: "\n")

        // Add code block markers
        return "```\n\(lines.joined(separator: "\n"))\n```"
    }

    private static func formatParagraph(_ text: String) -> String {
        // Handle single line breaks in short paragraphs (signatures/addresses)
        if text.contains("\n") && text.count < 100 {
            return text // Keep original formatting for short blocks
        }

        // For regular paragraphs, normalize
        return text.replacingOccurrences(of: "\n", with: " ")
    }
}
