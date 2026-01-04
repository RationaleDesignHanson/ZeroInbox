//
//  ARDisplayService.swift
//  Zero (iOS)
//
//  Created by Claude Code on 2025-12-12.
//  Part of Wearables Implementation (Week 5-6: AR Display)
//
//  Purpose: Manage AR display for Meta Oakley/Orion glasses.
//  Email notifications, inbox widget, action confirmations.
//  Falls back to ARKit for development/testing.
//

import Foundation
import SwiftUI
import Combine
import ARKit

#if os(iOS)

/// Service for AR display management
/// Renders email notifications, inbox widgets, and action confirmations
/// to Meta Oakley/Orion AR glasses (or ARKit simulator)
@MainActor
class ARDisplayService: NSObject, ObservableObject {
    static let shared = ARDisplayService()

    // MARK: - Published State

    @Published var isDisplayActive: Bool = false
    @Published var currentState: DisplayState = .off
    @Published var currentNotification: ARNotificationContent?
    @Published var inboxWidget: ARInboxWidget?
    @Published var displayMode: DisplayMode = .disabled

    enum DisplayState {
        case off
        case sleep
        case active
        case error
    }

    enum DisplayMode {
        case metaGlasses  // Real Meta Oakley/Orion hardware
        case arkit        // ARKit simulation on iPhone
        case disabled     // No AR display
    }

    // MARK: - Private Properties

    private var glassesAdapter = MetaGlassesAdapter.shared
    private var sleepTimer: Timer?
    private var brightness: Int = 1000 // Default brightness (nits)

    // ARKit simulator (for development)
    private var arkitSimulator: ARKitDisplaySimulator?

    // Notification queue
    private var notificationQueue: [ARNotificationContent] = []
    private var isShowingNotification = false

    // MARK: - Initialization

    override init() {
        super.init()

        determineDisplayMode()

        Logger.info("🥽 ARDisplayService initialized (mode: \(displayMode))", category: .arDisplay)
    }

    // MARK: - Public API

    /// Activate display
    func activateDisplay() async throws {
        guard displayMode != .disabled else {
            throw ARDisplayError.displayUnavailable
        }

        currentState = .active

        // Show persistent widget
        if let inboxData = getCurrentInboxData() {
            showInboxCountWidget(
                unreadCount: inboxData.unread,
                urgentCount: inboxData.urgent
            )
        }

        // Schedule sleep after 30s
        scheduleSleep(after: 30.0)

        isDisplayActive = true

        Logger.info("✓ AR display activated", category: .arDisplay)
    }

    /// Deactivate display
    func deactivateDisplay() {
        currentState = .off
        isDisplayActive = false

        // Dismiss all content
        dismissAllNotifications()
        hideInboxCountWidget()

        // Stop sleep timer
        sleepTimer?.invalidate()

        Logger.info("AR display deactivated", category: .arDisplay)
    }

    /// Show email notification (5-second overlay)
    func showEmailNotification(_ email: WatchEmail) {
        guard displayMode != .disabled else {
            Logger.debug("AR display disabled, falling back to voice", category: .arDisplay)
            fallbackToVoice(email)
            return
        }

        let content = ARNotificationContent(
            title: "New Email",
            sender: email.sender,
            subject: email.title,
            priority: email.priority,
            position: SIMD3<Float>(0.3, 0.2, -1.5), // Center-right, 1.5m away
            size: CGSize(width: 0.4, height: 0.2),
            duration: 5.0
        )

        // Add to queue
        notificationQueue.append(content)

        // Process queue
        Task {
            await processNotificationQueue()
        }
    }

    /// Show inbox count widget (persistent)
    func showInboxCountWidget(unreadCount: Int, urgentCount: Int) {
        let widget = ARInboxWidget(
            unreadCount: unreadCount,
            urgentCount: urgentCount,
            position: SIMD3<Float>(0.7, 0.7, -1.5), // Top-right corner
            size: CGSize(width: 0.15, height: 0.08),
            opacity: 1.0
        )

        inboxWidget = widget

        // Render
        Task {
            await renderWidget(widget)
        }

        // Wake display if sleeping
        if currentState == .sleep {
            wakeDisplay()
        }
    }

    /// Update inbox widget counts
    func updateInboxWidget(unreadCount: Int, urgentCount: Int) {
        guard var widget = inboxWidget else {
            // Widget doesn't exist, create it
            showInboxCountWidget(unreadCount: unreadCount, urgentCount: urgentCount)
            return
        }

        let oldUnread = widget.unreadCount
        let oldUrgent = widget.urgentCount

        // Update counts
        widget.unreadCount = unreadCount
        widget.urgentCount = urgentCount
        inboxWidget = widget

        // Animate update
        Task {
            await animateWidgetUpdate(
                widget: widget,
                oldUnread: oldUnread,
                oldUrgent: oldUrgent,
                newUnread: unreadCount,
                newUrgent: urgentCount
            )
        }
    }

