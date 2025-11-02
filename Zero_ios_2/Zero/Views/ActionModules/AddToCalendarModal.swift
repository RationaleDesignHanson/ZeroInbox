import SwiftUI
import EventKit

struct AddToCalendarModal: View {
    let card: EmailCard
    @Binding var isPresented: Bool
    
    @State private var eventTitle = ""
    @State private var eventDate = Date()
    @State private var notes = ""
    @State private var showSuccess = false
    @State private var selectedSupplies: Set<String> = []
    @State private var errorMessage: String?
    @State private var showError = false
    @State private var savedEventTitle: String?
    @State private var savedEventDate: Date?

    private let eventStore = EKEventStore()
    
    var needsSupplies: Bool {
        card.summary.lowercased().contains("supplies") || 
        card.summary.lowercased().contains("poster board")
    }
    
    var isBookFair: Bool {
        card.title.lowercased().contains("book fair")
    }
    
    var suggestedSupplies: [(id: String, name: String, price: Double, image: String)] {
        if needsSupplies {
            return [
                ("s1", "Poster Board 3-Pack", 12.99, "https://images.unsplash.com/photo-1531346878377-a5be20888e57?w=400"),
                ("s2", "Crayola Markers 24-Count", 8.99, "https://images.unsplash.com/photo-1513542789411-b6a5d4f31634?w=400")
            ]
        } else if isBookFair {
            return [
                ("b1", "Wonder by R.J. Palacio", 14.99, "https://images.unsplash.com/photo-1544947950-fa07a98d237f?w=400"),
                ("b2", "Harry Potter Box Set", 49.99, "https://images.unsplash.com/photo-1481627834876-b7833e8f5570?w=400"),
                ("b3", "Diary of a Wimpy Kid Set", 29.99, "https://images.unsplash.com/photo-1512820790803-83ca734da794?w=400")
            ]
        }
        return []
    }
    
    var totalCost: Double {
        suggestedSupplies
            .filter { selectedSupplies.contains($0.id) }
            .reduce(0) { $0 + $1.price }
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
            .padding(.top, 20)  // Ensure header clears sheet top rounded corner
            .padding(.horizontal)
            .padding(.bottom, 8)

            ScrollView {
            VStack(alignment: .leading, spacing: DesignTokens.Spacing.card) {
                    // Header
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Add to Calendar")
                            .font(.title2.bold())
                            .foregroundColor(DesignTokens.Colors.textPrimary)
                        
                        Text(card.title)
                            .font(.subheadline)
                            .foregroundColor(DesignTokens.Colors.textSubtle)
                    }
                    
                    Divider()
                        .background(Color.white.opacity(0.3))
                    
                    // Event title
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Event Title")
                            .font(.headline)
                            .foregroundColor(DesignTokens.Colors.textPrimary)
                        
                        TextField("", text: $eventTitle)
                            .textFieldStyle(PlainTextFieldStyle())
                            .padding()
                            .background(Color.white.opacity(0.1))
                            .cornerRadius(DesignTokens.Radius.button)
                            .foregroundColor(DesignTokens.Colors.textPrimary)
                    }
                    
                    // Date picker
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Date & Time")
                            .font(.headline)
                            .foregroundColor(DesignTokens.Colors.textPrimary)
                        
                        DatePicker("", selection: $eventDate, displayedComponents: [.date, .hourAndMinute])
                            .datePickerStyle(.compact)
                            .labelsHidden()
                            .padding()
                            .background(Color.white.opacity(0.1))
                            .cornerRadius(DesignTokens.Radius.button)
                            .colorScheme(.dark)
                    }
                    
                    // Notes
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Notes")
                            .font(.headline)
                            .foregroundColor(DesignTokens.Colors.textPrimary)

