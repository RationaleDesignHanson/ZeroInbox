import Foundation
import SwiftUI

/**
 * Clever Placeholders - Context-Aware Silly Content
 *
 * Generates entertaining, contextually relevant placeholder content when real data is missing.
 * Content is silly but clearly related to the email and action being performed.
 *
 * Examples:
 * - Package tracking for a pizza order → "Your pepperoni is arriving via Delivery Dragon"
 * - Invoice payment for Amazon → "Pay Jeff Bezos his daily allowance"
 * - Flight check-in → "Boarding Group: 'Window Seat Lottery Winners'"
 */

struct CleverPlaceholders {

    // MARK: - Context-Aware Content Generation

    /// Generate clever placeholder content based on email context
    static func generateContent(for action: EmailAction, card: EmailCard) -> PlaceholderContent {
        let actionId = action.actionId
        let emailSubject = card.title.lowercased()
        let emailBody = (card.body ?? card.summary).lowercased()
        let sender = card.sender?.name ?? card.company?.name ?? "Unknown Sender"

        // Extract keywords to make content contextually relevant
        let keywords = extractKeywords(from: emailSubject + " " + emailBody)

        switch actionId {
        case "track_package":
            return generateTrackingContent(keywords: keywords, sender: sender, card: card)
        case "pay_invoice":
            return generatePaymentContent(keywords: keywords, sender: sender, card: card)
        case "check_in_flight":
            return generateFlightContent(keywords: keywords, sender: sender, card: card)
        case "write_review":
            return generateReviewContent(keywords: keywords, sender: sender, card: card)
        case "view_order":
            return generateOrderContent(keywords: keywords, sender: sender, card: card)
        case "buy_again":
            return generateReorderContent(keywords: keywords, sender: sender, card: card)
        case "sign_form":
            return generateFormContent(keywords: keywords, sender: sender, card: card)
        case "rsvp_yes", "rsvp_no":
            return generateRSVPContent(keywords: keywords, sender: sender, card: card)
        case "schedule_purchase":
            return generateScheduledPurchaseContent(keywords: keywords, sender: sender, card: card)
        case "manage_subscription":
            return generateSubscriptionContent(keywords: keywords, sender: sender, card: card)
        case "view_reservation":
            return generateReservationContent(keywords: keywords, sender: sender, card: card)
        case "contact_driver":
            return generateDriverContent(keywords: keywords, sender: sender, card: card)
        case "check_in_appointment":
            return generateAppointmentContent(keywords: keywords, sender: sender, card: card)
        case "view_assignment":
            return generateAssignmentContent(keywords: keywords, sender: sender, card: card)
        case "download_receipt":
            return generateReceiptContent(keywords: keywords, sender: sender, card: card)
        case "join_meeting":
            return generateMeetingContent(keywords: keywords, sender: sender, card: card)
        default:
            return generateGenericContent(actionId: actionId, keywords: keywords, sender: sender)
        }
    }

    // MARK: - Specific Content Generators

    private static func generateTrackingContent(keywords: [String], sender: String, card: EmailCard) -> PlaceholderContent {
        let item = detectItem(from: keywords)
        let carrier = detectCarrier(from: sender)

        let trackingNumber: String
        let status: String
        let eta: String
        let funFact: String

        // Generate contextual silly content
        if keywords.contains("amazon") || sender.lowercased().contains("amazon") {
            trackingNumber = "1Z-BEZOS-\(Int.random(in: 1000...9999))"
            status = "Your \(item) is currently doing jumping jacks in the warehouse"
            eta = "Arrives before you can say 'two-day shipping'"
            funFact = "📦 This package has traveled more miles than most influencers"
        } else if keywords.contains("food") || keywords.contains("pizza") || keywords.contains("restaurant") {
            trackingNumber = "HUNGRY-\(Int.random(in: 100...999))"
            status = "Your \(item) is being personally escorted by a very hungry driver"
            eta = "Before your stomach starts sending angry emails"
            funFact = "🍕 Driver is currently resisting temptation level: MAXIMUM"
        } else {
            trackingNumber = "TRACK-ME-\(Int.random(in: 10000...99999))"
            status = "Your \(item) is having an adventure across the country"
            eta = "Soon™ (we're being intentionally vague)"
            funFact = "📍 Currently playing hide-and-seek at the distribution center"
        }

        return PlaceholderContent(
            title: "Tracking Your \(item.capitalized)",
            subtitle: "Via \(carrier)",
            mainText: """
            **Tracking #:** \(trackingNumber)

            **Status:** \(status)

            **Estimated Arrival:** \(eta)

            \(funFact)
            """,
            emoji: "📦",
            imageName: "shippingbox.fill",
            context: [
                "trackingNumber": trackingNumber,
                "carrier": carrier,
                "estimatedDelivery": eta
            ]
        )
    }

