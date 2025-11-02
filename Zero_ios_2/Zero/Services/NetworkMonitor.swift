//
//  NetworkMonitor.swift
//  Zero
//
//  Created by Claude Code on 10/26/25.
//

import Foundation
import SwiftUI
import Network
import Combine

/**
 * NetworkMonitor - Real-time network connectivity monitoring
 *
 * Features:
 * - Monitor network status (connected/disconnected)
 * - Detect connection type (WiFi, cellular, wired)
 * - Notify observers of connectivity changes
 * - Automatic retry support
 *
 * Usage:
 * ```swift
 * // Start monitoring
 * NetworkMonitor.shared.startMonitoring()
 *
 * // Check connection status
 * if NetworkMonitor.shared.isConnected {
 *     // Perform network operation
 * }
 *
 * // Observe changes
 * NetworkMonitor.shared.$isConnected
 *     .sink { isConnected in
 *         print("Network:", isConnected ? "Connected" : "Disconnected")
 *     }
 * ```
 */
@MainActor
class NetworkMonitor: ObservableObject {

    // MARK: - Singleton
    static let shared = NetworkMonitor()

    // MARK: - Published Properties
    @Published var isConnected = true
    @Published var connectionType: ConnectionType = .unknown
    @Published var isExpensive = false

    // MARK: - Private Properties
    private let monitor = NWPathMonitor()
    private let queue = DispatchQueue(label: "com.zero.networkmonitor")
    private var isMonitoring = false

    // MARK: - Initialization
    private init() {
        Logger.info("NetworkMonitor initialized", category: .service)
    }

    // MARK: - Public API

    /// Start monitoring network connectivity
    func startMonitoring() {
        guard !isMonitoring else {
            Logger.info("NetworkMonitor already running", category: .service)
            return
        }

        monitor.pathUpdateHandler = { [weak self] path in
            Task { @MainActor [weak self] in
                guard let self = self else { return }

                let wasConnected = self.isConnected
                self.isConnected = path.status == .satisfied
                self.connectionType = ConnectionType(from: path)
                self.isExpensive = path.isExpensive

                // Log connection changes
                if wasConnected != self.isConnected {
                    if self.isConnected {
                        Logger.info("✅ Network connected (\(self.connectionType.displayName))", category: .service)
                    } else {
                        Logger.warning("❌ Network disconnected", category: .service)
                    }

                    // Post notification
                    NotificationCenter.default.post(
                        name: .networkStatusChanged,
                        object: nil,
                        userInfo: ["isConnected": self.isConnected]
                    )
                }
            }
        }

        monitor.start(queue: queue)
        isMonitoring = true

        Logger.info("NetworkMonitor started", category: .service)
    }

    /// Stop monitoring network connectivity
    func stopMonitoring() {
        guard isMonitoring else { return }

        monitor.cancel()
        isMonitoring = false

        Logger.info("NetworkMonitor stopped", category: .service)
    }

    /// Execute action when network is available, retry if offline
    func executeWhenConnected<T>(
        maxRetries: Int = 3,
        retryDelay: TimeInterval = 2.0,
        action: @escaping () async throws -> T
    ) async throws -> T {
        var attempts = 0
        var lastError: Error?

        while attempts < maxRetries {
            // Check if connected
            if isConnected {
                do {
                    return try await action()
                } catch {
                    lastError = error
                    Logger.error("Network operation failed: \(error.localizedDescription)", category: .service)

                    // If it's a network error, retry
                    if isNetworkError(error) {
                        attempts += 1
                        if attempts < maxRetries {
                            Logger.info("Retrying in \(retryDelay)s (attempt \(attempts + 1)/\(maxRetries))", category: .service)
                            try await Task.sleep(nanoseconds: UInt64(retryDelay * 1_000_000_000))
                            continue
                        }
                    }

                    throw error
                }
            } else {
                // Wait for connection
                Logger.info("Waiting for network connection...", category: .service)

                // Wait up to retryDelay seconds for connection
                let deadline = Date().addingTimeInterval(retryDelay)
                while !isConnected && Date() < deadline {
                    try await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
                }

                attempts += 1
            }
        }

        // All attempts failed
        throw lastError ?? NetworkError.noConnection
    }
}

// MARK: - Connection Type

