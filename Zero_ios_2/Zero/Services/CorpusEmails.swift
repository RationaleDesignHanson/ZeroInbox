//
// Synthetic Corpus Emails
// Generated from corpus analysis patterns (NO real user data)
//
// These emails are ENTIRELY FICTIONAL, created to match the intent
// distribution found in the corpus analysis. They help provide realistic
// variety in the demo experience.
//

import Foundation

extension DataGenerator {
    /// Generate synthetic emails based on corpus analysis patterns
    /// All content is fictional - no real user data used
    static func generateCorpusInspiredEmails() -> [EmailCard] {
        var cards: [EmailCard] = []

        // education.permission.form - Synthetic corpus email (COMPOUND ACTION)
        cards.append(EmailCard(
            id: "corpus_education_001",
            type: .mail,
            state: .unseen,
            priority: .critical,
            hpa: "Sign Form",
            timeAgo: "5h ago",
            title: "Permission Form: Zoo Field Trip",
            summary: """
            **Actions:**
            • Sign permission form by **November 8th**
            • Pay $18 field trip fee online

            **Why:**
            Emma's class is visiting the City Zoo on November 15th to learn about wildlife and ecosystems.

            **Context:**
            • Trip includes admission and bus transportation
            • Bring sack lunch, water bottle, and weather-appropriate clothing
            • Departs **8:30 AM**, returns **2:00 PM**
            """,
            body: """
            Dear Parents,
            
            We're planning a field trip to the City Zoo on November 15th! This is a wonderful opportunity for students to learn about wildlife and ecosystems.
            
            Details:
            - Date: November 15, 2025
            - Cost: $18 per student (includes admission and bus)
            - Departure: 8:30 AM
            - Return: 2:00 PM
            
            Please sign the attached permission form and return it by November 8th. Payment can be made online at https://riverside.edu/payments
            
            What to bring:
            - Sack lunch
            - Water bottle
            - Weather-appropriate clothing
            
            Thank you!
            Mrs. Thompson
            """,
            htmlBody: nil,
            metaCTA: "Swipe Right: Sign Form",
            intent: "education.permission.form",
            intentConfidence: 0.92,
            suggestedActions: [
                EmailAction(actionId: "sign_form", displayName: "Sign Form", actionType: .inApp, isPrimary: true, priority: 1, isCompound: true, compoundSteps: ["sign_form","pay_form_fee"]),
                EmailAction(actionId: "pay_form_fee", displayName: "Pay Fee", actionType: .goTo, isPrimary: false, priority: 2),
                EmailAction(actionId: "add_to_calendar", displayName: "Add to Calendar", actionType: .inApp, isPrimary: false, priority: 3)
            ],
            sender: SenderInfo(name: "Mrs. Thompson", initial: "M", email: "teacher@riverside.edu"),
            recipientEmail: "sarah.chen@example.com",
            kid: KidInfo(name: "Emma Chen", initial: "E", grade: "3rd Grade")
        ))

        // education.assignment.due - Synthetic corpus email
        cards.append(EmailCard(
            id: "corpus_education_002",
            type: .mail,
            state: .unseen,
            priority: .high,
            hpa: "View Assignment",
            timeAgo: "1h ago",
            title: "Math Homework Due Monday",
            summary: """
            **Actions:**
            • Complete Chapter 8 math worksheet by **Monday, October 30th**

            **Why:**
            Math homework on fractions and decimals is due for your child's class.

            **Context:**
            • View assignment at class portal
            • Covers Chapter 8 fractions and decimals
            """,
            body: """
            Dear Parents,
            
            Please remind your child to complete the Chapter 8 math worksheet by Monday, October 30th. The worksheet covers fractions and decimals.
            
            You can view the assignment on our class portal at https://classroom.lincolnelementary.edu/assignments/math-ch8
            
            Thank you,
            Ms. Rodriguez
            """,
            htmlBody: nil,
            metaCTA: "Swipe Right: View Assignment",
            intent: "education.assignment.due",
            intentConfidence: 0.92,
            suggestedActions: [
                EmailAction(actionId: "view_assignment", displayName: "View Assignment", actionType: .goTo, isPrimary: true, priority: 1),
                EmailAction(actionId: "add_to_calendar", displayName: "Add to Calendar", actionType: .inApp, isPrimary: false, priority: 2)
            ],
            sender: SenderInfo(name: "Ms. Rodriguez", initial: "M", email: "teacher@lincolnelementary.edu"),
            recipientEmail: "sarah.chen@example.com"
        ))

        // education.assignment.due - Synthetic corpus email
        cards.append(EmailCard(
            id: "corpus_education_003",
            type: .mail,
            state: .unseen,
            priority: .critical,
            hpa: "View Document",
            timeAgo: "1h ago",
            title: "Science Fair Project Reminder",
            summary: """
            **Actions:**
            • Bring completed science fair project by **Friday, November 3rd**

            **Why:**
            Science fair projects are due this week with presentations required.

            **Context:**
            • Students must bring displays and be prepared to present
            • Project guidelines available at school website
            """,
            body: """
            Hi Everyone,
            
            Just a reminder that science fair projects are due this Friday, Nov 3rd. Students should bring their completed displays and be prepared to present.
            
            Project guidelines: https://riverview.edu/science-fair
            
            Let me know if you have questions!
            Mr. Chen
            """,
            htmlBody: nil,
            metaCTA: "Swipe Right: View Document",
            intent: "education.assignment.due",
            intentConfidence: 0.92,
            suggestedActions: [
                EmailAction(actionId: "view_document", displayName: "View Document", actionType: .goTo, isPrimary: true, priority: 1),
                EmailAction(actionId: "add_reminder", displayName: "Add Reminder", actionType: .inApp, isPrimary: false, priority: 2)
            ],
            sender: SenderInfo(name: "Mr. Chen", initial: "M", email: "science@riverview.edu"),
            recipientEmail: "sarah.chen@example.com"
        ))

        // education.grade.posted - Synthetic corpus email
        cards.append(EmailCard(
            id: "corpus_education_004",
            type: .mail,
            state: .unseen,
            priority: .medium,
            hpa: "Check Grade",
            timeAgo: "2h ago",
            title: "New Grade Posted: History Essay",
            summary: """
            **Actions:**
            • View full feedback on Canvas

            **Why:**
            Grade posted for Chapter 12 Essay in US History: **92/100**

            **Context:**
            • Excellent analysis of the Civil War
            • Strong thesis and supporting evidence noted
            """,
            body: """
            A grade has been posted for your assignment 'Chapter 12 Essay' in US History.
            
            Grade: 92/100
            Comments: Excellent analysis of the Civil War. Strong thesis and supporting evidence.
            
            View full feedback: https://canvas.school.edu/courses/12345/grades
            
            Canvas
            """,
            htmlBody: nil,
            metaCTA: "Swipe Right: Check Grade",
            intent: "education.grade.posted",
            intentConfidence: 0.92,
            suggestedActions: [
                EmailAction(actionId: "check_grade", displayName: "Check Grade", actionType: .inApp, isPrimary: true, priority: 1),
                EmailAction(actionId: "view_document", displayName: "View Document", actionType: .goTo, isPrimary: false, priority: 2)
            ],
            sender: SenderInfo(name: "Canvas", initial: "C", email: "notifications@canvas.instructure.com"),
            recipientEmail: "sarah.chen@example.com"
        ))

        // education.grade.posted - Synthetic corpus email
        cards.append(EmailCard(
            id: "corpus_education_005",
            type: .mail,
            state: .unseen,
            priority: .high,
            hpa: "Check Grade",
            timeAgo: "5h ago",
            title: "Report Card Available",
            summary: """
            **Actions:**
            • View Emma's Quarter 1 report card on PowerSchool

            **Why:**
            Emma's Q1 report card is ready with **3.8 GPA** overall.

            **Context:**
            • View detailed grades and teacher comments
            • PowerSchool parent portal access required
            """,
            body: """
            The Quarter 1 report card for Emma Chen is now available in PowerSchool.
            
            Overall GPA: 3.8
            
            Log in to view detailed grades and teacher comments: https://powerschool.district.edu/parent
            
            PowerSchool Parent Portal
            """,
            htmlBody: nil,
            metaCTA: "Swipe Right: Check Grade",
            intent: "education.grade.posted",
            intentConfidence: 0.92,
            suggestedActions: [
                EmailAction(actionId: "check_grade", displayName: "Check Grade", actionType: .inApp, isPrimary: true, priority: 1)
            ],
            sender: SenderInfo(name: "PowerSchool", initial: "P", email: "noreply@powerschool.com"),
            recipientEmail: "sarah.chen@example.com"
        ))

        // healthcare.appointment.reminder - Synthetic corpus email
        cards.append(EmailCard(
            id: "corpus_healthcare_006",
            type: .mail,
            state: .unseen,
            priority: .high,
            hpa: "Add to Calendar",
            timeAgo: "2d ago",
            title: "Appointment Reminder: Nov 5 at 2:30 PM",
            summary: """
            **Actions:**
            • Add Emma's doctor appointment to calendar for **Monday, November 5 at 2:30 PM**

            **Why:**
            Emma has a pediatrics appointment with Dr. Sarah Williams next week.

            **Context:**
            • Location: Family Health Center - Main Campus, Suite 200
            • Arrive **10 minutes early** for paperwork
            • Call **(555) 123-4567** to reschedule if needed
            """,
            body: """
            This is a reminder of your upcoming appointment:
            
            Patient: Emma Chen
            Provider: Dr. Sarah Williams (Pediatrics)
            Date: Monday, November 5, 2025
            Time: 2:30 PM
            Location: Family Health Center - Main Campus
            123 Medical Plaza, Suite 200
            
            Please arrive 10 minutes early to complete any necessary paperwork.
            
            Need to reschedule? Call (555) 123-4567 or visit https://familyhealth.com/appointments
            
            Family Health Center
            """,
            htmlBody: nil,
            metaCTA: "Swipe Right: Add to Calendar",
            intent: "healthcare.appointment.reminder",
            intentConfidence: 0.92,
            suggestedActions: [
                EmailAction(actionId: "add_to_calendar", displayName: "Add to Calendar", actionType: .inApp, isPrimary: true, priority: 1),
                EmailAction(actionId: "get_directions", displayName: "Get Directions", actionType: .goTo, isPrimary: false, priority: 2),
                EmailAction(actionId: "schedule_meeting", displayName: "Reschedule", actionType: .inApp, isPrimary: false, priority: 3)
            ],
            sender: SenderInfo(name: "Family Health Center", initial: "F", email: "appointments@familyhealth.com"),
            recipientEmail: "sarah.chen@example.com"
        ))

        // healthcare.appointment.reminder - Synthetic corpus email
        cards.append(EmailCard(
            id: "corpus_healthcare_007",
            type: .mail,
            state: .unseen,
            priority: .critical,
            hpa: "Add to Calendar",
            timeAgo: "1d ago",
            title: "Dental Cleaning Tomorrow - Don't Forget!",
            summary: """
            **Actions:**
            • Add dental cleaning to calendar for **Tuesday, October 31 at 10:00 AM**

            **Why:**
            Your dental cleaning appointment with Dr. Johnson is tomorrow morning.

            **Context:**
            • Location: Smile Dental - Downtown Office, 456 Main Street
            • Call **(555) 987-6543** to reschedule if needed
            """,
            body: """
            Hi Sarah,
            
            Friendly reminder that you have a dental cleaning appointment tomorrow:
            
            Tuesday, October 31, 2025 at 10:00 AM
            Dr. Johnson, DDS
            Smile Dental - Downtown Office
            456 Main Street
            
            Please call (555) 987-6543 if you need to reschedule.
            
            See you soon!
            Smile Dental Team
            """,
            htmlBody: nil,
            metaCTA: "Swipe Right: Add to Calendar",
            intent: "healthcare.appointment.reminder",
            intentConfidence: 0.92,
            suggestedActions: [
                EmailAction(actionId: "add_to_calendar", displayName: "Add to Calendar", actionType: .inApp, isPrimary: true, priority: 1),
                EmailAction(actionId: "get_directions", displayName: "Get Directions", actionType: .goTo, isPrimary: false, priority: 2)
            ],
            sender: SenderInfo(name: "Smile Dental", initial: "S", email: "reminders@smiledental.com"),
            recipientEmail: "sarah.chen@example.com"
        ))

        // travel.flight.check-in - Synthetic corpus email
        cards.append(EmailCard(
            id: "corpus_travel_008",
            type: .mail,
            state: .unseen,
            priority: .critical,
            hpa: "Check In",
            timeAgo: "1d ago",
            title: "Check in now for your flight to San Diego",
            summary: """
            **Actions:**
            • Check in for Southwest flight **WN 1245** to San Diego

            **Why:**
            Your flight to San Diego departs tomorrow (**November 10 at 3:45 PM**) from Oakland.

            **Context:**
            • Confirmation: **ABC123**
            • Arrival: **5:30 PM** in San Diego (SAN)
            • Get boarding pass now via Southwest website
            """,
            body: """
            You're on your way to San Diego!
            
            Flight: WN 1245
            Date: November 10, 2025
            Departure: 3:45 PM from Oakland (OAK)
            Arrival: 5:30 PM in San Diego (SAN)
            
            Check in now and get your boarding pass: https://southwest.com/checkin/ABC123
            
            Confirmation: ABC123
            Passenger: Sarah Chen
            
            Safe travels!
            Southwest Airlines
            """,
            htmlBody: nil,
            metaCTA: "Swipe Right: Check In",
            intent: "travel.flight.check-in",
            intentConfidence: 0.92,
            suggestedActions: [
                EmailAction(actionId: "check_in_flight", displayName: "Check In", actionType: .goTo, isPrimary: true, priority: 1),
                EmailAction(actionId: "add_to_wallet", displayName: "Add to Wallet", actionType: .inApp, isPrimary: false, priority: 2),
                EmailAction(actionId: "add_to_calendar", displayName: "Add to Calendar", actionType: .inApp, isPrimary: false, priority: 3)
            ],
            sender: SenderInfo(name: "Southwest Airlines", initial: "S", email: "noreply@southwest.com"),
            recipientEmail: "sarah.chen@example.com"
        ))

        // travel.itinerary.update - Synthetic corpus email
        cards.append(EmailCard(
            id: "corpus_travel_009",
            type: .mail,
            state: .unseen,
            priority: .medium,
            hpa: "View Reservation",
            timeAgo: "5h ago",
            title: "Your Reservation is Confirmed",
            summary: """
            **Actions:**
            • View Hilton San Diego Bayfront reservation

            **Why:**
            Hotel confirmed for San Diego trip: **November 10-12, 2025**

            **Context:**
            • Check-in: Friday **3:00 PM**, Check-out: Sunday **12:00 PM**
            • Room: King Deluxe with Bay View
            • Total: **$459.00** (includes taxes)
            • Confirmation: **HLT789456**
            """,
            body: """
            Thank you for choosing Hilton!
            
            Reservation Details:
            Hotel: Hilton San Diego Bayfront
            Check-in: Friday, November 10, 2025 (3:00 PM)
            Check-out: Sunday, November 12, 2025 (12:00 PM)
            Room Type: King Deluxe with Bay View
            Confirmation: HLT789456
            
            Total: $459.00 (includes taxes)
            
            View or modify your reservation: https://hilton.com/reservations/HLT789456
            
            Address:
            1 Park Blvd
            San Diego, CA 92101
            Phone: (619) 555-1234
            
            We look forward to welcoming you!
            Hilton Team
            """,
            htmlBody: nil,
            metaCTA: "Swipe Right: View Reservation",
            intent: "travel.itinerary.update",
            intentConfidence: 0.92,
            suggestedActions: [
                EmailAction(actionId: "view_reservation", displayName: "View Reservation", actionType: .goTo, isPrimary: true, priority: 1),
                EmailAction(actionId: "add_to_calendar", displayName: "Add to Calendar", actionType: .inApp, isPrimary: false, priority: 2),
                EmailAction(actionId: "get_directions", displayName: "Get Directions", actionType: .goTo, isPrimary: false, priority: 3)
            ],
            sender: SenderInfo(name: "Hilton Honors", initial: "H", email: "reservations@hilton.com"),
            recipientEmail: "sarah.chen@example.com"
        ))

        // e-commerce.shipping.notification - Synthetic corpus email
        cards.append(EmailCard(
            id: "corpus_e-commerce_010",
            type: .mail,
            state: .unseen,
            priority: .medium,
            hpa: "Track Package",
            timeAgo: "2d ago",
            title: "Your order has shipped!",
            summary: """
            **Actions:**
            • Track Target order **#12345-67890** via UPS

            **Why:**
            Kids' winter jacket and backpack shipped, arriving **Thursday, November 2**.

            **Context:**
            • Tracking: **1Z999AA10123456789** (UPS)
            • Items: Winter Jacket (Size 10) - $39.99, Blue Backpack - $24.99
            """,
            body: """
            Good news! Your Target order is on its way.
            
            Order #: 12345-67890
            Expected delivery: Thursday, November 2, 2025
            
            Items:
            - Kids' Winter Jacket (Size 10) - $39.99
            - Backpack - Blue - $24.99
            
            Tracking: 1Z999AA10123456789
            Carrier: UPS
            
            Track your package: https://target.com/track/12345-67890
            
            Thank you for shopping with Target!
            """,
            htmlBody: nil,
            metaCTA: "Swipe Right: Track Package",
            intent: "e-commerce.shipping.notification",
            intentConfidence: 0.92,
            suggestedActions: [
                EmailAction(actionId: "track_package", displayName: "Track Package", actionType: .goTo, isPrimary: true, priority: 1),
                EmailAction(actionId: "view_order", displayName: "View Order", actionType: .goTo, isPrimary: false, priority: 2)
            ],
            sender: SenderInfo(name: "Target", initial: "T", email: "orders@target.com"),
            recipientEmail: "sarah.chen@example.com"
        ))

        // e-commerce.order.delayed - Synthetic corpus email
        cards.append(EmailCard(
            id: "corpus_e-commerce_011",
            type: .mail,
            state: .unseen,
            priority: .medium,
            hpa: "Track Package",
            timeAgo: "1h ago",
            title: "Delivery Update: Your Package is Running Late",
            summary: """
            **Actions:**
            • Track delayed Amazon order **#123-4567890-1234567**

            **Why:**
            Package delayed from November 1 to new delivery date: **Saturday, November 4**.

            **Context:**
            • Tracking ID: **TBA123456789**
            • Amazon apologizes for the inconvenience
            """,
            body: """
            Hello,
            
            We wanted to let you know that your package is running a bit behind schedule.
            
            Order #: 123-4567890-1234567
            New expected delivery: Saturday, November 4, 2025
            (Original: November 1, 2025)
            
            We apologize for the inconvenience. You can track your package here:
            https://amazon.com/progress-tracker/123-4567890-1234567
            
            Tracking ID: TBA123456789
            
            Thank you for your patience,
            Amazon Customer Service
            """,
            htmlBody: nil,
            metaCTA: "Swipe Right: Track Package",
            intent: "e-commerce.order.delayed",
            intentConfidence: 0.92,
            suggestedActions: [
                EmailAction(actionId: "track_package", displayName: "Track Package", actionType: .goTo, isPrimary: true, priority: 1),
                EmailAction(actionId: "contact_support", displayName: "Contact Support", actionType: .goTo, isPrimary: false, priority: 2)
            ],
            sender: SenderInfo(name: "Amazon", initial: "A", email: "shipment-tracking@amazon.com"),
            recipientEmail: "sarah.chen@example.com"
        ))

        // e-commerce.delivery.completed - Synthetic corpus email
        cards.append(EmailCard(
            id: "corpus_e-commerce_012",
            type: .mail,
            state: .unseen,
            priority: .low,
            hpa: "View Document",
            timeAgo: "1h ago",
            title: "Delivered: Your Package Has Arrived",
            summary: """
            **Actions:**
            • View FedEx delivery photo

            **Why:**
            Your package was delivered today at **2:47 PM** to your front porch.

            **Context:**
            • Tracking: **123456789012**
            • Delivery location: Front porch (left at door)
            """,
            body: """
            Your package was delivered today at 2:47 PM.
            
            Tracking #: 123456789012
            Delivered to: Front porch
            Signed by: Left at door
            
            View delivery photo: https://fedex.com/proof/123456789012
            
            Thank you for using FedEx!
            """,
            htmlBody: nil,
            metaCTA: "Swipe Right: View Document",
            intent: "e-commerce.delivery.completed",
            intentConfidence: 0.92,
            suggestedActions: [
                EmailAction(actionId: "view_document", displayName: "View Document", actionType: .goTo, isPrimary: true, priority: 1)
            ],
            sender: SenderInfo(name: "FedEx", initial: "F", email: "tracking@fedex.com"),
            recipientEmail: "sarah.chen@example.com"
        ))

        // finance.statement.ready - Synthetic corpus email
        cards.append(EmailCard(
            id: "corpus_finance_013",
            type: .mail,
            state: .unseen,
            priority: .medium,
            hpa: "Download Statement",
            timeAgo: "5h ago",
            title: "Your October Statement is Ready",
            summary: """
            **Actions:**
            • View Chase credit card statement for October
            • Pay minimum **$25.00** by **November 25, 2025**

            **Why:**
            Your October credit card statement shows **$1,247.52** new balance.

            **Context:**
            • Statement period: October 1-31, 2025
            • Account ending in: 5678
            • Set up autopay to never miss a payment
            """,
            body: """
            Your Chase credit card statement is now available.
            
            Statement Period: October 1-31, 2025
            Account ending in: 5678
            New Balance: $1,247.52
            Minimum Payment Due: $25.00
            Payment Due Date: November 25, 2025
            
            View statement: https://chase.com/statements/oct2025
            
            Set up autopay to never miss a payment: https://chase.com/autopay
            
            Thank you for being a Chase customer.
            """,
            htmlBody: nil,
            metaCTA: "Swipe Right: Download Statement",
            intent: "finance.statement.ready",
            intentConfidence: 0.92,
            suggestedActions: [
                EmailAction(actionId: "download_report", displayName: "Download Statement", actionType: .goTo, isPrimary: true, priority: 1),
                EmailAction(actionId: "pay_invoice", displayName: "Pay Bill", actionType: .inApp, isPrimary: false, priority: 2)
            ],
            sender: SenderInfo(name: "Chase Bank", initial: "C", email: "statements@chase.com"),
            recipientEmail: "sarah.chen@example.com"
        ))

        // billing.invoice.due - Synthetic corpus email
        cards.append(EmailCard(
            id: "corpus_billing_014",
            type: .mail,
            state: .unseen,
            priority: .high,
            hpa: "Pay Bill",
            timeAgo: "1d ago",
            title: "Your Verizon Bill is Ready",
            summary: """
            **Actions:**
            • Pay Verizon bill of **$127.89** by **November 20, 2025**

            **Why:**
            Your November Verizon bill is now available.

            **Context:**
            • Account: 9876543210
            • Charges: Unlimited Plan (3 lines) $105.00 + Device $18.89 + Taxes $4.00
            • View and pay at Verizon website
            """,
            body: """
            Your November Verizon bill is now available.
            
            Account: 9876543210
            Bill Date: October 28, 2025
            Amount Due: $127.89
            Due Date: November 20, 2025
            
            View and pay your bill: https://verizon.com/bill/pay
            
            Current charges:
            - Unlimited Plan (3 lines): $105.00
            - Device payment: $18.89
            - Taxes & fees: $4.00
            
            Questions? Visit https://verizon.com/support or call 1-800-VERIZON
            
            Thank you,
            Verizon
            """,
            htmlBody: nil,
            metaCTA: "Swipe Right: Pay Bill",
            intent: "billing.invoice.due",
            intentConfidence: 0.92,
            suggestedActions: [
                EmailAction(actionId: "pay_invoice", displayName: "Pay Bill", actionType: .inApp, isPrimary: true, priority: 1),
                EmailAction(actionId: "view_invoice", displayName: "View Invoice", actionType: .goTo, isPrimary: false, priority: 2),
                EmailAction(actionId: "download_receipt", displayName: "Download Receipt", actionType: .goTo, isPrimary: false, priority: 3)
            ],
            sender: SenderInfo(name: "Verizon", initial: "V", email: "billing@verizon.com"),
            recipientEmail: "sarah.chen@example.com"
        ))

        return cards
    }
}