    /// Hide inbox widget
    func hideInboxCountWidget() {
        inboxWidget = nil
    }

    /// Show action confirmation (3-second overlay)
    func showActionConfirmation(_ action: WatchAction) {
        let confirmation = ARConfirmationContent(
            message: "\(action.label)d", // "Archived", "Flagged", etc.
            icon: action.icon,
            position: SIMD3<Float>(0.4, 0.1, -1.5),
            size: CGSize(width: 0.2, height: 0.1),
            duration: 3.0
        )

        // Render confirmation
        Task {
            await renderConfirmation(confirmation)

            // Auto-dismiss after 3s
            try? await Task.sleep(nanoseconds: 3_000_000_000) // 3 seconds
            dismissConfirmation()
        }

        // Wake display if sleeping
        if currentState == .sleep {
            wakeDisplay()
        }
    }

    /// Dismiss all notifications
    func dismissAllNotifications() {
        notificationQueue.removeAll()
        currentNotification = nil
        isShowingNotification = false
    }

    /// Wake display from sleep
    func wakeDisplay() {
        guard currentState == .sleep else { return }

        currentState = .active

        // Restore brightness
        adjustBrightness(multiplier: 1.0)

        // Restore widget opacity
        if var widget = inboxWidget {
            widget.opacity = 1.0
            inboxWidget = widget
        }

        // Schedule sleep
        scheduleSleep(after: 30.0)

        Logger.debug("Display woke from sleep", category: .arDisplay)
    }

    /// Put display to sleep
    func sleepDisplay() {
        currentState = .sleep

        // Dim brightness
        adjustBrightness(multiplier: 0.5)

        // Dim widget
        if var widget = inboxWidget {
            widget.opacity = 0.3
            inboxWidget = widget
        }

        Logger.debug("Display entered sleep", category: .arDisplay)
    }

    // MARK: - Display Mode Detection

    private func determineDisplayMode() {
        if glassesAdapter.isConnected && glassesAdapter.hasDisplay {
            displayMode = .metaGlasses
            Logger.info("Using Meta Glasses display", category: .arDisplay)

        } else if ARWorldTrackingConfiguration.isSupported {
            displayMode = .arkit
            Logger.info("Using ARKit simulation mode", category: .arDisplay)

        } else {
            displayMode = .disabled
            Logger.warning("No AR display available", category: .arDisplay)
        }
    }

    // MARK: - Notification Queue Processing

    private func processNotificationQueue() async {
        guard !notificationQueue.isEmpty else { return }
        guard !isShowingNotification else { return }

        isShowingNotification = true

        while let notification = notificationQueue.first {
            currentNotification = notification

            // Render notification
            await renderNotification(notification)

            // Wait for duration
            try? await Task.sleep(nanoseconds: UInt64(notification.duration * 1_000_000_000))

            // Dismiss
            currentNotification = nil
            notificationQueue.removeFirst()

            // Brief pause between notifications
            try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
        }

        isShowingNotification = false
    }

    // MARK: - Rendering

    private func renderNotification(_ notification: ARNotificationContent) async {
        switch displayMode {
        case .metaGlasses:
            await renderToMetaGlasses(notification)

        case .arkit:
            renderToARKit(notification)

        case .disabled:
            break
        }

        // Wake display
        if currentState == .sleep {
            wakeDisplay()
        }
    }

    private func renderWidget(_ widget: ARInboxWidget) async {
        switch displayMode {
        case .metaGlasses:
            await renderWidgetToMetaGlasses(widget)

        case .arkit:
            renderWidgetToARKit(widget)

        case .disabled:
            break
        }
    }

    private func renderConfirmation(_ confirmation: ARConfirmationContent) async {
        switch displayMode {
        case .metaGlasses:
            await renderConfirmationToMetaGlasses(confirmation)

        case .arkit:
            renderConfirmationToARKit(confirmation)

        case .disabled:
            break
        }
    }

    // MARK: - Meta Glasses Rendering

    private func renderToMetaGlasses(_ notification: ARNotificationContent) async {
        // Convert to display content
        let texture = renderNotificationToImage(notification)
        let displayContent = ARDisplayContent(
            position: notification.position,
            size: notification.size,
            texture: texture,
            opacity: 1.0,
            duration: notification.duration
        )

        // Send to glasses
        do {
            try await glassesAdapter.renderToDisplay(displayContent)
            Logger.debug("✓ Rendered notification to Meta Glasses", category: .arDisplay)
        } catch {
            Logger.error("❌ Failed to render to Meta Glasses: \(error)", category: .arDisplay)
        }
    }

