import Foundation

/**
 * MockDataLoader (Stub Implementation)
 *
 * TEMPORARY: This is a minimal stub to unblock builds.
 * Returns empty arrays - DataGenerator will fall back to hardcoded mock data.
 *
 * TODO: Full JSON mock data loading can be implemented later if needed.
 * For now, the hardcoded mock data in DataGenerator.swift is sufficient.
 */
struct MockDataLoader {

    /// Load all mock emails from JSON fixtures
    /// Currently returns empty array - DataGenerator uses hardcoded fallback
    func loadAllEmails() throws -> [EmailCard] {
        // Stub implementation - return empty array
        // DataGenerator will fall back to hardcoded mock data
        return []
    }

    /// Load mock emails for specific category
    /// Currently returns empty array - DataGenerator uses hardcoded fallback
    func loadEmails(forCategory category: String) throws -> [EmailCard] {
        // Stub implementation - return empty array
        return []
    }
}
