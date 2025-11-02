import Foundation
import AuthenticationServices

/// Protocol defining email service operations
/// Enables dependency injection and testing with mock implementations
protocol EmailServiceProtocol {
    
    // MARK: - Authentication
    
    /// Demo login with password
    func authenticateDemo(password: String) async throws -> String
    
    /// Initiate Gmail OAuth flow
    func authenticateGmail(presentationAnchor: ASPresentationAnchor) async throws -> String

    /// Initiate Microsoft/Outlook OAuth flow
    func authenticateMicrosoft(presentationAnchor: ASPresentationAnchor) async throws -> String

    /// Clear authentication tokens
    func clearAuthentication()
    
    // MARK: - Email Operations
    
    /// Fetch emails from backend
    func fetchEmails(maxResults: Int, timeRange: EmailTimeRange) async throws -> [EmailCard]
    
    /// Fetch single email by ID
    func fetchEmail(id: String) async throws -> EmailCard
    
    /// Fetch thread for a specific email (on-demand)
    func fetchThread(emailId: String) async throws -> ThreadData
    
    /// Perform action on email (archive, delete, mark as read)
    func performAction(emailId: String, action: EmailBasicAction) async throws
    
    // MARK: - Search
    
    /// Search emails
    func searchEmails(query: String, sender: String?, limit: Int) async throws -> [SearchResult]
    
    // MARK: - Smart Replies
    
    /// Fetch smart reply suggestions for an email
    func fetchSmartReplies(emailId: String) async throws -> [String]
    
    /// Log smart reply feedback
    func logSmartReplyFeedback(
        emailId: String,
        replyIndex: Int,
        action: String,
        originalReply: String,
        finalReply: String?
    ) async throws
    
    /// Generate AI reply for email
    func generateReply(emailId: String) async throws -> String
}

// MARK: - Default Implementation for Optional Parameters

extension EmailServiceProtocol {
    func fetchEmails(maxResults: Int = 20, timeRange: EmailTimeRange = .twoWeeks) async throws -> [EmailCard] {
        return try await fetchEmails(maxResults: maxResults, timeRange: timeRange)
    }
    
    func searchEmails(query: String, sender: String? = nil, limit: Int = 50) async throws -> [SearchResult] {
        return try await searchEmails(query: query, sender: sender, limit: limit)
    }
}