enum ConnectionType {
    case wifi
    case cellular
    case wired
    case unknown

    init(from path: NWPath) {
        if path.usesInterfaceType(.wifi) {
            self = .wifi
        } else if path.usesInterfaceType(.cellular) {
            self = .cellular
        } else if path.usesInterfaceType(.wiredEthernet) {
            self = .wired
        } else {
            self = .unknown
        }
    }

    var displayName: String {
        switch self {
        case .wifi: return "Wi-Fi"
        case .cellular: return "Cellular"
        case .wired: return "Wired"
        case .unknown: return "Unknown"
        }
    }

    var icon: String {
        switch self {
        case .wifi: return "wifi"
        case .cellular: return "antenna.radiowaves.left.and.right"
        case .wired: return "cable.connector"
        case .unknown: return "network"
        }
    }
}

// MARK: - Network Error

enum NetworkError: Error, LocalizedError {
    case noConnection
    case timeout
    case serverUnreachable

    var errorDescription: String? {
        switch self {
        case .noConnection:
            return "No internet connection"
        case .timeout:
            return "Request timed out"
        case .serverUnreachable:
            return "Server is unreachable"
        }
    }
}

// MARK: - Helper Functions

extension NetworkMonitor {
    /// Check if an error is a network-related error
    private func isNetworkError(_ error: Error) -> Bool {
        // Check for common network error codes
        let nsError = error as NSError

        // URLError codes
        if nsError.domain == NSURLErrorDomain {
            switch nsError.code {
            case NSURLErrorNotConnectedToInternet,
                 NSURLErrorNetworkConnectionLost,
                 NSURLErrorTimedOut,
                 NSURLErrorCannotFindHost,
                 NSURLErrorCannotConnectToHost,
                 NSURLErrorDNSLookupFailed:
                return true
            default:
                return false
            }
        }

        return false
    }
}

// MARK: - Notification Names

extension Notification.Name {
    static let networkStatusChanged = Notification.Name("networkStatusChanged")
}

// MARK: - View Modifier for Network Status

struct NetworkStatusModifier: ViewModifier {
    @ObservedObject var networkMonitor = NetworkMonitor.shared
    @State private var showOfflineBanner = false

    func body(content: Content) -> some View {
        content
            .onChange(of: networkMonitor.isConnected) { _, isConnected in
                withAnimation {
                    showOfflineBanner = !isConnected
                }
            }
            .overlay(alignment: .top) {
                if showOfflineBanner {
                    ErrorBanner(
                        message: "No internet connection",
                        type: .warning,
                        dismissAction: { showOfflineBanner = false }
                    )
                    .transition(.move(edge: .top).combined(with: .opacity))
                    .padding(.top, 8)
                }
            }
            .onAppear {
                NetworkMonitor.shared.startMonitoring()
            }
    }
}

extension View {
    /// Show network status banner when offline
    func monitorNetworkStatus() -> some View {
        modifier(NetworkStatusModifier())
    }
}

// MARK: - Preview Helper

#if DEBUG
struct NetworkMonitor_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 20) {
            NetworkStatusView()
        }
        .padding()
    }
}

struct NetworkStatusView: View {
    @ObservedObject var monitor = NetworkMonitor.shared

    var body: some View {
        VStack(spacing: 16) {
            HStack {
                Image(systemName: monitor.isConnected ? "wifi" : "wifi.slash")
                    .font(.largeTitle)
                    .foregroundColor(monitor.isConnected ? .green : .red)

                VStack(alignment: .leading) {
                    Text(monitor.isConnected ? "Connected" : "Disconnected")
                        .font(.headline)

                    if monitor.isConnected {
                        Text(monitor.connectionType.displayName)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
            }

            if monitor.isExpensive {
                Text("⚠️ Expensive connection (cellular data)")
                    .font(.caption)
                    .foregroundColor(.orange)
            }

            Button("Test Connection") {
                Task {
                    do {
                        let result = try await monitor.executeWhenConnected {
                            // Simulate network request
                            try await Task.sleep(nanoseconds: 500_000_000)
                            return "Success!"
                        }
                        print(result)
                    } catch {
                        print("Failed:", error)
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
        .onAppear {
            monitor.startMonitoring()
        }
    }
}
#endif
