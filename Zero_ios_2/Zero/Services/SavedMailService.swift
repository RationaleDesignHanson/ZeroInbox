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
    private let session = URLSession.shared
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

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let (data, response) = try await session.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw SavedMailError.invalidResponse
        }

        guard httpResponse.statusCode == 200 else {
            throw SavedMailError.httpError(statusCode: httpResponse.statusCode)
        }

        let folderResponse = try JSONDecoder().decode(GetFoldersResponse.self, from: data)

        guard folderResponse.success else {
            throw SavedMailError.serverError("Failed to fetch folders")
        }

        // Update local cache
        self.folders = folderResponse.folders
        self.saveFoldersToCache()

        Logger.info("✅ Fetched \(folderResponse.folders.count) folders", category: .savedMail)

        return folderResponse.folders
    }

    /// Create a new folder
    func createFolder(userId: String, name: String, color: String?) async throws -> SavedMailFolder {
        isLoading = true
        defer { isLoading = false }

        guard let url = URL(string: "\(baseURL)/folders") else {
            throw SavedMailError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let body: [String: Any] = [
            "userId": userId,
            "name": name,
            "color": color ?? SavedMailFolder.randomColor()
        ]

        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await session.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw SavedMailError.invalidResponse
        }

        guard httpResponse.statusCode == 201 else {
            // Try to parse error message
            if let errorResponse = try? JSONDecoder().decode(CreateFolderResponse.self, from: data),
               let errorMessage = errorResponse.error {
                throw SavedMailError.serverError(errorMessage)
            }
            throw SavedMailError.httpError(statusCode: httpResponse.statusCode)
        }

        let folderResponse = try JSONDecoder().decode(CreateFolderResponse.self, from: data)

        guard folderResponse.success, let folder = folderResponse.folder else {
            throw SavedMailError.serverError(folderResponse.error ?? "Unknown error")
        }

        // Update local cache
        self.folders.append(folder)
        self.saveFoldersToCache()

        Logger.info("✅ Created folder: \(name)", category: .savedMail)

        return folder
    }

    /// Update a folder (rename or recolor)
    func updateFolder(userId: String, folderId: String, name: String?, color: String?) async throws -> SavedMailFolder {
        isLoading = true
        defer { isLoading = false }

        guard let url = URL(string: "\(baseURL)/folders/\(folderId)") else {
            throw SavedMailError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "PATCH"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        var body: [String: Any] = ["userId": userId]
        if let name = name {
            body["name"] = name
        }
        if let color = color {
            body["color"] = color
        }

        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await session.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw SavedMailError.invalidResponse
        }

        guard httpResponse.statusCode == 200 else {
            if let errorResponse = try? JSONDecoder().decode(UpdateFolderResponse.self, from: data),
               let errorMessage = errorResponse.error {
                throw SavedMailError.serverError(errorMessage)
            }
            throw SavedMailError.httpError(statusCode: httpResponse.statusCode)
        }

        let folderResponse = try JSONDecoder().decode(UpdateFolderResponse.self, from: data)

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
    }

    /// Delete a folder
    func deleteFolder(userId: String, folderId: String) async throws {
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

        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let (data, response) = try await session.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw SavedMailError.invalidResponse
        }

        guard httpResponse.statusCode == 200 else {
            if let errorResponse = try? JSONDecoder().decode(DeleteFolderResponse.self, from: data),
               let errorMessage = errorResponse.error {
                throw SavedMailError.serverError(errorMessage)
            }
            throw SavedMailError.httpError(statusCode: httpResponse.statusCode)
        }

        // Update local cache
        self.folders.removeAll { $0.id == folderId }
        self.saveFoldersToCache()

        Logger.info("✅ Deleted folder: \(folderId)", category: .savedMail)
    }

    /// Add email to folder
    func addEmailToFolder(userId: String, folderId: String, emailId: String) async throws -> SavedMailFolder {
        isLoading = true
        defer { isLoading = false }

        guard let url = URL(string: "\(baseURL)/folders/\(folderId)/emails") else {
            throw SavedMailError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let body: [String: Any] = [
            "userId": userId,
            "emailId": emailId
        ]

        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await session.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw SavedMailError.invalidResponse
        }

        guard httpResponse.statusCode == 200 else {
            if let errorResponse = try? JSONDecoder().decode(FolderEmailResponse.self, from: data),
               let errorMessage = errorResponse.error {
                throw SavedMailError.serverError(errorMessage)
            }
            throw SavedMailError.httpError(statusCode: httpResponse.statusCode)
        }

        let folderResponse = try JSONDecoder().decode(FolderEmailResponse.self, from: data)

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
    }

    /// Remove email from folder
    func removeEmailFromFolder(userId: String, folderId: String, emailId: String) async throws -> SavedMailFolder {
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

        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let (data, response) = try await session.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw SavedMailError.invalidResponse
        }

        guard httpResponse.statusCode == 200 else {
            if let errorResponse = try? JSONDecoder().decode(FolderEmailResponse.self, from: data),
               let errorMessage = errorResponse.error {
                throw SavedMailError.serverError(errorMessage)
            }
            throw SavedMailError.httpError(statusCode: httpResponse.statusCode)
        }

        let folderResponse = try JSONDecoder().decode(FolderEmailResponse.self, from: data)

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
    }

    /// Reorder folders
    func reorderFolders(userId: String, folderIds: [String]) async throws -> [SavedMailFolder] {
        isLoading = true
        defer { isLoading = false }

        guard let url = URL(string: "\(baseURL)/folders/reorder") else {
            throw SavedMailError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let body: [String: Any] = [
            "userId": userId,
            "folderIds": folderIds
        ]

        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await session.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw SavedMailError.invalidResponse
        }

        guard httpResponse.statusCode == 200 else {
            if let errorResponse = try? JSONDecoder().decode(ReorderFoldersResponse.self, from: data),
               let errorMessage = errorResponse.error {
                throw SavedMailError.serverError(errorMessage)
            }
            throw SavedMailError.httpError(statusCode: httpResponse.statusCode)
        }

        let folderResponse = try JSONDecoder().decode(ReorderFoldersResponse.self, from: data)

        guard folderResponse.success, let reorderedFolders = folderResponse.folders else {
            throw SavedMailError.serverError(folderResponse.error ?? "Unknown error")
        }

        // Update local cache
        self.folders = reorderedFolders
        self.saveFoldersToCache()

        Logger.info("✅ Reordered \(folderIds.count) folders", category: .savedMail)

        return reorderedFolders
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
