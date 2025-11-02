import Foundation
import Contacts
import ContactsUI

/// Service for saving and managing contacts from emails
class ContactsService {
    static let shared = ContactsService()

    private let contactStore = CNContactStore()

    private init() {}

    // MARK: - Save Contact

    /// Request contacts access
    func requestAccess(completion: @escaping (Bool, Error?) -> Void) {
        contactStore.requestAccess(for: .contacts) { granted, error in
            completion(granted, error)
        }
    }

    /// Save contact from email sender info
    func saveContact(
        from sender: SenderInfo,
        phoneNumber: String? = nil,
        organization: String? = nil,
        notes: String? = nil,
        completion: @escaping (Result<CNContact, Error>) -> Void
    ) {
        // Request access first
        requestAccess { [weak self] granted, error in
            guard let self = self else { return }

            if let error = error {
                completion(.failure(error))
                return
            }

            guard granted else {
                completion(.failure(ContactsError.accessDenied))
                return
            }

            // Create new contact
            let contact = CNMutableContact()

            // Set name (try to parse from sender name)
            let components = self.parseFullName(sender.name)
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
                try self.contactStore.execute(saveRequest)
                Logger.info("Contact saved: \(sender.name)", category: .action)

                // Return saved contact
                completion(.success(contact as CNContact))
            } catch {
                Logger.error("Failed to save contact: \(error.localizedDescription)", category: .action)
                completion(.failure(error))
            }
        }
    }

    /// Check if contact already exists
    func contactExists(email: String, completion: @escaping (Bool, CNContact?) -> Void) {
        requestAccess { [weak self] granted, error in
            guard let self = self, granted else {
                completion(false, nil)
                return
            }

            let predicate = CNContact.predicateForContacts(matchingEmailAddress: email)
            let keysToFetch = [
                CNContactGivenNameKey as CNKeyDescriptor,
                CNContactFamilyNameKey as CNKeyDescriptor,
                CNContactEmailAddressesKey as CNKeyDescriptor,
                CNContactPhoneNumbersKey as CNKeyDescriptor,
                CNContactOrganizationNameKey as CNKeyDescriptor
            ]

            do {
                let contacts = try self.contactStore.unifiedContacts(matching: predicate, keysToFetch: keysToFetch)
                if let existingContact = contacts.first {
                    completion(true, existingContact)
                } else {
                    completion(false, nil)
                }
            } catch {
                Logger.error("Failed to check for existing contact: \(error.localizedDescription)", category: .action)
                completion(false, nil)
            }
        }
    }

    /// Update existing contact with additional info
    func updateContact(
        identifier: String,
        phoneNumber: String? = nil,
        organization: String? = nil,
        notes: String? = nil,
        completion: @escaping (Result<CNContact, Error>) -> Void
    ) {
        requestAccess { [weak self] granted, error in
            guard let self = self else { return }

            if let error = error {
                completion(.failure(error))
                return
            }

            guard granted else {
                completion(.failure(ContactsError.accessDenied))
                return
            }

            let keysToFetch = [
                CNContactGivenNameKey as CNKeyDescriptor,
                CNContactFamilyNameKey as CNKeyDescriptor,
                CNContactEmailAddressesKey as CNKeyDescriptor,
                CNContactPhoneNumbersKey as CNKeyDescriptor,
                CNContactOrganizationNameKey as CNKeyDescriptor,
                CNContactNoteKey as CNKeyDescriptor
            ]

            do {
                // Fetch existing contact
                guard let existingContact = try? self.contactStore.unifiedContact(
                    withIdentifier: identifier,
                    keysToFetch: keysToFetch
                ).mutableCopy() as? CNMutableContact else {
                    completion(.failure(ContactsError.contactNotFound))
                    return
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

                try self.contactStore.execute(saveRequest)
                Logger.info("Contact updated: \(identifier)", category: .action)

                completion(.success(existingContact as CNContact))
            } catch {
                Logger.error("Failed to update contact: \(error.localizedDescription)", category: .action)
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