                        TextEditor(text: $notes)
                            .frame(height: 100)
                            .padding()
                            .background(Color.white.opacity(0.1))
                            .cornerRadius(DesignTokens.Radius.button)
                            .foregroundColor(DesignTokens.Colors.textPrimary)
                            .colorScheme(.dark)
                            .scrollContentBackground(.hidden)
                    }
                    
                    // Suggested supplies/books
                    if !suggestedSupplies.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            Text(suppliesTitle)
                                .font(.headline.bold())
                                .foregroundColor(DesignTokens.Colors.textPrimary)
                            
                            ForEach(suggestedSupplies, id: \.id) { supply in
                                SupplyRow(
                                    supply: supply,
                                    isSelected: selectedSupplies.contains(supply.id)
                                ) {
                                    if selectedSupplies.contains(supply.id) {
                                        selectedSupplies.remove(supply.id)
                                    } else {
                                        selectedSupplies.insert(supply.id)
                                    }
                                }
                            }
                            
                            // Total cost
                            if !selectedSupplies.isEmpty {
                                HStack {
                                    Text("Total")
                                        .font(.headline)
                                        .foregroundColor(DesignTokens.Colors.textPrimary)
                                    Spacer()
                                    Text("$\(String(format: "%.2f", totalCost))")
                                        .font(.title2.bold())
                                        .foregroundColor(DesignTokens.Colors.textPrimary)
                                }
                                .padding()
                                .background(Color.green.opacity(0.2))
                                .cornerRadius(DesignTokens.Radius.button)
                            }
                        }
                    }
                    
                    // Action buttons
                    VStack(spacing: 12) {
                        Button {
                            addToCalendar()
                        } label: {
                            HStack {
                                Image(systemName: selectedSupplies.isEmpty ? "calendar.badge.plus" : "cart.fill.badge.plus")
                                Text(buttonText)
                            }
                        }
                        .buttonStyle(.gradientPrimary)
                        
                        if showSuccess {
                            VStack(alignment: .leading, spacing: 8) {
                                HStack {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundColor(.green)
                                        .font(.title2)
                                    Text("Added to Calendar!")
                                        .foregroundColor(.green)
                                        .font(.headline.bold())
                                }

                                if let title = savedEventTitle, let date = savedEventDate {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(title)
                                            .font(.subheadline)
                                            .foregroundColor(DesignTokens.Colors.textSecondary)

                                        Text(formatEventDate(date))
                                            .font(.caption)
                                            .foregroundColor(DesignTokens.Colors.textSubtle)
                                    }
                                    .padding(.leading, 32)
                                }
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding()
                            .background(Color.green.opacity(0.2))
                            .cornerRadius(DesignTokens.Radius.button)
                        }

                        if showError, let error = errorMessage {
                            HStack {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .foregroundColor(.red)
                                Text(error)
                                    .foregroundColor(.red)
                                    .font(.caption)
                            }
                            .padding()
                            .background(Color.red.opacity(0.1))
                            .cornerRadius(DesignTokens.Radius.chip)
                        }
                    }
                    .padding(.top, 20)
                }
                .padding(DesignTokens.Spacing.card)
            }
        }
        .onAppear {
            eventTitle = card.title
            notes = card.summary
            eventDate = detectEventDate(from: card)
        }
    }
    
    var suppliesTitle: String {
        if needsSupplies {
            return "Order Supplies"
        } else if isBookFair {
            return "Order Books"
        }
        return "Add-ons"
    }
    
    var buttonText: String {
        if !selectedSupplies.isEmpty {
            if isBookFair {
                return "Add to Calendar & Order Books ($\(String(format: "%.2f", totalCost)))"
            } else if needsSupplies {
                return "Add to Calendar & Order Supplies ($\(String(format: "%.2f", totalCost)))"
            }
        }
        return "Add to Calendar"
    }
    
    func addToCalendar() {
        Task {
            do {
                // Request calendar access
                let granted = try await eventStore.requestFullAccessToEvents()

                guard granted else {
                    await MainActor.run {
                        errorMessage = "Calendar access was denied. Please enable it in Settings."
                        showError = true
                    }
                    return
                }

                // Create the event
                let event = EKEvent(eventStore: eventStore)
                event.title = eventTitle.isEmpty ? card.title : eventTitle
                event.startDate = eventDate
                event.endDate = eventDate.addingTimeInterval(3600) // 1 hour duration
                event.notes = notes.isEmpty ? card.summary : notes
                event.calendar = eventStore.defaultCalendarForNewEvents

                // Add location if kid info is available
                if let kid = card.kid {
                    event.location = "\(kid.name)'s \(kid.grade)"
                }

                // Save the event
                try eventStore.save(event, span: .thisEvent)

                await MainActor.run {
                    // Save event details for success message
                    savedEventTitle = event.title
                    savedEventDate = event.startDate
                    showSuccess = true
                    Logger.info("Event added to calendar: \(event.title ?? "Untitled")", category: .action)

                    let impact = UINotificationFeedbackGenerator()
                    impact.notificationOccurred(.success)

                    DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                        isPresented = false
                    }
                }
            } catch {
                await MainActor.run {
                    errorMessage = "Failed to add event: \(error.localizedDescription)"
                    showError = true
                    Logger.error("Calendar error: \(error.localizedDescription)", category: .action)
                }
            }
        }
    }

    /// Format event date for display
    func formatEventDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }

    /// Smart date detection from email card metadata
    func detectEventDate(from card: EmailCard) -> Date {
        let text = "\(card.title) \(card.summary)".lowercased()

        // Pattern 1: Specific dates (e.g., "January 15", "March 3rd", "Dec 25")
        let dateFormatter = DateFormatter()
        dateFormatter.locale = Locale(identifier: "en_US")

        // Month name patterns
        let monthNames = ["january", "february", "march", "april", "may", "june",
                          "july", "august", "september", "october", "november", "december"]

        for (index, month) in monthNames.enumerated() {
            // Check for full month name with day
            if let range = text.range(of: "\\b\(month)\\s+(\\d{1,2})(st|nd|rd|th)?\\b",
                                      options: .regularExpression) {
                let dayString = text[range].replacingOccurrences(of: "[a-z]", with: "", options: .regularExpression)
                    .trimmingCharacters(in: .whitespaces)
                    .components(separatedBy: .whitespaces)
                    .last ?? ""

                if let day = Int(dayString) {
                    var components = Calendar.current.dateComponents([.year], from: Date())
                    components.month = index + 1
                    components.day = day
                    components.hour = 9 // Default to 9 AM
                    components.minute = 0

                    if let detectedDate = Calendar.current.date(from: components) {
                        // If date is in the past, assume next year
                        if detectedDate < Date() {
                            components.year = (components.year ?? 0) + 1
                            if let futureDate = Calendar.current.date(from: components) {
                                return futureDate
                            }
                        }
                        return detectedDate
                    }
                }
            }

            // Check for abbreviated month (Jan, Feb, etc.)
            let abbreviated = String(month.prefix(3))
            if let range = text.range(of: "\\b\(abbreviated)\\.?\\s+(\\d{1,2})(st|nd|rd|th)?\\b",
                                      options: .regularExpression) {
                let dayString = text[range].replacingOccurrences(of: "[a-z\\.]", with: "", options: .regularExpression)
                    .trimmingCharacters(in: .whitespaces)
                    .components(separatedBy: .whitespaces)
                    .last ?? ""

                if let day = Int(dayString) {
                    var components = Calendar.current.dateComponents([.year], from: Date())
                    components.month = index + 1
                    components.day = day
                    components.hour = 9
                    components.minute = 0

                    if let detectedDate = Calendar.current.date(from: components) {
                        if detectedDate < Date() {
                            components.year = (components.year ?? 0) + 1
                            if let futureDate = Calendar.current.date(from: components) {
                                return futureDate
                            }
                        }
                        return detectedDate
                    }
                }
            }
        }

        // Pattern 2: Relative dates (e.g., "tomorrow", "next week", "in 3 days")
        if text.contains("tomorrow") {
            return Calendar.current.date(byAdding: .day, value: 1, to: Date()) ?? Date()
        }

        if text.contains("next week") {
            return Calendar.current.date(byAdding: .weekOfYear, value: 1, to: Date()) ?? Date()
        }

        if let range = text.range(of: "in (\\d+) days?", options: .regularExpression) {
            let daysString = text[range].replacingOccurrences(of: "[^0-9]", with: "", options: .regularExpression)
            if let days = Int(daysString) {
                return Calendar.current.date(byAdding: .day, value: days, to: Date()) ?? Date()
            }
        }

        // Pattern 3: Day of week (e.g., "Monday", "next Friday")
        let weekdays = ["sunday", "monday", "tuesday", "wednesday", "thursday", "friday", "saturday"]
        for (index, weekday) in weekdays.enumerated() {
            if text.contains(weekday) {
                let today = Calendar.current.component(.weekday, from: Date())
                let targetWeekday = index + 1 // Calendar weekdays are 1-indexed

                var daysToAdd = targetWeekday - today
                if daysToAdd <= 0 || text.contains("next \(weekday)") {
                    daysToAdd += 7 // Next occurrence
                }

                if let eventDate = Calendar.current.date(byAdding: .day, value: daysToAdd, to: Date()) {
                    var components = Calendar.current.dateComponents([.year, .month, .day], from: eventDate)
                    components.hour = 9
                    components.minute = 0
                    return Calendar.current.date(from: components) ?? eventDate
                }
            }
        }

        // Default: If no date detected, assume next week at 9 AM
        if let nextWeek = Calendar.current.date(byAdding: .weekOfYear, value: 1, to: Date()) {
            var components = Calendar.current.dateComponents([.year, .month, .day], from: nextWeek)
            components.hour = 9
            components.minute = 0
            return Calendar.current.date(from: components) ?? nextWeek
        }

        return Date()
    }
}

