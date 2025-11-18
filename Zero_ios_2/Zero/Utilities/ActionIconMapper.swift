import Foundation

/// Utility for mapping action names/IDs to SF Symbol icon names
/// Consolidates duplicate icon mapping logic across ModalContextHeader and ActionSelectorBottomSheet
struct ActionIconMapper {

    /// Get SF Symbol icon name for an action name or action ID
    /// - Parameter action: The action name (e.g., "Sign Form") or action ID (e.g., "sign_form")
    /// - Returns: SF Symbol icon name
    static func icon(for action: String) -> String {
        let lowercased = action.lowercased()

        // Education/School
        if lowercased.contains("grade") || lowercased.contains("assignment") {
            return "chart.bar.fill"
        }
        if lowercased.contains("homework") || lowercased.contains("study") {
            return "pencil.and.outline"
        }

        // Forms & Signatures
        if lowercased.contains("sign") || lowercased.contains("form") {
            return "signature"
        }

        // Shopping
        if lowercased.contains("shop") || lowercased.contains("browse") || lowercased.contains("deal") || lowercased.contains("cart") {
            return "cart.fill"
        }
        if lowercased.contains("track") || lowercased.contains("package") || lowercased.contains("delivery") {
            return "shippingbox.fill"
        }
        if lowercased.contains("pay") || lowercased.contains("invoice") || lowercased.contains("bill") {
            return "creditcard.fill"
        }

        // Travel
        if lowercased.contains("flight") || lowercased.contains("check in") || lowercased.contains("boarding") || lowercased.contains("check_in") {
            return "airplane.departure"
        }
        if lowercased.contains("hotel") || lowercased.contains("reservation") || lowercased.contains("booking") {
            return "building.2.fill"
        }

        // Work/Business
        if lowercased.contains("meeting") || lowercased.contains("schedule") || lowercased.contains("demo") {
            return "video.fill"
        }
        if lowercased.contains("calendar") {
            return "calendar.badge.plus"
        }
        if lowercased.contains("document") || lowercased.contains("approve") {
            return "doc.text.fill"
        }
        if lowercased.contains("spreadsheet") || lowercased.contains("report") {
            return "tablecells.fill"
        }
        if lowercased.contains("review") {
            return "star.fill"
        }

        // Healthcare/Appointments
        if lowercased.contains("appointment") || lowercased.contains("doctor") || lowercased.contains("prescription") || lowercased.contains("pickup") {
            return "cross.case.fill"
        }

        // Food/Restaurants
        if lowercased.contains("restaurant") || lowercased.contains("menu") || lowercased.contains("order food") {
            return "fork.knife"
        }

        // Security/Account
        if lowercased.contains("security") || lowercased.contains("verify") || lowercased.contains("password") {
            return "lock.shield.fill"
        }

        // Social/Events
        if lowercased.contains("event") || lowercased.contains("rsvp") || lowercased.contains("invitation") {
            return "party.popper.fill"
        }

        // Newsletter
        if lowercased.contains("newsletter") || lowercased.contains("summary") {
            return "newspaper.fill"
        }

        // Communication
        if lowercased.contains("reply") || lowercased.contains("message") {
            return "arrowshape.turn.up.left.fill"
        }

        // Downloads
        if lowercased.contains("download") {
            return "arrow.down.circle.fill"
        }

        // Generic actions
        if lowercased.contains("view") || lowercased.contains("detail") {
            return "eye.fill"
        }

        // Default: generic link/action
        return "checkmark.circle.fill"
    }
}
