import Foundation

/// Service to validate data integrity between fetched emails and displayed cards
class DataIntegrityService {
    static let shared = DataIntegrityService()

    private init() {}

    // MARK: - Data Integrity Checks

    struct IntegrityReport {
        let timestamp: Date
        let useMockData: Bool
        let emailsFetched: Int
        let cardsAvailable: Int
        let selectedArchetypes: [CardType]
        let cardsPerArchetype: [CardType: Int]
        let unseenCardsPerArchetype: [CardType: Int]
        let issues: [String]
        let isHealthy: Bool

        // Computed properties for backward compatibility
        var hasIssues: Bool {
            return !isHealthy
        }

        var description: String {
            return summary
        }

        var summary: String {
            var text = """
            📊 Data Integrity Report (\(timestamp.formatted()))

            Mode: \(useMockData ? "Mock Data" : "Real Email")
            Selected Categories: \(selectedArchetypes.map { $0.displayName }.joined(separator: ", "))

            📧 Total Emails Fetched: \(emailsFetched)
            🎴 Total Cards Available: \(cardsAvailable)

            Cards per Category:
            """

            for archetype in selectedArchetypes {
                let total = cardsPerArchetype[archetype] ?? 0
                let unseen = unseenCardsPerArchetype[archetype] ?? 0
                text += "\n  • \(archetype.displayName): \(unseen) unseen / \(total) total"
            }

            if !issues.isEmpty {
                text += "\n\n⚠️ Issues Found:"
                for issue in issues {
                    text += "\n  • \(issue)"
                }
            } else {
                text += "\n\n✅ No issues detected - data is healthy!"
            }

            return text
        }
    }

    /// Run comprehensive data integrity check
    func checkIntegrity(
        cards: [EmailCard],
        selectedArchetypes: [CardType]
    ) -> IntegrityReport {
        let useMockData = UserDefaults.standard.bool(forKey: "useMockData")
        var issues: [String] = []

        // Check 1: Do we have any cards at all?
        if cards.isEmpty {
            if useMockData {
                issues.append("No mock data loaded - DataGenerator may have failed")
            } else {
                issues.append("No real emails fetched - check OAuth authentication and backend connection")
            }
        }

        // Check 2: Calculate cards per archetype
        var cardsPerArchetype: [CardType: Int] = [:]
        var unseenCardsPerArchetype: [CardType: Int] = [:]

        for archetype in selectedArchetypes {
            let totalCards = cards.filter { $0.type == archetype }.count
            let unseenCards = cards.filter { $0.type == archetype && $0.state == .unseen }.count

            cardsPerArchetype[archetype] = totalCards
            unseenCardsPerArchetype[archetype] = unseenCards

            // Check 3: Do selected archetypes have cards?
            if totalCards == 0 {
                if useMockData {
                    issues.append("Mock mode: No cards for '\(archetype.displayName)' - archetype mismatch (mock uses legacy names)")
                } else {
                    issues.append("Real mode: No emails classified as '\(archetype.displayName)' - may need more emails or better classification")
                }
            }
        }

        // Check 4: Archetype count check (we now use all 8 archetypes)
        let allArchetypes: [CardType] = [
            .mail,
            .ads,
            .mail,
            .mail,
            .mail,
            .mail,
            .ads,
            .mail
        ]

        if selectedArchetypes.count < allArchetypes.count {
            issues.append("Only \(selectedArchetypes.count) of \(allArchetypes.count) archetypes selected. Consider selecting all for full email coverage.")
        }

        // Check 5: Verify cards match selected archetypes
        let cardsOutsideSelection = cards.filter { card in
            !selectedArchetypes.contains(card.type)
        }

        if !cardsOutsideSelection.isEmpty {
            issues.append("\(cardsOutsideSelection.count) cards have types not in selected archetypes (will be hidden)")
        }

        return IntegrityReport(
            timestamp: Date(),
            useMockData: useMockData,
            emailsFetched: cards.count,
            cardsAvailable: cards.filter { selectedArchetypes.contains($0.type) }.count,
            selectedArchetypes: selectedArchetypes,
            cardsPerArchetype: cardsPerArchetype,
            unseenCardsPerArchetype: unseenCardsPerArchetype,
            issues: issues,
            isHealthy: issues.isEmpty
        )
    }

    /// Quick health check (returns true if data is healthy)
    func isDataHealthy(cards: [EmailCard], selectedArchetypes: [CardType]) -> Bool {
        let report = checkIntegrity(cards: cards, selectedArchetypes: selectedArchetypes)
        return report.isHealthy
    }

    /// Auto-fix common issues
    func autoFixIssues(
        cards: [EmailCard],
        selectedArchetypes: inout [CardType]
    ) -> [String] {
        var fixes: [String] = []

        // Fix 1: Ensure all 8 archetypes are selected
        let allArchetypes: [CardType] = [
            .mail,
            .ads,
            .mail,
            .mail,
            .mail,
            .mail,
            .ads,
            .mail
        ]

        if selectedArchetypes.isEmpty || selectedArchetypes.count < allArchetypes.count {
            selectedArchetypes = allArchetypes
            fixes.append("Fixed: Updated selected archetypes to all 8 categories")
            Logger.info("AUTO-FIX: Set archetypes to all 8: \(allArchetypes.map { $0.displayName })", category: .app)
        }

        // Fix 2: No cards in selected archetypes
        if !cards.isEmpty {
            let availableArchetypes = Set(cards.map { $0.type })
            let hasNoCards = selectedArchetypes.allSatisfy { archetype in
                !availableArchetypes.contains(archetype)
            }

            if hasNoCards {
                // Select archetypes that actually have cards
                let newArchetypes = Array(availableArchetypes).sorted { $0.rawValue < $1.rawValue }
                if !newArchetypes.isEmpty {
                    selectedArchetypes = Array(newArchetypes.prefix(3)) // Max 3 categories
                    fixes.append("Fixed: Selected archetypes with available cards: \(selectedArchetypes.map { $0.displayName }.joined(separator: ", "))")
                    Logger.info("AUTO-FIX: Set archetypes to: \(selectedArchetypes.map { $0.displayName })", category: .app)
                }
            }
        }

        return fixes
    }
}
