//
//  SavedMailService.swift
//  Zero
//
//  Created by Claude Code on 10/25/25.
//

import Foundation
import Combine

/**
 * SavedMailService - Manages user-created email folders
 *
 * Handles API communication for creating, updating, and managing
 * custom folders that users create to save important emails.
 */
@MainActor
class SavedMailService: ObservableObject {
    static let shared: SavedMailService = {
        let instance = SavedMailService()
        instance.loadFoldersFromCache()
        return instance
    }()

    @Published var folders: [SavedMailFolder] = []
    @Published var isLoading = false
    @Published var error: String?

    private let baseURL: String
    private var cancellables = Set<AnyCancellable>()

    nonisolated private init() {
        // Use gateway URL based on current environment
        #if DEBUG
        self.baseURL = "\(Constants.API.Development.gatewayBaseURL)/saved-mail"
        #else
        self.baseURL = "\(Constants.API.Production.gatewayBaseURL)/saved-mail"
        #endif
    }

    // MARK: - Folder Operations

    /// Fetch all folders for the current user
    func fetchFolders(userId: String) async throws -> [SavedMailFolder] {
        // Week 6 Service Layer Cleanup: Using centralized NetworkService
        isLoading = true
        defer { isLoading = false }

        guard var urlComponents = URLComponents(string: "\(baseURL)/folders") else {
            throw SavedMailError.invalidURL
        }

        urlComponents.queryItems = [
            URLQueryItem(name: "userId", value: userId)
        ]

        guard let url = urlComponents.url else {
            throw SavedMailError.invalidURL
        }

        do {
            let folderResponse: GetFoldersResponse = try await NetworkService.shared.get(url: url)

            guard folderResponse.success else {
                throw SavedMailError.serverError("Failed to fetch folders")
            }

            // Update local cache
            self.folders = folderResponse.folders
            self.saveFoldersToCache()

            Logger.info("✅ Fetched \(folderResponse.folders.count) folders", category: .savedMail)

            return folderResponse.folders
        } catch let error as NetworkServiceError {
            if let statusCode = error.statusCode {
                throw SavedMailError.httpError(statusCode: statusCode)
            }
            throw SavedMailError.invalidResponse
        }
    }

    /// Create a new folder
    func createFolder(userId: String, name: String, color: String?) async throws -> SavedMailFolder {
        // Week 6 Service Layer Cleanup: Using centralized NetworkService
        isLoading = true
        defer { isLoading = false }

        guard let url = URL(string: "\(baseURL)/folders") else {
            throw SavedMailError.invalidURL
        }

        struct CreateFolderRequest: Codable {
            let userId: String
            let name: String
            let color: String
        }

        let requestBody = CreateFolderRequest(
            userId: userId,
            name: name,
            color: color ?? SavedMailFolder.randomColor()
        )

        do {
            let folderResponse: CreateFolderResponse = try await NetworkService.shared.post(
                url: url,
                body: requestBody
            )

            guard folderResponse.success, let folder = folderResponse.folder else {
                throw SavedMailError.serverError(folderResponse.error ?? "Unknown error")
            }

            // Update local cache
            self.folders.append(folder)
            self.saveFoldersToCache()

            Logger.info("✅ Created folder: \(name)", category: .savedMail)

            return folder
        } catch let error as NetworkServiceError {
            if let statusCode = error.statusCode {
                throw SavedMailError.httpError(statusCode: statusCode)
            }
            throw SavedMailError.invalidResponse
        }
    }

