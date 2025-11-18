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
        // Week 6 Service Layer Cleanup: Using centralized NetworkService
        let url = URL(string: "\(baseURL)/auth/demo")!

        struct DemoAuthRequest: Codable {
            let password: String
        }

        struct DemoAuthResponse: Codable {
            let success: Bool
            let token: String
            let email: String
            let provider: String
            let message: String?
        }

        let requestBody = DemoAuthRequest(password: password)

        do {
            let authResponse: DemoAuthResponse = try await NetworkService.shared.post(
                url: url,
                body: requestBody
            )

            // Store token
            self.authToken = authResponse.token
            try storeTokenInKeychain(token: authResponse.token, email: authResponse.email)

            return authResponse.email
        } catch let error as NetworkServiceError {
            if let statusCode = error.statusCode, statusCode == 401 {
                throw APIError.invalidPassword
            }
            throw APIError.requestFailed
        }
    }

    /// Initiate Gmail OAuth flow
    func authenticateGmail(presentationAnchor: ASPresentationAnchor) async throws -> String {
        // Week 6 Service Layer Cleanup: Using centralized NetworkService
        // Step 1: Get auth URL from backend
        let url = URL(string: "\(baseURL)/auth/gmail")!

        struct AuthResponse: Codable {
            let authUrl: String
        }

        let response: AuthResponse = try await NetworkService.shared.get(url: url)

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
        // Week 6 Service Layer Cleanup: Using centralized NetworkService
        // Step 1: Get auth URL from backend
        let url = URL(string: "\(baseURL)/auth/microsoft")!

        struct AuthResponse: Codable {
            let authUrl: String
        }

        let response: AuthResponse = try await NetworkService.shared.get(url: url)

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

        // Week 6 Service Layer Cleanup: Using centralized NetworkService
        // Build URL with time range filtering
        let urlString = "\(baseURL)/emails?maxResults=\(maxResults)&after=\(timeRange.afterDate)"
        guard let url = URL(string: urlString) else {
            Logger.error("Invalid URL", category: .email)
            throw APIError.requestFailed
        }

        Logger.info("Sending request...", category: .email)

        struct EmailsResponse: Codable {
            let emails: [EmailCard]
            let count: Int
            let provider: String
        }

        do {
            let emailsResponse: EmailsResponse = try await NetworkService.shared.request(
                url: url,
                method: .get,
                headers: ["Authorization": "Bearer \(token)"],
                body: Optional<String>.none
            )

            Logger.info("Successfully decoded \(emailsResponse.emails.count) emails", category: .email)
            return emailsResponse.emails
        } catch let error as NetworkServiceError {
            if let statusCode = error.statusCode {
                Logger.info("Response status: \(statusCode)", category: .email)

                if statusCode == 401 {
                    Logger.error("❌ 401 Unauthorized - JWT token is invalid or expired", category: .authentication)
                    Logger.error("Your session has expired. Please sign in again to continue.", category: .authentication)

                    // Clear stale auth data
                    clearAuthentication()

                    // Throw error with helpful message (will be shown in UI via APIError.notAuthenticated)
                    throw APIError.notAuthenticated
                }

                Logger.error("Request failed with status \(statusCode)", category: .email)
            }
            throw APIError.requestFailed
        } catch let DecodingError.keyNotFound(key, context) {
            Logger.error("❌ JSON Decoding Error: Missing key '\(key.stringValue)'", category: .email)
            Logger.error("Context: \(context.debugDescription)", category: .email)
            Logger.error("Coding path: \(context.codingPath.map { $0.stringValue }.joined(separator: " -> "))", category: .email)
            throw APIError.requestFailed
        } catch let DecodingError.typeMismatch(type, context) {
            Logger.error("❌ JSON Decoding Error: Type mismatch for type '\(type)'", category: .email)
            Logger.error("Context: \(context.debugDescription)", category: .email)
            Logger.error("Coding path: \(context.codingPath.map { $0.stringValue }.joined(separator: " -> "))", category: .email)
            throw APIError.requestFailed
        } catch let DecodingError.valueNotFound(type, context) {
            Logger.error("❌ JSON Decoding Error: Value not found for type '\(type)'", category: .email)
            Logger.error("Context: \(context.debugDescription)", category: .email)
            Logger.error("Coding path: \(context.codingPath.map { $0.stringValue }.joined(separator: " -> "))", category: .email)
            throw APIError.requestFailed
        } catch let DecodingError.dataCorrupted(context) {
            Logger.error("❌ JSON Decoding Error: Data corrupted", category: .email)
            Logger.error("Context: \(context.debugDescription)", category: .email)
            Logger.error("Coding path: \(context.codingPath.map { $0.stringValue }.joined(separator: " -> "))", category: .email)
            throw APIError.requestFailed
        } catch {
            Logger.error("❌ Unknown JSON Decoding Error: \(error.localizedDescription)", category: .email)
            throw error
        }
    }

    /// Fetch single email
    func fetchEmail(id: String) async throws -> EmailCard {
        // Week 6 Service Layer Cleanup: Using centralized NetworkService
        guard let token = authToken ?? loadTokenFromKeychain() else {
            throw APIError.notAuthenticated
        }

        guard let url = URL(string: "\(baseURL)/emails/\(id)") else {
            throw APIError.requestFailed
        }

        return try await NetworkService.shared.request(
            url: url,
            method: .get,
            headers: ["Authorization": "Bearer \(token)"],
            body: Optional<String>.none
        )
    }

    /// Fetch thread for a specific email (on-demand)
    func fetchThread(emailId: String) async throws -> ThreadData {
        // Week 6 Service Layer Cleanup: Using centralized NetworkService
        guard let token = authToken ?? loadTokenFromKeychain() else {
            throw APIError.notAuthenticated
        }

        Logger.info("Fetching thread for email: \(emailId)", category: .email)

        guard let url = URL(string: "\(baseURL)/emails/\(emailId)/thread") else {
            throw APIError.requestFailed
        }

        Logger.info("Thread request URL: \(url.absoluteString)", category: .email)

        do {
            let threadData: ThreadData = try await NetworkService.shared.request(
                url: url,
                method: .get,
                headers: ["Authorization": "Bearer \(token)"],
                body: Optional<String>.none
            )

            Logger.info("Thread fetched successfully: \(threadData.messageCount) messages", category: .email)
            return threadData
        } catch let error as NetworkServiceError {
            if let statusCode = error.statusCode {
                Logger.error("Thread fetch failed with status \(statusCode)", category: .email)
            }
            throw APIError.requestFailed
        }
    }

    /// Perform action on email (archive, delete, mark as read)
    func performAction(emailId: String, action: EmailBasicAction) async throws {
        // Week 6 Service Layer Cleanup: Using centralized NetworkService
        guard let token = authToken ?? loadTokenFromKeychain() else {
            throw APIError.notAuthenticated
        }

        guard let url = URL(string: "\(baseURL)/emails/\(emailId)/action") else {
            throw APIError.requestFailed
        }

        struct PerformActionRequest: Codable {
            let action: String
        }

        let requestBody = PerformActionRequest(action: action.rawValue)

        do {
            let _: EmptyResponse = try await NetworkService.shared.request(
                url: url,
                method: .post,
                headers: ["Authorization": "Bearer \(token)"],
                body: requestBody
            )
        } catch {
            throw APIError.actionFailed
        }
    }

    // Helper type for endpoints that return no content
    private struct EmptyResponse: Codable {}

    /// Search emails
    func searchEmails(query: String, sender: String? = nil, limit: Int = 50) async throws -> [SearchResult] {
        // Week 6 Service Layer Cleanup: Using centralized NetworkService
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

        struct SearchResponse: Codable {
            let results: [SearchResult]
            let totalCount: Int
            let hasMore: Bool
        }

        let searchResponse: SearchResponse = try await NetworkService.shared.request(
            url: url,
            method: .get,
            headers: ["Authorization": "Bearer \(token)"],
            body: Optional<String>.none
        )

        return searchResponse.results
    }

    /// Fetch smart reply suggestions for an email
    func fetchSmartReplies(emailId: String) async throws -> [String] {
        // Week 6 Service Layer Cleanup: Using centralized NetworkService
        guard let token = authToken ?? loadTokenFromKeychain() else {
            throw APIError.notAuthenticated
        }

        guard let url = URL(string: "\(baseURL)/emails/\(emailId)/smart-replies") else {
            throw APIError.requestFailed
        }

        struct SmartRepliesResponse: Codable {
            let replies: [String]
        }

        let repliesResponse: SmartRepliesResponse = try await NetworkService.shared.request(
            url: url,
            method: .get,
            headers: ["Authorization": "Bearer \(token)"],
            body: Optional<String>.none
        )

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
        // Week 6 Service Layer Cleanup: Using centralized NetworkService
        guard let token = authToken ?? loadTokenFromKeychain() else {
            throw APIError.notAuthenticated
        }

        guard let url = URL(string: "\(baseURL)/emails/\(emailId)/smart-replies/feedback") else {
            throw APIError.requestFailed
        }

        struct SmartReplyFeedbackRequest: Codable {
            let replyIndex: Int
            let action: String
            let originalReply: String
            let finalReply: String
        }

        let requestBody = SmartReplyFeedbackRequest(
            replyIndex: replyIndex,
            action: action,
            originalReply: originalReply,
            finalReply: finalReply ?? originalReply
        )

        let _: EmptyResponse = try await NetworkService.shared.request(
            url: url,
            method: .post,
            headers: ["Authorization": "Bearer \(token)"],
            body: requestBody
        )
    }

    /// Generate AI reply for email
    func generateReply(emailId: String) async throws -> String {
        // Week 6 Service Layer Cleanup: Using centralized NetworkService
        guard let token = authToken ?? loadTokenFromKeychain() else {
            throw APIError.notAuthenticated
        }

        guard let url = URL(string: "\(baseURL)/emails/\(emailId)/reply") else {
            throw APIError.requestFailed
        }

        struct GenerateReplyRequest: Codable {
            let useAI: Bool
        }

        struct ReplyResponse: Codable {
            let success: Bool
            let reply: String?
            let message: String?
        }

        let requestBody = GenerateReplyRequest(useAI: true)

        do {
            let decodedResponse: ReplyResponse = try await NetworkService.shared.request(
                url: url,
                method: .post,
                headers: ["Authorization": "Bearer \(token)"],
                body: requestBody
            )

            return decodedResponse.reply ?? decodedResponse.message ?? "Reply sent successfully"
        } catch let error as NetworkServiceError {
            if let statusCode = error.statusCode {
                Logger.error("Failed to send reply, status: \(statusCode)", category: .email)
            }
            throw APIError.requestFailed
        }
    }

    // MARK: - Keychain Management

    func storeTokenInKeychain(token: String, email: String) throws {
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
