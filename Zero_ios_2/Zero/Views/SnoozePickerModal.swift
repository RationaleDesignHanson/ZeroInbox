import SwiftUI

struct SnoozePickerModal: View {
    @Binding var isPresented: Bool
    @Binding var selectedDuration: Int // total hours
    let onConfirm: () -> Void
    
    @State private var selectedHours: Int = 0
    @State private var selectedMinutes: Int = 0
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Button {
                    isPresented = false
                } label: {
                    Text("Cancel")
                        .font(.body)
                        .foregroundColor(.white.opacity(DesignTokens.Opacity.textSubtle))
                }

                Spacer()

                VStack(spacing: 4) {
                    Text("Snooze")
                        .font(.title3.bold())
                        .foregroundColor(.white)

                    Text(timeDisplayString)
                        .font(.caption)
                        .foregroundColor(.purple.opacity(DesignTokens.Opacity.textTertiary))
                }

                Spacer()

                Button {
                    // Calculate total hours from picker selection
                    let totalMinutes = (selectedHours * 60) + selectedMinutes
                    selectedDuration = max(1, totalMinutes / 60) // Convert to hours, minimum 1
                    onConfirm()
                    isPresented = false
                } label: {
                    Text("Done")
                        .font(.body.bold())
                        .foregroundColor(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(
                            LinearGradient(
                                colors: [Color.purple, Color.blue],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .cornerRadius(DesignTokens.Radius.button)
                }
                .disabled(selectedHours == 0 && selectedMinutes == 0)
                .opacity(selectedHours == 0 && selectedMinutes == 0 ? 0.5 : 1.0)
            }
            .padding(.horizontal, DesignTokens.Spacing.card)
            .padding(.vertical, DesignTokens.Spacing.section)
            .background(
                ZStack {
                    Color.black.opacity(DesignTokens.Opacity.overlayMedium)

                    // Subtle gradient overlay
                    LinearGradient(
                        colors: [
                            Color.purple.opacity(DesignTokens.Opacity.glassLight),
                            Color.clear
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                }
            )

            // Elegant separator
            Rectangle()
                .fill(
                    LinearGradient(
                        colors: [
                            Color.clear,
                            Color.purple.opacity(DesignTokens.Opacity.overlayMedium),
                            Color.blue.opacity(DesignTokens.Opacity.overlayMedium),
                            Color.clear
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .frame(height: 1)

            // Icon and description
            VStack(spacing: DesignTokens.Spacing.component) {
                Image(systemName: iconForCurrentSelection)
                    .font(.system(size: 40))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Color.purple, Color.blue],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .shadow(color: Color.purple.opacity(DesignTokens.Opacity.overlayStrong), radius: 10)

                Text(descriptionForCurrentSelection)
                    .font(.subheadline)
                    .foregroundColor(DesignTokens.Colors.textSubtle)
            }
            .padding(.top, DesignTokens.Spacing.card)
            .padding(.bottom, DesignTokens.Spacing.section)

            // Elegant picker wheels with glassmorphism
            ZStack {
                // Glassmorphic background for picker area
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color.white.opacity(DesignTokens.Opacity.glassUltraLight))
                    .background(
                        RoundedRectangle(cornerRadius: 20)
                            .fill(.ultraThinMaterial.opacity(DesignTokens.Opacity.overlayMedium))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(
                                LinearGradient(
                                    colors: [
                                        Color.purple.opacity(DesignTokens.Opacity.overlayMedium),
                                        Color.blue.opacity(DesignTokens.Opacity.overlayLight),
                                        Color.purple.opacity(DesignTokens.Opacity.overlayMedium)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 1
                            )
                    )
                    .padding(.horizontal, 32)

                // Picker wheels
                HStack(spacing: 0) {
                    // Hours picker
                    Picker("Hours", selection: $selectedHours) {
                        ForEach(0..<24, id: \.self) { hour in
                            Text("\(hour)")
                                .font(.system(size: 22, weight: .medium, design: .rounded))
                                .foregroundColor(.white)
                                .tag(hour)
                        }
                    }
                    .pickerStyle(.wheel)
                    .frame(maxWidth: .infinity)

                    Text("hr")
                        .font(.system(size: 20, weight: .semibold, design: .rounded))
                        .foregroundColor(DesignTokens.Colors.textSubtle)
                        .padding(.horizontal, DesignTokens.Spacing.component)

                    // Minutes picker
                    Picker("Minutes", selection: $selectedMinutes) {
                        ForEach(Array(stride(from: 0, through: 55, by: 5)), id: \.self) { minute in
                            Text("\(minute)")
                                .font(.system(size: 22, weight: .medium, design: .rounded))
                                .foregroundColor(DesignTokens.Colors.textPrimary)
                                .tag(minute)
                        }
                    }
                    .pickerStyle(.wheel)
                    .frame(maxWidth: .infinity)

                    Text("min")
                        .font(.system(size: 20, weight: .semibold, design: .rounded))
                        .foregroundColor(DesignTokens.Colors.textSubtle)
                        .padding(.horizontal, DesignTokens.Spacing.component)
                }
                .padding(.horizontal, DesignTokens.Spacing.card)
            }
            .frame(height: 200)
            .padding(.bottom, 32)
        }
        .frame(maxWidth: .infinity)
        .background(
            ZStack {
                // Base gradient
                LinearGradient(
                    colors: [
                        Color(red: 0.12, green: 0.12, blue: 0.18),
                        Color(red: 0.08, green: 0.08, blue: 0.12)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )

                // Subtle accent gradient
                LinearGradient(
                    colors: [
                        Color.purple.opacity(DesignTokens.Opacity.glassLight),
                        Color.clear,
                        Color.blue.opacity(DesignTokens.Opacity.glassUltraLight)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            }
        )
        .cornerRadius(28)
        .shadow(color: Color.purple.opacity(DesignTokens.Opacity.overlayLight), radius: 20)
        .onAppear {
            // Initialize picker with current selected duration
            if selectedDuration > 0 {
                selectedHours = selectedDuration
                selectedMinutes = 0
            } else {
                // Default to 2 hours
                selectedHours = 2
                selectedMinutes = 0
            }
        }
    }

    // MARK: - Computed Properties

    var timeDisplayString: String {
        let totalMinutes = (selectedHours * 60) + selectedMinutes
        if totalMinutes == 0 {
            return "Select duration"
        } else if selectedHours == 0 {
            return "\(selectedMinutes) minutes"
        } else if selectedMinutes == 0 {
            return selectedHours == 1 ? "1 hour" : "\(selectedHours) hours"
        } else {
            return "\(selectedHours)h \(selectedMinutes)m"
        }
    }

    var iconForCurrentSelection: String {
        let totalMinutes = (selectedHours * 60) + selectedMinutes

        if totalMinutes == 0 {
            return "clock.badge.questionmark"
        } else if totalMinutes <= 60 {
            return "clock.fill"
        } else if totalMinutes <= 240 {
            return "clock.arrow.circlepath"
        } else if totalMinutes <= 480 {
            return "moon.zzz.fill"
        } else {
            return "calendar.badge.clock"
        }
    }

    var descriptionForCurrentSelection: String {
        let totalMinutes = (selectedHours * 60) + selectedMinutes

        if totalMinutes == 0 {
            return "Choose how long to snooze"
        } else if totalMinutes <= 60 {
            return "Short break"
        } else if totalMinutes <= 240 {
            return "A few hours"
        } else if totalMinutes <= 480 {
            return "Later today"
        } else {
            return "Tomorrow"
        }
    }
}

