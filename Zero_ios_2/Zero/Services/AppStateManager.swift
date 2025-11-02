import Foundation
import SwiftUI

/// App State Manager
/// Manages application UI state, loading states, and navigation flow
class AppStateManager: ObservableObject {
    
    // MARK: - Published Properties
    
    /// Current app state (splash, onboarding, feed, etc.)
    @Published var appState: AppState = .splash
    
    /// Loading indicator for real email fetching
    @Published var isLoadingRealEmails: Bool = false
    
    /// Loading indicator for email classification
    @Published var isClassifying: Bool = false

    /// Loading progress (0.0 to 1.0)
    @Published var loadingProgress: Double = 0.0

    /// Current loading message
    @Published var loadingMessage: String = ""

    /// Error message for real email operations
    @Published var realEmailError: String? = nil
    
    /// Last action performed (for undo functionality)
    @Published var lastAction: (card: EmailCard, previousState: CardState)? = nil
    
    // MARK: - Initialization
    
    init() {
        Logger.info("App state manager initialized", category: .app)
    }
    
    // MARK: - State Transitions
    
    func transitionToOnboarding() {
        appState = .onboarding
        Logger.info("State transition: onboarding", category: .app)
    }
    
    func transitionToFeed() {
        appState = .feed
        Logger.info("State transition: feed", category: .app)
    }
    
    func transitionToSplash() {
        appState = .splash
        Logger.info("State transition: splash", category: .app)
    }
    
    // MARK: - Loading States
    
    func startLoadingRealEmails() {
        isLoadingRealEmails = true
        realEmailError = nil
        loadingProgress = 0.0
        loadingMessage = "Connecting to server..."
        Logger.info("Started loading real emails", category: .email)
    }

    func finishLoadingRealEmails(success: Bool = true) {
        isLoadingRealEmails = false
        if success {
            loadingProgress = 0.6
            loadingMessage = "Emails fetched"
            Logger.info("Finished loading real emails", category: .email)
        } else {
            // On error, reset progress to 0 so UI can show error state
            loadingProgress = 0.0
            loadingMessage = ""
            Logger.info("Loading real emails failed, resetting progress", category: .email)
        }
    }

    func updateLoadingProgress(_ progress: Double, message: String) {
        loadingProgress = progress
        loadingMessage = message
        Logger.info("Loading progress: \(Int(progress * 100))% - \(message)", category: .email)
    }
    
    func setRealEmailError(_ error: String) {
        isLoadingRealEmails = false
        realEmailError = error
        Logger.error("Real email error: \(error)", category: .email)
    }
    
    func clearRealEmailError() {
        realEmailError = nil
    }
    
    func startClassifying() {
        isClassifying = true
        loadingProgress = 0.6
        loadingMessage = "Analyzing emails..."
        Logger.info("Started classification", category: .email)
    }

    func finishClassifying(success: Bool = true) {
        isClassifying = false
        if success {
            loadingProgress = 1.0
            loadingMessage = "Complete!"
            Logger.info("Finished classification", category: .email)
        } else {
            // On error, reset progress to 0
            loadingProgress = 0.0
            loadingMessage = ""
            Logger.info("Classification failed, resetting progress", category: .email)
        }
    }
    
    // MARK: - Last Action (Undo Support)
    
    func recordAction(card: EmailCard, previousState: CardState) {
        lastAction = (card: card, previousState: previousState)
        Logger.info("Recorded action for undo: card \(card.id), state \(previousState.rawValue)", category: .app)
    }
    
    func clearLastAction() {
        lastAction = nil
    }
    
    // MARK: - Computed Properties
    
    var isLoading: Bool {
        return isLoadingRealEmails || isClassifying
    }
    
    var hasError: Bool {
        return realEmailError != nil
    }
}


