import SwiftUI

struct FlashFeedback: View {
    let type: FeedbackType
    let onComplete: () -> Void
    
    @State private var scale: CGFloat = 0.5
    @State private var opacity: Double = 0
    
    var body: some View {
        ZStack {
            // Semi-transparent background
            Color.black.opacity(0.4)
                .ignoresSafeArea()
            
            // Feedback icon and text
            VStack(spacing: 20) {
                ZStack {
                    Circle()
                        .fill(type.color.opacity(0.2))
                        .frame(width: 120, height: 120)
                    
                    Circle()
                        .fill(type.color.opacity(0.4))
                        .frame(width: 100, height: 100)
                    
                    Image(systemName: type.icon)
                        .font(.system(size: 50, weight: .bold))
                        .foregroundColor(.white)
                }
                
                Text(type.message)
                    .font(.title3.bold())
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
            }
            .scaleEffect(scale)
            .opacity(opacity)
        }
        .onAppear {
            // Animate in
            withAnimation(.spring(response: 0.4, dampingFraction: 0.6)) {
                scale = 1.0
                opacity = 1.0
            }
            
            // Haptic
            let impact = UINotificationFeedbackGenerator()
            impact.notificationOccurred(type.hapticType)
            
            // Animate out
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                withAnimation(.easeOut(duration: 0.3)) {
                    scale = 1.2
                    opacity = 0
                }
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    onComplete()
                }
            }
        }
    }
}

enum FeedbackType {
    case seen, actioned, snoozed, dismissed, success, error
    
    var icon: String {
        switch self {
        case .seen: return "eye.fill"
        case .actioned: return "bolt.fill"
        case .snoozed: return "moon.zzz.fill"
        case .dismissed: return "xmark.circle.fill"
        case .success: return "checkmark.circle.fill"
        case .error: return "exclamationmark.triangle.fill"
        }
    }
    
    var color: Color {
        switch self {
        case .seen: return .blue
        case .actioned: return .green
        case .snoozed: return .purple
        case .dismissed: return .red
        case .success: return .green
        case .error: return .red
        }
    }
    
    var message: String {
        switch self {
        case .seen: return "Marked as Seen"
        case .actioned: return "Action Taken!"
        case .snoozed: return "Snoozed"
        case .dismissed: return "Dismissed"
        case .success: return "Success!"
        case .error: return "Error"
        }
    }
    
    var hapticType: UINotificationFeedbackGenerator.FeedbackType {
        switch self {
        case .success, .actioned: return .success
        case .error: return .error
        default: return .success
        }
    }
}

#Preview("Success") {
    FlashFeedback(type: .success, onComplete: {})
}

#Preview("Actioned") {
    FlashFeedback(type: .actioned, onComplete: {})
}

#Preview("Snoozed") {
    FlashFeedback(type: .snoozed, onComplete: {})
}