    private static func generatePaymentContent(keywords: [String], sender: String, card: EmailCard) -> PlaceholderContent {
        let amount = detectAmount(from: card.body ?? card.summary) ?? "$\(Int.random(in: 10...999)).99"
        let invoiceId = "INV-\(Int.random(in: 1000...9999))"

        let paymentFor: String
        let description: String

        if sender.lowercased().contains("amazon") {
            paymentFor = "Jeff's Daily Coffee Money"
            description = "This payment helps fuel the rocket ship collection ☕️🚀"
        } else if keywords.contains("subscription") || keywords.contains("monthly") {
            paymentFor = "Monthly Subscription to \(sender)"
            description = "Another month of pretending you'll cancel this 🙃"
        } else if keywords.contains("utility") || keywords.contains("electric") || keywords.contains("water") {
            paymentFor = "Keeping the Lights On"
            description = "Because darkness is so last century 💡"
        } else {
            paymentFor = "Mysterious Invoice from \(sender)"
            description = "We're sure you ordered *something* 🤷"
        }

        return PlaceholderContent(
            title: "Pay \(amount)",
            subtitle: "Invoice \(invoiceId)",
            mainText: """
            **Amount Due:** \(amount)
            **Payment For:** \(paymentFor)

            \(description)

            **Due Date:** Whenever you get around to it
            **Late Fee:** Passive aggressive emails
            """,
            emoji: "💳",
            imageName: "creditcard.fill",
            context: [
                "amount": amount,
                "invoiceId": invoiceId,
                "merchant": sender
            ]
        )
    }

    private static func generateFlightContent(keywords: [String], sender: String, card: EmailCard) -> PlaceholderContent {
        let airline = sender
        let flightNumber = detectFlightNumber(from: card.title) ?? "\(airline.prefix(2).uppercased()) \(Int.random(in: 100...999))"
        let destination = detectDestination(from: keywords) ?? "Paradise"

        return PlaceholderContent(
            title: "Check In for Flight \(flightNumber)",
            subtitle: "Destination: \(destination)",
            mainText: """
            **Boarding Group:** Window Seat Lottery Winners 🎰

            **Gate Assignment:** Will tell you at the last minute

            **Seat:** Middle seat (kidding... maybe) 😬

            **Baggage Allowance:** One emotional support item

            **In-Flight Snacks:** Pretzels that could double as weapons

            ✈️ **Pro Tip:** Get to the airport 47 hours early for maximum anxiety
            """,
            emoji: "✈️",
            imageName: "airplane.departure",
            context: [
                "flightNumber": flightNumber,
                "airline": airline,
                "destination": destination
            ]
        )
    }

    private static func generateReviewContent(keywords: [String], sender: String, card: EmailCard) -> PlaceholderContent {
        let product = detectProduct(from: card.title) ?? "That Thing You Ordered"

        let reviewPrompt: String
        if keywords.contains("headphones") || keywords.contains("audio") {
            reviewPrompt = "Did they make you feel like a DJ? Even in the grocery store? ⭐️"
        } else if keywords.contains("book") {
            reviewPrompt = "Did it gather dust on your nightstand elegantly? 📚"
        } else if keywords.contains("shoes") || keywords.contains("clothing") {
            reviewPrompt = "Did you feel like a fashion icon? Even taking out trash? 👟"
        } else {
            reviewPrompt = "Did it spark joy? Or at least mild contentment? ✨"
        }

        return PlaceholderContent(
            title: "Review: \(product)",
            subtitle: "Your opinion matters (to the algorithm)",
            mainText: """
            **Product:** \(product)

            **Question:** \(reviewPrompt)

            **Suggested Review:**
            "It exists. It does the thing. I am moderately pleased.
            Would recommend to people who need this type of thing.
            ⭐️⭐️⭐️⭐️⭐️"

            🎭 **Remember:** Your review will be read by exactly 2.3 people
            """,
            emoji: "⭐️",
            imageName: "star.fill",
            context: [
                "productName": product
            ]
        )
    }

