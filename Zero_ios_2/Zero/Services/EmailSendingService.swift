import Foundation
import UIKit

/// Service for sending emails programmatically via backend
class EmailSendingService {

    static let shared = EmailSendingService()

    private init() {}

    /// Send email with PDF attachment
    func sendEmailWithAttachment(
        to recipient: String,
        subject: String,
        body: String,
        pdfData: Data,
        filename: String,
        threadId: String? = nil,
        completion: @escaping (Result<String, Error>) -> Void
    ) {

        // ⚠️ SAFE MODE CHECK - Intercept email before sending
        let safeMode = SafeModeService.shared.processOutgoingEmail(
            to: recipient,
            subject: subject,
            body: body,
            hasAttachment: true
        )

        // If in read-only mode, simulate success without sending
        if !safeMode.shouldSend {
            Logger.info("✅ [READ-ONLY] Simulated email send success", category: .network)
            let simulatedMessageId = "simulated-\(UUID().uuidString)"
            SafeModeService.shared.blockedEmailCount += 1
            completion(.success(simulatedMessageId))
            return
        }

        // Use modified recipient if in demo mode
        let finalRecipient = safeMode.modifiedRecipient ?? recipient

        // Log warning if email was redirected
        if let warning = safeMode.warningMessage {
            Logger.warning(warning, category: .network)
            SafeModeService.shared.redirectedEmailCount += 1
        }

        // Get API configuration
        let baseURL = AppEnvironment.current.apiBaseURL

        // Construct endpoint
        guard let url = URL(string: "\(baseURL)/api/gmail/messages/send") else {
            completion(.failure(EmailError.invalidURL))
            return
        }

        // Encode PDF to base64
        let pdfBase64 = pdfData.base64EncodedString()

        // Create request body (using final recipient after safe mode processing)
        let requestBody: [String: Any] = [
            "to": finalRecipient,
            "subject": subject,
            "body": body,
            "attachment": [
                "data": pdfBase64,
                "filename": filename
            ]
        ]

        if let threadId = threadId {
            var mutableBody = requestBody
            mutableBody["threadId"] = threadId
        }

        // Create request
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        // Add auth headers if available
        if let accessToken = UserDefaults.standard.string(forKey: "accessToken") {
            request.setValue(accessToken, forHTTPHeaderField: "x-access-token")
        }
        if let refreshToken = UserDefaults.standard.string(forKey: "refreshToken") {
            request.setValue(refreshToken, forHTTPHeaderField: "x-refresh-token")
        }

        Logger.info("Sending email with PDF attachment", category: .network)
        Logger.info("  To: \(finalRecipient)", category: .network)
        Logger.info("  Subject: \(subject)", category: .network)
        Logger.info("  Filename: \(filename)", category: .network)
        Logger.info("  PDF size: \(pdfData.count) bytes", category: .network)
        Logger.info("  Safe Mode: \(SafeModeService.shared.currentMode.rawValue)", category: .network)

        // Week 6 Service Layer Cleanup: Using centralized NetworkService
        Task {
            do {
                let messageId = try await sendEmailWithAttachmentAsync(
                    to: finalRecipient,
                    subject: subject,
                    body: body,
                    pdfData: pdfData,
                    filename: filename,
                    threadId: threadId
                )
                completion(.success(messageId))
            } catch {
                completion(.failure(error))
            }
        }
    }

    /// Async version of sendEmailWithAttachment
    private func sendEmailWithAttachmentAsync(
        to recipient: String,
        subject: String,
        body: String,
        pdfData: Data,
        filename: String,
        threadId: String?
    ) async throws -> String {
        // Week 6 Service Layer Cleanup: Using centralized NetworkService
        let baseURL = AppEnvironment.current.apiBaseURL

        guard let url = URL(string: "\(baseURL)/api/gmail/messages/send") else {
            throw EmailError.invalidURL
        }

        // Encode PDF to base64
        let pdfBase64 = pdfData.base64EncodedString()

        struct SendEmailRequest: Codable {
            let to: String
            let subject: String
            let body: String
            let attachment: Attachment
            let threadId: String?

            struct Attachment: Codable {
                let data: String
                let filename: String
            }
        }

        struct SendEmailResponse: Codable {
            let messageId: String
        }

        let requestBody = SendEmailRequest(
            to: recipient,
            subject: subject,
            body: body,
            attachment: SendEmailRequest.Attachment(data: pdfBase64, filename: filename),
            threadId: threadId
        )

        var headers: [String: String] = [:]
        if let accessToken = UserDefaults.standard.string(forKey: "accessToken") {
            headers["x-access-token"] = accessToken
        }
        if let refreshToken = UserDefaults.standard.string(forKey: "refreshToken") {
            headers["x-refresh-token"] = refreshToken
        }

        do {
            let response: SendEmailResponse = try await NetworkService.shared.request(
                url: url,
                method: .post,
                headers: headers,
                body: requestBody
            )

            Logger.info("Email sent successfully! Message ID: \(response.messageId)", category: .network)
            return response.messageId
        } catch let error as NetworkServiceError {
            if let statusCode = error.statusCode {
                Logger.error("Email API error: \(statusCode)", category: .network)
                throw EmailError.serverError(statusCode)
            }
            throw EmailError.invalidResponse
        }
    }

