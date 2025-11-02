import Foundation

/// Utility to replace long URLs in email body text with readable, clickable link labels
/// Transforms "https://example.com/long/tracking/url" → "[Track Package](url)"
/// For HTML emails, extracts existing anchor text instead of generating labels
struct URLShortener {

    /// Replace long URLs with readable link text in markdown format
    /// - Parameters:
    ///   - text: Original email body text with URLs
    ///   - htmlBody: Optional HTML body to extract anchor text from
    /// - Returns: Processed text with shortened link labels
    static func shortenURLs(in text: String, htmlBody: String? = nil) -> String {
        // If HTML body provided, try to extract link text from HTML first
        if let html = htmlBody {
            return processHTMLLinks(plainText: text, htmlBody: html)
        }

        // Otherwise generate smart labels for plain text URLs
        return processPlainTextLinks(text)
    }

    /// Process HTML email body to extract link text from anchor tags
    private static func processHTMLLinks(plainText: String, htmlBody: String) -> String {
        var result = plainText

        // Extract all <a href="url">text</a> patterns from HTML
        let anchorPattern = #"<a[^>]*href=[\"']([^\"']+)[\"'][^>]*>([^<]+)</a>"#
        guard let regex = try? NSRegularExpression(pattern: anchorPattern, options: [.caseInsensitive]) else {
            return processPlainTextLinks(plainText)
        }

        let htmlMatches = regex.matches(in: htmlBody, options: [], range: NSRange(htmlBody.startIndex..., in: htmlBody))

        // Build a map of URL → anchor text from HTML
        var urlToTextMap: [String: String] = [:]
        for match in htmlMatches {
            guard match.numberOfRanges == 3,
                  let urlRange = Range(match.range(at: 1), in: htmlBody),
                  let textRange = Range(match.range(at: 2), in: htmlBody) else {
                continue
            }

            let url = String(htmlBody[urlRange])
            let linkText = String(htmlBody[textRange])
                .trimmingCharacters(in: .whitespacesAndNewlines)

            // Clean up link text (remove extra whitespace, decode HTML entities)
            let cleanedText = linkText
                .replacingOccurrences(of: "&nbsp;", with: " ")
                .replacingOccurrences(of: "&amp;", with: "&")
                .replacingOccurrences(of: "&lt;", with: "<")
                .replacingOccurrences(of: "&gt;", with: ">")
                .replacingOccurrences(of: "&quot;", with: "\"")

            urlToTextMap[url] = cleanedText
        }

        // Now replace URLs in plain text with extracted anchor text
        guard let detector = try? NSDataDetector(types: NSTextCheckingResult.CheckingType.link.rawValue) else {
            return plainText
        }

        let matches = detector.matches(in: plainText, options: [], range: NSRange(plainText.startIndex..., in: plainText))

        var linkCount = 0
        for match in matches.reversed() {
            guard let range = Range(match.range, in: plainText),
                  let url = match.url else { continue }

            if isMarkdownLink(at: range, in: plainText) {
                continue
            }

            let urlString = url.absoluteString

            // Check if we have extracted anchor text from HTML
            let label: String
            if let anchorText = urlToTextMap[urlString], !anchorText.isEmpty {
                label = anchorText
            } else {
                // Fallback to smart label generation
                label = generateLabel(for: url, linkNumber: &linkCount)
            }

            let markdownLink = "[\(label)](\(urlString))"
            result.replaceSubrange(range, with: markdownLink)
        }

        return result
    }

    /// Process plain text links with smart label generation
    private static func processPlainTextLinks(_ text: String) -> String {
        var result = text
        var linkCount = 0

        // Create URL detector
        guard let detector = try? NSDataDetector(types: NSTextCheckingResult.CheckingType.link.rawValue) else {
            return text
        }

        // Find all URLs in text
        let matches = detector.matches(in: text, options: [], range: NSRange(text.startIndex..., in: text))

        // Process URLs in reverse order to maintain string indices during replacement
        for match in matches.reversed() {
            guard let range = Range(match.range, in: text),
                  let url = match.url else { continue }

            // Skip if already in markdown format [text](url)
            if isMarkdownLink(at: range, in: text) {
                continue
            }

            // Generate smart label based on URL
            let label = generateLabel(for: url, linkNumber: &linkCount)

            // Replace with markdown link: [label](url)
            let markdownLink = "[\(label)](\(url.absoluteString))"
            result.replaceSubrange(range, with: markdownLink)
        }

        return result
    }

