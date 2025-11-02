import Foundation

/// Represents a reusable email reply template
struct ReplyTemplate: Identifiable, Codable, Equatable {
    let id: String
    var name: String
    var content: String
    var category: TemplateCategory
    var isBuiltIn: Bool
    var createdAt: Date
    var usageCount: Int

    init(id: String = UUID().uuidString,
         name: String,
         content: String,
         category: TemplateCategory,
         isBuiltIn: Bool = false,
         createdAt: Date = Date(),
         usageCount: Int = 0) {
        self.id = id
        self.name = name
        self.content = content
        self.category = category
        self.isBuiltIn = isBuiltIn
        self.createdAt = createdAt
        self.usageCount = usageCount
    }
}

enum TemplateCategory: String, Codable, CaseIterable {
    case confirmation = "Confirmation"
    case thankYou = "Thank You"
    case followUp = "Follow Up"
    case approval = "Approval"
    case outOfOffice = "Out of Office"
    case general = "General"
    case custom = "Custom"

    var icon: String {
        switch self {
        case .confirmation: return "checkmark.circle"
        case .thankYou: return "hand.thumbsup"
        case .followUp: return "arrow.turn.up.right"
        case .approval: return "checkmark.seal"
        case .outOfOffice: return "airplane"
        case .general: return "text.bubble"
        case .custom: return "star"
        }
    }
}

/// Pre-built templates that ship with the app
struct BuiltInTemplates {
    static let all: [ReplyTemplate] = [
        // Confirmations
        ReplyTemplate(
            name: "Quick Confirm",
            content: "Confirmed! Thanks for letting me know.",
            category: .confirmation,
            isBuiltIn: true
        ),
        ReplyTemplate(
            name: "Will Attend",
            content: "Yes, I'll be there. Looking forward to it!",
            category: .confirmation,
            isBuiltIn: true
        ),
        ReplyTemplate(
            name: "Got It",
            content: "Got it, thanks!",
            category: .confirmation,
            isBuiltIn: true
        ),

        // Thank You
        ReplyTemplate(
            name: "Thanks",
            content: "Thank you!",
            category: .thankYou,
            isBuiltIn: true
        ),
        ReplyTemplate(
            name: "Appreciate It",
            content: "I really appreciate this. Thank you for your help!",
            category: .thankYou,
            isBuiltIn: true
        ),
        ReplyTemplate(
            name: "Thanks for Update",
            content: "Thanks for the update!",
            category: .thankYou,
            isBuiltIn: true
        ),

        // Follow Up
        ReplyTemplate(
            name: "Will Follow Up",
            content: "Got it. I'll follow up shortly.",
            category: .followUp,
            isBuiltIn: true
        ),
        ReplyTemplate(
            name: "Need More Info",
            content: "Thanks for reaching out. Could you provide more details?",
            category: .followUp,
            isBuiltIn: true
        ),
        ReplyTemplate(
            name: "Checking In",
            content: "Just checking in on this. Let me know if you need anything!",
            category: .followUp,
            isBuiltIn: true
        ),

        // Approval
        ReplyTemplate(
            name: "Approved",
            content: "Approved! Please proceed.",
            category: .approval,
            isBuiltIn: true
        ),
        ReplyTemplate(
            name: "Looks Good",
            content: "This looks great. You have my approval!",
            category: .approval,
            isBuiltIn: true
        ),

        // Out of Office
        ReplyTemplate(
            name: "Out Today",
            content: "I'm out of the office today. I'll respond when I return. Thanks!",
            category: .outOfOffice,
            isBuiltIn: true
        ),
        ReplyTemplate(
            name: "Limited Access",
            content: "I have limited email access right now. I'll get back to you as soon as possible.",
            category: .outOfOffice,
            isBuiltIn: true
        ),

        // General
        ReplyTemplate(
            name: "Sounds Good",
            content: "Sounds good to me!",
            category: .general,
            isBuiltIn: true
        ),
        ReplyTemplate(
            name: "Will Do",
            content: "Will do!",
            category: .general,
            isBuiltIn: true
        ),
        ReplyTemplate(
            name: "No Problem",
            content: "No problem at all!",
            category: .general,
            isBuiltIn: true
        )
    ]
}
