import Foundation
import SwiftUI

/**
 * ContentViewState
 * Centralized state management for ContentView
 * Extracted from ContentView to enable testing and reduce complexity
 *
 * Before: 25+ @State properties scattered in ContentView
 * After: Single ObservableObject with clear organization
 */
class ContentViewState: ObservableObject {

    // MARK: - UI State

    @Published var dragOffset: CGSize = .zero
    @Published var showArchetypeSheet = false

    // MARK: - Modal States

    @Published var showActionModal = false
    @Published var actionModalCard: EmailCard?

    @Published var showSplayView = false

    @Published var showEmailComposer = false
    @Published var emailComposerCard: EmailCard?
    @Published var signedDocumentName: String?

    @Published var showSnoozePicker = false
    @Published var snoozeCard: EmailCard?
    @Published var snoozeDuration: Int = 2 // default 2 hours

    @Published var showUrgentConfirmation = false
    @Published var urgentConfirmCard: EmailCard?

    // MARK: - Sheet States (item-based presentation)

    @Published var actionOptionsCard: EmailCard? // Using .sheet(item:) pattern
    @Published var selectedActionId: String?

    @Published var saveSnoozeMenuCard: EmailCard?
    @Published var showSaveSnoozeMenu = false

    @Published var folderPickerCard: EmailCard?
    @Published var showFolderPicker = false

    // MARK: - Navigation States

    @Published var showSettings = false
    @Published var showShoppingCart = false
    @Published var showSearch = false
    @Published var showSavedMail = false
    @Published var selectedThreadCard: EmailCard?

    // MARK: - UI Data

    @Published var cartItemCount = 0
    @Published var totalInitialCards = 0 // Track initial card count for progress meter

    // MARK: - Toast States

    @Published var showUndoToast = false
    @Published var undoActionText = ""

    // MARK: - Computed Properties

    /// True if any modal is currently being shown
    var hasActiveModal: Bool {
        showActionModal ||
        showSplayView ||
        showEmailComposer ||
        showSnoozePicker ||
        showUrgentConfirmation ||
        showSettings ||
        showShoppingCart ||
        showSearch ||
        showSavedMail
    }

    /// True if any sheet is currently being shown
    var hasActiveSheet: Bool {
        actionOptionsCard != nil ||
        saveSnoozeMenuCard != nil ||
        folderPickerCard != nil ||
        selectedThreadCard != nil
    }

    // MARK: - State Management

    /// Reset all modal states (useful for cleanup)
    func resetModalState() {
        showActionModal = false
        actionModalCard = nil
        showSplayView = false
        showEmailComposer = false
        emailComposerCard = nil
        signedDocumentName = nil
        showSnoozePicker = false
        snoozeCard = nil
        showUrgentConfirmation = false
        urgentConfirmCard = nil
    }

    /// Reset all sheet states
    func resetSheetState() {
        actionOptionsCard = nil
        selectedActionId = nil
        saveSnoozeMenuCard = nil
        showSaveSnoozeMenu = false
        folderPickerCard = nil
        showFolderPicker = false
        selectedThreadCard = nil
    }

    /// Reset all navigation states
    func resetNavigationState() {
        showSettings = false
        showShoppingCart = false
        showSearch = false
        showSavedMail = false
    }

    /// Reset undo toast
    func hideUndoToast() {
        showUndoToast = false
        undoActionText = ""
    }

    /// Show undo toast with message
    func showUndo(message: String) {
        undoActionText = message
        showUndoToast = true
    }

    /// Reset all state (complete cleanup)
    func resetAllState() {
        resetModalState()
        resetSheetState()
        resetNavigationState()
        hideUndoToast()

        // Reset UI state
        dragOffset = .zero
        showArchetypeSheet = false
        cartItemCount = 0
    }
}

// MARK: - Preview Support

#if DEBUG
extension ContentViewState {
    static var preview: ContentViewState {
        let state = ContentViewState()
        state.cartItemCount = 3
        state.totalInitialCards = 42
        return state
    }

    static var previewWithModal: ContentViewState {
        let state = ContentViewState()
        state.showSettings = true
        return state
    }
}
#endif
