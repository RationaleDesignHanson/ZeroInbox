import Foundation
import SwiftUI

/// User Preferences Service
/// Manages user settings, archetypes, saved deals, and persistence
class UserPreferencesService: ObservableObject {
    
    // MARK: - Published Properties
    
    /// Currently selected archetype
    @Published var currentArchetype: CardType = .mail

    /// User's selected archetypes (filtered card types) - v1.10+: 2 binary categories
    @Published var selectedArchetypes: [CardType] = [
        .mail,
        .ads
    ] {
        didSet {
            saveSelectedArchetypes()
            Logger.info("Selected archetypes updated: \(selectedArchetypes.map { $0.rawValue })", category: .userPreferences)
        }
    }
    
    /// Saved deals (card IDs bookmarked by user)
    @Published var savedDeals: Set<String> = [] {
        didSet {
            saveSavedDeals()
            Logger.info("Saved deals updated: \(savedDeals.count) items", category: .userPreferences)
        }
    }
    
    /// Email time range filter
    @Published var emailTimeRange: EmailTimeRange = .twoWeeks {
        didSet {
            saveEmailTimeRange()
            Logger.info("Email time range changed: \(emailTimeRange.rawValue)", category: .userPreferences)
        }
    }
    
    /// Remembered snooze duration (session memory)
    @Published var rememberedSnoozeDuration: Int? = nil
    
    /// Whether user has set a snooze duration this session
    @Published var hasSetSnoozeDuration: Bool = false
    
    /// Custom actions per card (cardId -> actionId)
    @Published var customActions: [String: String] = [:]

    /// Whether user has premium subscription
    @Published var isPremiumUser: Bool = false {
        didSet {
            savePremiumStatus()
            Logger.info("Premium status updated: \(isPremiumUser)", category: .userPreferences)
        }
    }

    // MARK: - Initialization
    
    init() {
        loadSelectedArchetypes()
        loadEmailTimeRange()
        loadSavedDeals()
        loadPremiumStatus()
        Logger.info("User preferences loaded", category: .userPreferences)
    }
    
    // MARK: - Snooze Duration
    
    func setRememberedSnoozeDuration(_ duration: Int) {
        rememberedSnoozeDuration = duration
        hasSetSnoozeDuration = true
        Logger.info("Snooze duration set: \(duration)h", category: .userPreferences)
    }
    
    // MARK: - Saved Deals
    
    func toggleSavedDeal(for cardId: String) {
        if savedDeals.contains(cardId) {
            savedDeals.remove(cardId)
            Logger.info("Deal unsaved: \(cardId)", category: .userPreferences)
        } else {
            savedDeals.insert(cardId)
            Logger.info("Deal saved: \(cardId)", category: .userPreferences)
        }
    }
    
    func isSaved(cardId: String) -> Bool {
        return savedDeals.contains(cardId)
    }
    
    // MARK: - Archetype Navigation
    
    func switchToNextArchetype() {
        Logger.info("🔄 switchToNextArchetype() called", category: .userPreferences)
        Logger.info("   Current: \(currentArchetype.rawValue)", category: .userPreferences)
        Logger.info("   Selected archetypes: \(selectedArchetypes.map { $0.rawValue })", category: .userPreferences)

        guard let currentIndex = selectedArchetypes.firstIndex(of: currentArchetype) else {
            Logger.warning("   ⚠️ Current archetype '\(currentArchetype.rawValue)' not found in selectedArchetypes!", category: .userPreferences)
            return
        }

        Logger.info("   Current index: \(currentIndex)", category: .userPreferences)
        let nextIndex = (currentIndex + 1) % selectedArchetypes.count
        Logger.info("   Next index: \(nextIndex) (after modulo \(selectedArchetypes.count))", category: .userPreferences)

        currentArchetype = selectedArchetypes[nextIndex]
        Logger.info("   ✅ Switched to: \(currentArchetype.rawValue)", category: .userPreferences)
    }
    
    func switchToPreviousArchetype() {
        Logger.info("🔄 switchToPreviousArchetype() called", category: .userPreferences)
        Logger.info("   Current: \(currentArchetype.rawValue)", category: .userPreferences)
        Logger.info("   Selected archetypes: \(selectedArchetypes.map { $0.rawValue })", category: .userPreferences)

        guard let currentIndex = selectedArchetypes.firstIndex(of: currentArchetype) else {
            Logger.warning("   ⚠️ Current archetype '\(currentArchetype.rawValue)' not found in selectedArchetypes!", category: .userPreferences)
            return
        }

        Logger.info("   Current index: \(currentIndex)", category: .userPreferences)
        let previousIndex = (currentIndex - 1 + selectedArchetypes.count) % selectedArchetypes.count
        Logger.info("   Previous index: \(previousIndex) (after modulo \(selectedArchetypes.count))", category: .userPreferences)

        currentArchetype = selectedArchetypes[previousIndex]
        Logger.info("   ✅ Switched to: \(currentArchetype.rawValue)", category: .userPreferences)
    }
    
