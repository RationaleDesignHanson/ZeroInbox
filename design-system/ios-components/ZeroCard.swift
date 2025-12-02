//
//  ZeroCard.swift
//  Zero Design System
//
//  READY TO INTEGRATE - Drop into: Zero_ios_2/Zero/Core/UI/Components/
//  Requires: DesignTokens.swift in Zero/Config/
//
//  Usage:
//  ZeroCard(priority: .high) {
//      VStack {
//          Text("Email Title")
//          Text("Summary text...")
//      }
//  }
//

import SwiftUI

struct ZeroCard<Content: View>: View {
    // MARK: - Types

    enum Priority {
        case high
        case medium
        case low
        case none

        var badgeColor: Color {
            switch self {
            case .high: return DesignTokens.Colors.errorPrimary
            case .medium: return DesignTokens.Colors.warningPrimary
            case .low: return DesignTokens.Colors.successPrimary
            case .none: return .clear
            }
        }

        var badgeText: String? {
            switch self {
            case .high: return "High"
            case .medium: return "Medium"
            case .low: return "Low"
            case .none: return nil
            }
        }
    }

    enum Layout {
        case compact    // Single line, no expansion
        case standard   // Multi-line, expandable
        case expanded   // Full details visible

        var minHeight: CGFloat {
            switch self {
            case .compact: return 72
            case .standard: return 100
            case .expanded: return 200
            }
        }
    }

    // MARK: - Properties

    let priority: Priority
    let layout: Layout
    let isSelected: Bool
    let onTap: (() -> Void)?
    let content: Content

    // MARK: - Initializer

    init(
        priority: Priority = .none,
        layout: Layout = .standard,
        isSelected: Bool = false,
        onTap: (() -> Void)? = nil,
        @ViewBuilder content: () -> Content
    ) {
        self.priority = priority
        self.layout = layout
        self.isSelected = isSelected
        self.onTap = onTap
        self.content = content()
    }

    // MARK: - Body

    var body: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.element) {
            // Priority badge (if present)
            if let badgeText = priority.badgeText {
                HStack {
                    Circle()
                        .fill(priority.badgeColor)
                        .frame(width: 8, height: 8)
                    Text(badgeText)
                        .font(DesignTokens.Typography.caption)
                        .foregroundColor(priority.badgeColor)
                    Spacer()
                }
            }

            // Card content
            content
        }
        .frame(maxWidth: .infinity, minHeight: layout.minHeight, alignment: .topLeading)
        .padding(DesignTokens.Spacing.card)
        .background(
            RoundedRectangle(cornerRadius: DesignTokens.Radius.card)
                .fill(DesignTokens.Colors.surfacePrimary)
                .shadow(
                    color: Color.black.opacity(0.08),
                    radius: 8,
                    x: 0,
                    y: 2
                )
        )
        .overlay(
            RoundedRectangle(cornerRadius: DesignTokens.Radius.card)
                .stroke(
                    isSelected ? DesignTokens.Colors.accentBlue : DesignTokens.Colors.borderSubtle,
                    lineWidth: isSelected ? 2 : 1
                )
        )
        .contentShape(Rectangle())
        .onTapGesture {
            onTap?()
        }
    }
}

// MARK: - EmailCard (Specialized variant)

struct ZeroEmailCard: View {
    // MARK: - Properties

    let sender: String
    let subject: String
    let summary: String
    let timestamp: String
    let priority: ZeroCard.Priority
    let isUnread: Bool
    let isSelected: Bool
    let onTap: (() -> Void)?

    // MARK: - Body

    var body: some View {
        ZeroCard(
            priority: priority,
            layout: .standard,
            isSelected: isSelected,
            onTap: onTap
        ) {
            VStack(alignment: .leading, spacing: DesignTokens.Spacing.inline) {
                // Header: Sender + Timestamp
                HStack {
                    Text(sender)
                        .font(DesignTokens.Typography.bodyMedium)
                        .fontWeight(isUnread ? .semibold : .regular)
                        .foregroundColor(DesignTokens.Colors.textPrimary)

                    Spacer()

                    Text(timestamp)
                        .font(DesignTokens.Typography.caption)
                        .foregroundColor(DesignTokens.Colors.textSecondary)
                }

                // Subject
                Text(subject)
                    .font(DesignTokens.Typography.bodyLarge)
                    .fontWeight(.semibold)
                    .foregroundColor(DesignTokens.Colors.textPrimary)
                    .lineLimit(2)

                // Summary
                Text(summary)
                    .font(DesignTokens.Typography.bodySmall)
                    .foregroundColor(DesignTokens.Colors.textSecondary)
                    .lineLimit(3)

                // Unread indicator
                if isUnread {
                    HStack {
                        Circle()
                            .fill(DesignTokens.Colors.accentBlue)
                            .frame(width: 6, height: 6)
                        Text("Unread")
                            .font(DesignTokens.Typography.caption)
                            .foregroundColor(DesignTokens.Colors.accentBlue)
                    }
                }
            }
        }
    }
}

