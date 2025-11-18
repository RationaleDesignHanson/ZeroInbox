import Foundation

/// Simplified template-based mock data generator
/// Reduced from 6,140 lines to ~500 lines (92% reduction)
/// Maintains same public API for backward compatibility
struct DataGenerator {
    // MARK: - Performance Optimization: Cached Mock Data
    private static var cachedMockData: [EmailCard]?
    private static let cacheVersion = "v2.2-diverse-actions" // Change this to invalidate cache

    static func generateSarahChenEmails() -> [EmailCard] {
        return generateComprehensiveMockData()
    }

    static func generateBasicEmails() -> [EmailCard] {
        return generateComprehensiveMockData()
    }

    /// Reset cached mock data (useful for testing or when data needs to be refreshed)
    static func resetCache() {
        cachedMockData = nil
        UserDefaults.standard.removeObject(forKey: "mockDataCacheVersion")
        Logger.info("DataGenerator cache cleared", category: .service)
    }

    /// Comprehensive mock data showcasing all action types per archetype
    /// Week 5 Performance Optimization: Results are cached after first generation
    static func generateComprehensiveMockData() -> [EmailCard] {
        // Check if cache version matches
        let savedVersion = UserDefaults.standard.string(forKey: "mockDataCacheVersion")
        let cacheValid = savedVersion == cacheVersion

        // Return cached data if available AND version matches
        if let cached = cachedMockData, cacheValid {
            Logger.debug("Returning cached mock data (\(cached.count) emails)", category: .service)
            return cached
        }

        // Clear old cache if version mismatch
        if !cacheValid {
            Logger.info("Cache version mismatch - regenerating mock data", category: .service)
            cachedMockData = nil
        }

        Logger.info("Generating mock data for first time (will be cached)", category: .service)
        var cards: [EmailCard] = []

        // MARK: - NEWSLETTERS (3 cards) - ADS MODE
        cards.append(createCard(
            id: "newsletter1", type: .ads, priority: .medium,
            title: "The Download: This Week in AI - Issue #47",
            summary: "Weekly AI and tech newsletter featuring GPT-5 speculation, EU AI Act launch, and GitHub Copilot X upgrade. Industry stats show 67% of developers now use AI assistants daily with $21B invested this quarter.",
            actions: [("view_newsletter_summary", "View Summary", true), ("save_for_later", "Save for Later", false), ("archive", "Archive", false)],
            sender: ("TechCrunch", "T"), hpa: "View Summary",
            productImageUrl: "https://images.unsplash.com/photo-1677442136019-21780ecad995?w=400",
            brandName: "TechCrunch"
        ))

        cards.append(createCard(
            id: "newsletter2", type: .ads, priority: .low,
            title: "Weekend Reads: Top 10 Books on Productivity",
            summary: "Curated list of must-read books on productivity, time management, and focus. From 'Deep Work' to 'Atomic Habits', discover the books that will transform how you work.",
            actions: [("view_newsletter_summary", "View Summary", true), ("save_for_later", "Save for Later", false)],
            sender: ("Book Digest", "B"), hpa: "View Summary",
            productImageUrl: "https://images.unsplash.com/photo-1512820790803-83ca734da794?w=400",
            brandName: "Book Digest"
        ))

        cards.append(createCard(
            id: "newsletter3", type: .ads, priority: .low,
            title: "The Morning Brew: Daily Business News",
            summary: "Quick 5-minute read covering today's top business stories, market updates, and startup news. Fed announces rate decision, Tesla stock surges 12%, and more.",
            actions: [("view_newsletter_summary", "View Summary", true), ("archive", "Archive", false)],
            sender: ("Morning Brew", "M"), hpa: "View Summary",
            productImageUrl: "https://images.unsplash.com/photo-1504711434969-e33886168f5c?w=400",
            brandName: "Morning Brew"
        ))

        // MARK: - FAMILY (4 actions)
        cards.append(createCard(
            id: "family1", type: .mail, priority: .high,
            title: "Permission Form - Field Trip",
            summary: "Please sign the permission form for Emma's upcoming field trip to the Science Museum on November 15th. Deadline: November 10th.",
            actions: [("sign_form", "Sign Form", true), ("add_to_calendar", "Add to Calendar", false), ("schedule_meeting", "Schedule Meeting", false)],
            sender: ("Lincoln Elementary", "L"), hpa: "Sign Form"
        ))

        cards.append(createCard(
            id: "family2", type: .mail, priority: .medium,
            title: "Parent-Teacher Conference Scheduling",
            summary: "It's time to schedule your fall parent-teacher conference. Please select a time slot that works for you between November 18-22.",
            actions: [("schedule_meeting", "Schedule Meeting", true), ("add_reminder", "Set Reminder", false)],
            sender: ("Ms. Johnson", "J"), hpa: "Schedule Meeting"
        ))

        cards.append(createCard(
            id: "family3", type: .mail, priority: .medium,
            title: "School Photos - Order Now",
            summary: "Your child's school photos are ready! View and order prints, digital downloads, or photo packages. Order by November 20th for free shipping.",
            actions: [("view_photos", "View Photos", true), ("shop", "Order Prints", false)],
            sender: ("Lifetouch Photography", "L"), hpa: "View Photos"
        ))

        cards.append(createCard(
            id: "family4", type: .mail, priority: .high,
            title: "Immunization Records Required",
            summary: "State health requirements: Please submit Emma's updated immunization records by November 30th to remain in compliance with school enrollment.",
            actions: [("upload_document", "Upload Records", true), ("view_requirements", "View Requirements", false)],
            sender: ("School Nurse", "S"), hpa: "Upload Records"
        ))

        // MARK: - SHOPPING (10 actions)
        cards.append(createCard(
            id: "shopping1", type: .mail, priority: .high,
            title: "Order Confirmed: Sony WH-1000XM5 Headphones",
            summary: "Your order #AMZ-7821-5643 has been confirmed! Sony WH-1000XM5 Wireless Headphones ($349.99). Estimated delivery: November 18-20.",
            actions: [("track_package", "Track Package", true), ("view_order", "View Order", false), ("contact_support", "Contact Support", false)],
            sender: ("Amazon", "A"), hpa: "Track Package"
        ))

        cards.append(createCard(
            id: "shopping2", type: .mail, priority: .medium,
            title: "Your Package Has Shipped",
            summary: "Great news! Your order has shipped and is on the way. Track your package: Tracking #1Z999AA10123456789. Expected delivery: November 17 by 8pm.",
            actions: [("track_package", "Track Package", true), ("add_to_calendar", "Add Delivery Date", false)],
            sender: ("UPS", "U"), hpa: "Track Package"
        ))

        cards.append(createCard(
            id: "shopping3", type: .mail, priority: .high,
            title: "Out for Delivery Today",
            summary: "Your package is out for delivery! It will arrive today between 2-6 PM. Make sure someone is home to sign for the package.",
            actions: [("track_package", "Track Package", true), ("provide_instructions", "Delivery Instructions", false)],
            sender: ("FedEx", "F"), hpa: "Track Package"
        ))

        cards.append(createCard(
            id: "shopping4", type: .ads, priority: .medium,
            title: "Flash Sale: 40% Off Winter Coats",
            summary: "Limited time offer! Get 40% off all winter coats and jackets. Use code WINTER40 at checkout. Sale ends tonight at midnight.",
            actions: [("shop", "Shop Now", true), ("copy_promo_code", "Copy Code", false), ("save_for_later", "Save", false)],
            sender: ("Patagonia", "P"), hpa: "Shop Now",
            productImageUrl: "https://images.unsplash.com/photo-1551028719-00167b16eac5?w=400",
            brandName: "Patagonia",
            originalPrice: 150.00,
            salePrice: 90.00,
            discount: 40
        ))

        cards.append(createCard(
            id: "shopping5", type: .ads, priority: .low,
            title: "Your Cart is Waiting",
            summary: "You left 3 items in your cart: Nike Running Shoes ($120), Yoga Mat ($35), and Water Bottle ($20). Complete your order now!",
            actions: [("complete_purchase", "Complete Purchase", true), ("view_cart", "View Cart", false)],
            sender: ("REI", "R"), hpa: "Complete Purchase",
            productImageUrl: "https://images.unsplash.com/photo-1542291026-7eec264c27ff?w=400",
            brandName: "REI",
            salePrice: 175.00
        ))

        cards.append(createCard(
            id: "shopping6", type: .ads, priority: .medium,
            title: "Price Drop Alert: iPhone 15 Pro",
            summary: "The iPhone 15 Pro you're watching just dropped to $999 (was $1,199). Save $200 today only!",
            actions: [("shop", "Buy Now", true), ("automated_add_to_cart", "Add to Cart", false)],
            sender: ("Best Buy", "B"), hpa: "Buy Now",
            productImageUrl: "https://images.unsplash.com/photo-1632661674596-df8be070a5c5?w=400",
            brandName: "Apple",
            originalPrice: 1199.00,
            salePrice: 999.00,
            discount: 17
        ))

        cards.append(createCard(
            id: "shopping7", type: .mail, priority: .low,
            title: "How Was Your Recent Purchase?",
            summary: "Thanks for your recent order! How was your experience with the Sony WH-1000XM5 Headphones? Share your feedback and help other customers.",
            actions: [("write_review", "Write Review", true), ("view_order", "View Order", false)],
            sender: ("Amazon", "A"), hpa: "Write Review"
        ))

        cards.append(createCard(
            id: "shopping8", type: .mail, priority: .medium,
            title: "Return Window Closing Soon",
            summary: "Your return window for Order #1234567 closes in 3 days. If you're not satisfied, you can return it for free by November 20th.",
            actions: [("start_return", "Start Return", true), ("view_order", "View Order", false)],
            sender: ("Target", "T"), hpa: "Start Return"
        ))

        cards.append(createCard(
            id: "shopping9", type: .mail, priority: .high,
            title: "Subscription Renewal Notice",
            summary: "Your Amazon Prime membership will renew on November 25th for $139/year. Update your payment method or cancel anytime.",
            actions: [("update_payment", "Update Payment", true), ("cancel_subscription", "Cancel", false), ("add_reminder", "Remind Me", false)],
            sender: ("Amazon Prime", "A"), hpa: "Update Payment"
        ))

        cards.append(createCard(
            id: "shopping10", type: .ads, priority: .medium,
            title: "Special Offer Just for You",
            summary: "As a valued customer, enjoy 25% off your next purchase! Use code LOYAL25. Valid on orders $50+ through November 30th.",
            actions: [("shop", "Shop Now", true), ("save_offer", "Save Offer", false)],
            sender: ("Nordstrom", "N"), hpa: "Shop Now",
            productImageUrl: "https://images.unsplash.com/photo-1490481651871-ab68de25d43d?w=400",
            brandName: "Nordstrom",
            discount: 25
        ))

        // MARK: - BILLING (4 actions)
        cards.append(createCard(
            id: "billing1", type: .mail, priority: .high,
            title: "Your Electric Bill is Ready",
            summary: "Your November electricity bill is now available. Amount due: $142.38. Payment due: November 22nd. View your detailed usage breakdown.",
            actions: [("pay_invoice", "Pay Bill", true), ("view_invoice", "View Bill", false), ("setup_autopay", "Setup Autopay", false)],
            sender: ("Pacific Power", "P"), hpa: "Pay Bill"
        ))

        cards.append(createCard(
            id: "billing2", type: .mail, priority: .high,
            title: "Payment Reminder: Internet Service",
            summary: "Friendly reminder: Your Xfinity bill of $89.99 is due in 3 days (November 18th). Pay now to avoid service interruption.",
            actions: [("pay_invoice", "Pay Now", true), ("view_invoice", "View Bill", false)],
            sender: ("Xfinity", "X"), hpa: "Pay Now"
        ))

        cards.append(createCard(
            id: "billing3", type: .mail, priority: .medium,
            title: "Credit Card Statement Available",
            summary: "Your Chase Sapphire statement is ready. Statement balance: $2,847.65. Minimum payment: $56.00. Due date: December 1st.",
            actions: [("pay_invoice", "Make Payment", true), ("view_statement", "View Statement", false), ("setup_autopay", "Setup Autopay", false)],
            sender: ("Chase", "C"), hpa: "Make Payment"
        ))

        cards.append(createCard(
            id: "billing4", type: .mail, priority: .low,
            title: "Payment Successful",
            summary: "We've received your payment of $142.38 for your November electricity bill. Thank you! Your next bill will be ready around December 15th.",
            actions: [("view_invoice", "View Receipt", true), ("download_receipt", "Download", false)],
            sender: ("Pacific Power", "P"), hpa: "View Receipt"
        ))

        // MARK: - SALES (2 actions) - ADS MODE
        cards.append(createCard(
            id: "sales1", type: .ads, priority: .medium,
            title: "Exclusive Black Friday Preview",
            summary: "VIP early access! Shop our Black Friday deals 24 hours before everyone else. Up to 70% off on electronics, home goods, and more. Starts November 20th at midnight.",
            actions: [("shop", "Shop Early Access", true), ("view_deals", "Browse Deals", false)],
            sender: ("Target", "T"), hpa: "Shop Early Access",
            productImageUrl: "https://images.unsplash.com/photo-1607083206869-4c7672e72a8a?w=400",
            brandName: "Target",
            discount: 70
        ))

        cards.append(createCard(
            id: "sales2", type: .ads, priority: .low,
            title: "You're Invited: Seasonal Sale Event",
            summary: "Join us for our biggest sale of the season! November 25-27. In-store and online. Free shipping on all orders, plus exclusive member rewards.",
            actions: [("rsvp", "RSVP", true), ("shop", "Shop Now", false)],
            sender: ("Macy's", "M"), hpa: "RSVP",
            productImageUrl: "https://images.unsplash.com/photo-1441986300917-64674bd600d8?w=400",
            brandName: "Macy's"
        ))

        // MARK: - PROJECT (4 actions)
        cards.append(createCard(
            id: "project1", type: .mail, priority: .high,
            title: "[ACTION REQUIRED] Q4 Budget Approval",
            summary: "The Q4 budget proposal requires your approval by EOD Friday. Total requested: $2.4M across 6 departments. Review and approve in the portal.",
            actions: [("approve_request", "Approve Budget", true), ("view_details", "Review Details", false), ("schedule_meeting", "Discuss", false)],
            sender: ("Finance Team", "F"), hpa: "Approve Budget"
        ))

        cards.append(createCard(
            id: "project2", type: .mail, priority: .medium,
            title: "Weekly Standup Notes - Nov 15",
            summary: "Team standup summary: 3 PRs merged, 2 blockers identified (API rate limits, database performance). Next sprint planning on Wednesday.",
            actions: [("view_summary", "View Notes", true), ("add_comment", "Add Comment", false)],
            sender: ("Project Manager", "P"), hpa: "View Notes"
        ))

        cards.append(createCard(
            id: "project3", type: .mail, priority: .high,
            title: "Pull Request Ready for Review",
            summary: "Sarah Chen opened PR #342: 'Add user authentication flow'. 247 lines changed across 8 files. Tests passing. Awaiting your review.",
            actions: [("review_pr", "Review PR", true), ("approve_pr", "Approve", false), ("view_changes", "View Changes", false)],
            sender: ("GitHub", "G"), hpa: "Review PR"
        ))

        cards.append(createCard(
            id: "project4", type: .mail, priority: .medium,
            title: "Sprint Retrospective: Action Items",
            summary: "Last sprint retrospective action items: 1) Improve code review turnaround (target: 24h), 2) Update testing guidelines, 3) Schedule architecture review.",
            actions: [("view_action_items", "View Items", true), ("mark_complete", "Mark Done", false)],
            sender: ("Scrum Master", "S"), hpa: "View Items"
        ))

        // MARK: - LEARNING (2 actions)
        cards.append(createCard(
            id: "learning1", type: .mail, priority: .medium,
            title: "New Course: SwiftUI Mastery 2025",
            summary: "Master modern iOS development with our comprehensive SwiftUI course. 12 hours of video, 50+ exercises, real-world projects. Enroll now and get 30% off!",
            actions: [("enroll", "Enroll Now", true), ("view_curriculum", "View Curriculum", false)],
            sender: ("Udemy", "U"), hpa: "Enroll Now"
        ))

        cards.append(createCard(
            id: "learning2", type: .mail, priority: .low,
            title: "Your Certificate is Ready",
            summary: "Congratulations! You've completed 'Machine Learning Fundamentals'. Download your certificate and share it on LinkedIn to showcase your achievement.",
            actions: [("download_certificate", "Download Certificate", true), ("share", "Share on LinkedIn", false)],
            sender: ("Coursera", "C"), hpa: "Download Certificate"
        ))

        // MARK: - TRAVEL (3 actions)
        cards.append(createCard(
            id: "travel1", type: .mail, priority: .high,
            title: "Your Flight to NYC - Check In Now",
            summary: "Flight UA2847 to New York (JFK) departs tomorrow at 8:45 AM. Check in now and download your boarding pass. Gate info available 2 hours before departure.",
            actions: [("check_in", "Check In", true), ("view_itinerary", "View Itinerary", false), ("add_to_calendar", "Add to Calendar", false)],
            sender: ("United Airlines", "U"), hpa: "Check In"
        ))

        cards.append(createCard(
            id: "travel2", type: .mail, priority: .medium,
            title: "Reservation Confirmed: Hilton Midtown",
            summary: "Your reservation at Hilton New York Midtown is confirmed! Check-in: Nov 20, Check-out: Nov 23. Confirmation #HLT89234567. View your reservation details.",
            actions: [("view_reservation", "View Reservation", true), ("update_reservation", "Modify Dates", false), ("cancel", "Cancel", false)],
            sender: ("Hilton Hotels", "H"), hpa: "View Reservation"
        ))

        cards.append(createCard(
            id: "travel3", type: .mail, priority: .medium,
            title: "Complete Your Trip Itinerary",
            summary: "Your NYC trip is coming up! Add activities, restaurants, and attractions to your itinerary. Get personalized recommendations based on your interests.",
            actions: [("view_itinerary", "View Itinerary", true), ("add_activities", "Add Activities", false)],
            sender: ("TripAdvisor", "T"), hpa: "View Itinerary"
        ))

        // MARK: - ACCOUNT (5 actions)
        cards.append(createCard(
            id: "account1", type: .mail, priority: .high,
            title: "Verify Your Email Address",
            summary: "Welcome to Zero! Please verify your email address to activate your account and start using all features. Verification link expires in 24 hours.",
            actions: [("verify_account", "Verify Email", true), ("resend_code", "Resend Link", false)],
            sender: ("Zero Team", "Z"), hpa: "Verify Email"
        ))

        cards.append(createCard(
            id: "account2", type: .mail, priority: .high,
            title: "Security Alert: New Login Detected",
            summary: "We detected a new login to your account from Chrome on macOS (San Francisco, CA) on Nov 15 at 2:34 PM. Was this you?",
            actions: [("confirm_login", "Yes, This Was Me", true), ("secure_account", "No, Secure Account", false)],
            sender: ("Security Team", "S"), hpa: "Confirm Login"
        ))

        cards.append(createCard(
            id: "account3", type: .mail, priority: .medium,
            title: "Password Reset Request",
            summary: "You requested a password reset for your account. Click the link below to create a new password. This link expires in 1 hour.",
            actions: [("reset_password", "Reset Password", true), ("contact_support", "I Didn't Request This", false)],
            sender: ("Account Security", "A"), hpa: "Reset Password"
        ))

        cards.append(createCard(
            id: "account4", type: .mail, priority: .low,
            title: "Update Your Profile",
            summary: "Your profile is 60% complete. Add a profile photo, update your bio, and connect your social accounts to get the most out of your account.",
            actions: [("update_profile", "Update Profile", true), ("skip", "Skip for Now", false)],
            sender: ("Zero Team", "Z"), hpa: "Update Profile"
        ))

        cards.append(createCard(
            id: "account5", type: .mail, priority: .medium,
            title: "Account Settings Changed",
            summary: "Your account settings were updated on Nov 15 at 3:20 PM: Email notifications enabled, two-factor authentication activated. Review changes.",
            actions: [("view_settings", "View Settings", true), ("undo_changes", "Undo Changes", false)],
            sender: ("Account Security", "A"), hpa: "View Settings"
        ))

        // MARK: - ADDITIONAL FEATURE COVERAGE (7 cards)
        cards.append(createCard(
            id: "feature1", type: .mail, priority: .high,
            title: "Delivery Access Code Required",
            summary: "Your Amazon package arrives today between 2-4 PM. The driver will need your gate access code: 4821. Make sure this code is provided.",
            actions: [("provide_access_code", "Provide Code", true), ("contact_driver", "Contact Driver", false)],
            sender: ("Amazon Delivery", "A"), hpa: "Provide Code"
        ))

        cards.append(createCard(
            id: "feature2", type: .mail, priority: .medium,
            title: "Urgent: Network Outage Scheduled",
            summary: "Scheduled network maintenance tonight 11 PM - 3 AM. Services will be unavailable. Plan accordingly and save your work.",
            actions: [("view_outage_details", "View Details", true), ("subscribe_updates", "Get Updates", false)],
            sender: ("IT Department", "I"), hpa: "View Details"
        ))

        cards.append(createCard(
            id: "feature3", type: .mail, priority: .low,
            title: "Community Event: Tech Meetup",
            summary: "Join us for our monthly tech meetup on Nov 25 at 6 PM! Guest speaker from Google will discuss 'Building Scalable Systems'. Pizza and drinks provided!",
            actions: [("read_community_post", "Read More", true), ("rsvp", "RSVP", false)],
            sender: ("SF Tech Community", "S"), hpa: "Read More"
        ))

        cards.append(createCard(
            id: "feature4", type: .mail, priority: .medium,
            title: "Storm Warning: Prepare for Outage",
            summary: "Severe storm expected tonight. Power outages likely. Charge devices, stock essentials, and secure outdoor items. Updates every 2 hours.",
            actions: [("prepare_for_outage", "View Checklist", true), ("get_updates", "Get Alerts", false)],
            sender: ("Emergency Services", "E"), hpa: "View Checklist"
        ))

        cards.append(createCard(
            id: "feature5", type: .mail, priority: .medium,
            title: "Property Listing: 123 Main St",
            summary: "New listing matches your saved search! 3 bed, 2 bath, 1,800 sqft in downtown. $675K. Open house this Saturday 2-4 PM. Schedule a showing today!",
            actions: [("save_properties", "Save Property", true), ("schedule_showing", "Schedule Showing", false), ("view_details", "View Details", false)],
            sender: ("Zillow", "Z"), hpa: "Save Property"
        ))

        cards.append(createCard(
            id: "feature6", type: .mail, priority: .low,
            title: "Your Monthly Activity Summary",
            summary: "November activity: 15 workouts completed, 87 miles run, 12,500 avg daily steps. You're on track to hit your monthly goal! Keep it up!",
            actions: [("view_activity_details", "View Details", true), ("share_progress", "Share", false)],
            sender: ("Strava", "S"), hpa: "View Details"
        ))

        cards.append(createCard(
            id: "feature7", type: .mail, priority: .high,
            title: "Download App: Mobile Experience",
            summary: "Get the Zero mobile app for iOS and Android! Access your inbox on the go with offline support, push notifications, and more.",
            actions: [("open_app", "Download App", true), ("learn_more", "Learn More", false)],
            sender: ("Zero Team", "Z"), hpa: "Download App"
        ))

        // MARK: - MISSING BACKEND ACTIONS (8 high-priority additions)
        cards.append(createCard(
            id: "missing1", type: .mail, priority: .high,
            title: "Cancel Your Gym Membership",
            summary: "Ready to cancel your gym membership? Complete the cancellation form online. Note: 30-day notice required per your contract terms.",
            actions: [("cancel_subscription", "Cancel Membership", true), ("view_contract", "View Contract", false)],
            sender: ("24 Hour Fitness", "2"), hpa: "Cancel Membership"
        ))

        cards.append(createCard(
            id: "missing2", type: .mail, priority: .medium,
            title: "Unsubscribe Confirmation",
            summary: "You've been unsubscribed from our marketing emails. You'll no longer receive promotional content but will still get order confirmations and account updates.",
            actions: [("unsubscribe", "Confirm Unsubscribe", true), ("resubscribe", "Resubscribe", false)],
            sender: ("Marketing Team", "M"), hpa: "Confirm Unsubscribe"
        ))

        cards.append(createCard(
            id: "missing3", type: .mail, priority: .low,
            title: "Product Image Gallery",
            summary: "Check out our latest collection! Browse photos of new arrivals, customer favorites, and seasonal specials. Shop directly from the gallery.",
            actions: [("view_attachment", "View Gallery", true), ("shop", "Shop Now", false)],
            sender: ("Fashion Retailer", "F"), hpa: "View Gallery"
        ))

        cards.append(createCard(
            id: "missing4", type: .mail, priority: .low,
            title: "Quarterly Report Attached",
            summary: "Q3 2025 quarterly report is attached. Revenue up 23% YoY, new product launches exceeded targets. Full analysis and projections included.",
            actions: [("preview_document", "Preview Report", true), ("download", "Download PDF", false)],
            sender: ("Finance Department", "F"), hpa: "Preview Report"
        ))

        cards.append(createCard(
            id: "missing5", type: .mail, priority: .medium,
            title: "View Spreadsheet: Sales Data",
            summary: "Updated sales spreadsheet for Q4 planning. Includes regional breakdowns, YoY comparisons, and forecast models. Collaborate with your team.",
            actions: [("view_spreadsheet", "Open Spreadsheet", true), ("download", "Download", false)],
            sender: ("Sales Analytics", "S"), hpa: "Open Spreadsheet"
        ))

        cards.append(createCard(
            id: "missing6", type: .mail, priority: .medium,
            title: "Contract for Signature",
            summary: "Employment contract ready for review and signature. Please review terms, compensation, and benefits. Sign electronically by Nov 20th.",
            actions: [("sign_form", "Sign Contract", true), ("preview_document", "Review First", false)],
            sender: ("HR Department", "H"), hpa: "Sign Contract"
        ))

        cards.append(createCard(
            id: "missing7", type: .mail, priority: .medium,
            title: "Weekly Newsletter: Download PDF",
            summary: "This week's newsletter is available as PDF! Includes all articles, interviews, and resources. Perfect for offline reading.",
            actions: [("view_newsletter_summary", "View Summary", true), ("preview_document", "Download PDF", false)],
            sender: ("Newsletter Team", "N"), hpa: "View Summary"
        ))

        cards.append(createCard(
            id: "missing8", type: .mail, priority: .low,
            title: "Image Attachment: Event Photos",
            summary: "Photos from last week's company event are here! Download and share your favorites. High-resolution versions available.",
            actions: [("view_attachment", "View Photos", true), ("download_all", "Download All", false)],
            sender: ("Events Team", "E"), hpa: "View Photos"
        ))

        // MARK: - HEALTHCARE (5 cards)
        cards.append(createCard(
            id: "healthcare1", type: .mail, priority: .high,
            title: "Your Prescription is Ready for Pickup",
            summary: "Your prescription for Amoxicillin 500mg is ready at CVS Pharmacy (Main St). Pick up by November 20th. Qty: 30 tablets.",
            actions: [("pickup_prescription", "View Pickup Details", true), ("schedule_appointment", "Schedule Consult", false), ("get_directions", "Get Directions", false)],
            sender: ("CVS Pharmacy", "C"), hpa: "View Pickup Details"
        ))

        cards.append(createCard(
            id: "healthcare2", type: .mail, priority: .high,
            title: "Lab Results Available",
            summary: "Your recent lab test results are now available in your patient portal. Dr. Chen will review them with you at your next visit.",
            actions: [("view_results", "View Results", true), ("schedule_appointment", "Schedule Follow-up", false), ("add_to_notes", "Save to Notes", false)],
            sender: ("LabCorp", "L"), hpa: "View Results"
        ))

        cards.append(createCard(
            id: "healthcare3", type: .mail, priority: .medium,
            title: "Appointment Reminder: Dr. Smith",
            summary: "Reminder: You have an appointment with Dr. Smith tomorrow at 2:00 PM. Arrive 15 minutes early. Location: Medical Center, Suite 305.",
            actions: [("check_in_appointment", "Check In", true), ("get_directions", "Get Directions", false), ("add_to_calendar", "Add to Calendar", false)],
            sender: ("City Medical Center", "M"), hpa: "Check In"
        ))

        cards.append(createCard(
            id: "healthcare4", type: .mail, priority: .medium,
            title: "Annual Physical Due",
            summary: "It's time for your annual physical exam! Schedule your appointment now. We have openings in early December.",
            actions: [("schedule_appointment", "Schedule Now", true), ("add_reminder", "Remind Me Later", false)],
            sender: ("Dr. Johnson", "D"), hpa: "Schedule Now"
        ))

        cards.append(createCard(
            id: "healthcare5", type: .mail, priority: .low,
            title: "Insurance Claim Processed",
            summary: "Your insurance claim #IC-4782 has been processed. Amount covered: $450.00. Your responsibility: $50.00 copay.",
            actions: [("view_claim_details", "View Claim", true), ("pay_invoice", "Pay Copay", false), ("download_receipt", "Download", false)],
            sender: ("Blue Cross", "B"), hpa: "View Claim"
        ))

        // MARK: - CAREER (4 cards)
        cards.append(createCard(
            id: "career1", type: .mail, priority: .high,
            title: "Job Offer: Senior iOS Engineer at Acme Corp",
            summary: "Congratulations! We're excited to extend you an offer for the Senior iOS Engineer position. Salary: $165K. Benefits start day 1. Please respond by November 22nd.",
            actions: [("accept_offer", "Accept Offer", true), ("schedule_interview", "Schedule Call", false), ("add_to_notes", "Save Details", false)],
            sender: ("Acme Corp HR", "A"), hpa: "Accept Offer"
        ))

        cards.append(createCard(
            id: "career2", type: .mail, priority: .medium,
            title: "Interview Scheduled: Product Manager Role",
            summary: "Your interview is confirmed for November 19th at 10:00 AM via Zoom. You'll meet with the hiring manager and 2 team members. Duration: 90 minutes.",
            actions: [("join_meeting", "Join Zoom", true), ("add_to_calendar", "Add to Calendar", false), ("get_directions", "View Details", false)],
            sender: ("TechStart Recruiting", "T"), hpa: "Join Zoom"
        ))

        cards.append(createCard(
            id: "career3", type: .mail, priority: .medium,
            title: "Application Status Update",
            summary: "Your application for the Data Scientist position has moved to the next round! We'll be in touch soon to schedule your technical interview.",
            actions: [("check_application_status", "View Status", true), ("quick_reply", "Send Thank You", false)],
            sender: ("DataCo Talent", "D"), hpa: "View Status"
        ))

        cards.append(createCard(
            id: "career4", type: .mail, priority: .low,
            title: "LinkedIn: 5 New Job Matches",
            summary: "Based on your profile, we found 5 new job opportunities that match your skills: Senior Engineer roles at Google, Apple, and 3 other companies.",
            actions: [("view_job_listings", "View Jobs", true), ("save_for_later", "Save for Later", false)],
            sender: ("LinkedIn Jobs", "L"), hpa: "View Jobs"
        ))

        // MARK: - CIVIC (3 cards)
        cards.append(createCard(
            id: "civic1", type: .mail, priority: .high,
            title: "Jury Duty Summons",
            summary: "You have been summoned for jury duty on December 5th, 2025 at 8:00 AM. Superior Court of California, Room 302. Please confirm your attendance.",
            actions: [("view_jury_summons", "View Summons", true), ("confirm_court_appearance", "Confirm Attendance", false), ("add_to_calendar", "Add to Calendar", false)],
            sender: ("Superior Court", "S"), hpa: "View Summons"
        ))

        cards.append(createCard(
            id: "civic2", type: .mail, priority: .medium,
            title: "Voter Registration Confirmation",
            summary: "Your voter registration has been confirmed! You're registered to vote in District 3. View your ballot and polling location for the upcoming election.",
            actions: [("view_voter_info", "View Polling Place", true), ("view_ballot", "View Sample Ballot", false), ("add_to_calendar", "Add Election Date", false)],
            sender: ("County Registrar", "C"), hpa: "View Polling Place"
        ))

        cards.append(createCard(
            id: "civic3", type: .mail, priority: .high,
            title: "Property Tax Payment Due",
            summary: "Your property tax payment of $4,250.00 is due by December 10th. Pay online to avoid penalties. Property ID: 123-456-789-000.",
            actions: [("pay_property_tax", "Pay Now", true), ("view_tax_notice", "View Details", false), ("add_reminder", "Set Reminder", false)],
            sender: ("County Tax Collector", "T"), hpa: "Pay Now"
        ))

        // MARK: - SOCIAL (4 cards)
        cards.append(createCard(
            id: "social1", type: .mail, priority: .medium,
            title: "You're Invited: Sarah's Birthday Party",
            summary: "Join us for Sarah's surprise 30th birthday party on November 22nd at 7 PM! Location: The Garden Restaurant. Please RSVP by November 18th.",
            actions: [("rsvp_yes", "RSVP Yes", true), ("rsvp_no", "RSVP No", false), ("add_to_calendar", "Add to Calendar", false)],
            sender: ("Mike Chen", "M"), hpa: "RSVP Yes"
        ))

        cards.append(createCard(
            id: "social2", type: .mail, priority: .medium,
            title: "Meetup Reminder: Tech Talk Tomorrow",
            summary: "Don't forget: iOS Development Meetup tomorrow at 6:30 PM. Topic: SwiftUI Best Practices. Location: TechHub Coworking, 5th Floor.",
            actions: [("join_meeting", "View Event", true), ("get_directions", "Get Directions", false), ("reply_thanks", "Send Thanks", false)],
            sender: ("Meetup.com", "M"), hpa: "View Event"
        ))

        cards.append(createCard(
            id: "social3", type: .mail, priority: .low,
            title: "LinkedIn: Alex wants to connect",
            summary: "Alex Martinez (Product Manager at Google) wants to connect with you on LinkedIn. You have 12 mutual connections.",
            actions: [("accept_social_invitation", "Accept", true), ("view_social_message", "View Profile", false)],
            sender: ("LinkedIn", "L"), hpa: "Accept"
        ))

        cards.append(createCard(
            id: "social4", type: .mail, priority: .low,
            title: "Facebook: Reunion Event This Weekend",
            summary: "Stanford Class of 2015 Reunion - This Saturday at 2 PM. 47 people are going. Alumni Center, Main Quad.",
            actions: [("rsvp_yes", "I'm Going", true), ("get_directions", "Get Directions", false), ("share_achievement", "Share", false)],
            sender: ("Facebook Events", "F"), hpa: "I'm Going"
        ))

        // MARK: - FINANCE (3 cards)
        cards.append(createCard(
            id: "finance1", type: .mail, priority: .high,
            title: "Suspicious Transaction Alert",
            summary: "We detected a potentially fraudulent transaction on your Chase card: $847.52 at Electronics Store in Miami. If this wasn't you, dispute immediately.",
            actions: [("verify_transaction", "Verify Transaction", true), ("dispute_transaction", "Report Fraud", false), ("contact_support", "Call Bank", false)],
            sender: ("Chase Fraud Alert", "C"), hpa: "Verify Transaction"
        ))

        cards.append(createCard(
            id: "finance2", type: .mail, priority: .medium,
            title: "Your Tax Documents Are Ready",
            summary: "Your 2024 tax documents (W-2, 1099) are now available for download. Access them securely through your account portal.",
            actions: [("download_tax_document", "Download Documents", true), ("view_statement", "View Summary", false), ("add_to_notes", "Save Info", false)],
            sender: ("E*TRADE", "E"), hpa: "Download Documents"
        ))

        cards.append(createCard(
            id: "finance3", type: .mail, priority: .low,
            title: "Your Credit Score Increased!",
            summary: "Good news! Your credit score increased by 15 points to 785 this month. View your full credit report and see what improved.",
            actions: [("view_credit_report", "View Report", true), ("view_portfolio", "View Factors", false)],
            sender: ("Credit Karma", "C"), hpa: "View Report"
        ))

        // Cache and return
        cachedMockData = cards
        UserDefaults.standard.set(cacheVersion, forKey: "mockDataCacheVersion")
        Logger.info("Generated \(cards.count) mock emails (cached for performance, version: \(cacheVersion))", category: .service)
        return cards
    }

