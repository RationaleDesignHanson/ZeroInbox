import SwiftUI

struct ActivityItineraryItem: Identifiable {
    let id = UUID()
    let time: String
    let title: String
    let description: String?
}

struct WhatToBring: Identifiable {
    let id = UUID()
    let item: String
    let isEssential: Bool
    var isPacked: Bool = false
}

struct ViewActivityDetailsModal: View {
    let card: EmailCard
    @Binding var isPresented: Bool

    @State private var activityTitle = ""
    @State private var activityDate: Date?
    @State private var activityLocation = ""
    @State private var itinerary: [ActivityItineraryItem] = []
    @State private var whatToBring: [WhatToBring] = []
    @State private var additionalNotes = ""
    @State private var showCalendarSuccess = false

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
                            Image(systemName: "doc.text.fill")
                                .font(.largeTitle)
                                .foregroundColor(.blue)

                            VStack(alignment: .leading, spacing: 4) {
                                Text(activityTitle)
                                    .font(.title2.bold())
                                    .foregroundColor(DesignTokens.Colors.textPrimary)

                                if let date = activityDate {
                                    Text(date, style: .date)
                                        .font(.subheadline)
                                        .foregroundColor(DesignTokens.Colors.textSubtle)
                                }
                            }
                        }
                    }

                    Divider()
                        .background(Color.white.opacity(0.3))

                    // Location
                    if !activityLocation.isEmpty {
                        HStack(spacing: 12) {
                            Image(systemName: "location.fill")
                                .foregroundColor(.red)
                                .font(.title3)
                            Text(activityLocation)
                                .font(.subheadline)
                                .foregroundColor(DesignTokens.Colors.textPrimary)
                        }
                        .padding()
                        .background(Color.white.opacity(0.08))
                        .cornerRadius(DesignTokens.Radius.button)
                    }

                    // Itinerary Section
                    if !itinerary.isEmpty {
                        VStack(alignment: .leading, spacing: 16) {
                            Text("📅 Itinerary")
                                .font(.headline)
                                .foregroundColor(DesignTokens.Colors.textPrimary)

                            VStack(spacing: 0) {
                                ForEach(Array(itinerary.enumerated()), id: \.element.id) { index, item in
                                    ItineraryRow(
                                        item: item,
                                        isFirst: index == 0,
                                        isLast: index == itinerary.count - 1
                                    )
                                }
                            }
                        }
                        .padding()
                        .background(Color.blue.opacity(0.1))
                        .cornerRadius(DesignTokens.Radius.card)
                        .overlay(
                            RoundedRectangle(cornerRadius: DesignTokens.Radius.card)
                                .strokeBorder(Color.blue.opacity(0.4), lineWidth: 1)
                        )
                    }

                    // What to Bring Section
                    if !whatToBring.isEmpty {
                        VStack(alignment: .leading, spacing: 16) {
                            HStack {
                                Text("🎒 What to Bring")
                                    .font(.headline)
                                    .foregroundColor(DesignTokens.Colors.textPrimary)

                                Spacer()

                                let packedCount = whatToBring.filter { $0.isPacked }.count
                                Text("\(packedCount)/\(whatToBring.count)")
                                    .font(.subheadline.bold())
                                    .foregroundColor(.green)
                            }

                            VStack(spacing: 12) {
                                ForEach($whatToBring) { $item in
                                    WhatToBringRow(item: $item)
                                }
                            }
                        }
                        .padding()
                        .background(Color.green.opacity(0.1))
                        .cornerRadius(DesignTokens.Radius.card)
                        .overlay(
                            RoundedRectangle(cornerRadius: DesignTokens.Radius.card)
                                .strokeBorder(Color.green.opacity(0.4), lineWidth: 1)
                        )
                    }

                    // Additional Notes
                    if !additionalNotes.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("📝 Additional Notes")
                                .font(.headline)
                                .foregroundColor(DesignTokens.Colors.textPrimary)

                            Text(additionalNotes)
                                .font(.subheadline)
                                .foregroundColor(DesignTokens.Colors.textSecondary)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        .padding()
                        .background(Color.white.opacity(0.05))
                        .cornerRadius(DesignTokens.Radius.button)
                    }

                    // Action Buttons
                    VStack(spacing: 12) {
                        Button {
                            addToCalendar()
                        } label: {
                            HStack {
                                Image(systemName: "calendar.badge.plus")
                                Text("Add to Calendar")
                                    .font(.headline)
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(DesignTokens.Radius.button)
                        }

                        Button {
                            shareItinerary()
                        } label: {
                            HStack {
                                Image(systemName: "square.and.arrow.up")
                                Text("Share Itinerary")
                                    .font(.subheadline)
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.white.opacity(0.1))
                            .foregroundColor(DesignTokens.Colors.textPrimary)
                            .cornerRadius(DesignTokens.Radius.button)
                            .overlay(
                                RoundedRectangle(cornerRadius: DesignTokens.Radius.button)
                                    .strokeBorder(Color.white.opacity(0.3), lineWidth: 1)
                            )
                        }
                    }

                    // Calendar Success
                    if showCalendarSuccess {
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                            Text("Added to calendar!")
                                .foregroundColor(.green)
                                .font(.subheadline.bold())
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.green.opacity(0.2))
                        .cornerRadius(DesignTokens.Radius.button)
                    }

                    // Info message
                    HStack(alignment: .top, spacing: 8) {
                        Image(systemName: "info.circle")
                            .foregroundColor(.blue)
                            .font(.caption)
                        Text("Use this detailed itinerary to plan ahead and ensure you're fully prepared for the activity.")
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
            detectActivityDetails()
        }
    }

    func detectActivityDetails() {
        activityTitle = card.title
        activityDate = Calendar.current.date(byAdding: .day, value: 7, to: Date())
        activityLocation = extractLocation()
        additionalNotes = card.summary

        // Parse itinerary from content
        itinerary = parseItinerary()

        // Generate what to bring list
        whatToBring = generateWhatToBring()
    }

    func extractLocation() -> String {
        let text = card.title + " " + card.summary
        let patterns = ["at (.+?)(?:on|\\.|,|$)", "location:? (.+?)(?:\\.|,|$)"]

        for pattern in patterns {
            if let regex = try? NSRegularExpression(pattern: pattern, options: [.caseInsensitive]),
               let match = regex.firstMatch(in: text, range: NSRange(text.startIndex..., in: text)),
               match.numberOfRanges > 1,
               let range = Range(match.range(at: 1), in: text) {
                return String(text[range]).trimmingCharacters(in: .whitespaces)
            }
        }

        return "Location TBD"
    }

    func parseItinerary() -> [ActivityItineraryItem] {
        // Try to extract time-based items from body
        let text = card.body ?? card.summary
        var items: [ActivityItineraryItem] = []

        // Look for time patterns like "8:00 AM - Depart"
        let timePattern = "(\\d{1,2}:\\d{2}\\s*(?:AM|PM|am|pm)?)\\s*[-–—:]\\s*(.+?)(?:\\n|$)"

        if let regex = try? NSRegularExpression(pattern: timePattern, options: []) {
            let matches = regex.matches(in: text, range: NSRange(text.startIndex..., in: text))

            for match in matches {
                if match.numberOfRanges >= 3,
                   let timeRange = Range(match.range(at: 1), in: text),
                   let titleRange = Range(match.range(at: 2), in: text) {
                    let time = String(text[timeRange])
                    let title = String(text[titleRange]).trimmingCharacters(in: .whitespacesAndNewlines)

                    items.append(ActivityItineraryItem(
                        time: time,
                        title: title,
                        description: nil
                    ))
                }
            }
        }

        // If no itinerary found, create a sample one
        if items.isEmpty {
            items = [
                ActivityItineraryItem(time: "8:00 AM", title: "Meet at starting point", description: nil),
                ActivityItineraryItem(time: "8:30 AM", title: "Begin activity", description: nil),
                ActivityItineraryItem(time: "12:00 PM", title: "Lunch break", description: nil),
                ActivityItineraryItem(time: "3:00 PM", title: "Wrap up and depart", description: nil)
            ]
        }

        return items
    }

    func generateWhatToBring() -> [WhatToBring] {
        let text = (card.title + " " + card.summary + " " + (card.body ?? "")).lowercased()

        var items: [WhatToBring] = []

        // Common activity items
        if text.contains("hike") || text.contains("hiking") || text.contains("trail") {
            items = [
                WhatToBring(item: "Hiking boots", isEssential: true),
                WhatToBring(item: "Water bottle (2L)", isEssential: true),
                WhatToBring(item: "Snacks/energy bars", isEssential: true),
                WhatToBring(item: "Sun hat", isEssential: false),
                WhatToBring(item: "Sunscreen", isEssential: true),
                WhatToBring(item: "First aid kit", isEssential: false)
            ]
        } else if text.contains("camp") || text.contains("camping") {
            items = [
                WhatToBring(item: "Tent & sleeping bag", isEssential: true),
                WhatToBring(item: "Food & water", isEssential: true),
                WhatToBring(item: "Flashlight/headlamp", isEssential: true),
                WhatToBring(item: "Warm clothing", isEssential: true),
                WhatToBring(item: "Matches/lighter", isEssential: false),
                WhatToBring(item: "Camp stove", isEssential: false)
            ]
        } else if text.contains("beach") {
            items = [
                WhatToBring(item: "Sunscreen", isEssential: true),
                WhatToBring(item: "Towel", isEssential: true),
                WhatToBring(item: "Swimsuit", isEssential: true),
                WhatToBring(item: "Water bottle", isEssential: true),
                WhatToBring(item: "Beach umbrella", isEssential: false),
                WhatToBring(item: "Snacks", isEssential: false)
            ]
        } else {
            // Generic activity items
            items = [
                WhatToBring(item: "Water bottle", isEssential: true),
                WhatToBring(item: "Comfortable shoes", isEssential: true),
                WhatToBring(item: "Snacks", isEssential: false),
                WhatToBring(item: "Phone charger", isEssential: false)
            ]
        }

        return items
    }

    func addToCalendar() {
        guard let date = activityDate else { return }

        Logger.info("Adding activity details to calendar", category: .action)

        let itineraryText = itinerary.map { "• \($0.time): \($0.title)" }.joined(separator: "\n")
        let bringText = whatToBring.map { "• \($0.item)\($0.isEssential ? " (Essential)" : "")" }.joined(separator: "\n")

        CalendarService.shared.addEvent(
            title: activityTitle,
            startDate: date,
            endDate: Calendar.current.date(byAdding: .hour, value: 6, to: date) ?? date,
            location: activityLocation,
            notes: """
            Itinerary:
            \(itineraryText)

            What to Bring:
            \(bringText)

            Notes:
            \(additionalNotes)
            """
        ) { result in
            DispatchQueue.main.async {
                switch result {
                case .success:
                    withAnimation(.spring()) {
                        showCalendarSuccess = true
                    }
                    Logger.info("Activity added to calendar", category: .action)

                    // Haptic feedback
                    let impact = UINotificationFeedbackGenerator()
                    impact.notificationOccurred(.success)

                    // Hide success after 3 seconds
                    DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                        withAnimation(.spring()) {
                            showCalendarSuccess = false
                        }
                    }

                case .failure(let error):
                    Logger.error("Failed to add activity: \(error.localizedDescription)", category: .action)
                }
            }
        }
    }

    func shareItinerary() {
        let itineraryText = itinerary.map { "\($0.time): \($0.title)" }.joined(separator: "\n")
        let bringText = whatToBring.map { "☐ \($0.item)\($0.isEssential ? " (Essential)" : "")" }.joined(separator: "\n")

        let fullText = """
        \(activityTitle)
        \(activityDate?.formatted(date: .long, time: .omitted) ?? "")
        Location: \(activityLocation)

        ITINERARY:
        \(itineraryText)

        WHAT TO BRING:
        \(bringText)

        NOTES:
        \(additionalNotes)
        """

        UIPasteboard.general.string = fullText
        Logger.info("Itinerary copied to clipboard", category: .action)

        // Haptic feedback
        let impact = UINotificationFeedbackGenerator()
        impact.notificationOccurred(.success)
    }
}