struct SupplyRow: View {
    let supply: (id: String, name: String, price: Double, image: String)
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                // Image
                AsyncImage(url: URL(string: supply.image)) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 60, height: 60)
                        .clipped()
                        .cornerRadius(DesignTokens.Radius.chip)
                } placeholder: {
                    Rectangle()
                        .fill(Color.gray.opacity(0.3))
                        .frame(width: 60, height: 60)
                        .cornerRadius(DesignTokens.Radius.chip)
                }
                
                // Info
                VStack(alignment: .leading, spacing: 4) {
                    Text(supply.name)
                        .font(.subheadline.bold())
                        .foregroundColor(DesignTokens.Colors.textPrimary)
                        .lineLimit(2)
                    
                    Text("$\(String(format: "%.2f", supply.price))")
                        .font(.subheadline)
                        .foregroundColor(.green)
                }
                
                Spacer()
                
                // Checkbox
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.title2)
                    .foregroundColor(isSelected ? .blue : .white.opacity(0.5))
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: DesignTokens.Radius.button)
                    .fill(isSelected ? Color.blue.opacity(0.2) : Color.white.opacity(0.05))
            )
            .overlay(
                RoundedRectangle(cornerRadius: DesignTokens.Radius.button)
                    .strokeBorder(isSelected ? Color.blue : Color.white.opacity(0.1), lineWidth: 2)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

