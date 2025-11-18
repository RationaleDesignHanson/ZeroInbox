//
//  FormField.swift
//  Zero
//
//  Created by Week 6 Refactoring
//  Purpose: Shared form field component
//

import SwiftUI

/// Reusable form field component
/// Week 6 Refactoring: Consolidates 100+ duplicate form field implementations
///
/// Usage:
/// ```swift
/// FormField(label: "Email", text: $email, placeholder: "Enter your email")
/// FormField(label: "Message", text: $message, placeholder: "Type message...", isMultiline: true)
/// FormField(label: "Amount", text: $amount, placeholder: "$0.00", keyboardType: .decimalPad)
/// ```
struct FormField: View {
    var label: String
    @Binding var text: String
    var placeholder: String = ""
    var isMultiline: Bool = false
    var minHeight: CGFloat = 44
    var keyboardType: UIKeyboardType = .default
    var icon: String? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.inline) {
            // Label with optional icon
            HStack(spacing: 8) {
                if let icon = icon {
                    Image(systemName: icon)
                        .foregroundColor(DesignTokens.Colors.textSubtle)
                        .font(.caption)
                }

                Text(label)
                    .font(.headline)
                    .foregroundColor(DesignTokens.Colors.textPrimary)
            }

            // Input field
            if isMultiline {
                TextEditor(text: $text)
                    .frame(minHeight: minHeight)
                    .padding(DesignTokens.Spacing.inline)
                    .background(Color.white.opacity(DesignTokens.Opacity.glassLight))
                    .cornerRadius(DesignTokens.Radius.button)
                    .foregroundColor(DesignTokens.Colors.textPrimary)
                    .scrollContentBackground(.hidden)
            } else {
                TextField(placeholder, text: $text)
                    .textFieldStyle(PlainTextFieldStyle())
                    .keyboardType(keyboardType)
                    .padding(DesignTokens.Spacing.inline)
                    .frame(minHeight: minHeight)
                    .background(Color.white.opacity(DesignTokens.Opacity.glassLight))
                    .cornerRadius(DesignTokens.Radius.button)
                    .foregroundColor(DesignTokens.Colors.textPrimary)
            }
        }
    }
}

// MARK: - Preview
#Preview {
    VStack(spacing: 20) {
        FormField(label: "Email", text: .constant("user@example.com"), placeholder: "Enter your email")
        FormField(label: "Phone", text: .constant(""), placeholder: "(555) 123-4567", keyboardType: .phonePad, icon: "phone.fill")
        FormField(label: "Amount", text: .constant("$99.99"), placeholder: "$0.00", keyboardType: .decimalPad, icon: "dollarsign.circle.fill")
        FormField(label: "Message", text: .constant("Hello world!"), placeholder: "Type your message...", isMultiline: true, minHeight: 100, icon: "message.fill")
    }
    .padding()
    .background(Color.black)
}

// MARK: - Specialized Form Fields

extension FormField {
    /// Create an email field
    static func email(label: String = "Email", text: Binding<String>, placeholder: String = "Enter your email") -> FormField {
        FormField(label: label, text: text, placeholder: placeholder, keyboardType: .emailAddress, icon: "envelope.fill")
    }

    /// Create a phone field
    static func phone(label: String = "Phone", text: Binding<String>, placeholder: String = "(555) 123-4567") -> FormField {
        FormField(label: label, text: text, placeholder: placeholder, keyboardType: .phonePad, icon: "phone.fill")
    }

    /// Create a currency field
    static func currency(label: String = "Amount", text: Binding<String>, placeholder: String = "$0.00") -> FormField {
        FormField(label: label, text: text, placeholder: placeholder, keyboardType: .decimalPad, icon: "dollarsign.circle.fill")
    }

    /// Create a URL field
    static func url(label: String = "Website", text: Binding<String>, placeholder: String = "https://example.com") -> FormField {
        FormField(label: label, text: text, placeholder: placeholder, keyboardType: .URL, icon: "link")
    }

    /// Create a multiline text field
    static func multiline(label: String, text: Binding<String>, placeholder: String, minHeight: CGFloat = 100, icon: String? = nil) -> FormField {
        FormField(label: label, text: text, placeholder: placeholder, isMultiline: true, minHeight: minHeight, icon: icon ?? "text.alignleft")
    }
}

// MARK: - Migration Notes

/*
 WEEK 6 REFACTORING: FormField Consolidation

 This component replaces 100+ duplicate form field implementations:

 BEFORE (in every modal):
 ------------------------
 VStack(alignment: .leading, spacing: 8) {
     Text("Event Title")
         .font(.headline)
         .foregroundColor(DesignTokens.Colors.textPrimary)

     TextField("", text: $eventTitle)
         .textFieldStyle(PlainTextFieldStyle())
         .padding()
         .background(Color.white.opacity(DesignTokens.Opacity.glassLight))
         .cornerRadius(DesignTokens.Radius.button)
         .foregroundColor(DesignTokens.Colors.textPrimary)
 }

 // For multiline:
 VStack(alignment: .leading, spacing: 8) {
     Text("Message")
         .font(.headline)
         .foregroundColor(DesignTokens.Colors.textPrimary)

     TextEditor(text: $message)
         .frame(minHeight: 100)
         .padding()
         .background(Color.white.opacity(DesignTokens.Opacity.glassLight))
         .cornerRadius(DesignTokens.Radius.button)
         .foregroundColor(DesignTokens.Colors.textPrimary)
 }

 AFTER:
 ------
 FormField(label: "Event Title", text: $eventTitle, placeholder: "Enter title")

 FormField(label: "Message", text: $message, placeholder: "Type message...", isMultiline: true, minHeight: 100)

 // Or use convenience methods:
 FormField.email(text: $email)
 FormField.phone(text: $phone)
 FormField.currency(text: $amount)
 FormField.multiline(label: "Notes", text: $notes, placeholder: "Add notes...")

 Benefits:
 ---------
 1. Single source of truth for form field styling
 2. Consistent input fields across all modals
 3. Type-safe keyboard types (email, phone, decimal, URL)
 4. Reduces ~15 lines per field = 1,500+ lines eliminated
 5. Built-in icon support for visual consistency
 6. Specialized field types for common use cases

 Customization Options:
 ----------------------
 - label: Field label text (required)
 - text: Binding to text value (required)
 - placeholder: Placeholder text (default: "")
 - isMultiline: Use TextEditor instead of TextField (default: false)
 - minHeight: Minimum field height (default: 44)
 - keyboardType: UIKeyboardType (default: .default)
 - icon: Optional SF Symbol icon name (default: nil)

 Specialized Methods:
 --------------------
 FormField.email(text: $email)              // Email keyboard + envelope icon
 FormField.phone(text: $phone)              // Phone keyboard + phone icon
 FormField.currency(text: $amount)          // Decimal keyboard + dollar icon
 FormField.url(text: $website)              // URL keyboard + link icon
 FormField.multiline(label:text:...)        // Multiline editor + text icon

 Files Using This Component:
 ---------------------------
 (Updated during Phase 2 of Week 6 refactoring)
 - AddToCalendarModal.swift
 - QuickReplyModal.swift
 - ContactDriverModal.swift
 - WriteReviewModal.swift
 - ... (40+ more modals)

 Future Enhancements:
 --------------------
 1. Add validation states (error borders, validation messages)
 2. Add character count for text fields
 3. Add secure text entry for passwords
 4. Add autocomplete/suggestions
 5. Add inline error messages
 6. Add focus management (next/previous field)
 7. Add clear button
 8. Add floating label animation
 */
