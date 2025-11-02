import SwiftUI
@preconcurrency import WebKit
import SafariServices

/// WebView wrapper for displaying HTML email content with native email client rendering
struct HTMLWebView: UIViewRepresentable {
    let htmlContent: String
    var onHeightChange: ((CGFloat) -> Void)? = nil
    var onError: ((String) -> Void)? = nil

    func makeCoordinator() -> Coordinator {
        Coordinator(onHeightChange: onHeightChange, onError: onError)
    }

    func makeUIView(context: Context) -> WKWebView {
        let configuration = WKWebViewConfiguration()

        // Enable inline media playback (for videos in emails)
        configuration.allowsInlineMediaPlayback = true
        configuration.mediaTypesRequiringUserActionForPlayback = .all

        let webView = WKWebView(frame: .zero, configuration: configuration)
        webView.isOpaque = false
        webView.backgroundColor = .clear
        webView.scrollView.backgroundColor = .clear
        webView.scrollView.isScrollEnabled = false // Disable internal scrolling (parent ScrollView handles it)
        webView.navigationDelegate = context.coordinator

        // Enable link preview and data detection
        webView.allowsLinkPreview = true

        return webView
    }

    func updateUIView(_ webView: WKWebView, context: Context) {
        // Apply URL shortening first to replace ugly URLs with smart labels
        let shortenedHTML = URLShortener.shortenHTMLLinks(in: htmlContent)

        // Strip inline width styles that break responsive layout
        let widthStrippedHTML = stripInlineWidths(shortenedHTML)

        // Sanitize and limit HTML size to prevent crashes
        let sanitizedHTML = sanitizeHTML(widthStrippedHTML)
        let limitedHTML = String(sanitizedHTML.prefix(500_000))  // 500KB max

        if sanitizedHTML.count > 500_000 {
            Logger.warning("HTML content truncated from \(sanitizedHTML.count) to 500000 chars", category: .app)
            onError?("Email content was very large and has been truncated")
        }

        // Wrap HTML with responsive viewport and native email styling
        let wrappedHTML = """
        <!DOCTYPE html>
        <html>
        <head>
            <meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no">
            <meta charset="UTF-8">
            <style>
                /* Base email styling matching native clients */
                body {
                    font-family: -apple-system, BlinkMacSystemFont, 'SF Pro Text', 'Segoe UI', Roboto, Helvetica, Arial, sans-serif;
                    font-size: 16px;
                    line-height: 1.6;
                    color: #ffffff;
                    background-color: transparent;
                    margin: 0;
                    padding: 16px;
                    word-wrap: break-word !important;
                    word-break: break-word !important;
                    overflow-wrap: break-word !important;
                    -webkit-text-size-adjust: 100%;
                    max-width: 100vw !important;
                    width: 100% !important;
                    overflow-x: hidden !important;
                    box-sizing: border-box !important;
                }

                /* Image handling - native email style */
                img {
                    max-width: 100% !important;
                    width: auto !important;
                    height: auto !important;
                    display: block;
                    margin: 8px 0;
                    border-radius: 8px;
                }

                /* Inline images should stay inline */
                img[style*="display: inline"],
                img[style*="display:inline"] {
                    display: inline !important;
                    margin: 0 4px;
                    max-width: 100% !important;
                }

                /* Table layout (common in email HTML) */
                table {
                    max-width: 100% !important;
                    width: 100% !important;
                    min-width: 0 !important;
                    border-collapse: collapse;
                    table-layout: fixed !important;
                    overflow-wrap: break-word !important;
                    word-break: break-word !important;
                }

                td, th {
                    padding: 8px;
                    vertical-align: top;
                    word-wrap: break-word !important;
                    overflow-wrap: break-word !important;
                    word-break: break-word !important;
                    max-width: 100% !important;
                }

                /* Prevent any element from exceeding viewport width */
                * {
                    max-width: 100% !important;
                    min-width: 0 !important;
                    box-sizing: border-box !important;
                }

                div, section, article, main, header, footer, span, p {
                    max-width: 100% !important;
                    overflow-wrap: break-word !important;
                    word-break: break-word !important;
                }

                /* Links - Elegant pill style with natural wrapping */
                a {
                    color: #93c5fd;
                    text-decoration: none;
                    background: rgba(147, 197, 253, 0.15);
                    padding: 2px 8px;
                    border-radius: 6px;
                    word-break: break-word !important;
                    overflow-wrap: break-word !important;
                    display: inline-block;
                    margin: 2px 0;
                    transition: all 0.2s ease;
                    font-size: 15px;
                    font-weight: 500;
                    border: 1px solid rgba(147, 197, 253, 0.3);
                }

                a:active {
                    background: rgba(147, 197, 253, 0.25);
                    color: #bfdbfe;
                    border-color: rgba(147, 197, 253, 0.5);
                }

                /* Headings */
                h1, h2, h3, h4, h5, h6 {
                    color: #ffffff;
                    margin-top: 16px;
                    margin-bottom: 8px;
                    line-height: 1.3;
                }

                /* Paragraphs */
                p {
                    margin: 12px 0;
                }

                /* Lists */
                ul, ol {
                    padding-left: 24px;
                    margin: 12px 0;
                }

                li {
                    margin: 6px 0;
                }

                /* Blockquotes - common in email replies */
                blockquote {
                    margin: 12px 0;
                    padding-left: 16px;
                    border-left: 3px solid rgba(255, 255, 255, 0.3);
                    color: rgba(255, 255, 255, 0.8);
                }

                /* Buttons in HTML emails */
                .button, a.button {
                    display: inline-block;
                    padding: 12px 24px;
                    background-color: #3b82f6;
                    color: #ffffff !important;
                    text-decoration: none;
                    border-radius: 8px;
                    margin: 8px 0;
                }

                /* Preformatted text */
                pre, code {
                    font-family: 'SF Mono', Menlo, Monaco, 'Courier New', monospace;
                    background-color: rgba(255, 255, 255, 0.1);
                    padding: 2px 6px;
                    border-radius: 4px;
                    font-size: 14px;
                }

                pre {
                    padding: 12px;
                    overflow-x: auto;
                    white-space: pre-wrap;
                }

                /* Email signature styling */
                .gmail_signature,
                .signature,
                div[data-signature] {
                    margin-top: 24px;
                    padding-top: 16px;
                    border-top: 1px solid rgba(255, 255, 255, 0.2);
                    font-size: 14px;
                    color: rgba(255, 255, 255, 0.7);
                }

                /* Quoted text (email replies) */
                .gmail_quote,
                .quoted-text {
                    margin-top: 20px;
                    padding-top: 16px;
                    border-top: 1px solid rgba(255, 255, 255, 0.2);
                    color: rgba(255, 255, 255, 0.6);
                    font-size: 14px;
                }

                /* Hide original message headers in replies */
                .gmail_attr {
                    font-size: 13px;
                    color: rgba(255, 255, 255, 0.5);
                    margin: 8px 0;
                }
            </style>
        </head>
        <body>
            \(limitedHTML)
        </body>
        </html>
        """

        webView.loadHTMLString(wrappedHTML, baseURL: nil)
    }

