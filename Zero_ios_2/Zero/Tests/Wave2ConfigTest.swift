import Foundation

/// Wave 2 Config Validation Test
/// Tests that all 20 Wave 2 JSON configs parse correctly

struct Wave2ConfigTest {
    static let wave2Configs = [
        // Phase B1 - Enhanced Tier 1
        "quick_reply_enhanced",
        "schedule_meeting_enhanced",
        "add_to_calendar_enhanced",
        "save_contact_enhanced",

        // Phase B2 - Enhanced Tier 2
        "rsvp_enhanced",
        "reservation_enhanced",
        "scheduled_purchase_enhanced",
        "browse_shopping_enhanced",

        // Phase C - New Actions
        "delegate_task",
        "save_for_later",
        "file_insurance_claim",
        "view_practice_details",
        "add_activity_to_calendar",
        "schedule_payment",
        "reply_to_ticket",
        "view_benefits"
    ]

    static func testAll() {
        print("\n========================================")
        print("🧪 Wave 2 Config Validation Test")
        print("========================================\n")

        var successCount = 0
        var failureCount = 0
        var errors: [(String, String)] = []

        for configName in wave2Configs {
            print("Testing: \(configName).json...", terminator: " ")

            if let config = ModalConfig.load(from: configName) {
                let validation = config.validate()
                if validation.isValid {
                    print("✅ PASS")
                    successCount += 1

                    // Print config details
                    printConfigDetails(configName, config)
                } else {
                    print("❌ FAIL - Validation errors")
                    failureCount += 1
                    if case .invalid(let validationErrors) = validation {
                        let errorMsg = validationErrors.joined(separator: ", ")
                        errors.append((configName, errorMsg))
                        print("   Errors: \(errorMsg)")
                    }
                }
            } else {
                print("❌ FAIL - Failed to load")
                failureCount += 1
                errors.append((configName, "Failed to load JSON"))
            }
        }

        print("\n========================================")
        print("📊 Test Results")
        print("========================================")
        print("Total configs: \(wave2Configs.count)")
        print("✅ Passed: \(successCount)")
        print("❌ Failed: \(failureCount)")

        if !errors.isEmpty {
            print("\n❌ Errors:")
            for (configName, error) in errors {
                print("   • \(configName): \(error)")
            }
        }

        print("\n========================================\n")
    }

    static func printConfigDetails(_ name: String, _ config: ModalConfig) {
        var features: [String] = []

        // Check for Wave 2 features
        if config.tertiaryButton != nil { features.append("tertiary button") }
        if config.cancelButton != nil { features.append("cancel button") }
        if config.destructiveAction != nil { features.append("destructive action") }
        if config.loadingStates != nil { features.append("loading states") }
        if config.permissions != nil { features.append("permissions") }

        // Check sections for collapsible
        let collapsibleSections = config.sections.filter { $0.collapsible == true }.count
        if collapsibleSections > 0 {
            features.append("\(collapsibleSections) collapsible sections")
        }

        // Check fields for new types
        var fieldTypes: Set<String> = []
        for section in config.sections {
            for field in section.fields {
                switch field.type {
                case .multiSelect: fieldTypes.insert("multiSelect")
                case .searchField: fieldTypes.insert("searchField")
                case .stars: fieldTypes.insert("stars")
                case .textArea: fieldTypes.insert("textArea")
                case .calculated: fieldTypes.insert("calculated")
                default: break
                }

                if field.helpText != nil { fieldTypes.insert("helpText") }
                if field.visibilityCondition != nil { fieldTypes.insert("visibility conditions") }
                if field.characterLimit != nil { fieldTypes.insert("character limits") }
                if field.pickerOptions != nil { fieldTypes.insert("enhanced pickers") }
            }
        }

        features.append(contentsOf: fieldTypes)

        if !features.isEmpty {
            print("   Features: \(features.joined(separator: ", "))")
        }
    }
}
