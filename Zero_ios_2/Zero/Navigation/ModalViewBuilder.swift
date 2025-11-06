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

        // Phase 3A: Newly wired existing modals
        case .addReminder(let card):
            AddReminderModal(card: card, isPresented: isPresented)

        case .addToWallet(let card):
            AddToWalletModal(card: card, isPresented: isPresented)

        case .browseShopping(let card):
            BrowseShoppingModal(card: card, context: [:], isPresented: isPresented)

        case .cancelSubscription(let card):
            CancelSubscriptionModal(card: card, onComplete: { isPresented.wrappedValue = false })

        case .checkInFlight(let card):
            CheckInFlightModal(
                card: card,
                flightNumber: card.title.components(separatedBy: " ").last ?? "",
                airline: card.company?.name ?? "Airline",
                checkInUrl: "",
                context: [:],
                isPresented: isPresented
            )

        case .contactDriver(let card):
            ContactDriverModal(
                card: card,
                driverInfo: [:],
                isPresented: isPresented
            )

        case .newsletterSummary(let card):
            NewsletterSummaryModal(
                card: card,
                context: [:],
                isPresented: isPresented
            )

        case .payInvoice(let card):
            PayInvoiceModal(
                card: card,
                invoiceId: card.title.components(separatedBy: " ").last ?? "INV-001",
                amount: card.paymentAmount != nil ? String(format: "$%.2f", card.paymentAmount!) : "$0.00",
                merchant: card.company?.name ?? "Merchant",
                context: [:],
                isPresented: isPresented
            )

        case .pickupDetails(let card):
            PickupDetailsModal(
                card: card,
                rxNumber: card.title.components(separatedBy: " ").last ?? "RX-001",
                pharmacy: card.company?.name ?? "Pharmacy",
                context: [:],
                isPresented: isPresented
            )

        case .quickReply(let card):
            QuickReplyModal(
                card: card,
                recipientEmail: card.sender?.email ?? "",
                subject: "Re: \(card.title)",
                context: [:],
                isPresented: isPresented
            )

        case .reservation(let card):
            ReservationModal(
                card: card,
                context: [:],
                isPresented: isPresented
            )

        case .saveContact(let card):
            SaveContactModal(card: card, isPresented: isPresented)

        case .sendMessage(let card):
            SendMessageModal(card: card, isPresented: isPresented)

        case .share(let card):
            ShareModal(
                card: card,
                content: "\(card.title)\n\n\(card.summary)",
                isPresented: isPresented
            )

        case .snooze(let card):
            SnoozeModal(card: card, isPresented: isPresented)

        case .trackPackage(let card):
            TrackPackageModal(
                card: card,
                trackingNumber: card.trackingNumber ?? "",
                carrier: card.company?.name ?? "Carrier",
                trackingUrl: "",
                context: [:],
                isPresented: isPresented
            )

        case .unsubscribe(let card):
            UnsubscribeModal(
                card: card,
                unsubscribeUrl: card.unsubscribeUrl ?? "",
                isPresented: isPresented
            )

        case .writeReview(let card):
            WriteReviewModal(
                card: card,
                productName: card.title,
                reviewLink: "",
                context: [:],
                isPresented: isPresented
            )

        // Phase 3B: New high-priority modals
        case .addToNotes(let card):
            AddToNotesModal(card: card, isPresented: isPresented)

        // Phase 3C: Remaining HIGH priority modals
        case .provideAccessCode(let card):
            ProvideAccessCodeModal(card: card, isPresented: isPresented)

        case .viewActivity(let card):
            ViewActivityModal(card: card, isPresented: isPresented)

        case .saveProperties(let card):
            SavePropertiesModal(card: card, isPresented: isPresented)

        // Phase 3D: MEDIUM priority modals
        case .scheduleDeliveryTime(let card):
            ScheduleDeliveryTimeModal(card: card, isPresented: isPresented)

        case .prepareForOutage(let card):
            PrepareForOutageModal(card: card, isPresented: isPresented)

        case .viewActivityDetails(let card):
            ViewActivityDetailsModal(card: card, isPresented: isPresented)

        case .readCommunityPost(let card):
            ReadCommunityPostModal(card: card, isPresented: isPresented)

        // Phase 3E: LOW priority modals
        case .viewOutageDetails(let card):
            ViewOutageDetailsModal(card: card, isPresented: isPresented)

        case .viewPostComments(let card):
            ViewPostCommentsModal(card: card, isPresented: isPresented)

        case .shoppingAutomation(let card, let productUrl, let productName):
            ShoppingAutomationModal(
                card: card,
                productUrl: productUrl,
                productName: productName,
                context: [:],
                isPresented: isPresented
            )
            .environmentObject(viewModel)
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

