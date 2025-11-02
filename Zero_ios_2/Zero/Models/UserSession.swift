import Foundation

/// User session model
/// Replaces hardcoded "user-123" throughout the codebase
class UserSession: ObservableObject {
    @Published var userId: String
    @Published var email: String?
    @Published var isAuthenticated: Bool
    @Published var authProvider: AuthProvider
    
    enum AuthProvider {
        case demo
        case gmail
        case outlook
        case none
    }
    
    // MARK: - Initialization
    
    init(userId: String = Constants.UserDefaults.defaultUserId, 
         email: String? = nil,
         isAuthenticated: Bool = false,
         authProvider: AuthProvider = .none) {
        self.userId = userId
        self.email = email
        self.isAuthenticated = isAuthenticated
        self.authProvider = authProvider
        
        Logger.info("UserSession initialized: \(userId)", category: .authentication)
    }
    
    // MARK: - Authentication
    
    func authenticate(userId: String, email: String, provider: AuthProvider) {
        self.userId = userId
        self.email = email
        self.isAuthenticated = true
        self.authProvider = provider
        
        Logger.info("User authenticated: \(email) via \(provider)", category: .authentication)
    }
    
    func logout() {
        Logger.info("User logged out: \(email ?? userId)", category: .authentication)
        
        self.userId = Constants.UserDefaults.defaultUserId
        self.email = nil
        self.isAuthenticated = false
        self.authProvider = .none
    }
    
    // MARK: - Convenience
    
    var displayName: String {
        return email ?? userId
    }
    
    var isDemo: Bool {
        return authProvider == .demo
    }
}