    // MARK: - Helper: Create Email Card Template
    private static func createCard(
        id: String,
        type: CardType,
        priority: Priority,
        title: String,
        summary: String,
        actions: [(actionId: String, displayName: String, isPrimary: Bool)],
        sender: (name: String, initial: String),
        hpa: String,
        productImageUrl: String? = nil,
        brandName: String? = nil,
        originalPrice: Double? = nil,
        salePrice: Double? = nil,
        discount: Int? = nil
    ) -> EmailCard {
        let emailActions = actions.enumerated().map { index, action in
            // Determine action type based on actionId
            let actionType: ActionType = {
                // GO_TO actions (open external URLs)
                if action.actionId.contains("shop") ||
                   action.actionId.contains("view_website") ||
                   action.actionId.contains("view_deals") ||
                   action.actionId.contains("browse") ||
                   action.actionId == "rsvp" {
                    return .goTo
                }
                // IN_APP actions (modals)
                return .inApp
            }()

            return EmailAction(
                actionId: action.actionId,
                displayName: action.displayName,
                actionType: actionType,
                isPrimary: action.isPrimary,
                priority: index + 1
            )
        }

        return EmailCard(
            id: id,
            type: type,
            state: .unseen,
            priority: priority,
            hpa: hpa,
            timeAgo: timeAgoString(),
            title: title,
            summary: summary,
            aiGeneratedSummary: generateAISummary(title: title, summary: summary, actions: actions),
            body: generateBody(title: title, summary: summary),
            htmlBody: nil,
            metaCTA: "Swipe Right: \(hpa)",
            intent: inferIntent(from: actions.first?.actionId ?? ""),
            intentConfidence: 0.92,
            suggestedActions: emailActions,
            sender: SenderInfo(name: sender.name, initial: sender.initial, email: nil),
            kid: nil,
            company: nil,
            store: nil,
            airline: nil,
            productImageUrl: productImageUrl,
            brandName: brandName,
            originalPrice: originalPrice,
            salePrice: salePrice,
            discount: discount,
            urgent: priority == .high,
            expiresIn: nil,
            requiresSignature: nil,
            paymentAmount: nil,
            paymentDescription: nil,
            value: nil,
            probability: nil,
            score: nil
        )
    }

