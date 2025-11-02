import Foundation

// MARK: - Email Card Model
struct EmailCard: Identifiable, Codable {
    let id: String
    let type: CardType
    var state: CardState
    var priority: Priority  // Changed to var to allow user updates
    let hpa: String
    let timeAgo: String
    let title: String
    let summary: String
    var aiGeneratedSummary: String?  // AI-synthesized summary (var for lazy loading)
    let body: String?  // Full email body text
    let htmlBody: String?  // Original HTML email content
    let metaCTA: String

    // THREAD DATA (v1.6) - Loaded on-demand
    let threadLength: Int?  // Message count (from initial load, no API call)
    var threadData: ThreadData?  // var because loaded lazily

    // ACTION-FIRST MODEL (v1.1)
    let intent: String?  // Intent ID (e.g., 'e-commerce.shipping.notification')
    let intentConfidence: Double?  // 0-1 confidence score
    let suggestedActions: [EmailAction]?  // Array of suggested actions

    // Computed property for backward compatibility - returns the primary action's ID
    var suggestedAction: String {
        return suggestedActions?.first(where: { $0.isPrimary })?.actionId ?? "view_document"
    }

    let sender: SenderInfo?
    let recipientEmail: String?  // Email account this was delivered to
    let kid: KidInfo?
    let company: CompanyInfo?
    let store: String?
    let airline: String?
    let productImageUrl: String?
    let brandName: String?
    let originalPrice: Double?
    let salePrice: Double?
    let discount: Int?
    let urgent: Bool?
    let expiresIn: String?
    let requiresSignature: Bool?
    let paymentAmount: Double?
    let paymentDescription: String?
    let value: String?
    let probability: Int?
    let score: Int?

    // Parent/School Mode fields (v2.0)
    let isSchoolEmail: Bool?
    let isVIP: Bool?
    let deadline: DeadlineInfo?
    let teacher: String?
    let school: String?

    // Newsletter Mode fields (v2.0)
    let isNewsletter: Bool?
    let unsubscribeUrl: String?
    let keyLinks: [NewsletterLink]?  // v2.1+ Rich newsletter links from backend
    let keyTopics: [String]?  // v2.1+ Newsletter topics for filtering

    // Shopping Mode fields (v2.0)
    let isShoppingEmail: Bool?
    let trackingNumber: String?
    let orderNumber: String?

    // Subscription Mode fields (v2.0)
    let isSubscription: Bool?
    let subscriptionAmount: Double?
    let subscriptionFrequency: String?  // "monthly" or "annual"
    let cancellationUrl: String?

    // Calendar Invite fields
    let calendarInvite: CalendarInvite?

    // Attachment fields (v2.1)
    let hasAttachments: Bool?
    let attachments: [EmailAttachment]?

