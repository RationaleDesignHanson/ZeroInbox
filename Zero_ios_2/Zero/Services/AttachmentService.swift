import Foundation
import UIKit

class AttachmentService {
    static let shared = AttachmentService()

    private init() {}

    // MARK: - Attachment Download

    enum AttachmentError: LocalizedError {
        case invalidMessageId
        case invalidAttachmentId
        case downloadFailed
        case noAuthToken
        case networkError(String)

        var errorDescription: String? {
            switch self {
            case .invalidMessageId:
                return "Invalid message ID"
            case .invalidAttachmentId:
                return "Invalid attachment ID"
            case .downloadFailed:
                return "Failed to download attachment"
            case .noAuthToken:
                return "No authentication token available"
            case .networkError(let message):
                return "Network error: \(message)"
            }
        }
    }

    /// Download an attachment from Gmail API
    /// - Parameters:
    ///   - attachment: EmailAttachment model with messageId and attachmentId
    ///   - completion: Returns Data or error
    func downloadAttachment(
        _ attachment: EmailAttachment,
        completion: @escaping (Result<Data, AttachmentError>) -> Void
    ) {
        guard let messageId = attachment.messageId else {
            completion(.failure(.invalidMessageId))
            return
        }

        // Get auth token
        guard let token = UserDefaults.standard.string(forKey: "jwtToken") else {
            Logger.error("No auth token available for attachment download", category: .network)
            completion(.failure(.noAuthToken))
            return
        }

        Logger.info("📎 Downloading attachment: \(attachment.filename) (\(attachment.fileSizeFormatted))", category: .network)

        // Gmail API endpoint for attachment download
        let gatewayURL = "https://emailshortform-gateway-hqdlmnyzrq-uc.a.run.app/api"
        let urlString = "\(gatewayURL)/emails/\(messageId)/attachments/\(attachment.id)"

        guard let url = URL(string: urlString) else {
            completion(.failure(.downloadFailed))
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.timeoutInterval = 60 // Longer timeout for large files

        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                Logger.error("Attachment download failed: \(error.localizedDescription)", category: .network)
                completion(.failure(.networkError(error.localizedDescription)))
                return
            }

            guard let httpResponse = response as? HTTPURLResponse else {
                completion(.failure(.downloadFailed))
                return
            }

            guard (200...299).contains(httpResponse.statusCode) else {
                Logger.error("Attachment download failed with status: \(httpResponse.statusCode)", category: .network)
                completion(.failure(.downloadFailed))
                return
            }

            guard let data = data else {
                completion(.failure(.downloadFailed))
                return
            }

            Logger.info("✅ Downloaded attachment: \(attachment.filename) (\(data.count) bytes)", category: .network)
            completion(.success(data))

        }.resume()
    }

    // MARK: - File Caching

    private var cacheDirectory: URL? {
        FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first?
            .appendingPathComponent("Attachments", isDirectory: true)
    }

    /// Save attachment data to local cache
    func cacheAttachment(_ attachment: EmailAttachment, data: Data) throws {
        guard let cacheDir = cacheDirectory else { return }

        // Create cache directory if needed
        try FileManager.default.createDirectory(at: cacheDir, withIntermediateDirectories: true)

        let fileURL = cacheDir.appendingPathComponent("\(attachment.id)_\(attachment.filename)")
        try data.write(to: fileURL)

        Logger.info("💾 Cached attachment: \(attachment.filename)", category: .app)
    }

    /// Get cached attachment data if available
    func getCachedAttachment(_ attachment: EmailAttachment) -> Data? {
        guard let cacheDir = cacheDirectory else { return nil }

        let fileURL = cacheDir.appendingPathComponent("\(attachment.id)_\(attachment.filename)")

        guard FileManager.default.fileExists(atPath: fileURL.path) else {
            return nil
        }

        return try? Data(contentsOf: fileURL)
    }

    /// Check if attachment is cached
    func isCached(_ attachment: EmailAttachment) -> Bool {
        guard let cacheDir = cacheDirectory else { return false }
        let fileURL = cacheDir.appendingPathComponent("\(attachment.id)_\(attachment.filename)")
        return FileManager.default.fileExists(atPath: fileURL.path)
    }

    /// Clear all cached attachments
    func clearCache() throws {
        guard let cacheDir = cacheDirectory else { return }
        try FileManager.default.removeItem(at: cacheDir)
        Logger.info("🗑️ Cleared attachment cache", category: .app)
    }

    // MARK: - Share/Export

    /// Get a temporary URL for sharing an attachment
    func getShareableURL(for attachment: EmailAttachment, data: Data) throws -> URL {
        let tempDir = FileManager.default.temporaryDirectory
        let fileURL = tempDir.appendingPathComponent(attachment.filename)

        try data.write(to: fileURL)
        return fileURL
    }

    // MARK: - Preview Support

    /// Check if attachment can be previewed in-app
    func canPreview(_ attachment: EmailAttachment) -> Bool {
        // Support PDFs, images, and common document types
        let previewableTypes = [
            "application/pdf",
            "image/jpeg",
            "image/jpg",
            "image/png",
            "image/gif",
            "image/heic",
            "text/plain",
            "application/msword",
            "application/vnd.openxmlformats-officedocument.wordprocessingml.document"
        ]

        return previewableTypes.contains { attachment.mimeType.lowercased().contains($0) }
    }

    /// Convert attachment data to UIImage if it's an image
    func getImage(from data: Data, mimeType: String) -> UIImage? {
        guard mimeType.contains("image") else { return nil }
        return UIImage(data: data)
    }
}
