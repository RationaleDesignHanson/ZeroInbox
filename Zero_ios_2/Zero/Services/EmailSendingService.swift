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

        // Encode body
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
        } catch {
            completion(.failure(EmailError.encodingError(error)))
            return
        }

        Logger.info("Sending email with PDF attachment", category: .network)
        Logger.info("  To: \(finalRecipient)", category: .network)
        Logger.info("  Subject: \(subject)", category: .network)
        Logger.info("  Filename: \(filename)", category: .network)
        Logger.info("  PDF size: \(pdfData.count) bytes", category: .network)
        Logger.info("  Safe Mode: \(SafeModeService.shared.currentMode.rawValue)", category: .network)

        // Send request
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                Logger.error("Email sending failed: \(error.localizedDescription)", category: .network)
                completion(.failure(EmailError.networkError(error)))
                return
            }

            guard let httpResponse = response as? HTTPURLResponse else {
                completion(.failure(EmailError.invalidResponse))
                return
            }

            Logger.info("Email API response status: \(httpResponse.statusCode)", category: .network)

            guard httpResponse.statusCode == 200 else {
                if let data = data, let errorMessage = String(data: data, encoding: .utf8) {
                    Logger.error("Email API error: \(errorMessage)", category: .network)
                }
                completion(.failure(EmailError.serverError(httpResponse.statusCode)))
                return
            }

            guard let data = data else {
                completion(.failure(EmailError.noData))
                return
            }

            // Parse response
            do {
                if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let messageId = json["messageId"] as? String {
                    Logger.info("Email sent successfully! Message ID: \(messageId)", category: .network)
                    completion(.success(messageId))
                } else {
                    completion(.failure(EmailError.invalidResponse))
                }
            } catch {
                completion(.failure(EmailError.decodingError(error)))
            }
        }

        task.resume()
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

        // Encode body
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
        } catch {
            completion(.failure(EmailError.encodingError(error)))
            return
        }

        Logger.info("Sending text email to \(finalRecipient)", category: .network)
        Logger.info("  Safe Mode: \(SafeModeService.shared.currentMode.rawValue)", category: .network)

        // Send request
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                Logger.error("Email sending failed: \(error.localizedDescription)", category: .network)
                completion(.failure(EmailError.networkError(error)))
                return
            }

            guard let httpResponse = response as? HTTPURLResponse else {
                completion(.failure(EmailError.invalidResponse))
                return
            }

            guard httpResponse.statusCode == 200 else {
                completion(.failure(EmailError.serverError(httpResponse.statusCode)))
                return
            }

            guard let data = data else {
                completion(.failure(EmailError.noData))
                return
            }

            // Parse response
            do {
                if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let messageId = json["messageId"] as? String {
                    Logger.info("Email sent successfully! Message ID: \(messageId)", category: .network)
                    completion(.success(messageId))
                } else {
                    completion(.failure(EmailError.invalidResponse))
                }
            } catch {
                completion(.failure(EmailError.decodingError(error)))
            }
        }

        task.resume()
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
