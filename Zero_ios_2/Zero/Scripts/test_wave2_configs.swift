#!/usr/bin/env swift

import Foundation

// Simple script to test Wave 2 config loading

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

print("\n========================================")
print("🧪 Wave 2 Config JSON Validation")
print("========================================\n")

var successCount = 0
var failureCount = 0
var errors: [(String, String)] = []

let configPath = "Config/ModalConfigs"

for configName in wave2Configs {
    let filePath = "\(configPath)/\(configName).json"
    print("Testing: \(configName).json...", terminator: " ")

    guard let data = try? Data(contentsOf: URL(fileURLWithPath: filePath)) else {
        print("❌ FAIL - File not found")
        failureCount += 1
        errors.append((configName, "File not found at \(filePath)"))
        continue
    }

    do {
        let json = try JSONSerialization.jsonObject(with: data)
        guard let dict = json as? [String: Any] else {
            print("❌ FAIL - Invalid JSON structure")
            failureCount += 1
            errors.append((configName, "Invalid JSON structure"))
            continue
        }

        // Basic validation
        guard let _ = dict["id"] as? String else {
            print("❌ FAIL - Missing 'id' field")
            failureCount += 1
            errors.append((configName, "Missing 'id' field"))
            continue
        }

        guard let _ = dict["title"] as? String else {
            print("❌ FAIL - Missing 'title' field")
            failureCount += 1
            errors.append((configName, "Missing 'title' field"))
            continue
        }

        guard let sections = dict["sections"] as? [[String: Any]], !sections.isEmpty else {
            print("❌ FAIL - Missing or empty 'sections' field")
            failureCount += 1
            errors.append((configName, "Missing or empty 'sections' field"))
            continue
        }

        print("✅ PASS")
        successCount += 1

        // Count Wave 2 features
        var features: [String] = []
        if dict["tertiaryButton"] != nil { features.append("tertiaryButton") }
        if dict["cancelButton"] != nil { features.append("cancelButton") }
        if dict["destructiveAction"] != nil { features.append("destructiveAction") }
        if dict["loadingStates"] != nil { features.append("loadingStates") }
        if dict["permissions"] != nil { features.append("permissions") }

        if !features.isEmpty {
            print("   Wave 2 features: \(features.joined(separator: ", "))")
        }

    } catch {
        print("❌ FAIL - JSON parse error")
        failureCount += 1
        errors.append((configName, "JSON parse error: \(error.localizedDescription)"))
    }
}

print("\n========================================")
print("📊 Test Results")
print("========================================")
print("Total configs: \(wave2Configs.count)")
print("✅ Passed: \(successCount)")
print("❌ Failed: \(failureCount)")
print("Success rate: \(Int(Double(successCount) / Double(wave2Configs.count) * 100))%")

if !errors.isEmpty {
    print("\n❌ Errors:")
    for (configName, error) in errors {
        print("   • \(configName): \(error)")
    }
} else {
    print("\n🎉 All Wave 2 configs are valid!")
}

print("\n========================================\n")
