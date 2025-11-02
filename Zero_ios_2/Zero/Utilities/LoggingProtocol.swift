import Foundation
import OSLog

/// Log privacy level for sensitive data
enum LogPrivacy {
    /// Public: Always visible in logs
    case `public`

    /// Private: Redacted in release builds, visible in debug
    case `private`

    /// Sensitive: Always redacted (e.g., passwords, tokens)
    case sensitive
}

/// Protocol defining logging capabilities
/// Abstraction allows for easy testing with mock implementations
protocol Logging {
    /// Log informational message
    /// - Parameter message: Message to log
    func info(_ message: String)

    /// Log error message
    /// - Parameter message: Error message to log
    func error(_ message: String)

    /// Log warning message
    /// - Parameter message: Warning message to log
    func warning(_ message: String)

    /// Log debug message
    /// - Parameter message: Debug message to log
    func debug(_ message: String)

    // MARK: - Enhanced Methods with Privacy Controls (Phase 3)

    /// Log info with privacy control
    func info(_ message: String, privacy: LogPrivacy)

    /// Log error with privacy control
    func error(_ message: String, privacy: LogPrivacy)

    /// Log warning with privacy control
    func warning(_ message: String, privacy: LogPrivacy)

    /// Log debug with privacy control
    func debug(_ message: String, privacy: LogPrivacy)
}

/// Production logging implementation using OSLog
/// Provides privacy redaction and proper log levels
final class OSLogger: Logging {
    private let logger: os.Logger
    private let subsystem: String
    private let category: String
    private let samplingRate: Double

    /// Initialize logger with subsystem and category
    /// - Parameters:
    ///   - subsystem: App bundle identifier
    ///   - category: Log category (e.g., "app", "network", "ui")
    ///   - samplingRate: Rate at which to sample debug logs (0.0-1.0, default 1.0 = all logs)
    init(
        subsystem: String = Bundle.main.bundleIdentifier ?? "work.rationale.zero",
        category: String,
        samplingRate: Double = 1.0
    ) {
        self.subsystem = subsystem
        self.category = category
        self.samplingRate = min(max(samplingRate, 0.0), 1.0)
        self.logger = os.Logger(subsystem: subsystem, category: category)
    }

    // MARK: - Simple Methods (backward compatible)

    func info(_ message: String) {
        logger.info("\(message, privacy: .public)")
    }

    func error(_ message: String) {
        logger.error("\(message, privacy: .public)")
    }

    func warning(_ message: String) {
        logger.warning("\(message, privacy: .public)")
    }

    func debug(_ message: String) {
        // Apply sampling to debug logs to reduce noise
        guard shouldSample() else { return }
        logger.debug("\(message, privacy: .public)")
    }

    // MARK: - Enhanced Methods with Privacy Controls

    func info(_ message: String, privacy: LogPrivacy) {
        switch privacy {
        case .public:
            logger.info("\(message, privacy: .public)")
        case .private:
            #if DEBUG
            logger.info("\(message, privacy: .public)")
            #else
            logger.info("\(message, privacy: .private)")
            #endif
        case .sensitive:
            logger.info("\(message, privacy: .private)")
        }
    }

    func error(_ message: String, privacy: LogPrivacy) {
        switch privacy {
        case .public:
            logger.error("\(message, privacy: .public)")
        case .private:
            #if DEBUG
            logger.error("\(message, privacy: .public)")
            #else
            logger.error("\(message, privacy: .private)")
            #endif
        case .sensitive:
            logger.error("\(message, privacy: .private)")
        }
    }

    func warning(_ message: String, privacy: LogPrivacy) {
        switch privacy {
        case .public:
            logger.warning("\(message, privacy: .public)")
        case .private:
            #if DEBUG
            logger.warning("\(message, privacy: .public)")
            #else
            logger.warning("\(message, privacy: .private)")
            #endif
        case .sensitive:
            logger.warning("\(message, privacy: .private)")
        }
    }

    func debug(_ message: String, privacy: LogPrivacy) {
        guard shouldSample() else { return }
        switch privacy {
        case .public:
            logger.debug("\(message, privacy: .public)")
        case .private:
            #if DEBUG
            logger.debug("\(message, privacy: .public)")
            #else
            logger.debug("\(message, privacy: .private)")
            #endif
        case .sensitive:
            logger.debug("\(message, privacy: .private)")
        }
    }

    // MARK: - Private Helpers

    private func shouldSample() -> Bool {
        // Always log in debug builds
        #if DEBUG
        return true
        #else
        // Apply sampling rate in production
        return Double.random(in: 0.0...1.0) <= samplingRate
        #endif
    }
}

/// Mock logger for testing that captures log messages
final class MockLogger: Logging {
    var infoMessages: [String] = []
    var errorMessages: [String] = []
    var warningMessages: [String] = []
    var debugMessages: [String] = []

    func info(_ message: String) {
        infoMessages.append(message)
    }

    func error(_ message: String) {
        errorMessages.append(message)
    }

    func warning(_ message: String) {
        warningMessages.append(message)
    }

    func debug(_ message: String) {
        debugMessages.append(message)
    }

    // MARK: - Enhanced Methods

    func info(_ message: String, privacy: LogPrivacy) {
        infoMessages.append(message)
    }

    func error(_ message: String, privacy: LogPrivacy) {
        errorMessages.append(message)
    }

    func warning(_ message: String, privacy: LogPrivacy) {
        warningMessages.append(message)
    }

    func debug(_ message: String, privacy: LogPrivacy) {
        debugMessages.append(message)
    }

    /// Clear all captured messages
    func clear() {
        infoMessages.removeAll()
        errorMessages.removeAll()
        warningMessages.removeAll()
        debugMessages.removeAll()
    }
}
