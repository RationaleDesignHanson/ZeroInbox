import SwiftUI
import Contacts

struct SaveContactModal: View {
    let card: EmailCard
    @Binding var isPresented: Bool

    @State private var contactName = ""
    @State private var email = ""
    @State private var phoneNumber = ""
    @State private var organization = ""
    @State private var notes = ""
    @State private var contactExists = false
    @State private var existingContact: CNContact?
    @State private var showSuccess = false
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var isCheckingExisting = true

    var body: some View {
        VStack(spacing: 0) {
            // Custom header bar
            HStack {
                Spacer()
                Button {
                    isPresented = false
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(DesignTokens.Colors.textSubtle)
                        .font(.title2)
                }
            }
            .padding()

            // Scrollable content
            ScrollView {
                VStack(alignment: .leading, spacing: DesignTokens.Spacing.card) {
                    // Header
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Image(systemName: "person.crop.circle.badge.plus")
                                .font(.title)
                                .foregroundColor(.blue)

                            VStack(alignment: .leading, spacing: 4) {
                                Text(contactExists ? "Update Contact" : "Save Contact")
                                    .font(.title2.bold())
                                    .foregroundColor(DesignTokens.Colors.textPrimary)

                                Text(card.title)
                                    .font(.subheadline)
                                    .foregroundColor(DesignTokens.Colors.textSubtle)
                            }
                        }
                    }

                    Divider()
                        .background(Color.white.opacity(DesignTokens.Opacity.overlayMedium))

                    // Existing contact notice
                    if isCheckingExisting {
                        HStack {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            Text("Checking for existing contact...")
                                .font(.caption)
                                .foregroundColor(DesignTokens.Colors.textSubtle)
                        }
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.white.opacity(DesignTokens.Opacity.glassUltraLight))
                        .cornerRadius(DesignTokens.Radius.chip)
                    } else if contactExists, let existing = existingContact {
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Image(systemName: "info.circle.fill")
                                    .foregroundColor(.blue)
                                Text("Contact Already Exists")
                                    .font(.subheadline.bold())
                                    .foregroundColor(DesignTokens.Colors.textPrimary)
                            }

                            Text("We found an existing contact for this email. You can update it with additional information below.")
                                .font(.caption)
                                .foregroundColor(DesignTokens.Colors.textSecondary)

                            // Show existing contact info
                            VStack(alignment: .leading, spacing: 4) {
                                if !existing.givenName.isEmpty {
                                    Text("Name: \(existing.givenName) \(existing.familyName)")
                                        .font(.caption2)
                                        .foregroundColor(DesignTokens.Colors.textTertiary)
                                }
                                if !existing.emailAddresses.isEmpty {
                                    Text("Email: \(existing.emailAddresses.first?.value as? String ?? "")")
                                        .font(.caption2)
                                        .foregroundColor(DesignTokens.Colors.textTertiary)
                                }
                            }
                            .padding(.leading)
                        }
                        .padding()
                        .background(Color.blue.opacity(DesignTokens.Opacity.overlayLight))
                        .cornerRadius(DesignTokens.Radius.button)
                    }

                    // Name Field
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Name")
                            .font(.headline)
                            .foregroundColor(DesignTokens.Colors.textPrimary)

                        TextField("", text: $contactName)
                            .textFieldStyle(PlainTextFieldStyle())
                            .padding()
                            .background(Color.white.opacity(DesignTokens.Opacity.glassLight))
                            .cornerRadius(DesignTokens.Radius.button)
                            .foregroundColor(DesignTokens.Colors.textPrimary)
                            .autocapitalization(.words)
                            .disabled(contactExists)
                            .overlay(
                                RoundedRectangle(cornerRadius: DesignTokens.Radius.button)
                                    .strokeBorder(Color.white.opacity(DesignTokens.Opacity.overlayMedium), lineWidth: 1)
                            )
                    }

                    // Email Field
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Email")
                            .font(.headline)
                            .foregroundColor(DesignTokens.Colors.textPrimary)

                        TextField("", text: $email)
                            .textFieldStyle(PlainTextFieldStyle())
                            .padding()
                            .background(Color.white.opacity(DesignTokens.Opacity.glassLight))
                            .cornerRadius(DesignTokens.Radius.button)
                            .foregroundColor(DesignTokens.Colors.textPrimary)
                            .keyboardType(.emailAddress)
                            .autocapitalization(.none)
                            .disabled(contactExists)
                            .overlay(
                                RoundedRectangle(cornerRadius: DesignTokens.Radius.button)
                                    .strokeBorder(Color.white.opacity(DesignTokens.Opacity.overlayMedium), lineWidth: 1)
                            )
                    }

                    // Phone Number Field
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Phone Number (Optional)")
                            .font(.headline)
                            .foregroundColor(DesignTokens.Colors.textPrimary)

                        TextField("", text: $phoneNumber)
                            .textFieldStyle(PlainTextFieldStyle())
                            .padding()
                            .background(Color.white.opacity(DesignTokens.Opacity.glassLight))
                            .cornerRadius(DesignTokens.Radius.button)
                            .foregroundColor(DesignTokens.Colors.textPrimary)
                            .keyboardType(.phonePad)
                            .overlay(
                                RoundedRectangle(cornerRadius: DesignTokens.Radius.button)
                                    .strokeBorder(Color.white.opacity(DesignTokens.Opacity.overlayMedium), lineWidth: 1)
                            )
                    }

                    // Organization Field
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Organization (Optional)")
                            .font(.headline)
                            .foregroundColor(DesignTokens.Colors.textPrimary)

                        TextField("", text: $organization)
                            .textFieldStyle(PlainTextFieldStyle())
                            .padding()
                            .background(Color.white.opacity(DesignTokens.Opacity.glassLight))
                            .cornerRadius(DesignTokens.Radius.button)
                            .foregroundColor(DesignTokens.Colors.textPrimary)
                            .disabled(contactExists)
                            .overlay(
                                RoundedRectangle(cornerRadius: DesignTokens.Radius.button)
                                    .strokeBorder(Color.white.opacity(DesignTokens.Opacity.overlayMedium), lineWidth: 1)
                            )
                    }

                    // Notes Field
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Notes (Optional)")
                            .font(.headline)
                            .foregroundColor(DesignTokens.Colors.textPrimary)

                        TextEditor(text: $notes)
                            .frame(height: 80)
                            .padding()
                            .background(Color.white.opacity(DesignTokens.Opacity.glassLight))
                            .cornerRadius(DesignTokens.Radius.button)
                            .foregroundColor(DesignTokens.Colors.textPrimary)
                            .colorScheme(.dark)
                            .scrollContentBackground(.hidden)
                            .overlay(
                                RoundedRectangle(cornerRadius: DesignTokens.Radius.button)
                                    .strokeBorder(Color.white.opacity(DesignTokens.Opacity.overlayMedium), lineWidth: 1)
                            )
                    }

                    // Save Contact button
                    Button {
                        saveContact()
                    } label: {
                        HStack {
                            Image(systemName: contactExists ? "person.crop.circle.badge.checkmark" : "person.crop.circle.badge.plus")
                            Text(contactExists ? "Update Contact" : "Save Contact")
                                .font(.headline)
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(email.isEmpty ? Color.gray : Color.blue)
                        .foregroundColor(DesignTokens.Colors.textPrimary)
                        .cornerRadius(DesignTokens.Radius.button)
                    }
                    .disabled(email.isEmpty)

                    // Success message
                    if showSuccess {
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                            Text(contactExists ? "Contact Updated!" : "Contact Saved!")
                                .foregroundColor(.green)
                                .font(.subheadline.bold())
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.green.opacity(DesignTokens.Opacity.overlayLight))
                        .cornerRadius(DesignTokens.Radius.button)
                    }

                    // Error message
                    if showError {
                        HStack {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundColor(.red)
                            Text(errorMessage)
                                .foregroundColor(.red)
                                .font(.caption)
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.red.opacity(DesignTokens.Opacity.overlayLight))
                        .cornerRadius(DesignTokens.Radius.button)
                    }
                }
                .padding(DesignTokens.Spacing.card)
            }
        }
        .onAppear {
            detectContactInfo()
        }
    }

    func detectContactInfo() {
        // Get sender info
        if let sender = card.sender {
            contactName = sender.name
            email = sender.email ?? ""

            // Check if contact already exists
            ContactsService.shared.contactExists(email: email) { exists, existing in
                DispatchQueue.main.async {
                    self.contactExists = exists
                    self.existingContact = existing
                    self.isCheckingExisting = false

                    if exists {
                        // Pre-fill with existing info
                        if let contact = existing {
                            contactName = "\(contact.givenName) \(contact.familyName)".trimmingCharacters(in: .whitespaces)
                            if !contact.phoneNumbers.isEmpty {
                                phoneNumber = contact.phoneNumbers.first?.value.stringValue ?? ""
                            }
                            organization = contact.organizationName
                            notes = contact.note
                        }
                    }
                }
            }
        }

        // Try to extract phone number from email
        let phoneNumbers = ContactsService.shared.extractPhoneNumbers(
            from: "\(card.title) \(card.summary) \(card.body ?? "")"
        )
        if !phoneNumbers.isEmpty, phoneNumber.isEmpty {
            phoneNumber = phoneNumbers.first ?? ""
        }

        // Use company as organization
        if let company = card.company, organization.isEmpty {
            organization = company.name
        }

        // Generate notes from email context
        if notes.isEmpty {
            notes = "Contact from email: \(card.title)\n\(card.summary)"
        }
    }

    func saveContact() {
        guard let sender = card.sender else { return }

        showError = false
        showSuccess = false

        if contactExists, let existing = existingContact {
            // Update existing contact
            ContactsService.shared.updateContact(
                identifier: existing.identifier,
                phoneNumber: phoneNumber.isEmpty ? nil : phoneNumber,
                organization: organization.isEmpty ? nil : organization,
                notes: notes.isEmpty ? nil : notes
            ) { result in
                handleSaveResult(result, isUpdate: true)
            }
        } else {
            // Create new contact
            ContactsService.shared.saveContact(
                from: sender,
                phoneNumber: phoneNumber.isEmpty ? nil : phoneNumber,
                organization: organization.isEmpty ? nil : organization,
                notes: notes.isEmpty ? nil : notes
            ) { result in
                handleSaveResult(result, isUpdate: false)
            }
        }
    }

    func handleSaveResult(_ result: Result<CNContact, Error>, isUpdate: Bool) {
        DispatchQueue.main.async {
            switch result {
            case .success:
                showSuccess = true
                Logger.info("Contact \(isUpdate ? "updated" : "saved"): \(email)", category: .action)

                // Haptic feedback
                let impact = UINotificationFeedbackGenerator()
                impact.notificationOccurred(.success)

                // Auto-dismiss after success
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                    isPresented = false
                }

            case .failure(let error):
                showError = true
                errorMessage = error.localizedDescription
                Logger.error("Failed to \(isUpdate ? "update" : "save") contact: \(error.localizedDescription)", category: .action)

                // Haptic feedback
                let impact = UINotificationFeedbackGenerator()
                impact.notificationOccurred(.error)
            }
        }
    }
}
