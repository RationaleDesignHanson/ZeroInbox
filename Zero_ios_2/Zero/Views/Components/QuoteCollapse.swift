import SwiftUI

// MARK: - Quote Collapse View

/// Intelligent quote and signature collapsing for email reader
/// Detects and collapses: quoted replies, signatures, legal disclaimers
struct QuoteCollapseView: View {
    let emailBody: String
    @State private var expandedSections: Set<Int> = []
    
    private var parsedSections: [EmailSection] {
        EmailBodyParser.parse(emailBody)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ForEach(Array(parsedSections.enumerated()), id: \.offset) { index, section in
                sectionView(for: section, at: index)
            }
        }
    }
    
    @ViewBuilder
    private func sectionView(for section: EmailSection, at index: Int) -> some View {
        switch section.type {
        case .body:
            // Main content - always visible
            Text(section.content)
                .font(DesignTokens.Typography.readerBody)
                .foregroundColor(.white.opacity(0.92))
                .lineSpacing(6)
                .fixedSize(horizontal: false, vertical: true)
            
        case .quote:
            // Quoted text - collapsible
            CollapsibleSection(
                isExpanded: expandedSections.contains(index),
                headerText: "Quoted message",
                headerIcon: "text.quote",
                lineColor: .blue.opacity(0.6),
                onToggle: { toggleSection(index) }
            ) {
                Text(section.content)
                    .font(DesignTokens.Typography.readerQuote)
                    .foregroundColor(.white.opacity(0.7))
                    .lineSpacing(4)
                    .italic()
            }
            
        case .signature:
            // Signature - collapsible
            CollapsibleSection(
                isExpanded: expandedSections.contains(index),
                headerText: "Signature",
                headerIcon: "signature",
                lineColor: .gray.opacity(0.5),
                onToggle: { toggleSection(index) }
            ) {
                Text(section.content)
                    .font(DesignTokens.Typography.bodySmall)
                    .foregroundColor(.white.opacity(0.5))
                    .lineSpacing(4)
            }
            
        case .disclaimer:
            // Legal disclaimer - always collapsed by default
            CollapsibleSection(
                isExpanded: expandedSections.contains(index),
                headerText: "Legal disclaimer",
                headerIcon: "doc.text",
                lineColor: .orange.opacity(0.4),
                onToggle: { toggleSection(index) }
            ) {
                Text(section.content)
                    .font(.system(size: 11))
                    .foregroundColor(.white.opacity(0.4))
                    .lineSpacing(2)
            }
            
        case .forwardedHeader:
            // Forwarded message header
            HStack(spacing: 8) {
                Image(systemName: "arrowshape.turn.up.right.fill")
                    .font(.system(size: 12))
                    .foregroundColor(.purple.opacity(0.8))
                
                Text("Forwarded message")
                    .font(DesignTokens.Typography.labelMedium)
                    .foregroundColor(.white.opacity(0.7))
            }
            .padding(.vertical, 8)
        }
    }
    
    private func toggleSection(_ index: Int) {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
            if expandedSections.contains(index) {
                expandedSections.remove(index)
            } else {
                expandedSections.insert(index)
                HapticService.shared.lightImpact()
            }
        }
    }
}

// MARK: - Collapsible Section

struct CollapsibleSection<Content: View>: View {
    let isExpanded: Bool
    let headerText: String
    let headerIcon: String
    let lineColor: Color
    let onToggle: () -> Void
    let content: () -> Content
    
    init(
        isExpanded: Bool,
        headerText: String,
        headerIcon: String,
        lineColor: Color = .blue.opacity(0.5),
        onToggle: @escaping () -> Void,
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.isExpanded = isExpanded
        self.headerText = headerText
        self.headerIcon = headerIcon
        self.lineColor = lineColor
        self.onToggle = onToggle
        self.content = content
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Collapse header
            Button(action: onToggle) {
                HStack(spacing: 8) {
                    // Accent line
                    Rectangle()
                        .fill(lineColor)
                        .frame(width: 3)
                        .cornerRadius(1.5)
                    
                    Image(systemName: headerIcon)
                        .font(.system(size: 12))
                        .foregroundColor(lineColor)
                    
                    Text(headerText)
                        .font(DesignTokens.Typography.labelMedium)
                        .foregroundColor(.white.opacity(0.6))
                    
                    Spacer()
                    
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundColor(.white.opacity(0.4))
                        .rotationEffect(.degrees(isExpanded ? 0 : 0))
                }
                .padding(.vertical, 10)
                .contentShape(Rectangle())
            }
            .buttonStyle(PlainButtonStyle())
            
            // Expandable content
            if isExpanded {
                HStack(alignment: .top, spacing: 0) {
                    // Quote line
                    Rectangle()
                        .fill(lineColor)
                        .frame(width: 3)
                        .cornerRadius(1.5)
                    
                    content()
                        .padding(.leading, 12)
                }
                .padding(.bottom, 12)
                .transition(.asymmetric(
                    insertion: .opacity.combined(with: .move(edge: .top)),
                    removal: .opacity
                ))
            }
        }
    }
}

