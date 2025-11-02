//
//  SavedMailFolder.swift
//  Zero
//
//  Created by Claude Code on 10/25/25.
//

import Foundation

/**
 * SavedMailFolder - User-created folders for organizing emails
 *
 * Represents a custom folder that users can create to save and organize
 * important emails for later reference. Folders can be named, colored,
 * and contain multiple emails.
 */
struct SavedMailFolder: Codable, Identifiable, Equatable {
    let id: String
    let userId: String
    var name: String
    var color: String?  // Hex color code (e.g., "#FF5733")
    var emailIds: [String]
    var isPreset: Bool  // True for system preset folders (Receipts, Travel, etc.)
    var icon: String?  // SF Symbol name for preset folders
    let createdAt: String
    var updatedAt: String
    var emailCount: Int  // Computed on backend

    enum CodingKeys: String, CodingKey {
        case id, userId, name, color, emailIds, isPreset, icon, createdAt, updatedAt, emailCount
    }

    // MARK: - Initialization

    init(
        id: String = UUID().uuidString,
        userId: String,
        name: String,
        color: String? = nil,
        emailIds: [String] = [],
        isPreset: Bool = false,
        icon: String? = nil,
        createdAt: String = ISO8601DateFormatter().string(from: Date()),
        updatedAt: String = ISO8601DateFormatter().string(from: Date()),
        emailCount: Int = 0
    ) {
        self.id = id
        self.userId = userId
        self.name = name
        self.color = color
        self.emailIds = emailIds
        self.isPreset = isPreset
        self.icon = icon
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.emailCount = emailCount
    }

    // MARK: - Computed Properties

    /// Display color for the folder (default to gray if not set)
    var displayColor: String {
        return color ?? "#8E8E93"  // Default iOS gray
    }

    /// Formatted creation date
    var formattedCreatedAt: String {
        guard let date = ISO8601DateFormatter().date(from: createdAt) else {
            return createdAt
        }
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: date)
    }

    /// Formatted last updated date
    var formattedUpdatedAt: String {
        guard let date = ISO8601DateFormatter().date(from: updatedAt) else {
            return updatedAt
        }
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }

    // MARK: - Validation

    /// Validate folder data
    func validate() -> (valid: Bool, errors: [String]) {
        var errors: [String] = []

        if userId.isEmpty {
            errors.append("userId is required")
        }

        if name.isEmpty {
            errors.append("name is required")
        }

        if name.count > 200 {
            errors.append("name must be 200 characters or less")
        }

        if let color = color, !isValidHexColor(color) {
            errors.append("color must be a valid hex color code (e.g., #FF5733)")
        }

        return (valid: errors.isEmpty, errors: errors)
    }

    /// Check if a string is a valid hex color code
    private func isValidHexColor(_ color: String) -> Bool {
        let hexPattern = "^#[0-9A-Fa-f]{6}$"
        let regex = try? NSRegularExpression(pattern: hexPattern)
        let range = NSRange(location: 0, length: color.utf16.count)
        return regex?.firstMatch(in: color, options: [], range: range) != nil
    }

    // MARK: - Helper Methods

    /// Check if folder contains a specific email
    func containsEmail(_ emailId: String) -> Bool {
        return emailIds.contains(emailId)
    }

    /// Get a copy of the folder with updated name
    func renamed(to newName: String) -> SavedMailFolder {
        var updated = self
        updated.name = newName
        updated.updatedAt = ISO8601DateFormatter().string(from: Date())
        return updated
    }

    /// Get a copy of the folder with updated color
    func recolored(to newColor: String?) -> SavedMailFolder {
        var updated = self
        updated.color = newColor
        updated.updatedAt = ISO8601DateFormatter().string(from: Date())
        return updated
    }

    // MARK: - Equatable

    static func == (lhs: SavedMailFolder, rhs: SavedMailFolder) -> Bool {
        return lhs.id == rhs.id &&
               lhs.name == rhs.name &&
               lhs.color == rhs.color &&
               lhs.emailIds == rhs.emailIds &&
               lhs.isPreset == rhs.isPreset
    }

    /// Display icon for the folder (preset folders have custom icons)
    var displayIcon: String {
        if isPreset, let icon = icon {
            return icon
        }
        return "folder.fill"
    }
}

// MARK: - API Response Models

/// Response from creating a folder
struct CreateFolderResponse: Codable {
    let success: Bool
    let folder: SavedMailFolder?
    let error: String?
}

/// Response from updating a folder
struct UpdateFolderResponse: Codable {
    let success: Bool
    let folder: SavedMailFolder?
    let error: String?
}

/// Response from deleting a folder
struct DeleteFolderResponse: Codable {
    let success: Bool
    let message: String?
    let error: String?
}

/// Response from adding/removing email from folder
struct FolderEmailResponse: Codable {
    let success: Bool
    let folder: SavedMailFolder?
    let error: String?
}

/// Response from getting all folders
struct GetFoldersResponse: Codable {
    let success: Bool
    let folders: [SavedMailFolder]
}

/// Response from reordering folders
struct ReorderFoldersResponse: Codable {
    let success: Bool
    let folders: [SavedMailFolder]?
    let error: String?
}

// MARK: - Predefined Colors

extension SavedMailFolder {
    /// Predefined color palette for folders
    static let colorPalette: [String] = [
        "#FF3B30",  // Red
        "#FF9500",  // Orange
        "#FFCC00",  // Yellow
        "#34C759",  // Green
        "#00C7BE",  // Teal
        "#007AFF",  // Blue
        "#5856D6",  // Purple
        "#AF52DE",  // Pink
        "#FF2D55",  // Magenta
        "#8E8E93"   // Gray
    ]

    /// Get a random color from the palette
    static func randomColor() -> String {
        return colorPalette.randomElement() ?? "#8E8E93"
    }
}