    /// Check if URL is already part of markdown link syntax
    private static func isMarkdownLink(at range: Range<String.Index>, in text: String) -> Bool {
        // Check if preceded by "](" which would indicate it's already formatted
        guard range.lowerBound > text.startIndex else { return false }

        // Check up to 2 characters before the URL
        let precedingIndex = text.index(before: range.lowerBound)
        if precedingIndex > text.startIndex {
            let twoCharsBefore = text.index(before: precedingIndex)
            let preceding = text[twoCharsBefore...precedingIndex]
            if preceding == "](" {
                return true
            }
        }

        // Also check if URL starts with markdown syntax (edge case)
        // Look for pattern [text](http...
        if let lowerBound = text.index(range.lowerBound, offsetBy: -10, limitedBy: text.startIndex) {
            let context = text[lowerBound..<range.upperBound]
            if context.contains("](\(text[range])") {
                return true
            }
        }

        return false
    }

    /// Generate smart, readable label for URL based on content and context
    /// Returns concise labels with emoji icons for visual context
    private static func generateLabel(for url: URL, linkNumber: inout Int) -> String {
        let host = url.host?.lowercased() ?? ""
        let path = url.path.lowercased()
        let query = url.query?.lowercased() ?? ""

        // Handle URL shorteners (bit.ly, tinyurl, etc.) - show domain but indicate it's shortened
        let urlShorteners = ["bit.ly", "tinyurl.com", "t.co", "goo.gl", "ow.ly", "buff.ly", "is.gd"]
        if urlShorteners.contains(where: { host.contains($0) }) {
            return "🔗 Link"
        }

        // Handle tracking/redirect URLs (common in marketing emails)
        if host.contains("click") || host.contains("track") || host.contains("redirect") ||
           path.contains("/l/") || path.contains("/r/") || query.contains("redirect") {
            // Try to extract the actual domain from tracking URL
            if let targetParam = extractTargetDomain(from: url) {
                return "Visit \(targetParam)"
            }
            return "Link"
        }

        // E-commerce & Shopping
        if host.contains("amazon") || host.contains("amzn") {
            if path.contains("track") || query.contains("track") {
                return "📦 Track Package"
            }
            if path.contains("order") || path.contains("gp/css/order") {
                return "🛍️ View Order"
            }
            if path.contains("cart") {
                return "🛒 Cart"
            }
            if path.contains("dp/") || path.contains("product") {
                return "🛍️ Product"
            }
            return "🛍️ Amazon"
        }

        // Shipping & Logistics
        if host.contains("fedex") {
            return "📦 FedEx Tracking"
        }
        if host.contains("ups") {
            return "📦 UPS Tracking"
        }
        if host.contains("usps") {
            return "📦 USPS Tracking"
        }
        if host.contains("dhl") {
            return "📦 DHL Tracking"
        }

        // Airlines & Travel
        if host.contains("delta") || host.contains("united") || host.contains("american") || host.contains("southwest") {
            if path.contains("checkin") || query.contains("checkin") {
                return "✈️ Check In"
            }
            if path.contains("booking") || path.contains("reservation") {
                return "✈️ Booking"
            }
            return "✈️ Flight"
        }

        // Hotels
        if host.contains("hilton") || host.contains("marriott") || host.contains("hyatt") || host.contains("airbnb") {
            return "🏨 Reservation"
        }

        // Payments & Billing
        if path.contains("invoice") || host.contains("invoice") {
            return "💳 Invoice"
        }
        if path.contains("receipt") {
            return "💳 Receipt"
        }
        if path.contains("payment") || path.contains("pay") || host.contains("pay") {
            return "💳 Payment"
        }
        if path.contains("billing") {
            return "💳 Billing"
        }

        // Calendar & Events
        if path.contains("calendar") || host.contains("calendar") {
            return "📅 Calendar"
        }
        if path.contains("event") || path.contains("rsvp") {
            return "📅 Event"
        }
        if path.contains("meeting") {
            return "📅 Meeting"
        }

        // Account & Authentication
        if path.contains("confirm") || query.contains("confirm") {
            return "✓ Confirm"
        }
        if path.contains("verify") || query.contains("verify") {
            return "✓ Verify"
        }
        if path.contains("reset") && path.contains("password") {
            return "🔑 Reset Password"
        }
        if path.contains("login") || path.contains("signin") {
            return "🔑 Sign In"
        }
        if path.contains("register") || path.contains("signup") {
            return "🔑 Sign Up"
        }

        // Documents & Forms
        if path.contains("document") || path.contains("doc") {
            return "📄 Document"
        }
        if path.contains("form") {
            return "📝 Form"
        }
        if path.contains("download") {
            return "⬇️ Download"
        }

        // Communication
        if path.contains("unsubscribe") {
            return "🚫 Unsubscribe"
        }
        if path.contains("reply") || path.contains("respond") {
            return "↩️ Reply"
        }

        // Social & Video
        if host.contains("youtube") || host.contains("youtu.be") {
            return "▶️ Video"
        }
        if host.contains("zoom.us") {
            return "📹 Zoom"
        }
        if host.contains("meet.google") {
            return "📹 Meeting"
        }

        // Generic fallback based on common path patterns
        if path.contains("details") {
            return "ℹ️ Details"
        }
        if path.contains("settings") {
            return "⚙️ Settings"
        }
        if path.contains("help") || path.contains("support") {
            return "❓ Support"
        }
        if path.contains("dashboard") {
            return "📊 Dashboard"
        }

        // Extract clean domain name for final fallback
        let cleanHost = host.replacingOccurrences(of: "www.", with: "")
        if !cleanHost.isEmpty {
            // Show just domain without subdomain (e.g., "example.com" instead of full URL)
            let components = cleanHost.split(separator: ".")
            if components.count >= 2 {
                let domain = "\(components[components.count - 2]).\(components[components.count - 1])"
                return "🔗 \(domain)"
            }
            return "🔗 \(cleanHost)"
        }

        // Final fallback for malformed URLs
        linkNumber += 1
        return "🔗 Link \(linkNumber)"
    }