    // MARK: - Custom Actions
    
    /// Define compound action groups (actions that should be treated as equivalent)
    private let compoundGroups: [[String]] = [
        ["add_to_calendar", "schedule_meeting"]
    ]
    
    func getCompoundGroup(for actionId: String) -> [String]? {
        return compoundGroups.first { $0.contains(actionId) }
    }
    
    func isInSameCompoundGroup(action1: String, action2: String) -> Bool {
        return compoundGroups.contains { group in
            group.contains(action1) && group.contains(action2)
        }
    }
    
    func setCustomAction(for cardId: String, action: String) {
        // Create a new dictionary to force @Published to trigger
        // Dictionary mutations don't reliably trigger SwiftUI updates
        var newActions = customActions
        newActions[cardId] = action
        customActions = newActions

        // Double-ensure update propagates
        DispatchQueue.main.async {
            self.objectWillChange.send()
        }

        Logger.info("✅ Custom action set for card \(cardId): \(action)", category: .userPreferences)
        Logger.info("📋 Total custom actions: \(customActions.count)", category: .userPreferences)
    }
    
    func getCustomAction(for cardId: String) -> String? {
        return customActions[cardId]
    }
    
    func getEffectiveAction(for card: EmailCard) -> String {
        return customActions[card.id] ?? card.suggestedAction
    }
    
    func getActionLabel(for actionId: String) -> String {
        switch actionId {
        // Documents & Files
        case "view_document": return "View"
        case "view_spreadsheet": return "View Spreadsheet"
        case "sign_form": return "Sign"
        case "sign_send": return "Sign & Send"
        case "review_attachment": return "Review"
        case "review_approve": return "Review & Approve"
        case "forward": return "Forward"

        // Calendar & Meetings
        case "schedule_meeting": return "Schedule"
        case "add_to_calendar": return "Add to Calendar"
        case "join_meeting": return "Join Meeting"
        case "rsvp_yes": return "RSVP Yes"
        case "rsvp_no": return "RSVP No"
        case "register_event": return "Register"

        // Shopping & E-commerce
        case "view_product": return "View Product"
        case "add_to_cart": return "Add to Cart"
        case "schedule_purchase": return "Buy Later"
        case "claim_deal": return "Claim Deal"
        case "save_deal": return "Save for Later"
        case "view_offer": return "View Offer"
        case "compare": return "Compare"
        case "track_package": return "Track Package"
        case "view_order": return "View Order"
        case "buy_again": return "Buy Again"
        case "return_item": return "Return Item"
        case "complete_cart": return "Complete Order"
        case "copy_promo_code": return "Copy Code"
        case "set_reminder": return "Set Reminder"

        // Billing & Payments
        case "pay_invoice": return "Pay Invoice"
        case "view_invoice": return "View Invoice"
        case "download_receipt": return "Download Receipt"
        case "manage_subscription": return "Manage Subscription"
        case "update_payment": return "Update Payment"
        case "set_payment_reminder": return "Set Reminder"
        case "pay_form_fee": return "Pay Fee"

        // Travel
        case "check_in_flight": return "Check In"
        case "view_itinerary": return "View Itinerary"
        case "add_to_wallet": return "Add to Wallet"
        case "manage_booking": return "Manage Booking"

        // Account & Security
        case "reset_password": return "Reset Password"
        case "verify_account": return "Verify Account"
        case "verify_device": return "Verify Device"
        case "review_security": return "Review Security"
        case "revoke_secret": return "Revoke Secret"

        // Education & Family
        case "view_assignment": return "View Assignment"
        case "check_grade": return "Check Grade"

        // Healthcare
        case "check_in_appointment": return "Check In"
        case "get_directions": return "Get Directions"
        case "view_pickup_details": return "View Pickup"
        case "view_results": return "View Results"

        // Dining & Delivery
        case "view_reservation": return "View Reservation"
        case "modify_reservation": return "Modify Reservation"
        case "track_delivery": return "Track Delivery"
        case "contact_driver": return "Contact Driver"

        // Feedback & Reviews
        case "write_review": return "Write Review"
        case "rate_product": return "Rate Product"
        case "take_survey": return "Take Survey"

        // Project & Support
        case "view_task": return "View Task"
        case "view_incident": return "View Incident"
        case "view_ticket": return "View Ticket"
        case "reply_to_ticket": return "Reply"
        case "contact_support": return "Contact Support"

        // Apps & Links
        case "open_app": return "Open App"
        case "open_link": return "Open"
        case "view_details": return "View Details"

        // Email Actions
        case "reply": return "Reply"
        case "quick_reply": return "Quick Reply"
        case "compose": return "Compose"
        case "acknowledge": return "Acknowledge"
        case "save_for_later": return "Save for Later"

        // Default
        default: return "View"
        }
    }
    
    // MARK: - Persistence
    
    private func saveSelectedArchetypes() {
        let rawValues = selectedArchetypes.map { $0.rawValue }
        UserDefaults.standard.set(rawValues, forKey: "selectedArchetypes")
    }
    