// MARK: - Itinerary Row

struct ItineraryRow: View {
    let item: ActivityItineraryItem
    let isFirst: Bool
    let isLast: Bool

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            // Timeline indicator
            VStack(spacing: 0) {
                if !isFirst {
                    Rectangle()
                        .fill(Color.blue.opacity(0.3))
                        .frame(width: 2, height: 20)
                }

                Circle()
                    .fill(Color.blue)
                    .frame(width: 12, height: 12)

                if !isLast {
                    Rectangle()
                        .fill(Color.blue.opacity(0.3))
                        .frame(width: 2, height: 40)
                }
            }

            // Content
            VStack(alignment: .leading, spacing: 4) {
                Text(item.time)
                    .font(.caption.bold())
                    .foregroundColor(.blue)

                Text(item.title)
                    .font(.subheadline.bold())
                    .foregroundColor(DesignTokens.Colors.textPrimary)

                if let description = item.description {
                    Text(description)
                        .font(.caption)
                        .foregroundColor(DesignTokens.Colors.textSubtle)
                }
            }
            .padding(.vertical, 8)

            Spacer()
        }
    }
}

// MARK: - What to Bring Row

struct WhatToBringRow: View {
    @Binding var item: WhatToBring

    var body: some View {
        Button {
            withAnimation(.spring(response: 0.3)) {
                item.isPacked.toggle()
            }
        } label: {
            HStack(spacing: 12) {
                Image(systemName: item.isPacked ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(item.isPacked ? .green : .white.opacity(0.5))
                    .font(.title3)

                Text(item.item)
                    .font(.subheadline)
                    .foregroundColor(DesignTokens.Colors.textPrimary)
                    .strikethrough(item.isPacked)

                if item.isEssential {
                    Text("Essential")
                        .font(.caption2.bold())
                        .foregroundColor(.orange)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.orange.opacity(0.2))
                        .cornerRadius(8)
                }

                Spacer()
            }
            .padding()
            .background(Color.white.opacity(item.isPacked ? 0.05 : 0.08))
            .cornerRadius(DesignTokens.Radius.button)
        }
    }
}