    private static func generateOrderContent(keywords: [String], sender: String, card: EmailCard) -> PlaceholderContent {
        let orderNumber = detectOrderNumber(from: card.body ?? card.summary) ?? "#\(Int.random(in: 100000...999999))"
        let item = detectItem(from: keywords)

        return PlaceholderContent(
            title: "Order \(orderNumber)",
            subtitle: "The moment of truth",
            mainText: """
            **Items:** \(item.capitalized) (and probably more you forgot about)

            **Order Status:** Definitely happened

            **Shipped Via:** A series of mysterious warehouses

            **Expected to Arrive:** When you've given up hope

            📦 **Fun Fact:** This order has seen more of the country than you have
            """,
            emoji: "📦",
            imageName: "cube.box.fill",
            context: [
                "orderNumber": orderNumber
            ]
        )
    }

    private static func generateReorderContent(keywords: [String], sender: String, card: EmailCard) -> PlaceholderContent {
        let item = detectItem(from: keywords)

        return PlaceholderContent(
            title: "Buy \(item.capitalized) Again",
            subtitle: "Because once wasn't enough",
            mainText: """
            **Previously Purchased:** \(item.capitalized)

            **Reasons to buy again:**
            • It made you happy (briefly)
            • You lost the first one
            • You need backup backups
            • Dopamine hits are legal

            🛒 **Amazon's Motto:** "You can't take it with you, but you can buy it again"
            """,
            emoji: "🔁",
            imageName: "arrow.clockwise.circle.fill",
            context: [
                "productName": item
            ]
        )
    }

    private static func generateFormContent(keywords: [String], sender: String, card: EmailCard) -> PlaceholderContent {
        let formType = detectFormType(from: keywords, card: card)

        let description: String
        if keywords.contains("field trip") || keywords.contains("trip") {
            description = "Sign here to confirm your child will bring home a rock collection 🪨"
        } else if keywords.contains("medical") {
            description = "Sign here to acknowledge you've read terms you didn't read 📋"
        } else if keywords.contains("school") || keywords.contains("teacher") {
            description = "Sign here to officially become a homework supervisor 📝"
        } else {
            description = "Sign here because bureaucracy demands it 🖊"
        }

        return PlaceholderContent(
            title: "Sign \(formType)",
            subtitle: "The ancient art of digital scribbling",
            mainText: """
            **Form Type:** \(formType)
            **From:** \(sender)

            \(description)

            **Instructions:**
            1. Draw something that vaguely resembles your name
            2. Feel like a digital artist
            3. Submit

            ✍️ **Pro Tip:** Nobody checks if it actually looks like a signature
            """,
            emoji: "✍️",
            imageName: "signature",
            context: [
                "formType": formType
            ]
        )
    }

    private static func generateRSVPContent(keywords: [String], sender: String, card: EmailCard) -> PlaceholderContent {
        let event = detectEvent(from: keywords, card: card)
        let date = detectDate(from: card.body ?? card.summary) ?? "Soon™"

        let going = keywords.contains("yes") || !keywords.contains("no")

        return PlaceholderContent(
            title: going ? "You're Going! 🎉" : "Can't Make It 😔",
            subtitle: event,
            mainText: """
            **Event:** \(event)
            **Date:** \(date)
            **Your Status:** \(going ? "Committed (no backing out now)" : "Saved by a convenient excuse")

            \(going ? "**What to Bring:** Your sparkling personality ✨" : "**Excuse Quality:** Plausible enough")

            \(going ? "**Reminder:** Fashionably late is still late" : "**FOMO Level:** Manageable")
            """,
            emoji: going ? "🎉" : "🏠",
            imageName: going ? "party.popper.fill" : "house.fill",
            context: [
                "eventTitle": event,
                "eventDate": date,
                "response": going ? "yes" : "no"
            ]
        )
    }

