import SwiftUI

struct DeliveryWindow: Identifiable {
    let id = UUID()
    let date: Date
    let startTime: String
    let endTime: String
    let available: Bool
}

struct ScheduleDeliveryTimeModal: View {
    let card: EmailCard
    @Binding var isPresented: Bool

    @State private var selectedDate = Date()
    @State private var deliveryWindows: [DeliveryWindow] = []
    @State private var selectedWindow: DeliveryWindow?
    @State private var showSuccess = false
    @State private var deliveryItem = ""

    var body: some View {
        VStack(spacing: 0) {
            // Custom header bar
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
            .padding()

            // Scrollable content
            ScrollView {
                VStack(alignment: .leading, spacing: DesignTokens.Spacing.card) {
                    // Header
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Image(systemName: "shippingbox.fill")
                                .font(.largeTitle)
                                .foregroundColor(.orange)

                            VStack(alignment: .leading, spacing: 4) {
                                Text("Schedule Delivery")
                                    .font(.title2.bold())
                                    .foregroundColor(DesignTokens.Colors.textPrimary)

                                if !deliveryItem.isEmpty {
                                    Text(deliveryItem)
                                        .font(.subheadline)
                                        .foregroundColor(DesignTokens.Colors.textSubtle)
                                }
                            }
                        }
                    }

                    Divider()
                        .background(Color.white.opacity(0.3))

                    if !showSuccess {
                        // Date Picker
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Select Date")
                                .font(.headline)
                                .foregroundColor(DesignTokens.Colors.textPrimary)

                            DatePicker(
                                "Delivery Date",
                                selection: $selectedDate,
                                in: Date()...,
                                displayedComponents: .date
                            )
                            .datePickerStyle(.graphical)
                            .accentColor(.orange)
                            .colorScheme(.dark)
                            .padding()
                            .background(Color.white.opacity(0.08))
                            .cornerRadius(DesignTokens.Radius.card)
                            .onChange(of: selectedDate) { _, _ in
                                generateDeliveryWindows()
                            }
                        }

                        // Delivery Windows
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Choose Time Window")
                                .font(.headline)
                                .foregroundColor(DesignTokens.Colors.textPrimary)

                            VStack(spacing: 12) {
                                ForEach(deliveryWindows) { window in
                                    DeliveryWindowCard(
                                        window: window,
                                        isSelected: selectedWindow?.id == window.id,
                                        onTap: {
                                            if window.available {
                                                selectedWindow = window
                                            }
                                        }
                                    )
                                }
                            }
                        }

                        // Delivery Instructions
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Delivery Instructions (Optional)")
                                .font(.headline)
                                .foregroundColor(DesignTokens.Colors.textPrimary)

                            TextEditor(text: .constant(""))
                                .frame(height: 80)
                                .padding()
                                .background(Color.white.opacity(0.1))
                                .cornerRadius(DesignTokens.Radius.button)
                                .foregroundColor(DesignTokens.Colors.textPrimary)
                                .colorScheme(.dark)
                                .scrollContentBackground(.hidden)
                                .overlay(
                                    RoundedRectangle(cornerRadius: DesignTokens.Radius.button)
                                        .strokeBorder(Color.white.opacity(0.3), lineWidth: 1)
                                )
                        }

                        // Confirm Button
                        Button {
                            confirmDelivery()
                        } label: {
                            HStack {
                                Image(systemName: "checkmark.circle.fill")
                                Text("Confirm Delivery Time")
                                    .font(.headline)
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(selectedWindow == nil ? Color.gray : Color.orange)
                            .foregroundColor(.white)
                            .cornerRadius(DesignTokens.Radius.button)
                        }
                        .disabled(selectedWindow == nil)

                    } else {
                        // Success State
                        VStack(spacing: 20) {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 72))
                                .foregroundColor(.green)

                            VStack(spacing: 8) {
                                Text("Delivery Scheduled!")
                                    .font(.title.bold())
                                    .foregroundColor(.green)

                                if let window = selectedWindow {
                                    Text(selectedDate, style: .date)
                                        .font(.headline)
                                        .foregroundColor(DesignTokens.Colors.textPrimary)

                                    Text("\(window.startTime) - \(window.endTime)")
                                        .font(.subheadline)
                                        .foregroundColor(DesignTokens.Colors.textSubtle)
                                }
                            }

