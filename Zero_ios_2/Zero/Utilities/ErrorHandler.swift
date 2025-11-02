import Foundation
import SwiftUI

/// Centralized error handling service
/// Provides consistent error handling, logging, and user-facing error recovery
class ErrorHandler: ObservableObject {
    
    // MARK: - Singleton
    
    static let shared = ErrorHandler()
    
    // MARK: - Published Properties
    
    @Published var currentError: AppError?
    @Published var showErrorAlert: Bool = false
    
    private init() {
        Logger.info("ErrorHandler initialized", category: .app)
    }
    
    // MARK: - Error Handling
    
    /// Handle an error with logging and optional user notification
    func handle(_ error: Error, 
                context: String,
                showToUser: Bool = true,
                canRetry: Bool = false,
                retryAction: (() -> Void)? = nil) {
        
        // Convert to AppError
        let appError: AppError
        if let err = error as? AppError {
            appError = err
        } else {
            appError = AppError.unknown(error.localizedDescription)
        }
        
        // Log error
        Logger.error("[\(context)] \(appError.message)", category: .error)
        
        // Show to user if requested
        if showToUser {
            DispatchQueue.main.async { [weak self] in
                self?.currentError = appError
                self?.showErrorAlert = true
            }
        }
        
        // Analytics
        AnalyticsService.shared.log("error_occurred", properties: [
            "context": context,
            "error_type": appError.type,
            "message": appError.message,
            "can_retry": canRetry
        ])
    }
    
    /// Handle error with custom message
    func handle(message: String, 
                context: String,
                severity: ErrorSeverity = .error,
                showToUser: Bool = true) {
        
        let error = AppError.custom(message, severity: severity)
        
        switch severity {
        case .warning:
            Logger.warning("[\(context)] \(message)", category: .error)
        case .error:
            Logger.error("[\(context)] \(message)", category: .error)
        case .critical:
            Logger.error("🚨 CRITICAL [\(context)] \(message)", category: .error)
        }
        
        if showToUser {
            DispatchQueue.main.async { [weak self] in
                self?.currentError = error
                self?.showErrorAlert = true
            }
        }
    }
    
    /// Clear current error
    func clearError() {
        currentError = nil
        showErrorAlert = false
    }
}

// MARK: - AppError

enum AppError: LocalizedError, Identifiable {
    case network(String)
    case authentication(String)
    case emailFetch(String)
    case classification(String)
    case shopping(String)
    case storage(String)
    case custom(String, severity: ErrorSeverity)
    case unknown(String)
    
    var id: String {
        return message
    }
    
    var errorDescription: String? {
        return message
    }
    
    var type: String {
        switch self {
        case .network: return "network"
        case .authentication: return "authentication"
        case .emailFetch: return "email_fetch"
        case .classification: return "classification"
        case .shopping: return "shopping"
        case .storage: return "storage"
        case .custom: return "custom"
        case .unknown: return "unknown"
        }
    }

    var message: String {
        switch self {
        case .network(let msg):
            return "Network Error: \(msg)"
        case .authentication(let msg):
            return "Authentication Error: \(msg)"
        case .emailFetch(let msg):
            return "Email Fetch Error: \(msg)"
        case .classification(let msg):
            return "Classification Error: \(msg)"
        case .shopping(let msg):
            return "Shopping Error: \(msg)"
        case .storage(let msg):
            return "Storage Error: \(msg)"
        case .custom(let msg, _):
            return msg
        case .unknown(let msg):
            return "Unknown Error: \(msg)"
        }
    }

    var userFacingMessage: String {
        switch self {
        case .network:
            return "Unable to connect to the server. Please check your internet connection and try again."
        case .authentication:
            return "Authentication failed. Please sign in again."
        case .emailFetch:
            return "Unable to load emails. Please try again."
        case .classification:
            return "Unable to classify emails. Using default categories."
        case .shopping:
            return "Shopping cart error. Please try again."
        case .storage:
            return "Unable to save data. Please check storage permissions."
        case .custom(let msg, _):
            return msg
        case .unknown:
            return "Something went wrong. Please try again."
        }
    }

    var severity: ErrorSeverity {
        switch self {
        case .custom(_, let sev):
            return sev
        case .authentication, .storage:
            return .critical
        case .network, .emailFetch, .shopping:
            return .error
        case .classification, .unknown:
            return .warning
        }
    }
    
    var icon: String {
        switch severity {
        case .warning:
            return "exclamationmark.triangle"
        case .error:
            return "xmark.circle"
        case .critical:
            return "exclamationmark.octagon"
        }
    }
    
    var color: Color {
        switch severity {
        case .warning:
            return .orange
        case .error:
            return .red
        case .critical:
            return Color(red: 0.8, green: 0.1, blue: 0.1)
        }
    }
}

// MARK: - ErrorSeverity

enum ErrorSeverity {
    case warning   // Non-critical, app continues
    case error     // Important, but recoverable
    case critical  // Severe, may need user action
}

// MARK: - Error Alert View

struct ErrorAlertView: ViewModifier {
    @ObservedObject var errorHandler: ErrorHandler
    
    func body(content: Content) -> some View {
        content
            .alert(isPresented: $errorHandler.showErrorAlert) {
                if let error = errorHandler.currentError {
                    return Alert(
                        title: Text("Error"),
                        message: Text(error.userFacingMessage),
                        dismissButton: .default(Text("OK")) {
                            errorHandler.clearError()
                        }
                    )
                } else {
                    return Alert(title: Text("Error"))
                }
            }
    }
}

extension View {
    /// Add error handling to any view
    func withErrorHandling() -> some View {
        modifier(ErrorAlertView(errorHandler: ErrorHandler.shared))
    }
}