// MARK: - Previews

#Preview("Card Priorities") {
    VStack(spacing: DesignTokens.Spacing.section) {
        ZeroCard(priority: .high) {
            VStack(alignment: .leading) {
                Text("High Priority Card")
                    .font(DesignTokens.Typography.bodyLarge)
                Text("This is important content")
                    .font(DesignTokens.Typography.bodySmall)
            }
        }

        ZeroCard(priority: .medium) {
            VStack(alignment: .leading) {
                Text("Medium Priority Card")
                    .font(DesignTokens.Typography.bodyLarge)
                Text("This is normal content")
                    .font(DesignTokens.Typography.bodySmall)
            }
        }

        ZeroCard(priority: .low) {
            VStack(alignment: .leading) {
                Text("Low Priority Card")
                    .font(DesignTokens.Typography.bodyLarge)
                Text("This is low priority content")
                    .font(DesignTokens.Typography.bodySmall)
            }
        }
    }
    .padding()
}

#Preview("Card Layouts") {
    VStack(spacing: DesignTokens.Spacing.section) {
        ZeroCard(layout: .compact) {
            Text("Compact Card - Single line only")
                .font(DesignTokens.Typography.bodyMedium)
        }

        ZeroCard(layout: .standard) {
            VStack(alignment: .leading, spacing: 8) {
                Text("Standard Card")
                    .font(DesignTokens.Typography.bodyLarge)
                Text("Multiple lines of content can be displayed here")
                    .font(DesignTokens.Typography.bodySmall)
            }
        }

        ZeroCard(layout: .expanded) {
            VStack(alignment: .leading, spacing: 8) {
                Text("Expanded Card")
                    .font(DesignTokens.Typography.bodyLarge)
                Text("This shows full details with lots of content that can span multiple lines and paragraphs")
                    .font(DesignTokens.Typography.bodySmall)
            }
        }
    }
    .padding()
}

#Preview("Email Cards") {
    ScrollView {
        VStack(spacing: DesignTokens.Spacing.element) {
            ZeroEmailCard(
                sender: "Sarah Chen",
                subject: "Q4 Budget Review Meeting",
                summary: "Hi team, I've scheduled our quarterly budget review for next Tuesday at 2 PM. Please review the attached documents before the meeting.",
                timestamp: "2h ago",
                priority: .high,
                isUnread: true,
                isSelected: false,
                onTap: nil
            )

            ZeroEmailCard(
                sender: "Amazon",
                subject: "Your order has shipped",
                summary: "Good news! Your order #123-4567890 has shipped and will arrive by December 20th. Track your package using the link below.",
                timestamp: "5h ago",
                priority: .medium,
                isUnread: true,
                isSelected: false,
                onTap: nil
            )

            ZeroEmailCard(
                sender: "LinkedIn",
                subject: "Weekly job recommendations",
                summary: "We found 12 new jobs that match your preferences. Check them out before they're filled.",
                timestamp: "1d ago",
                priority: .low,
                isUnread: false,
                isSelected: false,
                onTap: nil
            )

            ZeroEmailCard(
                sender: "GitHub",
                subject: "You have 3 new notifications",
                summary: "Someone commented on your pull request in zero-ios repository.",
                timestamp: "2d ago",
                priority: .none,
                isUnread: false,
                isSelected: true,
                onTap: nil
            )
        }
        .padding()
    }
}

#Preview("Dark Mode") {
    VStack(spacing: DesignTokens.Spacing.element) {
        ZeroEmailCard(
            sender: "Sarah Chen",
            subject: "Q4 Budget Review",
            summary: "Meeting scheduled for next Tuesday at 2 PM",
            timestamp: "2h ago",
            priority: .high,
            isUnread: true,
            isSelected: false,
            onTap: nil
        )

        ZeroEmailCard(
            sender: "Amazon",
            subject: "Order shipped",
            summary: "Your package will arrive by December 20th",
            timestamp: "5h ago",
            priority: .medium,
            isUnread: false,
            isSelected: true,
            onTap: nil
        )
    }
    .padding()
    .preferredColorScheme(.dark)
}
