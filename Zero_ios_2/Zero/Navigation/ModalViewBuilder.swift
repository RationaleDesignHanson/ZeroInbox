import SwiftUI

/// Extension to build SwiftUI views from ModalRouter destinations
/// Separates routing logic from view construction
extension View {
    
    /// Build a modal view from a router destination
    @ViewBuilder
    func modalView(
        for destination: ModalRouter.ModalDestination,
        isPresented: Binding<Bool>,
        viewModel: EmailViewModel,
        snoozeDuration: Binding<Int>,
        onSignComplete: @escaping (String) -> Void,
        onSnoozeConfirm: @escaping (EmailCard) -> Void
    ) -> some View {
        switch destination {
        case .documentViewer(let card):
            DocumentViewerModal(card: card, isPresented: isPresented)
            
        case .spreadsheetViewer(let card):
            SpreadsheetViewerModal(card: card, isPresented: isPresented)
            
        case .scheduleMeeting(let card):
            ScheduleMeetingModal(card: card, isPresented: isPresented, onComplete: {})
            
        case .emailComposer(let card, let recipient, let subject):
            EmailComposerModal(
                card: card,
                isPresented: isPresented,
                recipientOverride: recipient,
                subjectOverride: subject
            )
            
        case .signForm(let card, _):
            SignFormModal(
                card: card,
                isPresented: isPresented,
                onSignComplete: onSignComplete
            )
            
        case .openApp(let card):
            OpenAppModal(card: card, isPresented: isPresented)

        case .openURL(_):
            // SafariView is handled in ContentView's sheet modifier
            // This case exists for exhaustiveness but won't be used here
            EmptyView()

        case .addToCalendar(let card):
            AddToCalendarModal(card: card, isPresented: isPresented)
            
        case .scheduledPurchase(let card, let action):
            ScheduledPurchaseModal(card: card, action: action, isPresented: isPresented)

        case .shoppingPurchase(let card, let selectedAction):
            ShoppingPurchaseModal(card: card, isPresented: isPresented, selectedAction: selectedAction)
                .environmentObject(viewModel)

        case .snoozePicker(_):
            SnoozePickerModal(isPresented: isPresented, selectedDuration: snoozeDuration) {
                // Callback handled by ContentView
            }

        case .saveForLater(let card):
            SaveForLaterModal(card: card, isPresented: isPresented)
                .environmentObject(viewModel)

        case .viewAttachments(let card):
            AttachmentViewerModal(card: card, isPresented: isPresented)

        case .fallback(let card):
            EmailComposerModal(card: card, isPresented: isPresented)
        }
    }
}

/// Helper for determining which modal to show in ContentView
struct ModalPresentation {
    let card: EmailCard
    let selectedActionId: String?
    
    var destination: ModalRouter.ModalDestination {
        ModalRouter.route(card: card, selectedActionId: selectedActionId)
    }
}

