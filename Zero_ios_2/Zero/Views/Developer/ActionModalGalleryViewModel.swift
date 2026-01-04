import SwiftUI
import Combine

/// ViewModel for Action Modal Gallery
@MainActor
class ActionModalGalleryViewModel: ObservableObject {
    // MARK: - Published Properties

    @Published var allActions: [TestableAction] = []
    @Published var filteredActions: [TestableAction] = []
    @Published var selectedAction: TestableAction?

    @Published var modeFilter: ActionModeFilter = .all {
        didSet { applyFilters() }
    }

    @Published var permissionFilter: ActionPermissionFilter = .all {
        didSet { applyFilters() }
    }

    @Published var searchText: String = "" {
        didSet { applyFilters() }
    }

    // MARK: - Computed Properties

    var totalActionsCount: Int {
        allActions.count
    }

    var premiumActionsCount: Int {
        allActions.filter { $0.isPremium }.count
    }

    // MARK: - Methods

    func loadActions(from registry: ActionRegistry) {
        // Get all IN_APP actions from the registry
        let inAppActions = registry.getAllActions().filter { $0.actionType == .inApp }

        // Convert to TestableAction
        allActions = inAppActions.map { config in
            TestableAction(
                id: config.actionId,
                actionId: config.actionId,
                displayName: config.displayName,
                mode: mapMode(config.mode),
                priority: config.priority,
                isPremium: config.requiredPermission == .premium,
                hasJSONConfig: config.modalConfigJSON != nil,
                modalComponent: config.modalComponent,
                requiredContextKeys: config.requiredContextKeys,
                optionalContextKeys: config.optionalContextKeys,
                icon: iconForAction(config.actionId),
                color: colorForPriority(config.priority)
            )
        }
        .sorted { $0.priority.rawValue > $1.priority.rawValue }

        applyFilters()
    }

    private func applyFilters() {
        var filtered = allActions

        // Apply mode filter
        switch modeFilter {
        case .all:
            break
        case .mail:
            filtered = filtered.filter { $0.mode == .mail }
        case .ads:
            filtered = filtered.filter { $0.mode == .ads }
        case .both:
            filtered = filtered.filter { $0.mode == .both }
        }

        // Apply permission filter
        switch permissionFilter {
        case .all:
            break
        case .free:
            filtered = filtered.filter { !$0.isPremium }
        case .premium:
            filtered = filtered.filter { $0.isPremium }
        }

        // Apply search filter
        if !searchText.isEmpty {
            filtered = filtered.filter {
                $0.displayName.localizedCaseInsensitiveContains(searchText) ||
                $0.actionId.localizedCaseInsensitiveContains(searchText)
            }
        }

        filteredActions = filtered
    }

    private func mapMode(_ mode: ZeroMode) -> TestableActionMode {
        switch mode {
        case .mail: return .mail
        case .ads: return .ads
        case .both: return .both
        }
    }

    private func iconForAction(_ actionId: String) -> String {
        // Return appropriate SF Symbol based on action ID
        switch actionId {
        case "track_package": return "shippingbox.fill"
        case "pay_invoice": return "dollarsign.circle.fill"
        case "check_in_flight": return "airplane.departure"
        case "sign_form": return "signature"
        case "quick_reply": return "arrowshape.turn.up.left.fill"
        case "add_to_calendar": return "calendar.badge.plus"
        case "schedule_meeting": return "calendar.badge.clock"
        case "add_reminder": return "bell.badge.fill"
        case "add_to_wallet": return "wallet.pass.fill"
        case "browse_shopping": return "cart.fill"
        case "schedule_purchase": return "calendar.badge.clock"
        case "save_contact": return "person.crop.circle.badge.plus"
        case "send_message": return "message.fill"
        case "share": return "square.and.arrow.up"
        case "rsvp_yes", "rsvp_no": return "envelope.badge.fill"
        case "cancel_subscription": return "xmark.circle.fill"
        case "unsubscribe": return "trash.circle.fill"
        case "write_review": return "star.fill"
        case "contact_driver": return "phone.fill"
        case "view_pickup_details": return "mappin.and.ellipse"
        case "snooze": return "clock.badge.fill"
        case "open_app": return "app.fill"
        case "add_to_notes": return "note.text.badge.plus"
        case "view_document": return "doc.text.fill"
        case "view_spreadsheet": return "tablecells.fill"
        default: return "square.grid.2x2"
        }
    }

    private func colorForPriority(_ priority: ActionPriority) -> Color {
        switch priority {
        case .critical: return .red
        case .veryHigh: return .orange
        case .high: return .yellow
        case .mediumHigh: return .green
        case .medium: return .blue
        case .mediumLow: return .cyan
        case .low: return .purple
        case .veryLow: return .gray
        }
    }
}

// MARK: - Testable Action Model

struct TestableAction: Identifiable, Equatable {
    let id: String
    let actionId: String
    let displayName: String
    let mode: TestableActionMode
    let priority: ActionPriority
    let isPremium: Bool
    let hasJSONConfig: Bool
    let modalComponent: String?
    let requiredContextKeys: [String]
    let optionalContextKeys: [String]
    let icon: String
    let color: Color

    static func == (lhs: TestableAction, rhs: TestableAction) -> Bool {
        lhs.id == rhs.id
    }
}

enum TestableActionMode: String {
    case mail
    case ads
    case both
}