    /// Update a folder (rename or recolor)
    func updateFolder(userId: String, folderId: String, name: String?, color: String?) async throws -> SavedMailFolder {
        // Week 6 Service Layer Cleanup: Using centralized NetworkService
        isLoading = true
        defer { isLoading = false }

        guard let url = URL(string: "\(baseURL)/folders/\(folderId)") else {
            throw SavedMailError.invalidURL
        }

        struct UpdateFolderRequest: Codable {
            let userId: String
            let name: String?
            let color: String?
        }

        let requestBody = UpdateFolderRequest(
            userId: userId,
            name: name,
            color: color
        )

        do {
            let folderResponse: UpdateFolderResponse = try await NetworkService.shared.request(
                url: url,
                method: .patch,
                body: requestBody
            )

            guard folderResponse.success, let folder = folderResponse.folder else {
                throw SavedMailError.serverError(folderResponse.error ?? "Unknown error")
            }

            // Update local cache
            if let index = self.folders.firstIndex(where: { $0.id == folderId }) {
                self.folders[index] = folder
                self.saveFoldersToCache()
            }

            Logger.info("✅ Updated folder: \(folderId)", category: .savedMail)

            return folder
        } catch let error as NetworkServiceError {
            if let statusCode = error.statusCode {
                throw SavedMailError.httpError(statusCode: statusCode)
            }
            throw SavedMailError.invalidResponse
        }
    }

    /// Delete a folder
    func deleteFolder(userId: String, folderId: String) async throws {
        // Week 6 Service Layer Cleanup: Using centralized NetworkService
        isLoading = true
        defer { isLoading = false }

        guard var urlComponents = URLComponents(string: "\(baseURL)/folders/\(folderId)") else {
            throw SavedMailError.invalidURL
        }

        urlComponents.queryItems = [
            URLQueryItem(name: "userId", value: userId)
        ]

        guard let url = urlComponents.url else {
            throw SavedMailError.invalidURL
        }

        do {
            try await NetworkService.shared.delete(url: url)

            // Update local cache
            self.folders.removeAll { $0.id == folderId }
            self.saveFoldersToCache()

            Logger.info("✅ Deleted folder: \(folderId)", category: .savedMail)
        } catch let error as NetworkServiceError {
            if let statusCode = error.statusCode {
                throw SavedMailError.httpError(statusCode: statusCode)
            }
            throw SavedMailError.invalidResponse
        }
    }

    /// Add email to folder
    func addEmailToFolder(userId: String, folderId: String, emailId: String) async throws -> SavedMailFolder {
        // Week 6 Service Layer Cleanup: Using centralized NetworkService
        isLoading = true
        defer { isLoading = false }

        guard let url = URL(string: "\(baseURL)/folders/\(folderId)/emails") else {
            throw SavedMailError.invalidURL
        }

        struct AddEmailRequest: Codable {
            let userId: String
            let emailId: String
        }

        let requestBody = AddEmailRequest(
            userId: userId,
            emailId: emailId
        )

        do {
            let folderResponse: FolderEmailResponse = try await NetworkService.shared.post(
                url: url,
                body: requestBody
            )

            guard folderResponse.success, let folder = folderResponse.folder else {
                throw SavedMailError.serverError(folderResponse.error ?? "Unknown error")
            }

            // Update local cache
            if let index = self.folders.firstIndex(where: { $0.id == folderId }) {
                self.folders[index] = folder
                self.saveFoldersToCache()
            }

            Logger.info("✅ Added email \(emailId) to folder \(folderId)", category: .savedMail)

            return folder
        } catch let error as NetworkServiceError {
            if let statusCode = error.statusCode {
                throw SavedMailError.httpError(statusCode: statusCode)
            }
            throw SavedMailError.invalidResponse
        }
    }