// MARK: - Preview

#Preview("View Activity Details Modal") {
    ViewActivityDetailsModal(
        card: EmailCard(
            id: "preview",
            type: .mail,
            state: .seen,
            priority: .medium,
            hpa: "view_activity_details",
            timeAgo: "2h",
            title: "Weekend Camping Trip Itinerary",
            summary: "Here's the complete itinerary for our camping adventure this weekend. Make sure you're prepared!",
            body: """
            Saturday Itinerary:
            8:00 AM - Meet at parking lot
            9:00 AM - Start hike to campsite
            12:00 PM - Arrive at camp, setup tents
            1:00 PM - Lunch
            3:00 PM - Lake swimming
            6:00 PM - Campfire dinner
            9:00 PM - Stargazing

            Sunday Itinerary:
            7:00 AM - Breakfast
            9:00 AM - Morning hike
            12:00 PM - Pack up camp
            2:00 PM - Return to parking lot

            What to Bring:
            • Tent & sleeping bag
            • Food & water (bring extra!)
            • Flashlight/headlamp
            • Warm clothing (nights get cold)
            • Matches for campfire
            • First aid kit
            """,
            metaCTA: "View",
            suggestedActions: [
                EmailAction(
                    actionId: "view_activity_details",
                    displayName: "View Details",
                    actionType: .inApp,
                    isPrimary: true,
                    context: [:]
                )
            ],
            sender: SenderInfo(
                name: "Outdoor Adventures Club",
                initial: "O",
                email: "adventures@outdoorclub.com"
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
