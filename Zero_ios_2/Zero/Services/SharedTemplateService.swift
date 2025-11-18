import Foundation

/**
 * SharedTemplateService
 * Manages shared templates that can be used across teams/organizations
 * Syncs with backend for team collaboration
 */

class SharedTemplateService: ObservableObject {
    static let shared = SharedTemplateService()

    @Published var sharedTemplates: [SharedTemplate] = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    private let apiBaseURL = AppEnvironment.current.apiBaseURL

    private init() {}

    // MARK: - Fetch Shared Templates

    /// Fetch public/team shared templates from backend
    func fetchSharedTemplates(userId: String) async throws {
        await MainActor.run {
            isLoading = true
            errorMessage = nil
        }

        do {
            // In production, this would call actual API
            // For now, simulate network call with mock data
            try await Task.sleep(nanoseconds: 500_000_000) // 0.5s delay

            let mockTemplates = generateMockSharedTemplates()

            await MainActor.run {
                self.sharedTemplates = mockTemplates
                self.isLoading = false
                Logger.info("Fetched \(mockTemplates.count) shared templates", category: .app)
            }
        } catch {
            await MainActor.run {
                self.errorMessage = error.localizedDescription
                self.isLoading = false
                Logger.error("Shared templates error: \(error.localizedDescription)", category: .app)
            }
            throw error
        }
    }

    // MARK: - Share Template

    /// Share a user template with team or public
    func shareTemplate(
        _ template: ReplyTemplate,
        shareType: ShareType,
        teamId: String? = nil
    ) async throws -> SharedTemplate {
        await MainActor.run {
            isLoading = true
        }

        // In production, POST to backend API
        let sharedTemplate = SharedTemplate(
            id: UUID().uuidString,
            name: template.name,
            content: template.content,
            category: template.category,
            authorId: AuthContext.getUserId(),
            authorName: "Current User",
            shareType: shareType,
            teamId: teamId,
            usageCount: 0,
            rating: 0.0,
            ratingCount: 0,
            createdAt: Date(),
            updatedAt: Date()
        )

        await MainActor.run {
            self.sharedTemplates.insert(sharedTemplate, at: 0)
            self.isLoading = false
            Logger.info("Shared template: \(template.name)", category: .app)
        }

        return sharedTemplate
    }

    // MARK: - Import Template

    /// Import a shared template to user's personal templates
    func importTemplate(_ sharedTemplate: SharedTemplate) async throws -> ReplyTemplate {
        // Track import/usage
        try await incrementUsageCount(sharedTemplate.id)

        // Convert to personal template
        let personalTemplate = ReplyTemplate(
            id: UUID().uuidString,
            name: "\(sharedTemplate.name) (Imported)",
            content: sharedTemplate.content,
            category: sharedTemplate.category,
            isBuiltIn: false,
            createdAt: Date(),
            usageCount: 0
        )

        // Add to TemplateManager
        TemplateManager.shared.templates.append(personalTemplate)
        TemplateManager.shared.saveUserTemplates()

        Logger.info("Imported: \(sharedTemplate.name)", category: .app)
        return personalTemplate
    }

    // MARK: - Rate Template

    func rateTemplate(_ templateId: String, rating: Int) async throws {
        guard rating >= 1 && rating <= 5 else {
            throw SharedTemplateError.invalidRating
        }

        // In production, POST rating to backend
        await MainActor.run {
            if let index = sharedTemplates.firstIndex(where: { $0.id == templateId }) {
                var template = sharedTemplates[index]
                let newTotal = (template.rating * Double(template.ratingCount)) + Double(rating)
                template.ratingCount += 1
                template.rating = newTotal / Double(template.ratingCount)
                sharedTemplates[index] = template
                Logger.info("Rated \(templateId): \(rating) stars", category: .app)
            }
        }
    }

    // MARK: - Search & Filter

    func searchSharedTemplates(query: String) -> [SharedTemplate] {
        guard !query.isEmpty else { return sharedTemplates }

        let lowercaseQuery = query.lowercased()
        return sharedTemplates.filter {
            $0.name.lowercased().contains(lowercaseQuery) ||
            $0.content.lowercased().contains(lowercaseQuery) ||
            $0.authorName.lowercased().contains(lowercaseQuery)
        }
    }

    func filterByCategory(_ category: TemplateCategory?) -> [SharedTemplate] {
        guard let category = category else { return sharedTemplates }
        return sharedTemplates.filter { $0.category == category }
    }

    func filterByShareType(_ shareType: ShareType) -> [SharedTemplate] {
        return sharedTemplates.filter { $0.shareType == shareType }
    }

    // MARK: - Private Helpers

    private func incrementUsageCount(_ templateId: String) async throws {
        // In production, POST to backend
        await MainActor.run {
            if let index = sharedTemplates.firstIndex(where: { $0.id == templateId }) {
                sharedTemplates[index].usageCount += 1
            }
        }
    }

