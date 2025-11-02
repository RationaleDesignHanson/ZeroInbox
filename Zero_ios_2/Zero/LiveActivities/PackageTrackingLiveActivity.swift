import ActivityKit
import WidgetKit
import SwiftUI

/// Live Activity Widget for Package Tracking
/// Displays real-time tracking updates on Dynamic Island and Lock Screen
@available(iOS 16.1, *)
struct PackageTrackingLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: PackageTrackingAttributes.self) { context in
            // Lock Screen / Banner UI
            LockScreenLiveActivityView(context: context)
        } dynamicIsland: { context in
            DynamicIsland {
                // Expanded Region (when user long-presses)
                DynamicIslandExpandedRegion(.leading) {
                    // Package icon and status
                    VStack(alignment: .leading, spacing: 4) {
                        Image(systemName: context.state.status.icon)
                            .font(.title2)
                            .foregroundStyle(context.state.status.color)

                        Text(context.state.status.rawValue)
                            .font(.caption.bold())
                            .foregroundStyle(.primary)
                    }
                }

                DynamicIslandExpandedRegion(.trailing) {
                    // Delivery estimate
                    VStack(alignment: .trailing, spacing: 4) {
                        Text("Delivery")
                            .font(.caption2)
                            .foregroundStyle(.secondary)

                        Text(context.state.estimatedDelivery)
                            .font(.caption.bold())
                            .foregroundStyle(.primary)
                            .lineLimit(2)
                            .multilineTextAlignment(.trailing)
                    }
                }

                DynamicIslandExpandedRegion(.center) {
                    // Package info and location
                    VStack(spacing: 8) {
                        // Tracking number
                        HStack {
                            Text(context.attributes.carrier)
                                .font(.caption2.bold())
                                .foregroundStyle(.secondary)

                            Text("•")
                                .foregroundStyle(.secondary)

                            Text(context.attributes.trackingNumber)
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }

                        // Current location (if available)
                        if let location = context.state.currentLocation {
                            HStack {
                                Image(systemName: "location.fill")
                                    .font(.caption2)
                                    .foregroundStyle(.blue)

                                Text(location)
                                    .font(.caption)
                                    .foregroundStyle(.primary)
                            }
                        }

                        // Progress bar
                        ProgressView(value: Double(context.state.progress), total: 100)
                            .tint(context.state.status.color)
                            .frame(height: 4)
                    }
                    .padding(.vertical, 8)
                }

                DynamicIslandExpandedRegion(.bottom) {
                    // Last updated time
                    HStack {
                        Image(systemName: "clock")
                            .font(.caption2)
                        Text("Updated \(context.state.lastUpdated, style: .relative) ago")
                            .font(.caption2)
                    }
                    .foregroundStyle(.secondary)
                }

            } compactLeading: {
                // Compact Leading (small icon on left of notch)
                Image(systemName: context.state.status.icon)
                    .font(.caption2)
                    .foregroundStyle(context.state.status.color)

            } compactTrailing: {
                // Compact Trailing (progress on right of notch)
                Text("\(context.state.progress)%")
                    .font(.caption2.bold())
                    .foregroundStyle(context.state.status.color)

            } minimal: {
                // Minimal (when multiple activities are running)
                Image(systemName: context.state.status.icon)
                    .font(.caption2)
                    .foregroundStyle(context.state.status.color)
            }
            .contentMargins(.all, 8)
        }
    }
}

// MARK: - Lock Screen View

@available(iOS 16.1, *)
struct LockScreenLiveActivityView: View {
    let context: ActivityViewContext<PackageTrackingAttributes>

    var body: some View {
        VStack(spacing: 12) {
            // Header: Carrier and tracking number
            HStack {
                Image(systemName: context.state.status.icon)
                    .font(.title3)
                    .foregroundStyle(context.state.status.color)

                VStack(alignment: .leading, spacing: 2) {
                    Text(context.attributes.carrier)
                        .font(.caption.bold())
                        .foregroundStyle(.secondary)

                    Text(context.attributes.trackingNumber)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 2) {
                    Text(context.state.status.rawValue)
                        .font(.caption.bold())
                        .foregroundStyle(.primary)

                    Text("\(context.state.progress)%")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }

            // Progress bar
            ProgressView(value: Double(context.state.progress), total: 100)
                .tint(context.state.status.color)
                .frame(height: 6)

            // Current location and delivery estimate
            HStack {
                if let location = context.state.currentLocation {
                    HStack(spacing: 4) {
                        Image(systemName: "location.fill")
                            .font(.caption2)
                        Text(location)
                            .font(.caption)
                    }
                    .foregroundStyle(.primary)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 2) {
                    Text("Delivery")
                        .font(.caption2)
                        .foregroundStyle(.secondary)

                    Text(context.state.estimatedDelivery)
                        .font(.caption.bold())
                        .foregroundStyle(.primary)
                }
            }

            // Package description (if available)
            if let description = context.attributes.description {
                Text(description)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .padding(16)
        .activityBackgroundTint(Color.black.opacity(0.3))
        .activitySystemActionForegroundColor(.white)
    }
}

// MARK: - Preview

@available(iOS 16.1, *)
struct PackageTrackingLiveActivity_Previews: PreviewProvider {
    static let attributes = PackageTrackingAttributes(
        trackingNumber: "1Z999AA10123456784",
        carrier: "UPS",
        description: "MacBook Pro 16\""
    )

    static let contentState = PackageTrackingAttributes.ContentState(
        status: .inTransit,
        currentLocation: "Memphis, TN",
        estimatedDelivery: "Today by 8pm",
        lastUpdated: Date(),
        progress: 65
    )

    static var previews: some View {
        attributes
            .previewContext(contentState, viewKind: .dynamicIsland(.compact))
            .previewDisplayName("Compact")

        attributes
            .previewContext(contentState, viewKind: .dynamicIsland(.expanded))
            .previewDisplayName("Expanded")

        attributes
            .previewContext(contentState, viewKind: .dynamicIsland(.minimal))
            .previewDisplayName("Minimal")

        attributes
            .previewContext(contentState, viewKind: .content)
            .previewDisplayName("Lock Screen")
    }
}
