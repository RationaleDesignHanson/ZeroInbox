import Foundation
import AuthenticationServices
#if canImport(UIKit)
import UIKit
#endif

/// API Service for communicating with the EmailShortForm backend
class EmailAPIService: EmailServiceProtocol {

    // MARK: - Configuration

    static let shared = EmailAPIService()

    private let baseURL: String
    private var authToken: String?

    init() {
        self.baseURL = AppEnvironment.current.apiBaseURL
        Logger.info("Using \(AppEnvironment.current.displayName), API Base URL: \(baseURL)", category: .email)
    }

    // MARK: - Authentication

    /// Demo login with password (123456)
    func authenticateDemo(password: String) async throws -> String {
        let url = URL(string: "\(baseURL)/auth/demo")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let body = ["password": password]
        request.httpBody = try JSONEncoder().encode(body)

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.requestFailed
        }

        if httpResponse.statusCode == 401 {
            throw APIError.invalidPassword
        } else if httpResponse.statusCode != 200 {
            throw APIError.requestFailed
        }

        struct DemoAuthResponse: Codable {
            let success: Bool
            let token: String
            let email: String
            let provider: String
            let message: String?
        }

        let authResponse = try JSONDecoder().decode(DemoAuthResponse.self, from: data)

        // Store token
        self.authToken = authResponse.token
        try storeTokenInKeychain(token: authResponse.token, email: authResponse.email)