    // MARK: - Helper: Generate AI Summary
    private static func generateAISummary(title: String, summary: String, actions: [(actionId: String, displayName: String, isPrimary: Bool)]) -> String {
        let actionList = actions.map { "• \($0.displayName)" }.joined(separator: "\n")
        return """
        **Actions:**
        \(actionList)

        **Context:**
        \(summary)
        """
    }

    // MARK: - Helper: Generate Email Body
    private static func generateBody(title: String, summary: String) -> String {
        return """
        \(title)

        \(summary)

        This is a simulated email generated for development and testing purposes.
        """
    }

    // MARK: - Helper: Infer Intent from Action ID
    private static func inferIntent(from actionId: String) -> String {
        let intentMap: [String: String] = [
            "view_newsletter_summary": "generic.newsletter",
            "sign_form": "education.permission.sign",
            "schedule_meeting": "education.meeting.schedule",
            "track_package": "shopping.delivery.track",
            "shop": "shopping.browse",
            "write_review": "shopping.review",
            "pay_invoice": "billing.payment.pay",
            "verify_account": "account.verification",
            "check_in": "travel.flight.checkin",
            "view_reservation": "travel.hotel.reservation",
            "approve_request": "project.approval.request",
            "enroll": "learning.course.enroll"
        ]
        return intentMap[actionId] ?? "generic.action"
    }

    // MARK: - Helper: Random Time Ago
    private static func timeAgoString() -> String {
        let options = ["5m ago", "23m ago", "1h ago", "2h ago", "5h ago", "1d ago", "2d ago"]
        return options.randomElement() ?? "1h ago"
    }
}