    private func renderWidgetToMetaGlasses(_ widget: ARInboxWidget) async {
        let texture = renderWidgetToImage(widget)
        let displayContent = ARDisplayContent(
            position: widget.position,
            size: widget.size,
            texture: texture,
            opacity: widget.opacity,
            duration: 0 // Persistent
        )

        do {
            try await glassesAdapter.renderToDisplay(displayContent)
            Logger.debug("✓ Rendered widget to Meta Glasses", category: .arDisplay)
        } catch {
            Logger.error("❌ Failed to render widget: \(error)", category: .arDisplay)
        }
    }

    private func renderConfirmationToMetaGlasses(_ confirmation: ARConfirmationContent) async {
        let texture = renderConfirmationToImage(confirmation)
        let displayContent = ARDisplayContent(
            position: confirmation.position,
            size: confirmation.size,
            texture: texture,
            opacity: 1.0,
            duration: confirmation.duration
        )

        do {
            try await glassesAdapter.renderToDisplay(displayContent)
            Logger.debug("✓ Rendered confirmation to Meta Glasses", category: .arDisplay)
        } catch {
            Logger.error("❌ Failed to render confirmation: \(error)", category: .arDisplay)
        }
    }

    // MARK: - ARKit Rendering

    private func renderToARKit(_ notification: ARNotificationContent) {
        // Post notification for ARKit view to handle
        NotificationCenter.default.post(
            name: .arDisplayShowNotification,
            object: notification
        )
    }

    private func renderWidgetToARKit(_ widget: ARInboxWidget) {
        NotificationCenter.default.post(
            name: .arDisplayShowWidget,
            object: widget
        )
    }

    private func renderConfirmationToARKit(_ confirmation: ARConfirmationContent) {
        NotificationCenter.default.post(
            name: .arDisplayShowConfirmation,
            object: confirmation
        )
    }

    // MARK: - Image Rendering

