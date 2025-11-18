import Foundation
import Contacts
import ContactsUI

/// Service for saving and managing contacts from emails
class ContactsService {
    static let shared = ContactsService()

    private let contactStore = CNContactStore()

    private init() {}

    // MARK: - Save Contact

    /// Request contacts access (async/await)
    func requestAccess() async throws -> Bool {
        return try await withCheckedThrowingContinuation { continuation in
            contactStore.requestAccess(for: .contacts) { granted, error in
                if let error = error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume(returning: granted)
                }
            }
        }
    }

    /// Request contacts access (completion handler - backwards compatibility)
    func requestAccess(completion: @escaping (Bool, Error?) -> Void) {
        Task {
            do {
                let granted = try await requestAccess()
                completion(granted, nil)
            } catch {
                completion(false, error)
            }
        }
    }

    /// Save contact from email sender info (async/await)
    func saveContact(
        from sender: SenderInfo,
        phoneNumber: String? = nil,
        organization: String? = nil,
        notes: String? = nil
    ) async throws -> CNContact {
        // Request access first
        let granted = try await requestAccess()
        guard granted else {
            throw ContactsError.accessDenied
        }

        // Create new contact
        let contact = CNMutableContact()

        // Set name (try to parse from sender name)
        let components = parseFullName(sender.name)
        contact.givenName = components.givenName
        contact.familyName = components.familyName

        // Add email (if available)
        if let emailAddress = sender.email {
            let email = CNLabeledValue(label: CNLabelWork, value: emailAddress as NSString)
            contact.emailAddresses = [email]
        }

        // Add phone number if provided
        if let phone = phoneNumber {
            let phoneValue = CNLabeledValue(
                label: CNLabelPhoneNumberMobile,
                value: CNPhoneNumber(stringValue: phone)
            )
            contact.phoneNumbers = [phoneValue]
        }

        // Add organization if provided
        if let org = organization {
            contact.organizationName = org
        }

        // Add notes if provided
        if let notes = notes {
            contact.note = notes
        }

        // Save contact
        let saveRequest = CNSaveRequest()
        saveRequest.add(contact, toContainerWithIdentifier: nil)

        do {
            try contactStore.execute(saveRequest)
            Logger.info("Contact saved: \(sender.name)", category: .action)

            // Return saved contact
            return contact as CNContact
        } catch {
            Logger.error("Failed to save contact: \(error.localizedDescription)", category: .action)
            throw error
        }
    }

    /// Save contact from email sender info (completion handler - backwards compatibility)
    func saveContact(
        from sender: SenderInfo,
        phoneNumber: String? = nil,
        organization: String? = nil,
        notes: String? = nil,
        completion: @escaping (Result<CNContact, Error>) -> Void
    ) {
        Task {
            do {
                let contact = try await saveContact(
                    from: sender,
                    phoneNumber: phoneNumber,
                    organization: organization,
                    notes: notes
                )
                completion(.success(contact))
            } catch {
                completion(.failure(error))
            }
        }
    }

    /// Check if contact already exists (async/await)
    func contactExists(email: String) async -> (exists: Bool, contact: CNContact?) {
        do {
            let granted = try await requestAccess()
            guard granted else {
                return (false, nil)
            }

            let predicate = CNContact.predicateForContacts(matchingEmailAddress: email)
            let keysToFetch = [
                CNContactGivenNameKey as CNKeyDescriptor,
                CNContactFamilyNameKey as CNKeyDescriptor,
                CNContactEmailAddressesKey as CNKeyDescriptor,
                CNContactPhoneNumbersKey as CNKeyDescriptor,
                CNContactOrganizationNameKey as CNKeyDescriptor
            ]

            let contacts = try contactStore.unifiedContacts(matching: predicate, keysToFetch: keysToFetch)
            if let existingContact = contacts.first {
                return (true, existingContact)
            } else {
                return (false, nil)
            }
        } catch {
            Logger.error("Failed to check for existing contact: \(error.localizedDescription)", category: .action)
            return (false, nil)
        }
    }

    /// Check if contact already exists (completion handler - backwards compatibility)
    func contactExists(email: String, completion: @escaping (Bool, CNContact?) -> Void) {
        Task {
            let result = await contactExists(email: email)
            completion(result.exists, result.contact)
        }
    }

    /// Update existing contact with additional info (async/await)
    func updateContact(
        identifier: String,
        phoneNumber: String? = nil,
        organization: String? = nil,
        notes: String? = nil
    ) async throws -> CNContact {
        // Request access first
        let granted = try await requestAccess()
        guard granted else {
            throw ContactsError.accessDenied
        }

        let keysToFetch = [
            CNContactGivenNameKey as CNKeyDescriptor,
            CNContactFamilyNameKey as CNKeyDescriptor,
            CNContactEmailAddressesKey as CNKeyDescriptor,
            CNContactPhoneNumbersKey as CNKeyDescriptor,
            CNContactOrganizationNameKey as CNKeyDescriptor,
            CNContactNoteKey as CNKeyDescriptor
        ]

        // Fetch existing contact
        guard let existingContact = try? contactStore.unifiedContact(
            withIdentifier: identifier,
            keysToFetch: keysToFetch
        ).mutableCopy() as? CNMutableContact else {
            throw ContactsError.contactNotFound
        }

        // Update phone number
        if let phone = phoneNumber {
            let phoneValue = CNLabeledValue(
                label: CNLabelPhoneNumberMobile,
                value: CNPhoneNumber(stringValue: phone)
            )
            existingContact.phoneNumbers.append(phoneValue)
        }

        // Update organization
        if let org = organization {
            existingContact.organizationName = org
        }

        // Append to notes
        if let notes = notes {
            if existingContact.note.isEmpty {
                existingContact.note = notes
            } else {
                existingContact.note += "\n\n\(notes)"
            }
        }

        // Save updates
        let saveRequest = CNSaveRequest()
        saveRequest.update(existingContact)

        do {
            try contactStore.execute(saveRequest)
            Logger.info("Contact updated: \(identifier)", category: .action)

            return existingContact as CNContact
        } catch {
            Logger.error("Failed to update contact: \(error.localizedDescription)", category: .action)
            throw error
        }
    }

    /// Update existing contact with additional info (completion handler - backwards compatibility)
    func updateContact(
        identifier: String,
        phoneNumber: String? = nil,
        organization: String? = nil,
        notes: String? = nil,
        completion: @escaping (Result<CNContact, Error>) -> Void
    ) {
        Task {
            do {
                let contact = try await updateContact(
                    identifier: identifier,
                    phoneNumber: phoneNumber,
                    organization: organization,
                    notes: notes
                )
                completion(.success(contact))
            } catch {
                completion(.failure(error))
            }
        }
    }

    // MARK: - Helper Methods

    private func parseFullName(_ fullName: String) -> (givenName: String, familyName: String) {
        let components = fullName.trimmingCharacters(in: .whitespaces).components(separatedBy: " ")

        if components.count == 1 {
            return (givenName: components[0], familyName: "")
        } else if components.count >= 2 {
            let givenName = components.first ?? ""
            let familyName = components.dropFirst().joined(separator: " ")
            return (givenName: givenName, familyName: familyName)
        }

        return (givenName: fullName, familyName: "")
    }

    // MARK: - Extract Contact Info from Email

    /// Extract phone numbers from email text
    func extractPhoneNumbers(from text: String) -> [String] {
        var phoneNumbers: [String] = []

        // Pattern for US phone numbers (various formats)
        let patterns = [
            #"\b\d{3}[-.]?\d{3}[-.]?\d{4}\b"#,           // 123-456-7890 or 1234567890
            #"\b\(\d{3}\)\s*\d{3}[-.]?\d{4}\b"#,         // (123) 456-7890
            #"\b\+1\s*\d{3}[-.]?\d{3}[-.]?\d{4}\b"#      // +1 123-456-7890
        ]

        for pattern in patterns {
            if let regex = try? NSRegularExpression(pattern: pattern, options: []) {
                let matches = regex.matches(in: text, range: NSRange(text.startIndex..., in: text))
                for match in matches {
                    if let range = Range(match.range, in: text) {
                        let phone = String(text[range])
                            .replacingOccurrences(of: #"[^\d+]"#, with: "", options: .regularExpression)
                        if !phoneNumbers.contains(phone) {
                            phoneNumbers.append(phone)
                        }
                    }
                }
            }
        }

        return phoneNumbers
    }

    /// Detect if email contains contact-worthy information
    func detectContactOpportunity(in card: EmailCard) -> ContactOpportunity? {
        guard let sender = card.sender else { return nil }

        let text = "\(card.title) \(card.summary) \(card.body ?? "")".lowercased()

        // Check if this looks like a business/professional contact
        let businessKeywords = ["driver", "delivery", "support", "customer service", "representative", "agent", "contact"]
        let hasBusinessKeyword = businessKeywords.contains { text.contains($0) }

        // Extract phone numbers
        let phoneNumbers = extractPhoneNumbers(from: "\(card.title) \(card.summary) \(card.body ?? "")")

        // Only suggest if we have additional info beyond just email
        if hasBusinessKeyword || !phoneNumbers.isEmpty || card.company != nil {
            return ContactOpportunity(
                sender: sender,
                suggestedName: sender.name,
                suggestedPhoneNumbers: phoneNumbers,
                suggestedOrganization: card.company?.name,
                reason: hasBusinessKeyword ? "This email contains contact information" : "Save this contact for future reference"
            )
        }

        return nil
    }
}

// MARK: - Models

struct ContactOpportunity {
    let sender: SenderInfo
    let suggestedName: String
    let suggestedPhoneNumbers: [String]
    let suggestedOrganization: String?
    let reason: String
}

// MARK: - Errors

enum ContactsError: LocalizedError {
    case accessDenied
    case contactNotFound
    case saveFailed(Error)

    var errorDescription: String? {
        switch self {
        case .accessDenied:
            return "Contacts access was denied. Please enable it in Settings."
        case .contactNotFound:
            return "Contact not found"
        case .saveFailed(let error):
            return "Failed to save contact: \(error.localizedDescription)"
        }
    }
}