    // MARK: - Cleanup

    /// Properly dismantle WKWebView to prevent memory leaks
    static func dismantleUIView(_ uiView: WKWebView, coordinator: Coordinator) {
        // Stop all navigation
        uiView.stopLoading()

        // Remove delegate to break retain cycle
        uiView.navigationDelegate = nil

        // Clear content to release memory
        uiView.loadHTMLString("", baseURL: nil)

        Logger.info("WKWebView dismantled and cleaned up", category: .app)
    }

    // MARK: - HTML Sanitization

    /// Remove potentially dangerous HTML tags
    private func sanitizeHTML(_ html: String) -> String {
        var sanitized = html

        // Remove potentially dangerous tags that could cause issues
        let dangerousTags = ["<script", "</script>", "<iframe", "</iframe>", "javascript:"]
        for tag in dangerousTags {
            sanitized = sanitized.replacingOccurrences(of: tag, with: "", options: .caseInsensitive)
        }

        return sanitized
    }

    /// Strip inline width styles that break responsive layout
    /// Removes width, min-width, max-width from inline style attributes
    private func stripInlineWidths(_ html: String) -> String {
        var result = html

        // Remove width-related properties from style attributes
        // Pattern matches: width: 600px; or width:600px or width: 100%
        let widthPatterns = [
            "\\s*width\\s*:\\s*[^;\"']+;?",
            "\\s*min-width\\s*:\\s*[^;\"']+;?",
            "\\s*max-width\\s*:\\s*[^;\"']+;?"
        ]

        for pattern in widthPatterns {
            if let regex = try? NSRegularExpression(pattern: pattern, options: [.caseInsensitive]) {
                result = regex.stringByReplacingMatches(
                    in: result,
                    options: [],
                    range: NSRange(result.startIndex..., in: result),
                    withTemplate: ""
                )
            }
        }

        // Also remove width/height attributes from tags (like <table width="600">)
        let attributePatterns = [
            "\\s+width=[\"'][^\"']*[\"']",
            "\\s+width=[0-9]+",
            "\\s+min-width=[\"'][^\"']*[\"']",
            "\\s+min-width=[0-9]+"
        ]

        for pattern in attributePatterns {
            if let regex = try? NSRegularExpression(pattern: pattern, options: [.caseInsensitive]) {
                result = regex.stringByReplacingMatches(
                    in: result,
                    options: [],
                    range: NSRange(result.startIndex..., in: result),
                    withTemplate: ""
                )
            }
        }

        return result
    }

