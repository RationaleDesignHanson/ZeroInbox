import Foundation
import os.log

/// Centralized logging system using OSLog for professional logging
/// Replaces scattered print() statements throughout the codebase
///
/// Usage:
/// ```swift
/// Logger.info("User logged in", category: .authentication)
/// Logger.error("Failed to fetch emails", category: .network, error: error)
/// Logger.debug("Card count: \(count)", category: .ui)
/// ```
struct Logger {
    
    // MARK: - Log Categories
    enum Category: String {
        case app = "App"
        case network = "Network"
        case database = "Database"
        case ui = "UI"
        case authentication = "Authentication"
        case analytics = "Analytics"
        case service = "Service"
        case viewModel = "ViewModel"
        case modal = "Modal"
        case cards = "Cards"
        case card = "Card"
        case haptic = "Haptic"
        case shopping = "Shopping"
        case classification = "Classification"
        case error = "Error"
        case email = "Email"
        case action = "Action"
        case userPreferences = "UserPreferences"
        case admin = "Admin"
        case widget = "Widget"
        case savedMail = "SavedMail"

        var osLog: OSLog {
            return OSLog(subsystem: "com.emailshortform.zero", category: rawValue)
        }
    }
    
    // MARK: - Public Logging Methods
    
    /// Log informational message
    static func info(_ message: String, category: Category = .app, file: String = #file, function: String = #function, line: Int = #line) {
        let fileName = (file as NSString).lastPathComponent
        let logMessage = "[\(category.rawValue)] \(message) | \(fileName):\(line)"
        os_log("%{public}@", log: category.osLog, type: .info, logMessage)
        
        // Also log to file for TestFlight debugging
        logToFile(message: logMessage, level: "INFO", category: category)
    }
    
    /// Log debug message (only in debug builds)
    static func debug(_ message: String, category: Category = .app, file: String = #file, function: String = #function, line: Int = #line) {
        #if DEBUG
        let fileName = (file as NSString).lastPathComponent
        let logMessage = "[\(category.rawValue)] \(message) | \(fileName):\(line)"
        os_log("%{public}@", log: category.osLog, type: .debug, logMessage)
        logToFile(message: logMessage, level: "DEBUG", category: category)
        #endif
    }
    
    /// Log warning message
    static func warning(_ message: String, category: Category = .app, file: String = #file, function: String = #function, line: Int = #line) {
        let fileName = (file as NSString).lastPathComponent
        let logMessage = "⚠️ [\(category.rawValue)] \(message) | \(fileName):\(line)"
        os_log("%{public}@", log: category.osLog, type: .default, logMessage)
        logToFile(message: logMessage, level: "WARNING", category: category)
    }
    
    /// Log error message
    static func error(_ message: String, category: Category = .error, error: Error? = nil, file: String = #file, function: String = #function, line: Int = #line) {
        let fileName = (file as NSString).lastPathComponent
        var logMessage = "❌ [\(category.rawValue)] \(message) | \(fileName):\(line)"
        
        if let error = error {
            logMessage += " | Error: \(error.localizedDescription)"
        }
        
        os_log("%{public}@", log: category.osLog, type: .error, logMessage)
        logToFile(message: logMessage, level: "ERROR", category: category)
    }
    
    /// Log critical error (requires immediate attention)
    static func critical(_ message: String, category: Category = .error, error: Error? = nil, file: String = #file, function: String = #function, line: Int = #line) {
        let fileName = (file as NSString).lastPathComponent
        var logMessage = "🔥 [\(category.rawValue)] CRITICAL: \(message) | \(fileName):\(line)"
        
        if let error = error {
            logMessage += " | Error: \(error.localizedDescription)"
        }
        
        os_log("%{public}@", log: category.osLog, type: .fault, logMessage)
        logToFile(message: logMessage, level: "CRITICAL", category: category)
    }
    
    // MARK: - Convenience Methods
    
    /// Log network request
    static func logNetworkRequest(url: String, method: String = "GET") {
        info("📡 \(method) \(url)", category: .network)
    }
    
    /// Log network response
    static func logNetworkResponse(url: String, statusCode: Int, duration: TimeInterval) {
        if statusCode >= 200 && statusCode < 300 {
            info("✅ Response \(statusCode) from \(url) (\(String(format: "%.2f", duration))s)", category: .network)
        } else {
            error("❌ Response \(statusCode) from \(url) (\(String(format: "%.2f", duration))s)", category: .network)
        }
    }
    
    /// Log user action
    static func logUserAction(_ action: String, details: [String: Any] = [:]) {
        let detailsString = details.map { "\($0.key): \($0.value)" }.joined(separator: ", ")
        info("👤 User action: \(action) | \(detailsString)", category: .ui)
    }
    
    /// Log view lifecycle
    static func logViewLifecycle(_ view: String, event: String) {
        debug("📱 \(view) - \(event)", category: .ui)
    }
    
    // MARK: - File Logging (for TestFlight debugging)
    
    private static func logToFile(message: String, level: String, category: Category) {
        guard let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
            return
        }
        
        let logFileURL = documentsPath.appendingPathComponent(Constants.FilePaths.combinedLog)
        let timestamp = ISO8601DateFormatter().string(from: Date())
        let logEntry = "\(timestamp) | \(level) | \(message)\n"
        
        // Append to log file
        if let data = logEntry.data(using: .utf8) {
            if FileManager.default.fileExists(atPath: logFileURL.path) {
                if let fileHandle = try? FileHandle(forWritingTo: logFileURL) {
                    fileHandle.seekToEndOfFile()
                    fileHandle.write(data)
                    fileHandle.closeFile()
                }
            } else {
                try? data.write(to: logFileURL)
            }
        }
    }
    
    // MARK: - Log Retrieval (for debugging)
    
    /// Get all logs for debugging/support
    static func getAllLogs() -> String? {
        guard let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
            return nil
        }
        
        let logFileURL = documentsPath.appendingPathComponent(Constants.FilePaths.combinedLog)
        return try? String(contentsOf: logFileURL, encoding: .utf8)
    }
    
    /// Clear all logs
    static func clearLogs() {
        guard let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
            return
        }
        
        let logFileURL = documentsPath.appendingPathComponent(Constants.FilePaths.combinedLog)
        try? FileManager.default.removeItem(at: logFileURL)
        info("Logs cleared", category: .app)
    }
}

