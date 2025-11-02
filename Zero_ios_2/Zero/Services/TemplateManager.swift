import Foundation

/// Manages email reply templates (CRUD operations and persistence)
class TemplateManager: ObservableObject {
    static let shared = TemplateManager()

    @Published var templates: [ReplyTemplate] = []

    private let userDefaultsKey = "userTemplates"

    init() {
        loadTemplates()
    }

    // MARK: - Template Management

    /// Load all templates (built-in + user-created)
    func loadTemplates() {
        var allTemplates: [ReplyTemplate] = []

        // Add built-in templates
        allTemplates.append(contentsOf: BuiltInTemplates.all)

        // Load user templates from UserDefaults
        if let data = UserDefaults.standard.data(forKey: userDefaultsKey),
           let userTemplates = try? JSONDecoder().decode([ReplyTemplate].self, from: data) {
            allTemplates.append(contentsOf: userTemplates)
        }

        // Sort: most used first, then by creation date
        templates = allTemplates.sorted { lhs, rhs in
            if lhs.usageCount != rhs.usageCount {
                return lhs.usageCount > rhs.usageCount
            }
            return lhs.createdAt > rhs.createdAt
        }

        Logger.info("Loaded \(templates.count) templates (\(BuiltInTemplates.all.count) built-in)", category: .app)
    }

    /// Save user templates to UserDefaults
    func saveUserTemplates() {
        let userTemplates = templates.filter { !$0.isBuiltIn }

        if let data = try? JSONEncoder().encode(userTemplates) {
            UserDefaults.standard.set(data, forKey: userDefaultsKey)
            Logger.info("Saved \(userTemplates.count) user templates", category: .app)
        }
    }

    /// Create a new user template
    func createTemplate(name: String, content: String, category: TemplateCategory) {
        let template = ReplyTemplate(
            name: name,
            content: content,
            category: category,
            isBuiltIn: false
        )

        templates.append(template)
        saveUserTemplates()

        Logger.info("Created template: \(name)", category: .app)
    }

    /// Update an existing template
    func updateTemplate(_ template: ReplyTemplate, name: String, content: String, category: TemplateCategory) {
        guard !template.isBuiltIn else {
            Logger.warning("Cannot edit built-in template", category: .app)
            return
        }

        if let index = templates.firstIndex(where: { $0.id == template.id }) {
            templates[index].name = name
            templates[index].content = content
            templates[index].category = category
            saveUserTemplates()

            Logger.info("Updated template: \(name)", category: .app)
        }
    }

    /// Delete a user template
    func deleteTemplate(_ template: ReplyTemplate) {
        guard !template.isBuiltIn else {
            Logger.warning("Cannot delete built-in template", category: .app)
            return
        }

        templates.removeAll { $0.id == template.id }
        saveUserTemplates()

        Logger.info("Deleted template: \(template.name)", category: .app)
    }

    /// Increment usage count when template is used
    func recordUsage(for template: ReplyTemplate) {
        if let index = templates.firstIndex(where: { $0.id == template.id }) {
            templates[index].usageCount += 1

            // Only save if it's a user template
            if !template.isBuiltIn {
                saveUserTemplates()
            }

            Logger.info("Recorded usage for: \(template.name) (count: \(templates[index].usageCount))", category: .app)
        }

        // Re-sort templates by usage
        loadTemplates()
    }

    /// Get templates by category
    func templates(for category: TemplateCategory) -> [ReplyTemplate] {
        return templates.filter { $0.category == category }
    }

    /// Get most used templates
    func mostUsedTemplates(limit: Int = 5) -> [ReplyTemplate] {
        return Array(templates.sorted { $0.usageCount > $1.usageCount }.prefix(limit))
    }

    /// Search templates
    func searchTemplates(query: String) -> [ReplyTemplate] {
        guard !query.isEmpty else { return templates }

        let lowercasedQuery = query.lowercased()
        return templates.filter {
            $0.name.lowercased().contains(lowercasedQuery) ||
            $0.content.lowercased().contains(lowercasedQuery)
        }
    }
}