    private static func generateScheduledPurchaseContent(keywords: [String], sender: String, card: EmailCard) -> PlaceholderContent {
        let product = detectProduct(from: card.title) ?? "Limited Edition Thing"
        let saleDate = detectDate(from: card.body ?? card.summary) ?? "Drop Day"

        return PlaceholderContent(
            title: "Schedule Purchase",
            subtitle: "\(product) drops on \(saleDate)",
            mainText: """
            **Product:** \(product)
            **Drop Date:** \(saleDate)

            **Your Game Plan:**
            • Set 17 alarms ⏰
            • Clear your calendar
            • Stretch your clicking finger
            • Have backup payment methods ready

            🎯 **Success Rate:** Optimistic

            💨 **Competition Level:** Everyone and their bot
            """,
            emoji: "⏰",
            imageName: "alarm.fill",
            context: [
                "productName": product,
                "saleDate": saleDate
            ]
        )
    }

    private static func generateSubscriptionContent(keywords: [String], sender: String, card: EmailCard) -> PlaceholderContent {
        let service = sender
        let amount = detectAmount(from: card.body ?? card.summary) ?? "$9.99"

        return PlaceholderContent(
            title: "Manage \(service) Subscription",
            subtitle: "The monthly relationship you forgot about",
            mainText: """
            **Service:** \(service)
            **Monthly Cost:** \(amount)
            **Been Paying For:** Longer than you remember

            **Usage Stats:**
            • Last used: That one time in 2023
            • Times you've thought about canceling: 47
            • Times you've actually canceled: 0

            💸 **Financial Wisdom:** "It's only \(amount)!" - You, every month
            """,
            emoji: "💳",
            imageName: "creditcard.and.123",
            context: [
                "service": service,
                "amount": amount
            ]
        )
    }

    private static func generateReservationContent(keywords: [String], sender: String, card: EmailCard) -> PlaceholderContent {
        let venue = detectVenue(from: card.title, sender: sender)
        let date = detectDate(from: card.body ?? card.summary) ?? "Coming Up"

        let venueType: String
        if keywords.contains("hotel") || keywords.contains("resort") {
            venueType = "Your Temporary Palace"
        } else if keywords.contains("restaurant") || keywords.contains("dinner") {
            venueType = "Fancy Eating Establishment"
        } else {
            venueType = "Reservation"
        }

        return PlaceholderContent(
            title: "\(venueType) at \(venue)",
            subtitle: "Confirmed for \(date)",
            mainText: """
            **Venue:** \(venue)
            **Date:** \(date)
            **Confirmation Code:** DONT-LOSE-THIS-\(Int.random(in: 100...999))

            **Things to Remember:**
            • Show up (most important)
            • Bring credit card
            • Wear pants
            • Charge your phone for photos

            🎩 **Dress Code:** At least one step above pajamas
            """,
            emoji: keywords.contains("hotel") ? "🏨" : "🍽",
            imageName: keywords.contains("hotel") ? "building.2.fill" : "fork.knife",
            context: [
                "venue": venue,
                "date": date
            ]
        )
    }

    private static func generateDriverContent(keywords: [String], sender: String, card: EmailCard) -> PlaceholderContent {
        let driverName = "Driver McDriverface"
        let eta = "\(Int.random(in: 3...15)) minutes"

        let service: String
        if keywords.contains("uber") || keywords.contains("lyft") {
            service = "rideshare"
        } else if keywords.contains("food") || keywords.contains("delivery") {
            service = "food delivery"
        } else {
            service = "delivery"
        }

        return PlaceholderContent(
            title: "Your \(service.capitalized) Driver",
            subtitle: "\(driverName) is on the way",
            mainText: """
            **Driver:** \(driverName)
            **ETA:** \(eta) (subject to traffic, weather, and existential crises)
            **Vehicle:** The one you'll definitely spot immediately
            **Rating:** ⭐️⭐️⭐️⭐️⭐️ "Great at GPS"

            **Current Status:**
            Making every turn except the one to your location

            📱 **Pro Tip:** Wave frantically at every car that passes
            """,
            emoji: "🚗",
            imageName: "car.fill",
            context: [
                "driverName": driverName,
                "eta": eta
            ]
        )
    }

