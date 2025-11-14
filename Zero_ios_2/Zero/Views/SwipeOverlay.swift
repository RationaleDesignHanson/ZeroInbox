import SwiftUI

struct SwipeOverlay: View {
    let direction: SwipeDirection
    let distance: CGFloat
    
    var actionText: String {
        switch direction {
        case .right: return "TAKE ACTION"
        case .left: return "MARK AS READ"
        case .down: return "SNOOZE"
        case .up: return "CHANGE ACTION"
        }
    }

    var iconName: String {
        switch direction {
        case .right: return "bolt.fill"
        case .left: return "checkmark.circle.fill"
        case .down: return "moon.zzz.fill"
        case .up: return "arrow.triangle.2.circlepath"
        }
    }

    var overlayColor: Color {
        switch direction {
        case .right: return Color.green
        case .left: return Color.blue
        case .down: return Color.purple
        case .up: return Color.orange
        }
    }
    
    var body: some View {
        ZStack {
            // Gradient overlay based on swipe direction and distance
            if direction == .right {
                // Right swipe: Green gradient from left
                LinearGradient(
                    gradient: Gradient(colors: [
                        overlayColor.opacity(min(distance / 200, 0.5)),
                        Color.clear
                    ]),
                    startPoint: .leading,
                    endPoint: .trailing
                )
            } else if direction == .left {
                // Left swipe: Blue gradient from right
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color.clear,
                        overlayColor.opacity(min(distance / 200, 0.5))
                    ]),
                    startPoint: .leading,
                    endPoint: .trailing
                )
            } else if direction == .down {
                // Down swipe: Purple gradient from top
                LinearGradient(
                    gradient: Gradient(colors: [
                        overlayColor.opacity(min(distance / 200, 0.5)),
                        Color.clear
                    ]),
                    startPoint: .top,
                    endPoint: .bottom
                )
            } else {
                // Up swipe: Orange gradient from bottom
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color.clear,
                        overlayColor.opacity(min(distance / 200, 0.5))
                    ]),
                    startPoint: .top,
                    endPoint: .bottom
                )
            }
            
            // Action indicator positioned on swipe side
            if direction == .down || direction == .up {
                // Center for vertical swipes
                VStack {
                    if direction == .up {
                        Spacer()
                        actionIndicator
                            .padding(.bottom, 60)
                    } else {
                        actionIndicator
                            .padding(.top, 60)
                        Spacer()
                    }
                }
            } else {
                HStack {
                    if direction == .right {
                        // Show on left for right swipe
                        actionIndicator
                            .padding(.leading, 40)
                        Spacer()
                    } else {
                        // Show on right for left swipe
                        Spacer()
                        actionIndicator
                            .padding(.trailing, 40)
                    }
                }
            }
        }
        .allowsHitTesting(false)
    }
    
    var actionIndicator: some View {
        VStack(spacing: 16) {
            // Icon with simple pulsing animation
            ZStack {
                Circle()
                    .fill(overlayColor.opacity(DesignTokens.Opacity.overlayMedium))
                    .frame(width: 100, height: 100)

                Circle()
                    .fill(overlayColor.opacity(DesignTokens.Opacity.overlayStrong))
                    .frame(width: 80, height: 80)

                Image(systemName: iconName)
                    .font(.system(size: 40, weight: .bold))
                    .foregroundColor(.white)
            }

            // Action text
            Text(actionText)
                .font(.title3.bold())
                .foregroundColor(.white)
                .shadow(color: .black.opacity(DesignTokens.Opacity.overlayStrong), radius: 3)
                .multilineTextAlignment(.center)
        }
        .opacity(min(distance / 120, 1.0))
        .scaleEffect(min(distance / 120, 1.0))
        .animation(.easeOut(duration: 0.15), value: distance)
    }
}

#Preview("Right Swipe") {
    SwipeOverlay(direction: .right, distance: 150)
        .frame(width: 350, height: 500)
}

#Preview("Left Swipe") {
    SwipeOverlay(direction: .left, distance: 150)
        .frame(width: 350, height: 500)
}

#Preview("Down Swipe") {
    SwipeOverlay(direction: .down, distance: 150)
        .frame(width: 350, height: 500)
}

#Preview("Up Swipe") {
    SwipeOverlay(direction: .up, distance: 150)
        .frame(width: 350, height: 500)
}