    // Default initializer with v1.6 fields optional
    init(
        id: String,
        type: CardType,
        state: CardState,
        priority: Priority,
        hpa: String,
        timeAgo: String,
        title: String,
        summary: String,
        aiGeneratedSummary: String? = nil,
        body: String? = nil,
        htmlBody: String? = nil,
        metaCTA: String,
        threadLength: Int? = nil,
        threadData: ThreadData? = nil,
        intent: String? = nil,
        intentConfidence: Double? = nil,
        suggestedActions: [EmailAction]? = nil,
        sender: SenderInfo? = nil,
        recipientEmail: String? = nil,
        kid: KidInfo? = nil,
        company: CompanyInfo? = nil,
        store: String? = nil,
        airline: String? = nil,
        productImageUrl: String? = nil,
        brandName: String? = nil,
        originalPrice: Double? = nil,
        salePrice: Double? = nil,
        discount: Int? = nil,
        urgent: Bool? = nil,
        expiresIn: String? = nil,
        requiresSignature: Bool? = nil,
        paymentAmount: Double? = nil,
        paymentDescription: String? = nil,
        value: String? = nil,
        probability: Int? = nil,
        score: Int? = nil,
        isSchoolEmail: Bool? = nil,
        isVIP: Bool? = nil,
        deadline: DeadlineInfo? = nil,
        teacher: String? = nil,
        school: String? = nil,
        isNewsletter: Bool? = nil,
        unsubscribeUrl: String? = nil,
        keyLinks: [NewsletterLink]? = nil,
        keyTopics: [String]? = nil,
        isShoppingEmail: Bool? = nil,
        trackingNumber: String? = nil,
        orderNumber: String? = nil,
        isSubscription: Bool? = nil,
        subscriptionAmount: Double? = nil,
        subscriptionFrequency: String? = nil,
        cancellationUrl: String? = nil,
        calendarInvite: CalendarInvite? = nil,
        hasAttachments: Bool? = nil,
        attachments: [EmailAttachment]? = nil
    ) {
        self.id = id
        self.type = type
        self.state = state
        self.priority = priority
        self.hpa = hpa
        self.timeAgo = timeAgo
        self.title = title
        self.summary = summary
        self.aiGeneratedSummary = aiGeneratedSummary
        self.body = body
        self.htmlBody = htmlBody
        self.metaCTA = metaCTA
        self.threadLength = threadLength
        self.threadData = threadData
        self.intent = intent
        self.intentConfidence = intentConfidence
        self.suggestedActions = suggestedActions
        self.sender = sender
        self.recipientEmail = recipientEmail
        self.kid = kid
        self.company = company
        self.store = store
        self.airline = airline
        self.productImageUrl = productImageUrl
        self.brandName = brandName
        self.originalPrice = originalPrice
        self.salePrice = salePrice
        self.discount = discount
        self.urgent = urgent
        self.expiresIn = expiresIn
        self.requiresSignature = requiresSignature
        self.paymentAmount = paymentAmount
        self.paymentDescription = paymentDescription
        self.value = value
        self.probability = probability
        self.score = score
        self.isSchoolEmail = isSchoolEmail
        self.isVIP = isVIP
        self.deadline = deadline
        self.teacher = teacher
        self.school = school
        self.isNewsletter = isNewsletter
        self.unsubscribeUrl = unsubscribeUrl
        self.keyLinks = keyLinks
        self.keyTopics = keyTopics
        self.isShoppingEmail = isShoppingEmail
        self.trackingNumber = trackingNumber
        self.orderNumber = orderNumber
        self.isSubscription = isSubscription
        self.subscriptionAmount = subscriptionAmount
        self.subscriptionFrequency = subscriptionFrequency
        self.cancellationUrl = cancellationUrl
        self.calendarInvite = calendarInvite
        self.hasAttachments = hasAttachments
        self.attachments = attachments
    }

    // MARK: - Newsletter Link Model (v2.1) - Nested Type
    struct NewsletterLink: Codable, Identifiable {
        let id: String  // Generated from URL or index
        let title: String
        let url: String
        let description: String?

        init(id: String? = nil, title: String, url: String, description: String? = nil) {
            self.id = id ?? url  // Use URL as ID if not provided
            self.title = title
            self.url = url
            self.description = description
        }
    }
}

// MARK: - Email Attachment Model (v2.1)
struct EmailAttachment: Codable, Identifiable {
    let id: String  // attachmentId from Gmail
    let filename: String
    let mimeType: String
    let size: Int
    let messageId: String?  // Parent message ID for fetching

    init(id: String, filename: String, mimeType: String, size: Int, messageId: String? = nil) {
        self.id = id
        self.filename = filename
        self.mimeType = mimeType
        self.size = size
        self.messageId = messageId
    }

    // Computed property for human-readable file size
    var fileSizeFormatted: String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useKB, .useMB, .useGB]
        formatter.countStyle = .file
        return formatter.string(fromByteCount: Int64(size))
    }

    // Computed property for file type icon
    var fileIcon: String {
        if mimeType.contains("pdf") {
            return "doc.fill"
        } else if mimeType.contains("image") {
            return "photo.fill"
        } else if mimeType.contains("word") || mimeType.contains("document") {
            return "doc.text.fill"
        } else if mimeType.contains("excel") || mimeType.contains("spreadsheet") {
            return "tablecells.fill"
        } else if mimeType.contains("zip") || mimeType.contains("archive") {
            return "doc.zipper"
        } else {
            return "paperclip"
        }
    }
}