                            Text("You'll receive a confirmation email with your delivery details")
                                .font(.subheadline)
                                .foregroundColor(DesignTokens.Colors.textSecondary)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 40)
                        .background(Color.green.opacity(0.1))
                        .cornerRadius(DesignTokens.Radius.card)
                    }

                    // Info message
                    HStack(alignment: .top, spacing: 8) {
                        Image(systemName: "info.circle")
                            .foregroundColor(.blue)
                            .font(.caption)
                        Text("Choose a delivery window that works best for you. You'll receive SMS notifications when the driver is on the way.")
                            .font(.caption)
                            .foregroundColor(DesignTokens.Colors.textSubtle)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .padding()
                    .background(Color.blue.opacity(0.1))
                    .cornerRadius(DesignTokens.Radius.button)
                }
                .padding(DesignTokens.Spacing.card)
            }
        }
        .onAppear {
            detectDeliveryDetails()
            generateDeliveryWindows()
        }
    }

    func detectDeliveryDetails() {
        // Extract what's being delivered from the email
        let text = card.title.lowercased()

        if text.contains("furniture") {
            deliveryItem = "Furniture Delivery"
        } else if text.contains("package") {
            deliveryItem = "Package Delivery"
        } else if text.contains("appliance") {
            deliveryItem = "Appliance Delivery"
        } else if text.contains("grocery") || text.contains("groceries") {
            deliveryItem = "Grocery Delivery"
        } else if text.contains("food") {
            deliveryItem = "Food Delivery"
        } else {
            deliveryItem = "Delivery"
        }
    }

    func generateDeliveryWindows() {
        // Generate delivery windows for the selected date
        deliveryWindows = [
            DeliveryWindow(
                date: selectedDate,
                startTime: "8:00 AM",
                endTime: "10:00 AM",
                available: true
            ),
            DeliveryWindow(
                date: selectedDate,
                startTime: "10:00 AM",
                endTime: "12:00 PM",
                available: true
            ),
            DeliveryWindow(
                date: selectedDate,
                startTime: "12:00 PM",
                endTime: "2:00 PM",
                available: true
            ),
            DeliveryWindow(
                date: selectedDate,
                startTime: "2:00 PM",
                endTime: "4:00 PM",
                available: true
            ),
            DeliveryWindow(
                date: selectedDate,
                startTime: "4:00 PM",
                endTime: "6:00 PM",
                available: true
            ),
            DeliveryWindow(
                date: selectedDate,
                startTime: "6:00 PM",
                endTime: "8:00 PM",
                available: Calendar.current.component(.weekday, from: selectedDate) != 1 // Not available Sundays
            )
        ]

        // Reset selection when date changes
        selectedWindow = nil
    }

    func confirmDelivery() {
        guard let window = selectedWindow else { return }

        Logger.info("Delivery scheduled: \(selectedDate) \(window.startTime)-\(window.endTime)", category: .action)

        // Show success
        withAnimation(.spring()) {
            showSuccess = true
        }

        // Haptic feedback
        let impact = UINotificationFeedbackGenerator()
        impact.notificationOccurred(.success)

        // Log analytics
        AnalyticsService.shared.log(
            .actionExecuted,
            parameters: [
                "action_id": "schedule_delivery",
                "delivery_date": selectedDate.ISO8601Format(),
                "delivery_window": "\(window.startTime)-\(window.endTime)"
            ]
        )

        // Auto-dismiss after 3 seconds
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
            isPresented = false
        }
    }
}

// MARK: - Delivery Window Card

struct DeliveryWindowCard: View {
    let window: DeliveryWindow
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button {
            onTap()
        } label: {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 8) {
                        Image(systemName: "clock.fill")
                            .foregroundColor(isSelected ? .orange : .white.opacity(0.7))

                        Text("\(window.startTime) - \(window.endTime)")
                            .font(.subheadline.bold())
                            .foregroundColor(isSelected ? .orange : DesignTokens.Colors.textPrimary)
                    }

                    if !window.available {
                        Text("Unavailable")
                            .font(.caption)
                            .foregroundColor(.red)
                    }
                }

                Spacer()

                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.orange)
                        .font(.title3)
                }
            }
            .padding()
            .background(
                isSelected ? Color.orange.opacity(0.2) : Color.white.opacity(0.08)
            )
            .cornerRadius(DesignTokens.Radius.button)
            .overlay(
                RoundedRectangle(cornerRadius: DesignTokens.Radius.button)
                    .strokeBorder(
                        isSelected ? Color.orange : Color.white.opacity(0.3),
                        lineWidth: isSelected ? 2 : 1
                    )
            )
            .opacity(window.available ? 1.0 : 0.5)
        }
        .disabled(!window.available)
    }
}

// MARK: - Preview

#Preview("Schedule Delivery Time Modal") {
    ScheduleDeliveryTimeModal(
        card: EmailCard(
            id: "preview",
            type: .mail,
            state: .seen,
            priority: .medium,
            hpa: "schedule_delivery_time",
            timeAgo: "2h",
            title: "Your Furniture Delivery is Ready to Schedule",
            summary: "Your new sofa is ready for delivery! Please select a convenient delivery window. Our team will contact you 30 minutes before arrival.",
            body: "Dear Customer,\n\nYour furniture order is ready for delivery!\n\nOrder: Modern 3-Seater Sofa\nOrder #: 12345\n\nPlease choose a delivery date and time window that works best for you. Our delivery team will call 30 minutes before arrival.\n\nDelivery is available Monday-Saturday, 8 AM - 8 PM.\n\nThank you for your order!",
            metaCTA: "View",
            suggestedActions: [
                EmailAction(
                    actionId: "schedule_delivery_time",
                    displayName: "Schedule Delivery",
                    actionType: .inApp,
                    isPrimary: true,
                    context: [:]
                )
            ],
            sender: SenderInfo(
                name: "Wayfair Delivery",
                initial: "W",
                email: "delivery@wayfair.com"
            )
        ),
        isPresented: .constant(true)
    )
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(
        LinearGradient(
            colors: [
                Color(red: 0.1, green: 0.1, blue: 0.2),
                Color(red: 0.05, green: 0.05, blue: 0.15)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    )
}