    // Coordinator to handle navigation and link taps
    class Coordinator: NSObject, WKNavigationDelegate {
        var onHeightChange: ((CGFloat) -> Void)?
        var onError: ((String) -> Void)?

        init(onHeightChange: ((CGFloat) -> Void)? = nil, onError: ((String) -> Void)? = nil) {
            self.onHeightChange = onHeightChange
            self.onError = onError
            super.init()
        }

        func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
            // Allow initial load
            if navigationAction.navigationType == .other {
                decisionHandler(.allow)
                return
            }

            // Handle link taps - open in SFSafariViewController
            if navigationAction.navigationType == .linkActivated {
                if let url = navigationAction.request.url {
                    openLinkInSafari(url)

                    // Haptic feedback
                    let generator = UIImpactFeedbackGenerator(style: .light)
                    generator.impactOccurred()
                }
                decisionHandler(.cancel)
                return
            }

            decisionHandler(.allow)
        }

        private func openLinkInSafari(_ url: URL) {
            // Get the current window scene
            guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                  let viewController = windowScene.windows.first?.rootViewController else {
                // Fallback to external Safari
                UIApplication.shared.open(url)
                Logger.warning("Could not find view controller for HTML link, opening in external Safari", category: .ui)
                return
            }

            // Present SFSafariViewController
            let config = SFSafariViewController.Configuration()
            config.entersReaderIfAvailable = true  // Enable reader mode for HTML emails
            config.barCollapsingEnabled = true

            let safari = SFSafariViewController(url: url, configuration: config)
            safari.dismissButtonStyle = .done
            safari.preferredControlTintColor = .systemBlue

            // Find the topmost presented view controller
            var topController = viewController
            while let presented = topController.presentedViewController {
                topController = presented
            }

            topController.present(safari, animated: true)
            Logger.info("Opening HTML email link in Safari: \(url.absoluteString)", category: .ui)
        }

        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            // Adjust height to content size for proper scrolling
            // Use weak reference to prevent retain cycle
            webView.evaluateJavaScript("document.body.scrollHeight") { [weak self, weak webView] (height, error) in
                guard let webView = webView else { return }

                if let error = error {
                    Logger.error("Failed to get HTML content height: \(error.localizedDescription)", category: .app)
                    self?.onError?("Failed to render email content")
                    return
                }

                if let height = height as? CGFloat {
                    webView.frame.size.height = height
                    webView.scrollView.isScrollEnabled = false

                    // Notify parent of height change
                    self?.onHeightChange?(height)
                }
            }
        }

        func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
            Logger.error("WKWebView navigation failed: \(error.localizedDescription)", category: .app)
            onError?("Failed to load email content")
        }

        func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
            Logger.error("WKWebView provisional navigation failed: \(error.localizedDescription)", category: .app)
            onError?("Failed to load email content")
        }
    }
}