        return authResponse.email
    }

    /// Initiate Gmail OAuth flow
    func authenticateGmail(presentationAnchor: ASPresentationAnchor) async throws -> String {
        // Step 1: Get auth URL from backend
        let url = URL(string: "\(baseURL)/auth/gmail")!
        let (data, _) = try await URLSession.shared.data(from: url)

        struct AuthResponse: Codable {
            let authUrl: String
        }

        let response = try JSONDecoder().decode(AuthResponse.self, from: data)

        // Step 2: Open OAuth flow and wait for custom scheme callback
        // The backend will redirect to: com.googleusercontent.apps.514014482017-gpsj2233l3dl312j6ek96cglv0agovuq:/oauth?token=...&email=...
        let callbackURL = try await openAuthenticationSession(
            url: URL(string: response.authUrl)!,
            callbackURLScheme: "com.googleusercontent.apps.514014482017-gpsj2233l3dl312j6ek96cglv0agovuq",
            presentationAnchor: presentationAnchor
        )

        // Step 3: Extract token from custom scheme callback
        guard let components = URLComponents(url: callbackURL, resolvingAgainstBaseURL: false),
              let token = components.queryItems?.first(where: { $0.name == "token" })?.value,
              let email = components.queryItems?.first(where: { $0.name == "email" })?.value else {
            throw APIError.invalidCallback
        }

        // Step 4: Store token
        Logger.info("Storing token in memory and Keychain", category: .authentication)
        self.authToken = token
        try storeTokenInKeychain(token: token, email: email)
        Logger.info("Token stored successfully: \(token.prefix(20))...", category: .authentication)

        // DEBUG: Print FULL token to console for testing
        #if DEBUG
        print("\n🔑 FULL JWT TOKEN (copy this):\n\(token)\n")
        #endif

        // DEBUG: Help developers retrieve full JWT easily (clipboard + file)
        #if DEBUG
        #if canImport(UIKit)
        UIPasteboard.general.string = token
        #endif
        do {
            let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
            let out = docs.appendingPathComponent("jwt.txt")
            try token.write(to: out, atomically: true, encoding: .utf8)
            Logger.info("JWT copied to clipboard and written to: \(out.path)", category: .authentication)
        } catch {
            Logger.warning("Failed to write JWT to Documents: \(error.localizedDescription)", category: .authentication)
        }
        #endif

        return email
    }

    /// Authenticate with Microsoft/Outlook
    /// Returns the authenticated email address
    func authenticateMicrosoft(presentationAnchor: ASPresentationAnchor) async throws -> String {
        // Step 1: Get auth URL from backend
        let url = URL(string: "\(baseURL)/auth/microsoft")!
        let (data, _) = try await URLSession.shared.data(from: url)

        struct AuthResponse: Codable {
            let authUrl: String
        }

        let response = try JSONDecoder().decode(AuthResponse.self, from: data)

        // Step 2: Open OAuth flow and wait for custom scheme callback
        // The backend will redirect to: com.zeromail:/oauth?token=...&email=...&provider=outlook
        let callbackURL = try await openAuthenticationSession(
            url: URL(string: response.authUrl)!,
            callbackURLScheme: "com.zeromail",
            presentationAnchor: presentationAnchor
        )

        // Step 3: Extract token from custom scheme callback
        guard let components = URLComponents(url: callbackURL, resolvingAgainstBaseURL: false),
              let token = components.queryItems?.first(where: { $0.name == "token" })?.value,
              let email = components.queryItems?.first(where: { $0.name == "email" })?.value else {
            throw APIError.invalidCallback
        }

        // Step 4: Store token
        Logger.info("Storing Microsoft token in memory and Keychain", category: .authentication)
        self.authToken = token
        try storeTokenInKeychain(token: token, email: email)
        Logger.info("Microsoft token stored successfully: \(token.prefix(20))...", category: .authentication)

        // DEBUG: Print FULL token to console for testing
        #if DEBUG
        print("\n🔑 FULL MICROSOFT JWT TOKEN (copy this):\n\(token)\n")
        #endif

        // DEBUG: Help developers retrieve full JWT easily (clipboard + file)
        #if DEBUG
        #if canImport(UIKit)
        UIPasteboard.general.string = token
        #endif
        do {
            let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
            let out = docs.appendingPathComponent("jwt_microsoft.txt")
            try token.write(to: out, atomically: true, encoding: .utf8)
            Logger.info("Microsoft JWT copied to clipboard and written to: \(out.path)", category: .authentication)
        } catch {
            Logger.warning("Failed to write Microsoft JWT to Documents: \(error.localizedDescription)", category: .authentication)
        }
        #endif

        return email
    }

    /// Open authentication session
    private func openAuthenticationSession(
        url: URL,
        callbackURLScheme: String,
        presentationAnchor: ASPresentationAnchor
    ) async throws -> URL {
        return try await withCheckedThrowingContinuation { continuation in
            let contextProvider = PresentationContextProvider(anchor: presentationAnchor)
            let session = ASWebAuthenticationSession(
                url: url,
                callbackURLScheme: callbackURLScheme
            ) { callbackURL, error in
                if let error = error {
                    continuation.resume(throwing: error)
                } else if let callbackURL = callbackURL {
                    continuation.resume(returning: callbackURL)
                } else {
                    continuation.resume(throwing: APIError.authenticationFailed)
                }
                // Keep contextProvider alive
                _ = contextProvider
            }

            session.presentationContextProvider = contextProvider
            session.prefersEphemeralWebBrowserSession = false
            session.start()
        }
    }

    // MARK: - Emails

    /// Fetch emails from backend
    func fetchEmails(maxResults: Int = 20, timeRange: EmailTimeRange = .twoWeeks) async throws -> [EmailCard] {
        Logger.info("fetchEmails called, attempting to load token", category: .email)

        guard let token = authToken ?? loadTokenFromKeychain() else {
            Logger.error("No token found in memory or Keychain", category: .authentication)
            throw APIError.notAuthenticated
        }

        Logger.info("Token found: \(token.prefix(20))..., building request to: \(baseURL)/emails", category: .email)

        // Build URL with time range filtering
        let urlString = "\(baseURL)/emails?maxResults=\(maxResults)&after=\(timeRange.afterDate)"
        var request = URLRequest(url: URL(string: urlString)!)
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

        Logger.info("Sending request...", category: .email)
        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            Logger.error("Invalid HTTP response", category: .email)
            throw APIError.requestFailed
        }

        Logger.info("Response status: \(httpResponse.statusCode), received \(data.count) bytes", category: .email)

        // Handle 401 Unauthorized - token is expired or invalid
        if httpResponse.statusCode == 401 {
            Logger.error("❌ 401 Unauthorized - JWT token is invalid or expired", category: .authentication)

            // Parse backend error response to extract re-auth message
            struct AuthErrorResponse: Codable {
                let error: String
                let needsReauth: Bool?
                let message: String?
            }

            // Try to get custom message from backend, fallback to generic
            var errorMessage = "Your session has expired. Please sign in again to continue."
            if let errorResponse = try? JSONDecoder().decode(AuthErrorResponse.self, from: data),
               let customMessage = errorResponse.message {
                errorMessage = customMessage
            }

            Logger.error(errorMessage, category: .authentication)

            // Clear stale auth data
            clearAuthentication()

            // Throw error with helpful message (will be shown in UI via APIError.notAuthenticated)
            throw APIError.notAuthenticated
        }

        guard httpResponse.statusCode == 200 else {
            Logger.error("Request failed with status \(httpResponse.statusCode)", category: .email)
            if let responseStr = String(data: data, encoding: .utf8) {
                Logger.error("Response body: \(responseStr)", category: .email)
            }
            throw APIError.requestFailed
        }

        struct EmailsResponse: Codable {
            let emails: [EmailCard]
            let count: Int
            let provider: String
        }

        // Enhanced error logging for JSON decoding
        do {
            let emailsResponse = try JSONDecoder().decode(EmailsResponse.self, from: data)
            Logger.info("Successfully decoded \(emailsResponse.emails.count) emails", category: .email)
            return emailsResponse.emails
        } catch let DecodingError.keyNotFound(key, context) {
            Logger.error("❌ JSON Decoding Error: Missing key '\(key.stringValue)'", category: .email)
            Logger.error("Context: \(context.debugDescription)", category: .email)
            Logger.error("Coding path: \(context.codingPath.map { $0.stringValue }.joined(separator: " -> "))", category: .email)

            if let jsonString = String(data: data, encoding: .utf8) {
                Logger.error("Raw JSON (first 500 chars): \(jsonString.prefix(500))", category: .email)
            }
            throw APIError.requestFailed
        } catch let DecodingError.typeMismatch(type, context) {
            Logger.error("❌ JSON Decoding Error: Type mismatch for type '\(type)'", category: .email)
            Logger.error("Context: \(context.debugDescription)", category: .email)
            Logger.error("Coding path: \(context.codingPath.map { $0.stringValue }.joined(separator: " -> "))", category: .email)

            if let jsonString = String(data: data, encoding: .utf8) {
                Logger.error("Raw JSON (first 500 chars): \(jsonString.prefix(500))", category: .email)
            }
            throw APIError.requestFailed
        } catch let DecodingError.valueNotFound(type, context) {
            Logger.error("❌ JSON Decoding Error: Value not found for type '\(type)'", category: .email)
            Logger.error("Context: \(context.debugDescription)", category: .email)
            Logger.error("Coding path: \(context.codingPath.map { $0.stringValue }.joined(separator: " -> "))", category: .email)

            if let jsonString = String(data: data, encoding: .utf8) {
                Logger.error("Raw JSON (first 500 chars): \(jsonString.prefix(500))", category: .email)
            }
            throw APIError.requestFailed
        } catch let DecodingError.dataCorrupted(context) {
            Logger.error("❌ JSON Decoding Error: Data corrupted", category: .email)
            Logger.error("Context: \(context.debugDescription)", category: .email)
            Logger.error("Coding path: \(context.codingPath.map { $0.stringValue }.joined(separator: " -> "))", category: .email)
            Logger.error("Data size: \(data.count) bytes", category: .email)

            // Try to decode with lossy UTF-8 to see if there are encoding issues
            if let jsonString = String(data: data, encoding: .utf8) {
                Logger.error("✅ UTF-8 decode succeeded: \(jsonString.count) characters", category: .email)
                Logger.error("Raw JSON (first 500 chars): \(jsonString.prefix(500))", category: .email)
                Logger.error("Raw JSON (last 100 chars): \(jsonString.suffix(100))", category: .email)

                // Save response to file for debugging
                do {
                    let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
                    let debugFile = docs.appendingPathComponent("failed_response.json")
                    try data.write(to: debugFile)
                    Logger.error("💾 Saved failed response to: \(debugFile.path)", category: .email)
                } catch {
                    Logger.error("Failed to save debug file: \(error.localizedDescription)", category: .email)
                }

                // Try to parse manually to find where it fails
                do {
                    _ = try JSONSerialization.jsonObject(with: data, options: [])
                    Logger.error("❌ WEIRD: JSONSerialization succeeded but JSONDecoder failed!", category: .email)
                } catch {
                    Logger.error("❌ JSONSerialization also failed: \(error.localizedDescription)", category: .email)
                }
            } else {
                Logger.error("❌ Failed to convert data to UTF-8 string - ENCODING ISSUE", category: .email)
            }
            throw APIError.requestFailed
        } catch {
            Logger.error("❌ Unknown JSON Decoding Error: \(error.localizedDescription)", category: .email)

            if let jsonString = String(data: data, encoding: .utf8) {
                Logger.error("Raw JSON (first 500 chars): \(jsonString.prefix(500))", category: .email)
            }
            throw error
        }
    }

    /// Fetch single email
    func fetchEmail(id: String) async throws -> EmailCard {
        guard let token = authToken ?? loadTokenFromKeychain() else {
            throw APIError.notAuthenticated
        }

        var request = URLRequest(url: URL(string: "\(baseURL)/emails/\(id)")!)
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

        let (data, _) = try await URLSession.shared.data(for: request)
        return try JSONDecoder().decode(EmailCard.self, from: data)
    }

    /// Fetch thread for a specific email (on-demand)
    func fetchThread(emailId: String) async throws -> ThreadData {
        guard let token = authToken ?? loadTokenFromKeychain() else {
            throw APIError.notAuthenticated
        }

        Logger.info("Fetching thread for email: \(emailId)", category: .email)

        let url = URL(string: "\(baseURL)/emails/\(emailId)/thread")!
        var request = URLRequest(url: url)
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

        Logger.info("Thread request URL: \(url.absoluteString)", category: .email)

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            Logger.error("Invalid HTTP response for thread", category: .email)
            throw APIError.requestFailed
        }

        Logger.info("Thread response status: \(httpResponse.statusCode)", category: .email)

        guard httpResponse.statusCode == 200 else {
            if let responseText = String(data: data, encoding: .utf8) {
                Logger.error("Thread fetch failed (\(httpResponse.statusCode)): \(responseText)", category: .email)
            } else {
                Logger.error("Thread fetch failed with status \(httpResponse.statusCode)", category: .email)
            }
            throw APIError.requestFailed
        }

        let threadData = try JSONDecoder().decode(ThreadData.self, from: data)
        Logger.info("Thread fetched successfully: \(threadData.messageCount) messages", category: .email)

        return threadData
    }

    /// Perform action on email (archive, delete, mark as read)
    func performAction(emailId: String, action: EmailBasicAction) async throws {
        guard let token = authToken ?? loadTokenFromKeychain() else {
            throw APIError.notAuthenticated
        }

        var request = URLRequest(url: URL(string: "\(baseURL)/emails/\(emailId)/action")!)
        request.httpMethod = "POST"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let body = ["action": action.rawValue]
        request.httpBody = try JSONEncoder().encode(body)

        let (_, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw APIError.actionFailed
        }
    }

    /// Search emails
    func searchEmails(query: String, sender: String? = nil, limit: Int = 50) async throws -> [SearchResult] {
        guard let token = authToken ?? loadTokenFromKeychain() else {
            throw APIError.notAuthenticated
        }

        var urlComponents = URLComponents(string: "\(baseURL)/emails/search")!
        var queryItems = [URLQueryItem(name: "q", value: query)]
        if let sender = sender {
            queryItems.append(URLQueryItem(name: "sender", value: sender))
        }
        queryItems.append(URLQueryItem(name: "limit", value: "\(limit)"))
        urlComponents.queryItems = queryItems

        guard let url = urlComponents.url else {
            throw APIError.requestFailed
        }

        var request = URLRequest(url: url)
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw APIError.requestFailed
        }

        struct SearchResponse: Codable {
            let results: [SearchResult]
            let totalCount: Int
            let hasMore: Bool
        }

        let searchResponse = try JSONDecoder().decode(SearchResponse.self, from: data)
        return searchResponse.results
    }

    /// Fetch smart reply suggestions for an email
    func fetchSmartReplies(emailId: String) async throws -> [String] {
        guard let token = authToken ?? loadTokenFromKeychain() else {
            throw APIError.notAuthenticated
        }

        var request = URLRequest(url: URL(string: "\(baseURL)/emails/\(emailId)/smart-replies")!)
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw APIError.requestFailed
        }

        struct SmartRepliesResponse: Codable {
            let replies: [String]
        }

        let repliesResponse = try JSONDecoder().decode(SmartRepliesResponse.self, from: data)
        return repliesResponse.replies
    }

    /// Log smart reply feedback
    func logSmartReplyFeedback(
        emailId: String,
        replyIndex: Int,
        action: String,
        originalReply: String,
        finalReply: String?
    ) async throws {
        guard let token = authToken ?? loadTokenFromKeychain() else {
            throw APIError.notAuthenticated
        }

        var request = URLRequest(url: URL(string: "\(baseURL)/emails/\(emailId)/smart-replies/feedback")!)
        request.httpMethod = "POST"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let body: [String: Any] = [
            "replyIndex": replyIndex,
            "action": action,
            "originalReply": originalReply,
            "finalReply": finalReply ?? originalReply
        ]

        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (_, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw APIError.requestFailed
        }
    }

    /// Generate AI reply for email
    func generateReply(emailId: String) async throws -> String {
        guard let token = authToken ?? loadTokenFromKeychain() else {
            throw APIError.notAuthenticated
        }

        var request = URLRequest(url: URL(string: "\(baseURL)/emails/\(emailId)/reply")!)
        request.httpMethod = "POST"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let body = ["useAI": true]
        request.httpBody = try JSONEncoder().encode(body)

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.requestFailed
        }

        // Log response for debugging
        if let responseStr = String(data: data, encoding: .utf8) {
            Logger.info("Send reply response: \(responseStr)", category: .email)
        }

        guard httpResponse.statusCode == 200 else {
            Logger.error("Failed to send reply, status: \(httpResponse.statusCode)", category: .email)
            throw APIError.requestFailed
        }

        struct ReplyResponse: Codable {
            let success: Bool
            let reply: String?
            let message: String?
        }

        let decodedResponse = try JSONDecoder().decode(ReplyResponse.self, from: data)
        return decodedResponse.reply ?? decodedResponse.message ?? "Reply sent successfully"
    }

    // MARK: - Keychain Management

    private func storeTokenInKeychain(token: String, email: String) throws {
        Logger.info("Storing token for email: \(email)", category: .authentication)
        let data = token.data(using: .utf8)!

        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: email,
            kSecAttrService as String: "EmailShortForm",
            kSecValueData as String: data
        ]

        // Delete existing item
        SecItemDelete(query as CFDictionary)

        // Add new item
        let status = SecItemAdd(query as CFDictionary, nil)
        guard status == errSecSuccess else {
            Logger.error("Failed to store token, status: \(status)", category: .authentication)
            throw APIError.keychainError
        }
        Logger.info("Token stored successfully in Keychain", category: .authentication)
    }

    func loadTokenFromKeychain() -> String? {
        Logger.info("Loading token from Keychain", category: .authentication)
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: "EmailShortForm",
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)

        guard status == errSecSuccess,
              let data = result as? Data,
              let token = String(data: data, encoding: .utf8) else {
            Logger.warning("Failed to load token from Keychain, status: \(status)", category: .authentication)
            return nil
        }

        Logger.info("Token loaded successfully from Keychain: \(token.prefix(20))...", category: .authentication)
        return token
    }

    func clearAuthentication() {
        authToken = nil

        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: "EmailShortForm"
        ]

        SecItemDelete(query as CFDictionary)
    }
}

// MARK: - Supporting Types

enum EmailBasicAction: String, Codable {
    case archive
    case delete
    case markRead
}

enum APIError: LocalizedError {
    case notAuthenticated
    case requestFailed
    case authenticationFailed
    case invalidCallback
    case keychainError
    case actionFailed
    case invalidPassword

    var errorDescription: String? {
        switch self {
        case .notAuthenticated:
            return "Your session has expired. Please sign in again to continue."
        case .requestFailed:
            return "Request failed. Please try again."
        case .authenticationFailed:
            return "Authentication failed."
        case .invalidCallback:
            return "Invalid authentication callback."
        case .keychainError:
            return "Failed to store credentials securely."
        case .actionFailed:
            return "Failed to perform action."
        case .invalidPassword:
            return "Invalid password. Try 123456."
        }
    }
}

// MARK: - Presentation Context Provider

class PresentationContextProvider: NSObject, ASWebAuthenticationPresentationContextProviding {
    private let anchor: ASPresentationAnchor

    nonisolated init(anchor: ASPresentationAnchor) {
        self.anchor = anchor
        super.init()
    }

    nonisolated func presentationAnchor(for session: ASWebAuthenticationSession) -> ASPresentationAnchor {
        return anchor
    }
}