    /// Send simple text email without attachment
    func sendEmail(
        to recipient: String,
        subject: String,
        body: String,
        threadId: String? = nil,
        completion: @escaping (Result<String, Error>) -> Void
    ) {
        // ⚠️ SAFE MODE CHECK - Intercept email before sending
        let safeMode = SafeModeService.shared.processOutgoingEmail(
            to: recipient,
            subject: subject,
            body: body,
            hasAttachment: false
        )

        // If in read-only mode, simulate success without sending
        if !safeMode.shouldSend {
            Logger.info("✅ [READ-ONLY] Simulated email send success", category: .network)
            let simulatedMessageId = "simulated-\(UUID().uuidString)"
            SafeModeService.shared.blockedEmailCount += 1
            completion(.success(simulatedMessageId))
            return
        }

        // Use modified recipient if in demo mode
        let finalRecipient = safeMode.modifiedRecipient ?? recipient

        // Log warning if email was redirected
        if let warning = safeMode.warningMessage {
            Logger.warning(warning, category: .network)
            SafeModeService.shared.redirectedEmailCount += 1
        }

        // Get API configuration
        let baseURL = AppEnvironment.current.apiBaseURL

        // Construct endpoint
        guard let url = URL(string: "\(baseURL)/api/gmail/messages/send") else {
            completion(.failure(EmailError.invalidURL))
            return
        }

        // Create request body (using final recipient after safe mode processing)
        var requestBody: [String: Any] = [
            "to": finalRecipient,
            "subject": subject,
            "body": body
        ]

        if let threadId = threadId {
            requestBody["threadId"] = threadId
        }

        // Create request
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        // Add auth headers if available
        if let accessToken = UserDefaults.standard.string(forKey: "accessToken") {
            request.setValue(accessToken, forHTTPHeaderField: "x-access-token")
        }
        if let refreshToken = UserDefaults.standard.string(forKey: "refreshToken") {
            request.setValue(refreshToken, forHTTPHeaderField: "x-refresh-token")
        }

        Logger.info("Sending text email to \(finalRecipient)", category: .network)
        Logger.info("  Safe Mode: \(SafeModeService.shared.currentMode.rawValue)", category: .network)

        // Week 6 Service Layer Cleanup: Using centralized NetworkService
        Task {
            do {
                let messageId = try await sendEmailAsync(
                    to: finalRecipient,
                    subject: subject,
                    body: body,
                    threadId: threadId
                )
                completion(.success(messageId))
            } catch {
                completion(.failure(error))
            }
        }
    }

    /// Async version of sendEmail
    private func sendEmailAsync(
        to recipient: String,
        subject: String,
        body: String,
        threadId: String?
    ) async throws -> String {
        // Week 6 Service Layer Cleanup: Using centralized NetworkService
        let baseURL = AppEnvironment.current.apiBaseURL

        guard let url = URL(string: "\(baseURL)/api/gmail/messages/send") else {
            throw EmailError.invalidURL
        }

        struct SendEmailRequest: Codable {
            let to: String
            let subject: String
            let body: String
            let threadId: String?
        }

        struct SendEmailResponse: Codable {
            let messageId: String
        }

        let requestBody = SendEmailRequest(
            to: recipient,
            subject: subject,
            body: body,
            threadId: threadId
        )

        var headers: [String: String] = [:]
        if let accessToken = UserDefaults.standard.string(forKey: "accessToken") {
            headers["x-access-token"] = accessToken
        }
        if let refreshToken = UserDefaults.standard.string(forKey: "refreshToken") {
            headers["x-refresh-token"] = refreshToken
        }

        do {
            let response: SendEmailResponse = try await NetworkService.shared.request(
                url: url,
                method: .post,
                headers: headers,
                body: requestBody
            )

            Logger.info("Email sent successfully! Message ID: \(response.messageId)", category: .network)
            return response.messageId
        } catch let error as NetworkServiceError {
            if let statusCode = error.statusCode {
                throw EmailError.serverError(statusCode)
            }
            throw EmailError.invalidResponse
        }
    }
}

// MARK: - Email Errors

enum EmailError: LocalizedError {
    case missingConfiguration
    case invalidURL
    case encodingError(Error)
    case networkError(Error)
    case invalidResponse
    case serverError(Int)
    case noData
    case decodingError(Error)

    var errorDescription: String? {
        switch self {
        case .missingConfiguration:
            return "Email service is not configured"
        case .invalidURL:
            return "Invalid email service URL"
        case .encodingError(let error):
            return "Failed to encode email data: \(error.localizedDescription)"
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        case .invalidResponse:
            return "Invalid response from email service"
        case .serverError(let code):
            return "Server error: \(code)"
        case .noData:
            return "No data received from email service"
        case .decodingError(let error):
            return "Failed to decode response: \(error.localizedDescription)"
        }
    }
}