    private func generateMockSharedTemplates() -> [SharedTemplate] {
        return [
            // Public templates
            SharedTemplate(
                id: "st1",
                name: "Professional Meeting Follow-up",
                content: "Thank you for taking the time to meet with me today. As discussed, I'll follow up on [ACTION ITEMS] by [DATE]. Please let me know if you have any questions or need additional information.\n\nLooking forward to our next conversation.",
                category: .followUp,
                authorId: "user-456",
                authorName: "Candace Chen",
                shareType: .publicAccess,
                teamId: nil,
                usageCount: 234,
                rating: 4.7,
                ratingCount: 89,
                createdAt: Date().addingTimeInterval(-86400 * 30),
                updatedAt: Date().addingTimeInterval(-86400 * 5)
            ),

            SharedTemplate(
                id: "st2",
                name: "Customer Support - Issue Resolved",
                content: "Hi [NAME],\n\nGreat news! We've resolved the issue you reported. [BRIEF EXPLANATION OF FIX].\n\nYou should now be able to [EXPECTED OUTCOME]. If you encounter any further issues, please don't hesitate to reach out.\n\nThank you for your patience!",
                category: .confirmation,
                authorId: "user-789",
                authorName: "Mike Rodriguez",
                shareType: .publicAccess,
                teamId: nil,
                usageCount: 567,
                rating: 4.9,
                ratingCount: 203,
                createdAt: Date().addingTimeInterval(-86400 * 60),
                updatedAt: Date().addingTimeInterval(-86400 * 2)
            ),

            SharedTemplate(
                id: "st3",
                name: "Invoice Payment Confirmation",
                content: "Thank you for your payment of $[AMOUNT] for Invoice #[INVOICE_NUMBER].\n\nPayment received: [DATE]\nPayment method: [METHOD]\n\nYour account has been updated accordingly. Please retain this email for your records.",
                category: .confirmation,
                authorId: "user-321",
                authorName: "Emily Wang",
                shareType: .publicAccess,
                teamId: nil,
                usageCount: 445,
                rating: 4.6,
                ratingCount: 156,
                createdAt: Date().addingTimeInterval(-86400 * 45),
                updatedAt: Date().addingTimeInterval(-86400 * 10)
            ),

            // Team templates (if user is in a team)
            SharedTemplate(
                id: "st4",
                name: "Sales Handoff to Success Team",
                content: "Hi Success Team,\n\nNew customer onboarding for [COMPANY_NAME]:\n- Contract value: $[AMOUNT]\n- Start date: [DATE]\n- Primary contact: [NAME] ([EMAIL])\n- Key requirements: [REQUIREMENTS]\n\nPlease schedule kickoff call within 3 business days.\n\nThanks!",
                category: .general,
                authorId: "user-456",
                authorName: "Candace Chen",
                shareType: .team,
                teamId: "team-acme",
                usageCount: 89,
                rating: 4.8,
                ratingCount: 34,
                createdAt: Date().addingTimeInterval(-86400 * 20),
                updatedAt: Date().addingTimeInterval(-86400 * 1)
            ),

            SharedTemplate(
                id: "st5",
                name: "Weekly Status Update",
                content: "Team Weekly Update - Week of [DATE]\n\n✅ Completed:\n- [ITEM 1]\n- [ITEM 2]\n\n🚧 In Progress:\n- [ITEM 1]\n- [ITEM 2]\n\n⚠️ Blockers:\n- [IF ANY]\n\nNext Week Goals:\n- [GOAL 1]\n- [GOAL 2]",
                category: .general,
                authorId: "user-789",
                authorName: "Mike Rodriguez",
                shareType: .team,
                teamId: "team-acme",
                usageCount: 156,
                rating: 4.5,
                ratingCount: 67,
                createdAt: Date().addingTimeInterval(-86400 * 90),
                updatedAt: Date().addingTimeInterval(-86400 * 7)
            ),

            SharedTemplate(
                id: "st6",
                name: "Out of Office - Conference",
                content: "Thank you for your email. I'm currently attending [CONFERENCE_NAME] and will have limited access to email until [RETURN_DATE].\n\nFor urgent matters, please contact [BACKUP_NAME] at [BACKUP_EMAIL].\n\nI'll respond to your message as soon as possible upon my return.",
                category: .outOfOffice,
                authorId: "user-654",
                authorName: "Alex Johnson",
                shareType: .publicAccess,
                teamId: nil,
                usageCount: 234,
                rating: 4.4,
                ratingCount: 78,
                createdAt: Date().addingTimeInterval(-86400 * 120),
                updatedAt: Date().addingTimeInterval(-86400 * 30)
            )
        ]
    }
}

// MARK: - Models

struct SharedTemplate: Identifiable, Codable {
    let id: String
    let name: String
    let content: String
    let category: TemplateCategory
    let authorId: String
    let authorName: String
    let shareType: ShareType
    let teamId: String?
    var usageCount: Int
    var rating: Double
    var ratingCount: Int
    let createdAt: Date
    let updatedAt: Date

    var formattedRating: String {
        String(format: "%.1f", rating)
    }

    var isPopular: Bool {
        usageCount > 100
    }

    var isHighlyRated: Bool {
        rating >= 4.5 && ratingCount >= 10
    }
}

enum ShareType: String, Codable {
    case personal = "personal"   // Only visible to creator
    case team = "team"           // Visible to team members
    case publicAccess = "public" // Visible to all users
}

enum SharedTemplateError: Error, LocalizedError {
    case invalidRating
    case networkError
    case unauthorized

    var errorDescription: String? {
        switch self {
        case .invalidRating:
            return "Rating must be between 1 and 5 stars"
        case .networkError:
            return "Unable to connect to server"
        case .unauthorized:
            return "You don't have permission to perform this action"
        }
    }
}