    private static func generateAppointmentContent(keywords: [String], sender: String, card: EmailCard) -> PlaceholderContent {
        let provider = detectProvider(from: sender, keywords: keywords)
        let appointmentDate = detectDate(from: card.body ?? card.summary) ?? "Soon"

        return PlaceholderContent(
            title: "Check In for Appointment",
            subtitle: "With \(provider)",
            mainText: """
            **Provider:** \(provider)
            **Appointment:** \(appointmentDate)

            **Pre-Check-In Checklist:**
            ✓ Find insurance card
            ✓ Remember why you scheduled this
            ✓ Prepare for waiting room purgatory
            ✓ Download entire Netflix library

            ⏰ **Arrival Time:** 15 minutes early (to wait 45 minutes)
            """,
            emoji: "🏥",
            imageName: "cross.case.fill",
            context: [
                "provider": provider,
                "appointmentDate": appointmentDate
            ]
        )
    }

    private static func generateAssignmentContent(keywords: [String], sender: String, card: EmailCard) -> PlaceholderContent {
        let subject = detectSubject(from: keywords)
        let dueDate = detectDate(from: card.body ?? card.summary) ?? "Before Your Kid Panics"

        return PlaceholderContent(
            title: "\(subject) Assignment",
            subtitle: "Due: \(dueDate)",
            mainText: """
            **Subject:** \(subject)
            **Due Date:** \(dueDate)
            **Difficulty:** Requires Google + Prayer

            **Parent Helper Mode Activated:**
            • Step 1: Pretend you remember this from school
            • Step 2: Secretly Google everything
            • Step 3: Act like you knew it all along

            🎓 **Truth:** You're learning this for the first time too
            """,
            emoji: "📚",
            imageName: "book.fill",
            context: [
                "subject": subject,
                "dueDate": dueDate
            ]
        )
    }

    private static func generateReceiptContent(keywords: [String], sender: String, card: EmailCard) -> PlaceholderContent {
        let amount = detectAmount(from: card.body ?? card.summary) ?? "$\(Int.random(in: 10...500)).00"
        let merchant = sender

        return PlaceholderContent(
            title: "Receipt for \(amount)",
            subtitle: "From \(merchant)",
            mainText: """
            **Amount:** \(amount)
            **Merchant:** \(merchant)
            **Purpose:** Future tax write-off? (probably not)

            **Receipt Contents:**
            • Things you bought
            • Tax breakdown you won't read
            • Fine print you'll ignore
            • Barcode for your troubles

            📄 **Likelihood of Actually Saving This:** 12%
            """,
            emoji: "🧾",
            imageName: "doc.text.fill",
            context: [
                "amount": amount,
                "merchant": merchant
            ]
        )
    }

    private static func generateMeetingContent(keywords: [String], sender: String, card: EmailCard) -> PlaceholderContent {
        let meetingTitle = detectMeetingTitle(from: card.title) ?? "Important Virtual Gathering"
        let time = detectDate(from: card.body ?? card.summary) ?? "Coming Up"

        return PlaceholderContent(
            title: meetingTitle,
            subtitle: "Scheduled for \(time)",
            mainText: """
            **Meeting:** \(meetingTitle)
            **Time:** \(time)
            **Duration:** "Just 15 minutes" (narrator: it wasn't)

            **Pre-Meeting Checklist:**
            ✓ Test camera (looks good)
            ✓ Test mic (sounds clear)
            ✓ Wear nice shirt, keep pajama pants
            ✓ Prepare to say "Can you hear me?" 3 times

            🎥 **Pro Tip:** Have a cat nearby for emergency interruptions
            """,
            emoji: "💻",
            imageName: "video.fill",
            context: [
                "meetingTitle": meetingTitle,
                "meetingTime": time
            ]
        )
    }