    private func renderNotificationToImage(_ notification: ARNotificationContent) -> Data {
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: 400, height: 200))
        let image = renderer.image { context in
            // Background (semi-transparent black)
            UIColor.black.withAlphaComponent(0.8).setFill()
            context.fill(CGRect(x: 0, y: 0, width: 400, height: 200))

            // Border (white, 2px)
            UIColor.white.setStroke()
            let borderRect = CGRect(x: 1, y: 1, width: 398, height: 198)
            context.stroke(borderRect, width: 2.0)

            // Title
            let titleAttributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 18, weight: .bold),
                .foregroundColor: UIColor.white
            ]
            notification.title.draw(at: CGPoint(x: 20, y: 20), withAttributes: titleAttributes)

            // Sender (largest, most important)
            let senderAttributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 24, weight: .regular),
                .foregroundColor: UIColor.white
            ]
            "From: \(notification.sender)".draw(at: CGPoint(x: 20, y: 60), withAttributes: senderAttributes)

            // Subject
            let subjectAttributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 22, weight: .regular),
                .foregroundColor: UIColor.white
            ]
            notification.subject.draw(at: CGPoint(x: 20, y: 100), withAttributes: subjectAttributes)

            // Priority badge
            let priorityColor = colorForPriority(notification.priority)
            let priorityAttributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 20, weight: .bold),
                .foregroundColor: priorityColor
            ]
            "Priority: \(notification.priority.rawValue.capitalized)".draw(
                at: CGPoint(x: 20, y: 140),
                withAttributes: priorityAttributes
            )
        }

        return image.jpegData(compressionQuality: 0.8) ?? Data()
    }

    private func renderWidgetToImage(_ widget: ARInboxWidget) -> Data {
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: 150, height: 80))
        let image = renderer.image { context in
            // Background
            UIColor.black.withAlphaComponent(0.7).setFill()
            context.fill(CGRect(x: 0, y: 0, width: 150, height: 80))

            // Unread count
            let unreadAttributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 20, weight: .regular),
                .foregroundColor: UIColor.white
            ]
            "\(widget.unreadCount) unread".draw(at: CGPoint(x: 10, y: 15), withAttributes: unreadAttributes)

            // Urgent count
            let urgentColor: UIColor = widget.urgentCount > 0 ? .red : .gray
            let urgentAttributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 20, weight: .regular),
                .foregroundColor: urgentColor
            ]
            "\(widget.urgentCount) urgent".draw(at: CGPoint(x: 10, y: 45), withAttributes: urgentAttributes)
        }

        return image.jpegData(compressionQuality: 0.8) ?? Data()
    }

    private func renderConfirmationToImage(_ confirmation: ARConfirmationContent) -> Data {
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: 200, height: 100))
        let image = renderer.image { context in
            // Background
            UIColor.black.withAlphaComponent(0.8).setFill()
            context.fill(CGRect(x: 0, y: 0, width: 200, height: 100))

            // Checkmark
            let checkmarkAttributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 32, weight: .bold),
                .foregroundColor: UIColor.green
            ]
            "✓".draw(at: CGPoint(x: 20, y: 30), withAttributes: checkmarkAttributes)

            // Message
            let messageAttributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 24, weight: .semibold),
                .foregroundColor: UIColor.white
            ]
            confirmation.message.draw(at: CGPoint(x: 60, y: 35), withAttributes: messageAttributes)
        }

        return image.jpegData(compressionQuality: 0.8) ?? Data()
    }

    private func colorForPriority(_ priority: WatchEmail.Priority) -> UIColor {
        switch priority {
        case .high:
            return .red
        case .medium:
            return .orange
        case .low:
            return .gray
        }
    }

    // MARK: - Animations

    private func animateWidgetUpdate(
        widget: ARInboxWidget,
        oldUnread: Int,
        oldUrgent: Int,
        newUnread: Int,
        newUrgent: Int
    ) async {
        // Fade out
        try? await Task.sleep(nanoseconds: 200_000_000) // 0.2s

        // Re-render with new values
        await renderWidget(widget)

        // Fade in
        try? await Task.sleep(nanoseconds: 200_000_000) // 0.2s

        // Flash if urgent count increased
        if newUrgent > oldUrgent {
            // Flash red
            Logger.debug("Widget flash: urgent count increased", category: .arDisplay)
        }
    }

    private func dismissConfirmation() {
        Logger.debug("Confirmation dismissed", category: .arDisplay)
    }

    // MARK: - Brightness Control

    private func adjustBrightness(multiplier: Float) {
        let newBrightness = Int(Float(brightness) * multiplier)
        glassesAdapter.setDisplayBrightness(newBrightness)
    }

    /// Adjust brightness based on ambient light
    func adjustBrightnessForAmbientLight(_ luxLevel: Float) {
        switch luxLevel {
        case 0..<100:
            brightness = 500 // Indoor
        case 100..<1000:
            brightness = 1000 // Shade
        default:
            brightness = 2000 // Sunlight
        }

        glassesAdapter.setDisplayBrightness(brightness)
    }

    // MARK: - Sleep Management

    private func scheduleSleep(after interval: TimeInterval) {
        sleepTimer?.invalidate()
        sleepTimer = Timer.scheduledTimer(withTimeInterval: interval, repeats: false) { [weak self] _ in
            Task { @MainActor in
                self?.sleepDisplay()
            }
        }
    }

    // MARK: - Helper Methods

    private func getCurrentInboxData() -> (unread: Int, urgent: Int)? {
        // In production, get from email service
        // For now, return placeholder
        return nil
    }

    private func fallbackToVoice(_ email: WatchEmail) {
        VoiceOutputService.shared.speak("New email from \(email.sender): \(email.title)")
    }

    // MARK: - Testing Helpers

    func _testShowNotification(_ email: WatchEmail) {
        showEmailNotification(email)
    }

    func _testShowWidget(unread: Int, urgent: Int) {
        showInboxCountWidget(unreadCount: unread, urgentCount: urgent)
    }

    func _testShowConfirmation(_ action: WatchAction) {
        showActionConfirmation(action)
    }
}

// MARK: - Supporting Types

struct ARNotificationContent {
    let title: String
    let sender: String
    let subject: String
    let priority: WatchEmail.Priority
    let position: SIMD3<Float>
    let size: CGSize
    let duration: TimeInterval
}

struct ARInboxWidget {
    var unreadCount: Int
    var urgentCount: Int
    let position: SIMD3<Float>
    let size: CGSize
    var opacity: Float
}

struct ARConfirmationContent {
    let message: String
    let icon: String
    let position: SIMD3<Float>
    let size: CGSize
    let duration: TimeInterval
}

enum ARDisplayError: LocalizedError {
    case displayUnavailable
    case renderingFailed(String)
    case glassesNotConnected

    var errorDescription: String? {
        switch self {
        case .displayUnavailable:
            return "AR display is not available on this device."
        case .renderingFailed(let reason):
            return "Rendering failed: \(reason)"
        case .glassesNotConnected:
            return "Meta glasses are not connected."
        }
    }
}

// MARK: - Notification Names

extension Notification.Name {
    static let arDisplayShowNotification = Notification.Name("ARDisplayShowNotification")
    static let arDisplayShowWidget = Notification.Name("ARDisplayShowWidget")
    static let arDisplayShowConfirmation = Notification.Name("ARDisplayShowConfirmation")
}

// MARK: - ARKit Display Simulator (Placeholder)

class ARKitDisplaySimulator {
    // Placeholder for ARKit simulation
    // In production, this would be a full ARSCNView implementation
}

// MARK: - Logger Category Extension

extension Logger.Category {
    static let arDisplay = Logger.Category("ARDisplay")
}

#endif
