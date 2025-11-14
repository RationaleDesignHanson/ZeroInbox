import SwiftUI

struct UndoToast: View {
    let action: String
    let onUndo: () -> Void
    let onDismiss: () -> Void
    
    @State private var opacity: Double = 0
    @State private var offset: CGFloat = 20
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: actionIcon)
                .foregroundColor(.white)
            
            Text(action)
                .font(.subheadline.bold())
                .foregroundColor(.white)
            
            Spacer()
            
            Button {
                onUndo()
            } label: {
                Text("UNDO")
                    .font(.subheadline.bold())
                    .foregroundColor(.yellow)
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.black.opacity(0.85))
                .shadow(color: .black.opacity(DesignTokens.Opacity.overlayMedium), radius: 10, y: 5)
        )
        .padding(.horizontal, 20)
        .opacity(opacity)
        .offset(y: offset)
        .onAppear {
            // Slide up with bouncy spring
            withAnimation(.spring(response: 0.45, dampingFraction: 0.7, blendDuration: 0.1)) {
                opacity = 1
                offset = 0
            }
            
            // Subtle haptic
            let impact = UIImpactFeedbackGenerator(style: .light)
            impact.prepare()
            impact.impactOccurred()
            
            // Auto-dismiss after 6 seconds (extended for better UX)
            DispatchQueue.main.asyncAfter(deadline: .now() + 6) {
                withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                    opacity = 0
                    offset = -20
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    onDismiss()
                }
            }
        }
    }
    
    var actionIcon: String {
        switch action {
        case let str where str.contains("Seen"):
            return "eye.fill"
        case let str where str.contains("Action"):
            return "bolt.fill"
        case let str where str.contains("Snoozed"):
            return "moon.zzz.fill"
        case let str where str.contains("Dismissed"):
            return "xmark.circle.fill"
        default:
            return "checkmark.circle.fill"
        }
    }
}

#Preview {
    ZStack {
        Color.gray
            .ignoresSafeArea()

        VStack {
            Spacer()
            UndoToast(
                action: "Marked as Seen",
                onUndo: {},
                onDismiss: {}
            )
            .padding(.bottom, 50)
        }
    }
}