    private static func generateGenericContent(actionId: String, keywords: [String], sender: String) -> PlaceholderContent {
        let actionName = actionId.replacingOccurrences(of: "_", with: " ").capitalized

        return PlaceholderContent(
            title: actionName,
            subtitle: "From \(sender)",
            mainText: """
            **Action:** \(actionName)
            **Context:** Mysteriously absent

            **What we know:**
            • You clicked something
            • It involves \(sender)
            • We're all learning together

            🎭 **Plot Twist:** This is a placeholder. The real content is on vacation.
            """,
            emoji: "🤷",
            imageName: "questionmark.circle.fill",
            context: [:]
        )
    }

    // MARK: - Keyword Detection Helpers

    private static func extractKeywords(from text: String) -> [String] {
        let lowercased = text.lowercased()
        let words = lowercased.components(separatedBy: CharacterSet.alphanumerics.inverted)
        return words.filter { $0.count > 2 } // Filter out short words
    }

    private static func detectItem(from keywords: [String]) -> String {
        // Check for specific items
        if keywords.contains("headphones") { return "headphones" }
        if keywords.contains("book") { return "book" }
        if keywords.contains("shoes") { return "shoes" }
        if keywords.contains("laptop") { return "laptop" }
        if keywords.contains("phone") { return "phone" }
        if keywords.contains("coffee") { return "coffee beans" }
        if keywords.contains("pizza") { return "pizza" }
        if keywords.contains("furniture") { return "furniture" }
        if keywords.contains("clothes") || keywords.contains("clothing") { return "clothing" }
        return "mysterious package"
    }

    private static func detectCarrier(from sender: String) -> String {
        let lower = sender.lowercased()
        if lower.contains("ups") { return "UPS (United Parcels of Suspense)" }
        if lower.contains("fedex") { return "FedEx (Fast & Eventually Delivered)" }
        if lower.contains("usps") { return "USPS (Usually Sometimes Possibly Shipped)" }
        if lower.contains("amazon") { return "Amazon Logistics (Jeff's Personal Army)" }
        if lower.contains("dhl") { return "DHL (Delivery Happens... Later)" }
        return "Mystery Shipping Co."
    }

