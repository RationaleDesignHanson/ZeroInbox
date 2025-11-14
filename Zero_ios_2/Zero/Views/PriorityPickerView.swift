//
//  PriorityPickerView.swift
//  Zero
//
//  Created by Claude Code on 10/25/25.
//

import SwiftUI

/**
 * PriorityPickerView - Modal for selecting email priority
 *
 * Allows users to manually set priority for any email card
 * Features:
 * - Visual priority icons and colors
 * - Descriptions for each priority level
 * - Immediate card update on selection
 * - Persistent storage via CardManagementService
 */
struct PriorityPickerView: View {
    @Environment(\.presentationMode) var presentationMode
    @Environment(\.colorScheme) var colorScheme: ColorScheme
    @Binding var selectedPriority: Priority
    let onSelect: (Priority) -> Void

    var body: some View {
        NavigationView {
            ZStack {
                backgroundColor.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 20) {
                        // Header
                        VStack(spacing: 8) {
                            Image(systemName: "flag.fill")
                                .font(.system(size: 48))
                                .foregroundColor(.blue)
                                .padding(.top, 24)

                            Text("Set Priority")
                                .font(.title2.bold())
                                .foregroundColor(textColor)

                            Text("Choose how important this email is")
                                .font(.subheadline)
                                .foregroundColor(textColor.opacity(DesignTokens.Opacity.textDisabled))
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 40)
                        }
                        .padding(.bottom, 16)

                        // Priority options
                        VStack(spacing: 16) {
                            ForEach(Priority.allCases, id: \.self) { priority in
                                PriorityOptionRow(
                                    priority: priority,
                                    isSelected: priority == selectedPriority,
                                    onTap: {
                                        HapticService.shared.mediumImpact()
                                        selectedPriority = priority
                                        onSelect(priority)

                                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                                            presentationMode.wrappedValue.dismiss()
                                        }
                                    }
                                )
                            }
                        }
                        .padding(.horizontal)

                        Spacer()
                    }
                }
            }
            .navigationTitle("Email Priority")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        presentationMode.wrappedValue.dismiss()
                    }
                    .foregroundColor(.blue)
                }
            }
        }
    }

    // MARK: - Computed Colors

    private var backgroundColor: Color {
        colorScheme == .dark ? Color(white: 0.10) : Color(white: 0.95)
    }

    private var textColor: Color {
        colorScheme == .dark ? Color.white : Color.black
    }
}

// MARK: - Priority Option Row

struct PriorityOptionRow: View {
    let priority: Priority
    let isSelected: Bool
    let onTap: () -> Void
    @Environment(\.colorScheme) var colorScheme: ColorScheme

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 16) {
                // Priority icon
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color(hex: priority.color),
                                    Color(hex: priority.color).opacity(DesignTokens.Opacity.textTertiary)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 56, height: 56)
                        .shadow(color: Color(hex: priority.color).opacity(DesignTokens.Opacity.overlayMedium), radius: 8, y: 4)

                    Image(systemName: priority.icon)
                        .font(.system(size: 24, weight: .semibold))
                        .foregroundColor(.white)
                }

                // Priority info
                VStack(alignment: .leading, spacing: 4) {
                    Text(priority.displayName)
                        .font(.headline)
                        .foregroundColor(textColor)

                    Text(priorityDescription(for: priority))
                        .font(.subheadline)
                        .foregroundColor(textColor.opacity(DesignTokens.Opacity.textDisabled))
                        .lineLimit(2)
                }

                Spacer()

                // Selection indicator
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.title2)
                        .foregroundColor(.blue)
                }
            }
            .padding(DesignTokens.Spacing.component)
            .background(rowBackgroundColor)
            .cornerRadius(DesignTokens.Radius.card)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .strokeBorder(
                        isSelected ? Color.blue : Color.clear,
                        lineWidth: 2
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
    }

    // MARK: - Helpers

    private func priorityDescription(for priority: Priority) -> String {
        switch priority {
        case .critical:
            return "Requires immediate attention"
        case .high:
            return "Important, needs action soon"
        case .medium:
            return "Normal importance"
        case .low:
            return "Can wait, low urgency"
        }
    }

    private var textColor: Color {
        colorScheme == .dark ? Color.white : Color.black
    }

    private var rowBackgroundColor: Color {
        colorScheme == .dark ? Color(white: 0.15) : Color.white
    }
}

// MARK: - Preview

#Preview {
    PriorityPickerView(
        selectedPriority: .constant(.medium),
        onSelect: { priority in
            print("Selected: \(priority)")
        }
    )
}
