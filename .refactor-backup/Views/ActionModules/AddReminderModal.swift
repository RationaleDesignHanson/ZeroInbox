import SwiftUI
import EventKit

struct AddReminderModal: View {
    let card: EmailCard
    @Binding var isPresented: Bool

    @State private var reminderTitle = ""
    @State private var reminderNotes = ""
    @State private var dueDate = Date()
    @State private var hasDueDate = true
    @State private var priority: ReminderPriority = .medium
    @State private var showSuccess = false
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var savedReminderTitle: String?

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
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Image(systemName: "bell.badge.fill")
                                .font(.title)
                                .foregroundColor(.orange)

                            VStack(alignment: .leading, spacing: 4) {
                                Text("Set Reminder")
                                    .font(.title2.bold())
                                    .foregroundColor(DesignTokens.Colors.textPrimary)

                                Text(card.title)
                                    .font(.subheadline)
                                    .foregroundColor(DesignTokens.Colors.textSubtle)
                            }
                        }
                    }

                    Divider()
                        .background(Color.white.opacity(0.3))

                    // Reminder Title
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Reminder")
                            .font(.headline)
                            .foregroundColor(DesignTokens.Colors.textPrimary)

                        TextField("", text: $reminderTitle)
                            .textFieldStyle(PlainTextFieldStyle())
                            .padding()
                            .background(Color.white.opacity(0.1))
                            .cornerRadius(DesignTokens.Radius.button)
                            .foregroundColor(DesignTokens.Colors.textPrimary)
                            .overlay(
                                RoundedRectangle(cornerRadius: DesignTokens.Radius.button)
                                    .strokeBorder(Color.white.opacity(0.3), lineWidth: 1)
                            )
                    }

                    // Notes
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Notes")
                            .font(.headline)
                            .foregroundColor(DesignTokens.Colors.textPrimary)

                        TextEditor(text: $reminderNotes)
                            .frame(height: 100)
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

                    // Priority Selection
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Priority")
                            .font(.headline)
                            .foregroundColor(DesignTokens.Colors.textPrimary)

                        HStack(spacing: 12) {
                            ForEach(ReminderPriority.allCases, id: \.self) { p in
                                Button {
                                    priority = p
                                } label: {
                                    VStack(spacing: 4) {
                                        Image(systemName: p.icon)
                                            .font(.title3)
                                        Text(p.rawValue)
                                            .font(.caption)
                                    }
                                    .foregroundColor(priority == p ? .white : .white.opacity(0.5))
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, DesignTokens.Spacing.component)
                                    .background(priority == p ? p.color.opacity(0.3) : Color.white.opacity(0.05))
                                    .cornerRadius(DesignTokens.Radius.button)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: DesignTokens.Radius.button)
                                            .strokeBorder(priority == p ? p.color : Color.white.opacity(0.1), lineWidth: priority == p ? 2 : 1)
                                    )
                                }
                            }
                        }
                    }

                    // Due Date Toggle
                    Toggle(isOn: $hasDueDate) {
                        HStack {
                            Image(systemName: "calendar.badge.clock")
                                .foregroundColor(DesignTokens.Colors.textPrimary)
                            Text("Set Due Date")
                                .font(.headline)
                                .foregroundColor(DesignTokens.Colors.textPrimary)
                        }
                    }
                    .tint(.blue)

                    // Date Picker (if due date enabled)
                    if hasDueDate {
                        DatePicker("Due Date", selection: $dueDate, displayedComponents: [.date, .hourAndMinute])
                            .datePickerStyle(.compact)
                            .padding()
                            .background(Color.white.opacity(0.1))
                            .cornerRadius(DesignTokens.Radius.button)
                            .colorScheme(.dark)
                            .overlay(
                                RoundedRectangle(cornerRadius: DesignTokens.Radius.button)
                                    .strokeBorder(Color.white.opacity(0.3), lineWidth: 1)
                            )
                    }

                    // Create Reminder button
                    Button {
                        createReminder()
                    } label: {
                        HStack {
                            Image(systemName: "bell.badge.fill")
                            Text("Create Reminder")
                                .font(.headline)
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(reminderTitle.isEmpty ? Color.gray : Color.orange)
                        .foregroundColor(DesignTokens.Colors.textPrimary)
                        .cornerRadius(DesignTokens.Radius.button)
                    }
                    .disabled(reminderTitle.isEmpty)

                    // Success message
                    if showSuccess {
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.green)
                                    .font(.title2)
                                Text("Reminder Created!")
                                    .foregroundColor(.green)
                                    .font(.headline.bold())
                            }

                            if let title = savedReminderTitle {
                                Text(title)
                                    .font(.subheadline)
                                    .foregroundColor(DesignTokens.Colors.textSecondary)
                                    .padding(.leading, 32)
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding()
                        .background(Color.green.opacity(0.2))
                        .cornerRadius(DesignTokens.Radius.button)
                    }

                    // Error message
                    if showError {
                        HStack {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundColor(.red)
                            Text(errorMessage)
                                .foregroundColor(.red)
                                .font(.caption)
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.red.opacity(0.2))
                        .cornerRadius(DesignTokens.Radius.button)
                    }
                }
                .padding(DesignTokens.Spacing.card)
            }
        }
        .onAppear {
            detectReminderDetails()
        }
    }

    func detectReminderDetails() {
        // Use RemindersService to detect smart defaults
        if let opportunity = RemindersService.shared.detectReminderOpportunity(in: card) {
            reminderTitle = opportunity.title
            reminderNotes = card.summary

            if let date = opportunity.suggestedDate {
                dueDate = date
                hasDueDate = true
            }

            // Set priority based on detected priority value
            switch opportunity.priority {
            case 1...4:
                priority = .high
            case 5:
                priority = .medium
            default:
                priority = .low
            }
        } else {
            // Default values
            reminderTitle = "Follow up: \(card.title)"
            reminderNotes = card.summary

            // Default to 3 days from now at 9 AM
            if let defaultDate = Calendar.current.date(byAdding: .day, value: 3, to: Date()) {
                var components = Calendar.current.dateComponents([.year, .month, .day], from: defaultDate)
                components.hour = 9
                components.minute = 0
                dueDate = Calendar.current.date(from: components) ?? defaultDate
            }
        }
    }

    func createReminder() {
        showError = false
        showSuccess = false

        RemindersService.shared.createReminder(
            title: reminderTitle,
            notes: reminderNotes,
            dueDate: hasDueDate ? dueDate : nil,
            priority: priority.ekPriority,
            url: nil  // No direct URL field on EmailCard
        ) { result in
            DispatchQueue.main.async {
                switch result {
                case .success(let reminder):
                    savedReminderTitle = reminder.title
                    showSuccess = true
                    Logger.info("Reminder created: \(reminder.title ?? "Untitled")", category: .action)

                    // Haptic feedback
                    let impact = UINotificationFeedbackGenerator()
                    impact.notificationOccurred(.success)

                    // Auto-dismiss after success
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                        isPresented = false
                    }

                case .failure(let error):
                    showError = true
                    errorMessage = error.localizedDescription
                    Logger.error("Failed to create reminder: \(error.localizedDescription)", category: .action)

                    // Haptic feedback
                    let impact = UINotificationFeedbackGenerator()
                    impact.notificationOccurred(.error)
                }
            }
        }
    }
}

// MARK: - Priority Enum

enum ReminderPriority: String, CaseIterable {
    case high = "High"
    case medium = "Medium"
    case low = "Low"

    var icon: String {
        switch self {
        case .high: return "exclamationmark.3"
        case .medium: return "exclamationmark.2"
        case .low: return "exclamationmark"
        }
    }

    var color: Color {
        switch self {
        case .high: return .red
        case .medium: return .orange
        case .low: return .blue
        }
    }

    var ekPriority: Int {
        switch self {
        case .high: return 1
        case .medium: return 5
        case .low: return 9
        }
    }
}
