import SwiftUI

struct SnoozeModal: View {
    let card: EmailCard
    @Binding var isPresented: Bool
    @State private var selectedOption: SnoozeOption?
    @State private var customDate = Date()
    @State private var showCustomPicker = false
    @State private var showSuccess = false

    var snoozeOptions: [SnoozeOption] {
        SnoozeService.shared.suggestSnoozeTimes(for: card)
    }

    var body: some View {
        VStack(spacing: 0) {
            // Custom header
            HStack {
                Spacer()
                Button {
                    isPresented = false
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(DesignTokens.Colors.textSubtle)
                        .font(.title2)
                }
            }
            .padding(.top, DesignTokens.Spacing.card)
            .padding(.horizontal)
            .padding(.bottom, DesignTokens.Spacing.inline)

            ScrollView {
                VStack(alignment: .leading, spacing: DesignTokens.Spacing.card) {
                    // Header
                    VStack(alignment: .leading, spacing: DesignTokens.Spacing.inline) {
                        HStack {
                            Image(systemName: "clock.badge.checkmark.fill")
                                .font(.title)
                                .foregroundColor(.blue)

                            Text("Snooze Email")
                                .font(.title2.bold())
                                .foregroundColor(DesignTokens.Colors.textPrimary)
                        }

                        Text(card.title)
                            .font(.subheadline)
                            .foregroundColor(DesignTokens.Colors.textSubtle)
                            .lineLimit(2)
                    }

                    Divider()
                        .background(Color.white.opacity(0.3))

                    // Smart suggestions
                    VStack(alignment: .leading, spacing: DesignTokens.Spacing.component) {
                        Text("When should we remind you?")
                            .font(.headline)
                            .foregroundColor(DesignTokens.Colors.textPrimary)

                        ForEach(snoozeOptions) { option in
                            SnoozeOptionRow(
                                option: option,
                                isSelected: selectedOption?.id == option.id
                            ) {
                                selectedOption = option
                                showCustomPicker = false
                            }
                        }

                        // Custom time option
                        Button {
                            showCustomPicker.toggle()
                            if showCustomPicker {
                                selectedOption = nil
                            }
                        } label: {
                            HStack(spacing: DesignTokens.Spacing.component) {
                                Image(systemName: "calendar.badge.clock")
                                    .font(.title3)
                                    .foregroundColor(.purple)
                                    .frame(width: 32)

                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Custom Time")
                                        .font(.subheadline.bold())
                                        .foregroundColor(DesignTokens.Colors.textPrimary)

                                    Text("Choose a specific date and time")
                                        .font(.caption)
                                        .foregroundColor(DesignTokens.Colors.textSubtle)
                                }

                                Spacer()

                                Image(systemName: showCustomPicker ? "chevron.down" : "chevron.right")
                                    .font(.caption)
                                    .foregroundColor(DesignTokens.Colors.textSubtle)
                            }
                            .padding()
                            .background(
                                RoundedRectangle(cornerRadius: DesignTokens.Radius.button)
                                    .fill(showCustomPicker ? Color.purple.opacity(0.2) : Color.white.opacity(0.05))
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: DesignTokens.Radius.button)
                                    .strokeBorder(
                                        showCustomPicker ? Color.purple : Color.white.opacity(0.1),
                                        lineWidth: 2
                                    )
                            )
                        }
                        .buttonStyle(PlainButtonStyle())

                        // Custom date picker
                        if showCustomPicker {
                            DatePicker(
                                "Select Time",
                                selection: $customDate,
                                in: Date()...,
                                displayedComponents: [.date, .hourAndMinute]
                            )
                            .datePickerStyle(.graphical)
                            .colorScheme(.dark)
                            .padding()
                            .background(
                                RoundedRectangle(cornerRadius: DesignTokens.Radius.button)
                                    .fill(Color.white.opacity(0.1))
                            )
                        }
                    }

                    // Action buttons
                    VStack(spacing: 12) {
                        Button {
                            snoozeEmail()
                        } label: {
                            HStack {
                                Image(systemName: "clock.badge.checkmark")
                                Text("Snooze Email")
                            }
                        }
                        .buttonStyle(.gradientPrimary)
                        .disabled(selectedOption == nil && !showCustomPicker)

                        if showSuccess {
                            HStack {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.green)
                                Text("Email snoozed successfully!")
                                    .foregroundColor(.green)
                                    .font(.subheadline.bold())
                            }
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(
                                RoundedRectangle(cornerRadius: DesignTokens.Radius.button)
                                    .fill(Color.green.opacity(0.2))
                            )
                        }
                    }
                    .padding(.top, DesignTokens.Spacing.card)
                }
                .padding(DesignTokens.Spacing.card)
            }
        }
    }

    func snoozeEmail() {
        let snoozeTime: Date
        let reason: String

        if let option = selectedOption {
            snoozeTime = option.time
            reason = option.label
        } else if showCustomPicker {
            snoozeTime = customDate
            reason = "Custom time"
        } else {
            return
        }

        // Snooze the email
        SnoozeService.shared.snoozeEmail(card, until: snoozeTime, reason: reason)

        // Haptic feedback
        let impact = UINotificationFeedbackGenerator()
        impact.notificationOccurred(.success)

        // Show success
        showSuccess = true

        // Auto-dismiss after 1.5 seconds
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            isPresented = false
        }

        Logger.info("Snoozed '\(card.title)' until \(snoozeTime)", category: .action)
    }
}

struct SnoozeOptionRow: View {
    let option: SnoozeOption
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: DesignTokens.Spacing.component) {
                // Icon
                Image(systemName: option.icon)
                    .font(.title3)
                    .foregroundColor(isSelected ? .blue : DesignTokens.Colors.textSubtle)
                    .frame(width: 32)

                // Info
                VStack(alignment: .leading, spacing: 4) {
                    Text(option.label)
                        .font(.subheadline.bold())
                        .foregroundColor(DesignTokens.Colors.textPrimary)

                    Text(option.reason)
                        .font(.caption)
                        .foregroundColor(DesignTokens.Colors.textSubtle)
                }

                Spacer()

                // Selection indicator
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.title3)
                        .foregroundColor(.blue)
                } else {
                    Circle()
                        .strokeBorder(Color.white.opacity(0.3), lineWidth: 2)
                        .frame(width: 24, height: 24)
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: DesignTokens.Radius.button)
                    .fill(isSelected ? Color.blue.opacity(0.2) : Color.white.opacity(0.05))
            )
            .overlay(
                RoundedRectangle(cornerRadius: DesignTokens.Radius.button)
                    .strokeBorder(
                        isSelected ? Color.blue : Color.white.opacity(0.1),
                        lineWidth: 2
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}
