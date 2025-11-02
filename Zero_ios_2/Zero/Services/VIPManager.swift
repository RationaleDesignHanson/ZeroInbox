import Foundation

class VIPManager {
    static let shared = VIPManager()

    private let userDefaults = UserDefaults.standard
    private let vipKey = "vipContacts"
    private let vipFilterEnabledKey = "vipFilterEnabled"

    // Notification for VIP list changes
    static let vipListDidChangeNotification = Notification.Name("vipListDidChange")

    private init() {}

    // MARK: - VIP Management

    /// Get all VIP email addresses
    var vipContacts: Set<String> {
        get {
            let contacts = userDefaults.stringArray(forKey: vipKey) ?? []
            return Set(contacts)
        }
        set {
            userDefaults.set(Array(newValue), forKey: vipKey)
            NotificationCenter.default.post(name: Self.vipListDidChangeNotification, object: nil)
            Logger.info("VIP list updated: \(newValue.count) contacts", category: .app)
        }
    }

    /// Check if an email address is VIP
    func isVIP(email: String?) -> Bool {
        guard let email = email?.lowercased() else { return false }
        return vipContacts.contains(email)
    }

    /// Check if a sender is VIP (checks sender email)
    func isVIP(sender: SenderInfo?) -> Bool {
        guard let email = sender?.email else { return false }
        return isVIP(email: email)
    }

    /// Add email to VIP list
    func addVIP(email: String) {
        let normalizedEmail = email.lowercased().trimmingCharacters(in: .whitespaces)
        guard !normalizedEmail.isEmpty else { return }

        var contacts = vipContacts
        contacts.insert(normalizedEmail)
        vipContacts = contacts

        HapticService.shared.success()
        Logger.info("⭐ Added VIP: \(normalizedEmail)", category: .app)

        // Analytics
        AnalyticsService.shared.log("vip_added", properties: [
            "email": normalizedEmail,
            "total_vips": vipContacts.count
        ])
    }

    /// Remove email from VIP list
    func removeVIP(email: String) {
        let normalizedEmail = email.lowercased().trimmingCharacters(in: .whitespaces)

        var contacts = vipContacts
        contacts.remove(normalizedEmail)
        vipContacts = contacts

        HapticService.shared.warning()
        Logger.info("Removed VIP: \(normalizedEmail)", category: .app)

        // Analytics
        AnalyticsService.shared.log("vip_removed", properties: [
            "email": normalizedEmail,
            "total_vips": vipContacts.count
        ])
    }

    /// Toggle VIP status for an email
    @discardableResult
    func toggleVIP(email: String) -> Bool {
        let normalizedEmail = email.lowercased().trimmingCharacters(in: .whitespaces)

        if isVIP(email: normalizedEmail) {
            removeVIP(email: normalizedEmail)
            return false
        } else {
            addVIP(email: normalizedEmail)
            return true
        }
    }

    /// Clear all VIPs
    func clearAllVIPs() {
        let count = vipContacts.count
        vipContacts = []
        Logger.info("Cleared all VIPs (\(count) contacts)", category: .app)
    }

    // MARK: - VIP Filter

    /// Check if VIP filter is enabled
    var isVIPFilterEnabled: Bool {
        get {
            userDefaults.bool(forKey: vipFilterEnabledKey)
        }
        set {
            userDefaults.set(newValue, forKey: vipFilterEnabledKey)
            Logger.info("VIP filter \(newValue ? "enabled" : "disabled")", category: .app)

            // Analytics
            AnalyticsService.shared.log("vip_filter_toggled", properties: [
                "enabled": newValue,
                "vip_count": vipContacts.count
            ])
        }
    }

    /// Filter emails to show only VIPs (if filter enabled)
    func filterEmails(_ emails: [EmailCard]) -> [EmailCard] {
        guard isVIPFilterEnabled else { return emails }

        return emails.filter { card in
            // Check if card has isVIP flag set
            if card.isVIP == true {
                return true
            }

            // Check sender email against VIP list
            if let senderEmail = card.sender?.email, isVIP(email: senderEmail) {
                return true
            }

            // Check company email (for companies with consistent domains)
            if let companyName = card.company?.name {
                // Check if any VIP email matches the company domain
                let companyDomain = companyName.lowercased().replacingOccurrences(of: " ", with: "")
                return vipContacts.contains { vip in
                    vip.contains(companyDomain)
                }
            }

            return false
        }
    }

    // MARK: - VIP Suggestions

    /// Get suggested VIPs based on email frequency (emails you interact with most)
    func suggestVIPs(from emails: [EmailCard], limit: Int = 5) -> [(email: String, name: String, count: Int)] {
        // Count email frequency by sender
        var senderCounts: [String: (name: String, count: Int)] = [:]

        for email in emails {
            guard let senderEmail = email.sender?.email?.lowercased() else { continue }

            // Skip if already VIP
            if isVIP(email: senderEmail) { continue }

            let senderName = email.sender?.name ?? senderEmail

            if let existing = senderCounts[senderEmail] {
                senderCounts[senderEmail] = (existing.name, existing.count + 1)
            } else {
                senderCounts[senderEmail] = (senderName, 1)
            }
        }

        // Sort by frequency and return top suggestions
        return senderCounts
            .map { (email: $0.key, name: $0.value.name, count: $0.value.count) }
            .sorted { $0.count > $1.count }
            .prefix(limit)
            .map { $0 }
    }

    // MARK: - Import/Export

    /// Export VIP list as JSON string
    func exportVIPs() -> String? {
        let contacts = Array(vipContacts)
        guard let data = try? JSONEncoder().encode(contacts),
              let json = String(data: data, encoding: .utf8) else {
            return nil
        }
        return json
    }

    /// Import VIP list from JSON string
    func importVIPs(from json: String) throws {
        guard let data = json.data(using: .utf8),
              let contacts = try? JSONDecoder().decode([String].self, from: data) else {
            throw NSError(domain: "VIPManager", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid VIP data format"])
        }

        vipContacts = Set(contacts)
        Logger.info("Imported \(contacts.count) VIP contacts", category: .app)
    }

    // MARK: - Quick VIP from Name

    /// Extract email from various sender name formats
    func extractEmail(from senderString: String) -> String? {
        // Handle formats like:
        // "John Doe <john@example.com>"
        // "john@example.com"
        // "<john@example.com>"

        if let emailMatch = senderString.range(of: "<([^>]+)>", options: .regularExpression) {
            let email = String(senderString[emailMatch])
                .replacingOccurrences(of: "<", with: "")
                .replacingOccurrences(of: ">", with: "")
            return email
        }

        // Check if the whole string is an email
        if senderString.contains("@") {
            return senderString.trimmingCharacters(in: .whitespaces)
        }

        return nil
    }
}