// MARK: - Calendar Invite Model
struct CalendarInvite: Codable {
    let platform: String?
    let meetingUrl: String?
    let meetingTime: String?
    let meetingTitle: String?
    let organizer: String?
    let hasAcceptDecline: Bool?
}

// MARK: - Deadline Info (Parent Mode)
struct DeadlineInfo: Codable {
    let text: String
    let value: Int?
    let unit: String?
    let isUrgent: Bool
    let daysRemaining: Int?
}

// MARK: - Email Action Model (v1.1)
struct EmailAction: Identifiable, Codable {
    let id: String  // Same as actionId for Identifiable conformance
    let actionId: String
    let displayName: String
    let actionType: ActionType
    let isPrimary: Bool
    let priority: Int?
    let context: [String: String]?  // Entity values for this action (trackingNumber, etc.)
    let isCompound: Bool?
    let compoundSteps: [String]?

    // Regular initializer for mock data
    init(actionId: String, displayName: String, actionType: ActionType, isPrimary: Bool, priority: Int? = nil, context: [String: String]? = nil, isCompound: Bool? = nil, compoundSteps: [String]? = nil) {
        self.actionId = actionId
        self.id = actionId
        self.displayName = displayName
        self.actionType = actionType
        self.isPrimary = isPrimary
        self.priority = priority
        self.context = context
        self.isCompound = isCompound
        self.compoundSteps = compoundSteps
    }

    enum CodingKeys: String, CodingKey {
        case actionId, displayName, actionType, isPrimary, priority, context, isCompound, compoundSteps
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        // Decode actionId first (required), or throw if missing
        let decodedActionId = try container.decode(String.self, forKey: .actionId)
        self.actionId = decodedActionId
        self.id = decodedActionId  // Use actionId as id

        // Decode displayName with fallback to actionId (handle missing displayName gracefully)
        if let decodedDisplayName = try container.decodeIfPresent(String.self, forKey: .displayName), !decodedDisplayName.isEmpty {
            self.displayName = decodedDisplayName
        } else {
            // Fallback: Generate human-readable name from actionId
            self.displayName = decodedActionId
                .replacingOccurrences(of: "_", with: " ")
                .split(separator: " ")
                .map { $0.prefix(1).uppercased() + $0.dropFirst().lowercased() }
                .joined(separator: " ")
        }

        self.actionType = try container.decode(ActionType.self, forKey: .actionType)
        self.isPrimary = try container.decode(Bool.self, forKey: .isPrimary)
        self.priority = try container.decodeIfPresent(Int.self, forKey: .priority)
        self.context = try container.decodeIfPresent([String: String].self, forKey: .context)
        self.isCompound = try container.decodeIfPresent(Bool.self, forKey: .isCompound)
        self.compoundSteps = try container.decodeIfPresent([String].self, forKey: .compoundSteps)
    }
}

enum ActionType: String, Codable {
    case goTo = "GO_TO"
    case inApp = "IN_APP"
}

struct SenderInfo: Codable {
    let name: String
    let initial: String
    let email: String?
}

struct KidInfo: Codable {
    let name: String
    let initial: String
    let grade: String
}

struct CompanyInfo: Codable {
    let name: String
    let initials: String
}

enum CardType: String, Codable {
    // Binary Classification (v2.0 - Clean Architecture)
    case mail        // All non-promotional emails
    case ads         // Marketing, promotions, newsletters

    var displayName: String {
        switch self {
        case .mail: return "Mail"
        case .ads: return "Ads"
        }
    }
}

// MARK: - CaseIterable Conformance
extension CardType: CaseIterable {
    static var allCases: [CardType] {
        return [.mail, .ads]
    }
}

enum CardState: String, Codable {
    case unseen, seen, dismissed, snoozed, actioned, replied
}

enum Priority: String, Codable, CaseIterable {
    case critical, high, medium, low

