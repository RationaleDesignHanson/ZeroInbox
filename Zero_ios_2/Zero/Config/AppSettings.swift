import Foundation

/// Protocol defining app settings interface
/// This abstraction allows for easy testing with mock implementations
protocol Settings {
    var useMockData: Bool { get set }
    var selectedArchetypes: [String] { get set }
    var skipOnboarding: Bool { get set }
}

/// Production implementation of Settings backed by UserDefaults
/// Centralizes all UserDefaults access to prevent scattered storage logic
final class AppSettings: Settings {
    private let defaults: UserDefaults

    /// Default initializer using standard UserDefaults
    init() {
        self.defaults = .standard
    }

    /// Testable initializer with injectable UserDefaults
    /// - Parameter defaults: UserDefaults instance to use
    init(defaults: UserDefaults) {
        self.defaults = defaults
    }

    // MARK: - Private Keys

    private enum Key {
        static let useMockData = "useMockData"
        static let selectedArchetypes = "selectedArchetypes"
        static let skipOnboarding = "skipOnboarding"
    }

    // MARK: - Settings Properties

    var useMockData: Bool {
        get { defaults.bool(forKey: Key.useMockData) }
        set { defaults.set(newValue, forKey: Key.useMockData) }
    }

    var selectedArchetypes: [String] {
        get { defaults.stringArray(forKey: Key.selectedArchetypes) ?? [] }
        set { defaults.set(newValue, forKey: Key.selectedArchetypes) }
    }

    var skipOnboarding: Bool {
        get { defaults.bool(forKey: Key.skipOnboarding) }
        set { defaults.set(newValue, forKey: Key.skipOnboarding) }
    }
}