// MARK: - Email Body Parser

enum EmailSectionType {
    case body
    case quote
    case signature
    case disclaimer
    case forwardedHeader
}

struct EmailSection {
    let type: EmailSectionType
    let content: String
}

enum EmailBodyParser {
    
    // MARK: - Main Parser
    
    static func parse(_ body: String) -> [EmailSection] {
        var sections: [EmailSection] = []
        var currentContent = ""
        var inQuote = false
        var inSignature = false
        
        let lines = body.components(separatedBy: .newlines)
        
        for (index, line) in lines.enumerated() {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            
            // Check for forwarded message
            if isForwardedHeader(trimmed) {
                if !currentContent.isEmpty {
                    sections.append(EmailSection(type: .body, content: currentContent.trimmingCharacters(in: .whitespacesAndNewlines)))
                    currentContent = ""
                }
                sections.append(EmailSection(type: .forwardedHeader, content: trimmed))
                continue
            }
            
            // Check for quote start
            if isQuoteStart(trimmed) && !inQuote {
                if !currentContent.isEmpty {
                    sections.append(EmailSection(type: inSignature ? .signature : .body, content: currentContent.trimmingCharacters(in: .whitespacesAndNewlines)))
                    currentContent = ""
                }
                inQuote = true
                continue
            }
            
            // Check for signature start
            if isSignatureStart(trimmed, atIndex: index, totalLines: lines.count) && !inSignature && !inQuote {
                if !currentContent.isEmpty {
                    sections.append(EmailSection(type: .body, content: currentContent.trimmingCharacters(in: .whitespacesAndNewlines)))
                    currentContent = ""
                }
                inSignature = true
            }
            
            // Check for legal disclaimer
            if isDisclaimerStart(trimmed) && !inQuote {
                if !currentContent.isEmpty {
                    let type: EmailSectionType = inSignature ? .signature : .body
                    sections.append(EmailSection(type: type, content: currentContent.trimmingCharacters(in: .whitespacesAndNewlines)))
                    currentContent = ""
                }
                
                // Collect all disclaimer content
                var disclaimerContent = ""
                for i in index..<lines.count {
                    disclaimerContent += lines[i] + "\n"
                }
                sections.append(EmailSection(type: .disclaimer, content: disclaimerContent.trimmingCharacters(in: .whitespacesAndNewlines)))
                break
            }
            
            // Handle quoted lines (starting with >)
            if trimmed.hasPrefix(">") {
                if !inQuote {
                    if !currentContent.isEmpty {
                        sections.append(EmailSection(type: .body, content: currentContent.trimmingCharacters(in: .whitespacesAndNewlines)))
                        currentContent = ""
                    }
                    inQuote = true
                }
                // Strip quote marker
                let unquoted = trimmed.drop(while: { $0 == ">" || $0 == " " })
                currentContent += String(unquoted) + "\n"
            } else if inQuote && trimmed.isEmpty {
                // Empty line might end quote
                currentContent += "\n"
            } else if inQuote && !trimmed.isEmpty && !trimmed.hasPrefix(">") {
                // Non-quoted content ends the quote
                sections.append(EmailSection(type: .quote, content: currentContent.trimmingCharacters(in: .whitespacesAndNewlines)))
                currentContent = line + "\n"
                inQuote = false
            } else {
                currentContent += line + "\n"
            }
        }
        
        // Add remaining content
        if !currentContent.isEmpty {
            let type: EmailSectionType
            if inQuote {
                type = .quote
            } else if inSignature {
                type = .signature
            } else {
                type = .body
            }
            sections.append(EmailSection(type: type, content: currentContent.trimmingCharacters(in: .whitespacesAndNewlines)))
        }
        
        return sections.filter { !$0.content.isEmpty }
    }
    