    /// Display name for UI
    var displayName: String {
        switch self {
        case .critical: return "Critical"
        case .high: return "High"
        case .medium: return "Normal"
        case .low: return "Low"
        }
    }

    /// Icon for priority (SF Symbol)
    var icon: String {
        switch self {
        case .critical: return "exclamationmark.3"
        case .high: return "exclamationmark.2"
        case .medium: return "minus"
        case .low: return "arrow.down"
        }
    }

    /// Color for priority badge
    var color: String {
        switch self {
        case .critical: return "#FF3B30"  // Red
        case .high: return "#FF9500"      // Orange
        case .medium: return "#8E8E93"    // Gray
        case .low: return "#5AC8FA"       // Light Blue
        }
    }
}

enum AppState: Equatable {
    case splash, onboarding, feed, miniCelebration(CardType), celebration
}

enum SwipeDirection {
    case left, right, down, up
}

// MARK: - Thread Data Models (v1.6)

struct ThreadData: Codable {
    let messages: [ThreadMessage]
    let context: ThreadContext
    let messageCount: Int
}

struct ThreadMessage: Codable, Identifiable {
    let id: String
    let from: String
    let date: String
    let body: String
    let isLatest: Bool
}

struct ThreadContext: Codable {
    let purchases: [Purchase]
    let upcomingEvents: [Event]
    let locations: [Location]
    let unresolvedQuestions: [UnresolvedQuestion]
    let conversationStage: String?
}

struct Purchase: Codable, Identifiable {
    var id: String { messageId }
    let invoiceNumber: String?
    let amount: Double?
    let date: String
    let messageId: String
}

struct Event: Codable, Identifiable {
    var id: String { date + originalText }
    let date: String
    let originalText: String
    let context: String?
}

struct Location: Codable, Identifiable {
    var id: String { (address ?? "") + (phone ?? "") }
    let address: String?
    let phone: String?
    let messageId: String
}

struct UnresolvedQuestion: Codable, Identifiable {
    var id: String { date + question }
    let question: String
    let askedBy: String
    let date: String
}

// MARK: - Search Result Model

struct SearchResult: Codable, Identifiable {
    var id: String { threadId }
    let threadId: String
    let messageCount: Int
    let latestEmail: SearchEmailPreview
    let allMessages: [SearchMessagePreview]
}

struct SearchEmailPreview: Codable {
    let id: String
    let type: CardType
    let state: CardState
    let priority: Priority
    let hpa: String
    let timeAgo: String
    let title: String
    let summary: String
    let sender: SenderInfo?
    let threadLength: Int
}

struct SearchMessagePreview: Codable, Identifiable {
    let id: String
    let type: CardType
    let state: CardState
    let priority: Priority
    let hpa: String
    let timeAgo: String
    let title: String
    let summary: String
    let sender: SenderInfo?
    let threadLength: Int
}

// MARK: - Admin Feedback Models (v1.6)

struct ClassifiedEmail: Identifiable, Codable {
    let id: String
    let from: String
    let subject: String
    let snippet: String
    let timeAgo: String
    let classifiedType: CardType
    let priority: Priority
    let confidence: Double
}

struct ClassificationFeedback: Codable {
    let emailId: String
    let originalType: CardType
    let correctedType: CardType?
    let isCorrect: Bool
    let confidence: Double
    let notes: String?
    let timestamp: Date
}

// MARK: - Action Feedback Models (v1.8)

struct ClassifiedEmailWithActions: Identifiable, Codable {
    let id: String
    let from: String
    let subject: String
    let snippet: String
    let timeAgo: String
    let intent: String
    let suggestedActions: [EmailAction]
    let confidence: Double
}

struct ActionFeedback: Codable {
    let emailId: String
    let intent: String
    let originalActions: [String]  // Array of action IDs
    let correctedActions: [String]?  // Corrected action IDs (if incorrect)
    let isCorrect: Bool
    let missedActions: [String]?  // Actions that should have been suggested
    let unnecessaryActions: [String]?  // Actions that shouldn't have been suggested
    let confidence: Double
    let notes: String?
    let timestamp: Date
}