    /// Remove email from folder
    func removeEmailFromFolder(userId: String, folderId: String, emailId: String) async throws -> SavedMailFolder {
        // Week 6 Service Layer Cleanup: Using centralized NetworkService
        isLoading = true
        defer { isLoading = false }

        guard var urlComponents = URLComponents(string: "\(baseURL)/folders/\(folderId)/emails/\(emailId)") else {
            throw SavedMailError.invalidURL
        }

        urlComponents.queryItems = [
            URLQueryItem(name: "userId", value: userId)
        ]

        guard let url = urlComponents.url else {
            throw SavedMailError.invalidURL
        }

        do {
            let folderResponse: FolderEmailResponse = try await NetworkService.shared.request(
                url: url,
                method: .delete,
                body: Optional<String>.none
            )

            guard folderResponse.success, let folder = folderResponse.folder else {
                throw SavedMailError.serverError(folderResponse.error ?? "Unknown error")
            }

            // Update local cache
            if let index = self.folders.firstIndex(where: { $0.id == folderId }) {
                self.folders[index] = folder
                self.saveFoldersToCache()
            }

            Logger.info("✅ Removed email \(emailId) from folder \(folderId)", category: .savedMail)

            return folder
        } catch let error as NetworkServiceError {
            if let statusCode = error.statusCode {
                throw SavedMailError.httpError(statusCode: statusCode)
            }
            throw SavedMailError.invalidResponse
        }
    }

    /// Reorder folders
    func reorderFolders(userId: String, folderIds: [String]) async throws -> [SavedMailFolder] {
        // Week 6 Service Layer Cleanup: Using centralized NetworkService
        isLoading = true
        defer { isLoading = false }

        guard let url = URL(string: "\(baseURL)/folders/reorder") else {
            throw SavedMailError.invalidURL
        }

        struct ReorderFoldersRequest: Codable {
            let userId: String
            let folderIds: [String]
        }

        let requestBody = ReorderFoldersRequest(
            userId: userId,
            folderIds: folderIds
        )

        do {
            let folderResponse: ReorderFoldersResponse = try await NetworkService.shared.post(
                url: url,
                body: requestBody
            )

            guard folderResponse.success, let reorderedFolders = folderResponse.folders else {
                throw SavedMailError.serverError(folderResponse.error ?? "Unknown error")
            }

            // Update local cache
            self.folders = reorderedFolders
            self.saveFoldersToCache()

            Logger.info("✅ Reordered \(folderIds.count) folders", category: .savedMail)

            return reorderedFolders
        } catch let error as NetworkServiceError {
            if let statusCode = error.statusCode {
                throw SavedMailError.httpError(statusCode: statusCode)
            }
            throw SavedMailError.invalidResponse
        }
    }

    // MARK: - Local Cache

    private func saveFoldersToCache() {
        if let encoded = try? JSONEncoder().encode(folders) {
            UserDefaults.standard.set(encoded, forKey: "savedMailFolders")
        }
    }

    private func loadFoldersFromCache() {
        if let data = UserDefaults.standard.data(forKey: "savedMailFolders"),
           let decoded = try? JSONDecoder().decode([SavedMailFolder].self, from: data) {
            self.folders = decoded
            Logger.info("📂 Loaded \(decoded.count) folders from cache", category: .savedMail)
        }
    }

    /// Clear local cache
    func clearCache() {
        UserDefaults.standard.removeObject(forKey: "savedMailFolders")
        folders = []
        Logger.info("🗑️ Cleared saved mail cache", category: .savedMail)
    }

    // MARK: - Helper Methods

    /// Get folder by ID
    func getFolder(id: String) -> SavedMailFolder? {
        return folders.first { $0.id == id }
    }

    /// Check if email is in any folder
    func emailIsInFolder(emailId: String) -> Bool {
        return folders.contains { $0.containsEmail(emailId) }
    }

    /// Get all folders containing a specific email
    func foldersContaining(emailId: String) -> [SavedMailFolder] {
        return folders.filter { $0.containsEmail(emailId) }
    }
}

// MARK: - Error Types

enum SavedMailError: LocalizedError {
    case invalidURL
    case invalidResponse
    case httpError(statusCode: Int)
    case serverError(String)
    case decodingError

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid URL"
        case .invalidResponse:
            return "Invalid response from server"
        case .httpError(let statusCode):
            return "HTTP error: \(statusCode)"
        case .serverError(let message):
            return message
        case .decodingError:
            return "Failed to decode response"
        }
    }
}
