import SwiftUI
import Combine
import WidgetKit

/// Email ViewModel - Refactored (Phase 5)
/// Now delegates to specialized services instead of handling everything
/// - UserPreferencesService: handles settings, archetypes, saved deals
/// - AppStateManager: handles app state, loading, errors
/// - CardManagementService: handles card filtering, swipes, celebrations
class EmailViewModel: ObservableObject {

    // MARK: - Services (Injected)

    private let userPreferences: UserPreferencesService
    private let appState: AppStateManager
    private let cardManagement: CardManagementService
    private var cancellables = Set<AnyCancellable>()

    // MARK: - User Identity

    /// User ID derived from authenticated email account
    var userId: String {
        // Try to get email from Keychain (from authenticated session)
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: "EmailShortForm",
            kSecReturnAttributes as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)

        if status == errSecSuccess,
           let attributes = result as? [String: Any],
           let emailData = attributes[kSecAttrAccount as String] as? String {
            return emailData
        }

        return AuthContext.getUserId() // Fallback to default
    }

    // MARK: - Initialization

    init(userPreferences: UserPreferencesService,
         appState: AppStateManager,
         cardManagement: CardManagementService) {
        self.userPreferences = userPreferences
        self.appState = appState
        self.cardManagement = cardManagement

        // Forward changes from injected services to this ViewModel
        // This ensures SwiftUI re-renders when nested objects change
        userPreferences.objectWillChange.sink { [weak self] _ in
            DispatchQueue.main.async {
                self?.objectWillChange.send()
            }
        }.store(in: &cancellables)

        appState.objectWillChange.sink { [weak self] _ in
            DispatchQueue.main.async {
                self?.objectWillChange.send()
            }
        }.store(in: &cancellables)

        cardManagement.objectWillChange.sink { [weak self] _ in
            DispatchQueue.main.async {
                self?.objectWillChange.send()
            }
        }.store(in: &cancellables)

        Logger.info("EmailViewModel initialized with injected services", category: .app)
    }
    
    // MARK: - Convenience Accessors (Delegate to Services)
    
    // Cards
    var cards: [EmailCard] {
        get { cardManagement.cards }
        set { cardManagement.cards = newValue }
    }
    
    var currentIndex: Int {
        get { cardManagement.currentIndex }
        set { cardManagement.currentIndex = newValue }
    }
    
    var filteredCards: [EmailCard] {
        let filtered = cardManagement.filteredCards(
            for: userPreferences.currentArchetype,
            selectedArchetypes: userPreferences.selectedArchetypes
        )

        // Debug logging for filteredCards
        if filtered.isEmpty && !cards.isEmpty {
            Logger.warning("⚠️ EMPTY FILTERED CARDS | Total cards: \(cards.count), Current archetype: \(userPreferences.currentArchetype.rawValue), Selected archetypes: \(userPreferences.selectedArchetypes.map { $0.rawValue })", category: .card)

            // Show card type distribution
            let cardTypes = Dictionary(grouping: cards) { $0.type }
            let typeDistribution = cardTypes.map { "\($0.key.rawValue): \($0.value.count)" }.joined(separator: ", ")
            Logger.warning("Card type distribution: \(typeDistribution)", category: .card)
        }

        return filtered
    }
    
    var currentCard: EmailCard? {
        cardManagement.currentCard(
            for: userPreferences.currentArchetype,
            selectedArchetypes: userPreferences.selectedArchetypes
        )
    }
    
    // App State
    var currentAppState: AppState {
        get { appState.appState }
        set { appState.appState = newValue }
    }
    
    var isLoadingRealEmails: Bool {
        get { appState.isLoadingRealEmails }
    }
    
    var isClassifying: Bool {
        get { appState.isClassifying }
    }
    
    var realEmailError: String? {
        get { appState.realEmailError }
    }
    
    var lastAction: (card: EmailCard, previousState: CardState)? {
        get { appState.lastAction }
    }
    
    // User Preferences
    var currentArchetype: CardType {
        get { userPreferences.currentArchetype }
        set { userPreferences.currentArchetype = newValue }
    }
    
    var selectedArchetypes: [CardType] {
        get { userPreferences.selectedArchetypes }
        set { userPreferences.selectedArchetypes = newValue }
    }
    
    var savedDeals: Set<String> {
        get { userPreferences.savedDeals }
        set { userPreferences.savedDeals = newValue }
    }
    
    var emailTimeRange: EmailTimeRange {
        get { userPreferences.emailTimeRange }
        set {
            userPreferences.emailTimeRange = newValue
            // Reload emails when time range changes
            if !UserDefaults.standard.bool(forKey: "useMockData") {
                Task {
                    await loadRealEmails()
                }
            }
        }
    }
    
    var customActions: [String: String] {
        get { userPreferences.customActions }
        set { userPreferences.customActions = newValue }
    }
    
    var rememberedSnoozeDuration: Int? {
        get { userPreferences.rememberedSnoozeDuration }
    }
    
    var hasSetSnoozeDuration: Bool {
        get { userPreferences.hasSetSnoozeDuration }
    }
    
    // MARK: - Delegated Methods
    
    func setRememberedSnoozeDuration(_ duration: Int) {
        userPreferences.setRememberedSnoozeDuration(duration)
    }
    
    func toggleSavedDeal(for cardId: String) {
        userPreferences.toggleSavedDeal(for: cardId)
    }
    
    func isSaved(cardId: String) -> Bool {
        return userPreferences.isSaved(cardId: cardId)
    }
    
    func setCustomAction(for cardId: String, action: String) {
        userPreferences.setCustomAction(for: cardId, action: action)
    }
    
    func getCustomAction(for cardId: String) -> String? {
        return userPreferences.getCustomAction(for: cardId)
    }
    
    func getEffectiveAction(for card: EmailCard) -> String {
        return userPreferences.getEffectiveAction(for: card)
    }
    
    func getActionLabel(for actionId: String) -> String {
        return userPreferences.getActionLabel(for: actionId)
    }
    
    func getCompoundGroup(for actionId: String) -> [String]? {
        return userPreferences.getCompoundGroup(for: actionId)
    }
    
    func isInSameCompoundGroup(action1: String, action2: String) -> Bool {
        return userPreferences.isInSameCompoundGroup(action1: action1, action2: action2)
    }
    
    func switchToNextArchetype() {
        userPreferences.switchToNextArchetype()
        currentIndex = 0
    }
    
    func switchToPreviousArchetype() {
        userPreferences.switchToPreviousArchetype()
        currentIndex = 0
    }
    
    func handleSwipe(direction: SwipeDirection, card: EmailCard) {
        cardManagement.handleSwipe(
            direction: direction,
            card: card,
            customActions: userPreferences.customActions
        ) { [weak self] card, previousState in
            self?.appState.recordAction(card: card, previousState: previousState)
        }

        // Update widgets after swipe (unread count changed)
        syncWidgetData()

        // Check for celebration
        let celebration = cardManagement.checkForCelebration(
            currentArchetype: userPreferences.currentArchetype,
            selectedArchetypes: userPreferences.selectedArchetypes
        )

        switch celebration {
        case .major:
            appState.appState = .celebration
        case .mini(let archetype):
            appState.appState = .miniCelebration(archetype)
        case .none:
            break
        }
    }
    
    func undoLastAction() {
        guard let last = appState.lastAction else { return }
        cardManagement.undoAction(card: last.card, previousState: last.previousState)
        appState.clearLastAction()
    }
    
    func playSwipeSound(direction: SwipeDirection, isLong: Bool) {
        cardManagement.playSwipeSound(direction: direction, isLong: isLong)
    }
    
    func playCelebrationSound() {
        cardManagement.playCelebrationSound()
    }

    func updateCardPriority(cardId: String, priority: Priority) {
        cardManagement.updateCardPriority(cardId: cardId, priority: priority)
    }

    // MARK: - Card Loading (Email-specific logic stays here)
    
    func loadCards() {
        let useMockData = UserDefaults.standard.bool(forKey: "useMockData")
        Logger.info("📧 loadCards() called, useMockData: \(useMockData)", category: .email)

        if useMockData {
            // Load mock data
            Logger.info("Loading mock data via cardManagement.loadCards()", category: .email)
            cardManagement.loadCards()
        } else {
            // Load real emails from backend
            // First, try to load persisted emails to show immediately while fetching new ones
            // BUT only if we have a reasonable amount of fresh cached data
            if let persistedEmails = EmailPersistenceService.shared.loadEmails(),
               !persistedEmails.isEmpty,
               let ageInHours = EmailPersistenceService.shared.getDataAgeInHours(),
               ageInHours < 24 {  // Only use cache if less than 24 hours old
                Logger.info("📦 Loaded \(persistedEmails.count) persisted emails from cache (age: \(String(format: "%.1f", ageInHours))h)", category: .email)
                cardManagement.setCards(persistedEmails)
            } else {
                Logger.info("🔄 No valid cache found or cache expired, showing loading state", category: .email)
                // Clear cards to ensure loading state shows
                cardManagement.setCards([])
            }

            Logger.info("🔄 Real email mode: Starting real email fetch...", category: .email)
            Task {
                await loadRealEmails()
            }
        }
    }
    
    func refreshCards() {
        // Reset all cards to unseen
        for index in cards.indices {
            cards[index].state = .unseen
        }
        currentIndex = 0
        Logger.info("Refreshed all cards", category: .cards)
    }

    /// Refresh emails (pull-to-refresh) - doesn't show full-screen loading
    func refreshEmails() async {
        let useMockData = UserDefaults.standard.bool(forKey: "useMockData")

        if useMockData {
            // For mock data, force reload to get fresh cards
            Logger.info("Refreshing mock data (force reload)", category: .email)
            cardManagement.loadCards(forceReload: true)
            return
        }

        // For real emails, fetch new ones and merge with existing
        Logger.info("🔄 Refreshing real emails...", category: .email)

        do {
            let timeRange = userPreferences.emailTimeRange
            let fetchedCards = try await withTimeout(seconds: 30) {
                try await EmailAPIService.shared.fetchEmails(
                    maxResults: 50,
                    timeRange: timeRange
                )
            }

            Logger.info("✅ Refreshed: fetched \(fetchedCards.count) emails", category: .email)

            // Classify if needed
            let classifiedCards = await classifyEmailsIfNeeded(fetchedCards)

            // Merge with existing emails (deduplicates by ID)
            let mergedCards = EmailPersistenceService.shared.mergeWithPersistedEmails(newCards: classifiedCards)

            // Update cards
            cardManagement.setCards(mergedCards)

            // Persist
            EmailPersistenceService.shared.saveEmails(mergedCards)

            // Update widgets with refreshed data
            syncWidgetData()

            // Update last refresh timestamp
            UserDefaults.standard.set(Date(), forKey: "lastEmailRefresh")

            Logger.info("✅ Refresh complete: now have \(mergedCards.count) total emails", category: .email)
        } catch {
            Logger.error("❌ Refresh failed: \(error.localizedDescription)", category: .email)
            appState.setRealEmailError(error.localizedDescription)
        }
    }

    /// Get last refresh time
    func getLastRefreshTime() -> Date? {
        return UserDefaults.standard.object(forKey: "lastEmailRefresh") as? Date
    }

    /// Get last refresh time as friendly string (e.g., "2 min ago")
    func getLastRefreshTimeString() -> String {
        guard let lastRefresh = getLastRefreshTime() else {
            return "Never"
        }

        let interval = Date().timeIntervalSince(lastRefresh)
        let minutes = Int(interval / 60)

        if minutes < 1 {
            return "Just now"
        } else if minutes == 1 {
            return "1 min ago"
        } else if minutes < 60 {
            return "\(minutes) min ago"
        } else {
            let hours = minutes / 60
            return hours == 1 ? "1 hour ago" : "\(hours) hours ago"
        }
    }
    
    func loadRealEmails() async {
        let startTime = Date()
        appState.startLoadingRealEmails()

        Logger.info("🌐 loadRealEmails() called - Fetching from backend (time range: \(userPreferences.emailTimeRange.rawValue))", category: .email)

        do {
            Logger.info("📡 Calling EmailAPIService.shared.fetchEmails()...", category: .email)
            appState.updateLoadingProgress(0.2, message: "Fetching emails...")

            // Add 30 second timeout to prevent hanging forever
            // Reduced from 100 to 50 for faster initial load
            let timeRange = userPreferences.emailTimeRange
            let fetchedCards = try await withTimeout(seconds: 30) {
                try await EmailAPIService.shared.fetchEmails(
                    maxResults: 50,
                    timeRange: timeRange
                )
            }

            Logger.info("✅ Successfully fetched \(fetchedCards.count) emails from API", category: .email)
            appState.updateLoadingProgress(0.5, message: "Processing \(fetchedCards.count) emails...")

            // Show classifying state briefly
            appState.finishLoadingRealEmails()
            appState.startClassifying()

            // Classify emails using ML classifier (if not already classified by backend)
            appState.updateLoadingProgress(0.7, message: "Categorizing emails...")
            let classifiedCards = await classifyEmailsIfNeeded(fetchedCards)
            appState.updateLoadingProgress(0.9, message: "Finalizing...")

            let duration = Date().timeIntervalSince(startTime)

            // Merge with persisted emails and deduplicate
            let finalCards = EmailPersistenceService.shared.mergeWithPersistedEmails(newCards: classifiedCards)

            Logger.info("💾 Setting \(finalCards.count) cards via cardManagement.setCards()", category: .email)
            cardManagement.setCards(finalCards)
            appState.finishClassifying()

            // Persist emails to local storage for next app launch
            EmailPersistenceService.shared.saveEmails(finalCards)

            // Update widgets with new email data
            syncWidgetData()

            Logger.info("✅ Successfully loaded \(finalCards.count) real emails (took \(Int(duration * 1000))ms)", category: .email)

            // Run data integrity check
            cardManagement.runDataIntegrityCheck()

            // Analytics: Track successful email fetch
            AnalyticsService.shared.log("email_fetch_success", properties: [
                "email_count": classifiedCards.count,
                "duration_ms": Int(duration * 1000),
                "time_range": userPreferences.emailTimeRange.rawValue,
                "intents_detected": classifiedCards.filter { $0.intent != nil }.count,
                "avg_confidence": classifiedCards.compactMap { $0.intentConfidence }.reduce(0, +) / Double(max(classifiedCards.count, 1))
            ])
        } catch {
            // CRITICAL: Always clear loading state, even on error
            appState.finishLoadingRealEmails(success: false)
            appState.finishClassifying(success: false)

            // Provide more detailed error message
            let detailedError = "\(error.localizedDescription)\n\nPlease check your internet connection and try again."
            appState.setRealEmailError(detailedError)
            Logger.error("❌ ERROR fetching real emails: \(error.localizedDescription)", category: .email)

            // Log full error for debugging
            if let decodingError = error as? DecodingError {
                Logger.error("Decoding error details: \(decodingError)", category: .email)
            }

            // Analytics: Track failed email fetch
            AnalyticsService.shared.log("email_fetch_failed", properties: [
                "error": error.localizedDescription,
                "time_range": userPreferences.emailTimeRange.rawValue
            ])

            // In real email mode, NEVER fallback to mock data
            // Show empty state instead so user can retry
            Logger.info("Setting cards to empty array - showing empty state", category: .email)
            cardManagement.setCards([])
        }
    }

    /// Helper function to add timeout to async operations
    private func withTimeout<T>(seconds: TimeInterval, operation: @escaping () async throws -> T) async throws -> T {
        try await withThrowingTaskGroup(of: T.self) { group in
            // Start the operation
            group.addTask {
                try await operation()
            }

            // Start the timeout
            group.addTask {
                try await Task.sleep(nanoseconds: UInt64(seconds * 1_000_000_000))
                throw NSError(domain: "Timeout", code: -1, userInfo: [NSLocalizedDescriptionKey: "Request timed out after \(Int(seconds)) seconds. Please check your internet connection and try again."])
            }

            // Return the first one to complete (either success or timeout)
            let result = try await group.next()!
            group.cancelAll()
            return result
        }
    }
    
    // MARK: - Email Classification

    /// Classify emails using ML classifier if they don't already have intents
    /// Uses parallel batch processing for 3-5x faster classification
    private func classifyEmailsIfNeeded(_ emails: [EmailCard]) async -> [EmailCard] {
        // Check if ML classification is enabled
        let useMLClassification = UserDefaults.standard.bool(forKey: "useMLClassification")
        guard useMLClassification else {
            Logger.info("ML classification disabled, using backend classification", category: .classification)
            return emails
        }

        Logger.info("🚀 Classifying \(emails.count) emails with PARALLEL ML classifier", category: .classification)
        let startTime = Date()

        // Separate emails that need classification vs those that don't
        let (needsClassification, alreadyClassified) = emails.reduce(into: ([EmailCard](), [EmailCard]())) { result, email in
            if let intentConfidence = email.intentConfidence, intentConfidence > 0.7 {
                result.1.append(email)
            } else {
                result.0.append(email)
            }
        }

        Logger.info("📊 \(needsClassification.count) need classification, \(alreadyClassified.count) already classified", category: .classification)

        // If nothing needs classification, return early
        guard !needsClassification.isEmpty else {
            return emails
        }

        // Process in parallel batches of 5 emails at a time
        let batchSize = 5
        let batches = stride(from: 0, to: needsClassification.count, by: batchSize).map {
            Array(needsClassification[$0..<min($0 + batchSize, needsClassification.count)])
        }

        Logger.info("⚡ Processing \(batches.count) batches of up to \(batchSize) emails in parallel", category: .classification)

        var classifiedEmails: [EmailCard] = []

        // Process each batch in parallel
        for (batchIndex, batch) in batches.enumerated() {
            let batchStartTime = Date()

            // Process all emails in this batch concurrently
            let batchResults = await withTaskGroup(of: EmailCard.self, returning: [EmailCard].self) { group in
                for email in batch {
                    group.addTask {
                        await self.classifySingleEmail(email)
                    }
                }

                // Collect results
                var results: [EmailCard] = []
                for await result in group {
                    results.append(result)
                }
                return results
            }

            classifiedEmails.append(contentsOf: batchResults)

            let batchDuration = Date().timeIntervalSince(batchStartTime)
            Logger.info("✅ Batch \(batchIndex + 1)/\(batches.count) complete (\(batch.count) emails in \(Int(batchDuration * 1000))ms)", category: .classification)

            // Update progress
            let progress = 0.7 + (0.2 * Double(batchIndex + 1) / Double(batches.count))
            appState.updateLoadingProgress(progress, message: "Categorized \((batchIndex + 1) * batchSize) of \(needsClassification.count)...")
        }

        // Combine already classified + newly classified emails
        let finalEmails = alreadyClassified + classifiedEmails

        let totalDuration = Date().timeIntervalSince(startTime)
        let emailsPerSecond = Double(needsClassification.count) / totalDuration
        Logger.info("🎯 Classification complete: \(needsClassification.count) emails in \(Int(totalDuration * 1000))ms (\(String(format: "%.1f", emailsPerSecond)) emails/sec)", category: .classification)

        return finalEmails
    }

    /// Classify a single email (used by parallel batch processor)
    private func classifySingleEmail(_ email: EmailCard) async -> EmailCard {
        do {
            let result = try await ClassificationService.shared.classifyEmail(
                subject: email.title,
                from: email.sender?.name ?? "Unknown",
                body: email.body,
                snippet: email.summary
            )

            // Create enriched email with ML classification
            let enrichedEmail = EmailCard(
                id: email.id,
                type: result.type,
                state: email.state,
                priority: result.priority,
                hpa: result.hpa,
                timeAgo: email.timeAgo,
                title: email.title,
                summary: email.summary,
                body: email.body,
                htmlBody: email.htmlBody,
                metaCTA: "Swipe Right: \(result.hpa)",
                threadLength: email.threadLength,
                threadData: email.threadData,
                intent: result.intent,
                intentConfidence: result.intentConfidence,
                suggestedActions: result.suggestedActions,
                sender: email.sender,
                kid: email.kid,
                company: email.company,
                store: email.store,
                airline: email.airline,
                productImageUrl: email.productImageUrl,
                brandName: email.brandName,
                originalPrice: email.originalPrice,
                salePrice: email.salePrice,
                discount: email.discount,
                urgent: email.urgent,
                expiresIn: email.expiresIn,
                requiresSignature: email.requiresSignature,
                paymentAmount: email.paymentAmount,
                paymentDescription: email.paymentDescription,
                value: email.value,
                probability: email.probability,
                score: email.score
            )

            Logger.debug("✓ \(email.title) → \(result.type.displayName)", category: .classification)
            return enrichedEmail
        } catch {
            Logger.error("✗ Failed to classify '\(email.title)': \(error.localizedDescription)", category: .classification)
            // Keep original email if classification fails
            return email
        }
    }
    
    // MARK: - Widget Data Sync

    /// Update home screen and lock screen widgets with current inbox data
    private func syncWidgetData() {
        let unseenCards = cards.filter { $0.state == .unseen }
        let unreadCount = unseenCards.count
        let urgentCount = unseenCards.filter { $0.priority == .high || $0.priority == .critical }.count
        let topEmail = unseenCards.first
        let recentEmails = Array(unseenCards.prefix(5))

        WidgetDataService.updateWidgetData(
            unreadCount: unreadCount,
            urgentCount: urgentCount,
            topEmail: topEmail,
            recentEmails: recentEmails
        )
    }

    // MARK: - Authentication

    /// Authenticate with demo password (used by SplashView)
    @MainActor
    func authenticateWithDemoPassword(_ password: String) async throws -> String {
        Logger.info("Attempting demo authentication", category: .authentication)
        return try await EmailAPIService.shared.authenticateDemo(password: password)
    }
}