    private func loadSelectedArchetypes() {
        if let rawValues = UserDefaults.standard.array(forKey: "selectedArchetypes") as? [String] {
            // v1.10 Migration: All legacy categories → Binary mail/ads system
            let legacyToV110Map: [String: CardType] = [
                // v1.7-1.9 4-category names → v1.10+ binary
                "personal": .mail,
                "lifestyle": .mail,
                "work": .mail,
                "shop": .ads,

                // v1.0-1.6 8-category names → v1.10+ binary
                "family": .mail,
                "shopping": .ads,
                "billing": .mail,
                "sales": .mail,
                "project": .mail,
                "learning": .mail,
                "travel": .mail,
                "account": .mail,

                // Pre-v1.0 legacy names → v1.10+ binary
                "caregiver": .mail,
                "education": .mail,
                "deal_stacker": .ads,
                "status_seeker": .ads,
                "transactional_leader": .mail,
                "sales_hunter": .mail,
                "project_coordinator": .mail,
                "enterprise_innovator": .mail,
                "identity_manager": .mail
            ]

            var archetypes: [CardType] = []
            for rawValue in rawValues {
                // Try v1.10+ binary names first (mail, ads)
                if let cardType = CardType(rawValue: rawValue),
                   [CardType.mail, .ads].contains(cardType) {
                    archetypes.append(cardType)
                } else if let modernType = legacyToV110Map[rawValue] {
                    // Migrate from legacy names to v1.10+ binary
                    archetypes.append(modernType)
                    Logger.info("Migrated '\(rawValue)' → '\(modernType.rawValue)'", category: .userPreferences)
                }
            }

            // Remove duplicates (multiple legacy types map to same binary category)
            let uniqueArchetypes = Array(Set(archetypes)).sorted { first, second in
                // Mail first, then Ads
                let order: [CardType] = [.mail, .ads]
                return order.firstIndex(of: first) ?? 0 < order.firstIndex(of: second) ?? 0
            }

            if !uniqueArchetypes.isEmpty {
                // v1.10+ requires BOTH binary categories (mail + ads)
                // If migration resulted in only one category (e.g., ["personal", "work"] → [.mail]),
                // ensure we have both categories for proper navigation
                var finalArchetypes = uniqueArchetypes

                if !finalArchetypes.contains(.mail) {
                    finalArchetypes.insert(.mail, at: 0)
                    Logger.info("Added missing .mail category after migration", category: .userPreferences)
                }
                if !finalArchetypes.contains(.ads) {
                    finalArchetypes.append(.ads)
                    Logger.info("Added missing .ads category after migration", category: .userPreferences)
                }

                selectedArchetypes = finalArchetypes
                currentArchetype = finalArchetypes.first ?? .mail
                Logger.info("Loaded v1.10+ archetypes: \(finalArchetypes.map { $0.rawValue })", category: .userPreferences)

                // Save migrated archetypes back to UserDefaults
                saveSelectedArchetypes()
            } else {
                // If migration resulted in empty list, use v1.10+ binary defaults
                Logger.info("Migration resulted in empty archetypes, using v1.10+ defaults", category: .userPreferences)
                selectedArchetypes = [.mail, .ads]
                currentArchetype = .mail
                saveSelectedArchetypes()
            }
        }
    }
    
    private func saveSavedDeals() {
        UserDefaults.standard.set(Array(savedDeals), forKey: "savedDeals")
    }
    
    private func loadSavedDeals() {
        if let deals = UserDefaults.standard.array(forKey: "savedDeals") as? [String] {
            savedDeals = Set(deals)
            Logger.info("Loaded \(deals.count) saved deals", category: .userPreferences)
        }
    }
    
    private func saveEmailTimeRange() {
        UserDefaults.standard.set(emailTimeRange.rawValue, forKey: "emailTimeRange")
    }
    
    private func loadEmailTimeRange() {
        if let rawValue = UserDefaults.standard.string(forKey: "emailTimeRange"),
           let timeRange = EmailTimeRange(rawValue: rawValue) {
            emailTimeRange = timeRange
            Logger.info("Loaded email time range: \(timeRange.rawValue)", category: .userPreferences)
        }
    }

    // MARK: - Premium Status Persistence

    private func savePremiumStatus() {
        UserDefaults.standard.set(isPremiumUser, forKey: "isPremiumUser")
    }

    private func loadPremiumStatus() {
        isPremiumUser = UserDefaults.standard.bool(forKey: "isPremiumUser")
        Logger.info("Loaded premium status: \(isPremiumUser)", category: .userPreferences)
    }

    /// Set premium status (for in-app purchase completion or subscription restore)
    func setPremiumUser(_ isPremium: Bool) {
        isPremiumUser = isPremium
        Logger.info("Premium user status set to: \(isPremium)", category: .userPreferences)
    }

    /// Check if user has access to premium feature
    func hasPremiumAccess() -> Bool {
        return isPremiumUser
    }
}