    private static func detectProduct(from title: String) -> String? {
        // Extract product name from title if possible
        let patterns = [
            "review: (.*)",
            "rate (.*)",
            "feedback.*: (.*)",
            "how.*like (.*)"
        ]

        for pattern in patterns {
            if let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive),
               let match = regex.firstMatch(in: title, range: NSRange(title.startIndex..., in: title)),
               match.numberOfRanges > 1,
               let range = Range(match.range(at: 1), in: title) {
                return String(title[range]).trimmingCharacters(in: .whitespaces)
            }
        }
        return nil
    }

    private static func detectAmount(from text: String) -> String? {
        let pattern = #"\$\d+\.?\d*"#
        if let regex = try? NSRegularExpression(pattern: pattern),
           let match = regex.firstMatch(in: text, range: NSRange(text.startIndex..., in: text)),
           let range = Range(match.range, in: text) {
            return String(text[range])
        }
        return nil
    }

    private static func detectFlightNumber(from text: String) -> String? {
        let pattern = #"[A-Z]{2}\s?\d{3,4}"#
        if let regex = try? NSRegularExpression(pattern: pattern),
           let match = regex.firstMatch(in: text, range: NSRange(text.startIndex..., in: text)),
           let range = Range(match.range, in: text) {
            return String(text[range])
        }
        return nil
    }

    private static func detectDestination(from keywords: [String]) -> String? {
        // Check for city names
        let cities = ["san francisco", "new york", "chicago", "los angeles", "seattle",
                      "boston", "miami", "denver", "austin", "portland"]
        for city in cities {
            if keywords.contains(where: { $0.contains(city) }) {
                return city.capitalized
            }
        }
        return nil
    }

    private static func detectOrderNumber(from text: String) -> String? {
        let patterns = [
            #"order\s*#?\s*:?\s*([A-Z0-9-]{6,})"#,
            #"#([0-9]{6,})"#
        ]

        for pattern in patterns {
            if let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive),
               let match = regex.firstMatch(in: text, range: NSRange(text.startIndex..., in: text)),
               match.numberOfRanges > 1,
               let range = Range(match.range(at: 1), in: text) {
                return String(text[range])
            }
        }
        return nil
    }

    private static func detectFormType(from keywords: [String], card: EmailCard) -> String {
        if keywords.contains("permission") || keywords.contains("field") || keywords.contains("trip") {
            return "Field Trip Permission Form"
        }
        if keywords.contains("medical") || keywords.contains("health") {
            return "Medical Consent Form"
        }
        if keywords.contains("yearbook") {
            return "Yearbook Order Form"
        }
        return "Important School Form"
    }

    private static func detectEvent(from keywords: [String], card: EmailCard) -> String {
        if keywords.contains("dinner") { return "Fancy Dinner Thing" }
        if keywords.contains("party") { return "Social Gathering" }
        if keywords.contains("meeting") { return "Team Meeting" }
        if keywords.contains("wedding") { return "Wedding Celebration" }
        if keywords.contains("birthday") { return "Birthday Party" }
        return "Event You Were Invited To"
    }

    private static func detectDate(from text: String) -> String? {
        // Look for date patterns
        let patterns = [
            #"(Monday|Tuesday|Wednesday|Thursday|Friday|Saturday|Sunday)"#,
            #"(January|February|March|April|May|June|July|August|September|October|November|December)\s+\d{1,2}"#,
            #"\d{1,2}/\d{1,2}/\d{2,4}"#,
            #"tomorrow"#,
            #"next\s+\w+"#
        ]

        for pattern in patterns {
            if let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive),
               let match = regex.firstMatch(in: text, range: NSRange(text.startIndex..., in: text)),
               let range = Range(match.range, in: text) {
                return String(text[range])
            }
        }
        return nil
    }

    private static func detectVenue(from title: String, sender: String) -> String {
        // Try to extract venue from title, otherwise use sender
        if title.contains("at") {
            if let atIndex = title.firstIndex(of: "a"),
               let nextIndex = title.index(atIndex, offsetBy: 2, limitedBy: title.endIndex) {
                let afterAt = String(title[nextIndex...])
                return afterAt.components(separatedBy: CharacterSet.punctuationCharacters).first?.trimmingCharacters(in: .whitespaces) ?? sender
            }
        }
        return sender
    }

    private static func detectProvider(from sender: String, keywords: [String]) -> String {
        if keywords.contains("doctor") || keywords.contains("dr") { return "Dr. McHealthcare" }
        if keywords.contains("dentist") { return "Dr. Toothington" }
        if keywords.contains("kaiser") { return "Kaiser Permanente" }
        return sender
    }

    private static func detectSubject(from keywords: [String]) -> String {
        if keywords.contains("math") { return "Math" }
        if keywords.contains("science") { return "Science" }
        if keywords.contains("english") || keywords.contains("essay") { return "English" }
        if keywords.contains("history") { return "History" }
        if keywords.contains("homework") { return "Homework" }
        return "School Stuff"
    }

    private static func detectMeetingTitle(from title: String) -> String? {
        // Try to extract meeting name from email title
        if title.lowercased().contains("meeting:") {
            return title.components(separatedBy: ":").last?.trimmingCharacters(in: .whitespaces)
        }
        if title.lowercased().contains("invitation:") {
            return title.components(separatedBy: ":").last?.trimmingCharacters(in: .whitespaces)
        }
        return nil
    }
}

// MARK: - Placeholder Content Model

struct PlaceholderContent {
    let title: String
    let subtitle: String
    let mainText: String
    let emoji: String
    let imageName: String // SF Symbol name
    let context: [String: String]

    /// Get formatted text for display
    var formattedText: String {
        return """
        \(emoji) \(title)

        \(mainText)
        """
    }

    /// Get image from SF Symbols
    var sfSymbol: Image {
        Image(systemName: imageName)
    }
}
