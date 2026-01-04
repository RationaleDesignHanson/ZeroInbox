import Foundation

/// Wave 2 Config Decoding Test
/// Attempts to decode all Wave 2 configs using ModalConfig.load()

print("\n========================================")
print("🧪 Wave 2 Config Decoding Test")
print("Testing ModalConfig.load() with Swift decoding")
print("========================================\n")

let wave2Configs = [
    "quick_reply_enhanced",
    "schedule_meeting_enhanced",
    "add_to_calendar_enhanced",
    "save_contact_enhanced",
    "rsvp_enhanced",
    "reservation_enhanced",
    "scheduled_purchase_enhanced",
    "browse_shopping_enhanced",
    "delegate_task",
    "save_for_later",
    "file_insurance_claim",
    "view_practice_details",
    "add_activity_to_calendar",
    "schedule_payment",
    "reply_to_ticket",
    "view_benefits"
]

var passed = 0
var failed = 0

for configName in wave2Configs {
    print("Decoding: \(configName)...", terminator: " ")

    if let config = ModalConfig.load(from: configName) {
        // Successfully loaded
        let validation = config.validate()

        if validation.isValid {
            print("✅ PASS")
            passed += 1

            // Print details
            var details: [String] = []
            details.append("\(config.sections.count) sections")

            let totalFields = config.sections.reduce(0) { $0 + $1.fields.count }
            details.append("\(totalFields) fields")

            if config.tertiaryButton != nil { details.append("tertiary") }
            if config.cancelButton != nil { details.append("cancel") }
            if config.destructiveAction != nil { details.append("destructive") }
            if config.loadingStates != nil { details.append("loading states") }

            // Check for Wave 2 field types
            var wave2FieldTypes: Set<String> = []
            for section in config.sections {
                if section.collapsible == true { wave2FieldTypes.insert("collapsible") }

                for field in section.fields {
                    switch field.type {
                    case .textArea: wave2FieldTypes.insert("textArea")
                    case .multiSelect: wave2FieldTypes.insert("multiSelect")
                    case .searchField: wave2FieldTypes.insert("searchField")
                    case .stars: wave2FieldTypes.insert("stars")
                    case .calculated: wave2FieldTypes.insert("calculated")
                    default: break
                    }

                    if field.helpText != nil { wave2FieldTypes.insert("helpText") }
                    if field.visibilityCondition != nil { wave2FieldTypes.insert("visibility") }
                    if field.characterLimit != nil { wave2FieldTypes.insert("charLimit") }
                    if field.pickerOptions != nil { wave2FieldTypes.insert("richPicker") }
                    if field.defaultValue != nil { wave2FieldTypes.insert("defaults") }
                }
            }

            if !wave2FieldTypes.isEmpty {
                details.append("Wave2: [\(wave2FieldTypes.sorted().joined(separator: ", "))]")
            }

            print("   \(details.joined(separator: " • "))")

        } else {
            print("❌ FAIL - Validation failed")
            failed += 1
            if case .invalid(let errors) = validation {
                for error in errors {
                    print("     Error: \(error)")
                }
            }
        }
    } else {
        print("❌ FAIL - Decoding failed")
        failed += 1
    }
}

print("\n========================================")
print("📊 Decoding Results")
print("========================================")
print("Total: \(wave2Configs.count)")
print("✅ Passed: \(passed)")
print("❌ Failed: \(failed)")

if failed == 0 {
    print("\n🎉 Perfect! All configs decode correctly!")
    print("✨ Wave 2 modal system is production ready!")
} else {
    print("\n⚠️  Some configs failed to decode")
}

print("\n========================================\n")