    /// Process HTML content to replace ugly anchor text with smart labels
    /// Only replaces anchor text that is the URL itself (not human-written text)
    /// - Parameter html: Original HTML content
    /// - Returns: HTML with shortened link labels
    static func shortenHTMLLinks(in html: String) -> String {
        var result = html
        var linkCount = 0

        // Match <a> tags with href and extract URL and anchor text
        let anchorPattern = #"<a([^>]*href=[\"']([^\"']+)[\"'][^>]*)>([^<]+)</a>"#
        guard let regex = try? NSRegularExpression(pattern: anchorPattern, options: [.caseInsensitive]) else {
            return html
        }

        let matches = regex.matches(in: html, options: [], range: NSRange(html.startIndex..., in: html))

        // Process matches in reverse to maintain string indices
        for match in matches.reversed() {
            guard match.numberOfRanges == 4,
                  let fullRange = Range(match.range, in: html),
                  let attributesRange = Range(match.range(at: 1), in: html),
                  let urlRange = Range(match.range(at: 2), in: html),
                  let textRange = Range(match.range(at: 3), in: html) else {
                continue
            }

            let attributes = String(html[attributesRange])
            let urlString = String(html[urlRange])
            let anchorText = String(html[textRange])
                .trimmingCharacters(in: .whitespacesAndNewlines)
                .replacingOccurrences(of: "&nbsp;", with: " ")
                .replacingOccurrences(of: "&amp;", with: "&")

            // Only replace if anchor text looks like a URL (not human-written)
            // Check if anchor text is the URL itself or starts with http/www
            let shouldReplace = anchorText.lowercased().starts(with: "http") ||
                               anchorText.lowercased().starts(with: "www.") ||
                               anchorText.contains("://") ||
                               anchorText == urlString ||
                               anchorText.replacingOccurrences(of: " ", with: "") == urlString

            if shouldReplace, let url = URL(string: urlString) {
                // Generate smart label
                let smartLabel = generateLabel(for: url, linkNumber: &linkCount)

                // Replace the entire anchor tag with shortened version
                let newAnchor = "<a\(attributes)>\(smartLabel)</a>"
                result.replaceSubrange(fullRange, with: newAnchor)
            }
        }

        return result
    }

    /// Extract target domain from tracking/redirect URL
    /// Looks for common redirect patterns in query parameters
    private static func extractTargetDomain(from url: URL) -> String? {
        guard url.query != nil else { return nil }

        // Common redirect parameter names
        let redirectParams = ["url", "redirect", "target", "goto", "dest", "destination", "to", "link"]

        // Parse query parameters
        let components = URLComponents(url: url, resolvingAgainstBaseURL: false)
        guard let queryItems = components?.queryItems else { return nil }

        for item in queryItems {
            if redirectParams.contains(item.name.lowercased()), let value = item.value {
                // Try to extract domain from the redirect URL
                if let redirectURL = URL(string: value), let host = redirectURL.host {
                    return host.replacingOccurrences(of: "www.", with: "")
                }
            }
        }

        return nil
    }
}