    // MARK: - Detection Helpers
    
    private static func isQuoteStart(_ line: String) -> Bool {
        let patterns = [
            "On .* wrote:",
            "From:.*Sent:.*To:",
            "-------- Original Message --------",
            "Begin forwarded message:",
            "> On ",
            "-----Original Message-----",
            "________________________________",
        ]
        
        for pattern in patterns {
            if let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive) {
                let range = NSRange(line.startIndex..., in: line)
                if regex.firstMatch(in: line, options: [], range: range) != nil {
                    return true
                }
            }
        }
        
        return false
    }
    
    private static func isForwardedHeader(_ line: String) -> Bool {
        let patterns = [
            "---------- Forwarded message",
            "Begin forwarded message:",
            "Forwarded message from",
        ]
        
        return patterns.contains { line.lowercased().contains($0.lowercased()) }
    }
    
    private static func isSignatureStart(_ line: String, atIndex index: Int, totalLines: Int) -> Bool {
        // Signatures typically appear in the last portion of email
        let isNearEnd = Double(index) > Double(totalLines) * 0.6
        
        let patterns = [
            "^--\\s*$",           // Standard signature delimiter
            "^___+$",             // Underscores
            "^---+$",             // Dashes
            "^Best,?$",
            "^Thanks,?$",
            "^Thank you,?$",
            "^Regards,?$",
            "^Best regards,?$",
            "^Kind regards,?$",
            "^Sincerely,?$",
            "^Cheers,?$",
            "^Sent from my iPhone",
            "^Sent from my iPad",
            "^Get Outlook for",
        ]
        
        for pattern in patterns {
            if let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive) {
                let range = NSRange(line.startIndex..., in: line)
                if regex.firstMatch(in: line, options: [], range: range) != nil {
                    return isNearEnd || pattern.contains("--") || pattern.contains("Sent from")
                }
            }
        }
        
        return false
    }
    
    private static func isDisclaimerStart(_ line: String) -> Bool {
        let patterns = [
            "CONFIDENTIALITY NOTICE",
            "DISCLAIMER:",
            "This email and any attachments",
            "This message contains confidential",
            "NOTICE: This email",
            "This e-mail is confidential",
            "If you are not the intended recipient",
            "LEGAL DISCLAIMER",
            "The information contained in this",
        ]
        
        return patterns.contains { line.uppercased().contains($0.uppercased()) }
    }
}

// MARK: - Inline Quote Indicator

/// Small inline indicator for showing collapsed quote count
struct QuoteIndicator: View {
    let quoteCount: Int
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 4) {
                Image(systemName: "ellipsis")
                    .font(.system(size: 10, weight: .bold))
                Text("\(quoteCount) quoted")
                    .font(.system(size: 11, weight: .medium))
            }
            .foregroundColor(.blue.opacity(0.8))
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(
                Capsule()
                    .fill(Color.blue.opacity(0.15))
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Preview

#Preview("Quote Collapse") {
    ScrollView {
        VStack(alignment: .leading, spacing: 16) {
            Text("Email with Quotes")
                .font(.headline)
                .foregroundColor(.white)
            
            QuoteCollapseView(emailBody: """
            Hi John,

            Thanks for getting back to me about the project timeline. I agree with your assessment.

            Let's schedule a call for next week to discuss the details.

            On Dec 15, 2024, John Smith wrote:
            > Hi Sarah,
            >
            > I've reviewed the proposal and I think we should move forward.
            > The timeline looks good to me.
            >
            > Best,
            > John

            --
            Sarah Johnson
            Product Manager
            Acme Corp
            sarah@acme.com
            (555) 123-4567

            CONFIDENTIALITY NOTICE: This email and any attachments are for the exclusive and confidential use of the intended recipient. If you are not the intended recipient, please do not read, distribute, or take action based on this message.
            """)
            .padding()
            .background(Color.white.opacity(0.06))
            .cornerRadius(12)
        }
        .padding()
    }
    .background(Color.black)
}

