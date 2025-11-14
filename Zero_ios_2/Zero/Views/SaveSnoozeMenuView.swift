//
//  SaveSnoozeMenuView.swift
//  Zero
//
//  Created by Claude Code on 10/25/25.
//

import SwiftUI

/**
 * SaveSnoozeMenuView - Menu shown when user swipes down on a card
 *
 * Offers two options:
 * 1. Save to Folder - Opens folder picker for saving email
 * 2. Snooze - Snoozes the email (shows duration picker if first time)
 */
struct SaveSnoozeMenuView: View {
    let card: EmailCard
    @Binding var isPresented: Bool
    var onSaveToFolder: () -> Void
    var onSnooze: () -> Void
    @Environment(\.colorScheme) var colorScheme: ColorScheme

    var body: some View {
        VStack(spacing: 0) {
            // Handle bar
            RoundedRectangle(cornerRadius: 2.5)
                .fill(Color.gray.opacity(DesignTokens.Opacity.overlayMedium))
                .frame(width: 40, height: 5)
                .padding(.top, 12)
                .padding(.bottom, 20)

            // Header
            VStack(spacing: 8) {
                Text("What would you like to do?")
                    .font(.title2.bold())
                    .foregroundColor(textColor)

                Text(card.title)
                    .font(.subheadline)
                    .foregroundColor(textColor.opacity(DesignTokens.Opacity.textSubtle))
                    .lineLimit(2)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
            .padding(.bottom, 24)

            // Menu options
            VStack(spacing: 16) {
                // Save to Folder button
                Button(action: {
                    HapticService.shared.mediumImpact()
                    isPresented = false
                    // Small delay to allow sheet to dismiss
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        onSaveToFolder()
                    }
                }) {
                    HStack(spacing: 16) {
                        // Icon
                        ZStack {
                            Circle()
                                .fill(
                                    LinearGradient(
                                        colors: [Color.blue, Color.cyan],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .frame(width: 50, height: 50)

                            Image(systemName: "folder.fill.badge.plus")
                                .font(.system(size: 22))
                                .foregroundColor(.white)
                        }

                        // Text
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Save to Folder")
                                .font(.headline)
                                .foregroundColor(textColor)

                            Text("Save for later in a custom folder")
                                .font(.caption)
                                .foregroundColor(textColor.opacity(DesignTokens.Opacity.textDisabled))
                        }

                        Spacer()

                        // Chevron
                        Image(systemName: "chevron.right")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(textColor.opacity(DesignTokens.Opacity.overlayMedium))
                    }
                    .padding(DesignTokens.Spacing.section)
                    .background(
                        RoundedRectangle(cornerRadius: DesignTokens.Radius.container)
                            .fill(buttonBackgroundColor)
                            .overlay(
                                RoundedRectangle(cornerRadius: DesignTokens.Radius.container)
                                    .strokeBorder(borderColor, lineWidth: 1)
                            )
                    )
                }
                .buttonStyle(PlainButtonStyle())

                // Snooze button
                Button(action: {
                    HapticService.shared.mediumImpact()
                    isPresented = false
                    // Small delay to allow sheet to dismiss
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        onSnooze()
                    }
                }) {
                    HStack(spacing: 16) {
                        // Icon
                        ZStack {
                            Circle()
                                .fill(
                                    LinearGradient(
                                        colors: [Color.purple, Color.pink],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .frame(width: 50, height: 50)

                            Image(systemName: "clock.fill")
                                .font(.system(size: 22))
                                .foregroundColor(.white)
                        }

                        // Text
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Snooze")
                                .font(.headline)
                                .foregroundColor(textColor)

                            Text("Remind me later")
                                .font(.caption)
                                .foregroundColor(textColor.opacity(DesignTokens.Opacity.textDisabled))
                        }

                        Spacer()

                        // Chevron
                        Image(systemName: "chevron.right")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(textColor.opacity(DesignTokens.Opacity.overlayMedium))
                    }
                    .padding(DesignTokens.Spacing.section)
                    .background(
                        RoundedRectangle(cornerRadius: DesignTokens.Radius.container)
                            .fill(buttonBackgroundColor)
                            .overlay(
                                RoundedRectangle(cornerRadius: DesignTokens.Radius.container)
                                    .strokeBorder(borderColor, lineWidth: 1)
                            )
                    )
                }
                .buttonStyle(PlainButtonStyle())
            }
            .padding(.horizontal, DesignTokens.Spacing.card)
            .padding(.bottom, 24)

            // Cancel button
            Button("Cancel") {
                HapticService.shared.lightImpact()
                isPresented = false
            }
            .font(.headline)
            .foregroundColor(.blue)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: DesignTokens.Radius.button)
                    .fill(Color.gray.opacity(DesignTokens.Opacity.glassLight))
            )
            .padding(.horizontal, DesignTokens.Spacing.card)
            .padding(.bottom, 32)
        }
        .frame(maxWidth: .infinity)
        .background(backgroundColor)
        .cornerRadius(DesignTokens.Radius.container, corners: [.topLeft, .topRight])
    }

    // MARK: - Computed Colors

    private var backgroundColor: Color {
        colorScheme == .dark ? Color(white: 0.12) : Color.white
    }

    private var textColor: Color {
        colorScheme == .dark ? Color.white : Color.black
    }

    private var buttonBackgroundColor: Color {
        colorScheme == .dark ? Color(white: 0.18) : Color(white: 0.97)
    }

    private var borderColor: Color {
        colorScheme == .dark ? Color.white.opacity(DesignTokens.Opacity.glassLight) : Color.black.opacity(DesignTokens.Opacity.glassUltraLight)
    }
}

// MARK: - Corner Radius Extension

extension View {
    func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape(RoundedCorner(radius: radius, corners: corners))
    }
}

struct RoundedCorner: Shape {
    var radius: CGFloat = .infinity
    var corners: UIRectCorner = .allCorners

    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(
            roundedRect: rect,
            byRoundingCorners: corners,
            cornerRadii: CGSize(width: radius, height: radius)
        )
        return Path(path.cgPath)
    }
}

// MARK: - Preview

// Preview removed - requires complex EmailCard initialization
