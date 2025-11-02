#if DEBUG
import SwiftUI

/// DEBUG-ONLY: UI annotation system for development collaboration
/// Adds visible labels to UI elements for clear communication
/// Never included in Release builds

// MARK: - Annotation State

/// Global state for annotation visibility
class AnnotationState: ObservableObject {
    @Published var isEnabled: Bool = false
    @Published var copiedName: String? = nil

    static let shared = AnnotationState()
}

// MARK: - Annotation Modifier

struct AnnotatedModifier: ViewModifier {
    let name: String
    let componentType: ComponentType
    @ObservedObject var state = AnnotationState.shared
    @State private var showCopied = false

    enum ComponentType {
        case interactive    // Buttons, toggles, inputs
        case layout         // Sections, containers, stacks
        case text           // Labels, titles, body text
        case status         // Badges, indicators, icons
        case decoration     // Backgrounds, dividers

        var color: Color {
            switch self {
            case .interactive: return .blue
            case .layout: return .purple
            case .text: return .green
            case .status: return .orange
            case .decoration: return .gray
            }
        }

        var icon: String {
            switch self {
            case .interactive: return "hand.tap.fill"
            case .layout: return "square.stack.3d.up.fill"
            case .text: return "textformat"
            case .status: return "circle.badge.fill"
            case .decoration: return "paintbrush.fill"
            }
        }
    }

    func body(content: Content) -> some View {
        ZStack(alignment: .top) {
            content

            if state.isEnabled {
                // Annotation label overlay
                HStack(spacing: 4) {
                    Image(systemName: componentType.icon)
                        .font(.system(size: 10))
                        .foregroundColor(.white)

                    Text(name)
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(.white)

                    if showCopied {
                        Image(systemName: "checkmark")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(.white)
                    }
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(
                    Capsule()
                        .fill(componentType.color.opacity(0.9))
                        .shadow(color: .black.opacity(0.3), radius: 3, y: 2)
                )
                .offset(y: -30)
                .zIndex(999)
                .onTapGesture {
                    // Copy name to clipboard
                    UIPasteboard.general.string = name
                    state.copiedName = name

                    // Show checkmark briefly
                    withAnimation {
                        showCopied = true
                    }

                    // Hide checkmark after 1 second
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                        withAnimation {
                            showCopied = false
                        }
                    }

                    Logger.info("📋 Copied component name: \(name)", category: .ui)
                }
            }
        }
    }
}

// MARK: - View Extension

extension View {
    /// Add annotation label to view (DEBUG-only)
    /// - Parameters:
    ///   - name: Clear, hierarchical name (e.g., "BottomNav_MailToggle")
    ///   - type: Component type for color coding
    func annotated(_ name: String, type: AnnotatedModifier.ComponentType = .interactive) -> some View {
        modifier(AnnotatedModifier(name: name, componentType: type))
    }
}

// MARK: - Annotation Toggle Control

struct AnnotationToggle: View {
    @ObservedObject var state = AnnotationState.shared

    var body: some View {
        VStack(spacing: 12) {
            // Toggle button
            Button {
                withAnimation {
                    state.isEnabled.toggle()
                }
                HapticService.shared.lightImpact()
                Logger.info("🏷️ Annotations \(state.isEnabled ? "enabled" : "disabled")", category: .ui)
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: state.isEnabled ? "tag.fill" : "tag.slash.fill")
                        .font(.title3)
                    Text(state.isEnabled ? "Hide Labels" : "Show Labels")
                        .font(.headline)
                }
                .foregroundColor(.white)
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
                .background(
                    Capsule()
                        .fill(state.isEnabled ? Color.green : Color.gray)
                        .shadow(color: .black.opacity(0.3), radius: 5)
                )
            }

            // Legend
            if state.isEnabled {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Color Legend:")
                        .font(.caption.bold())
                        .foregroundColor(.white.opacity(0.8))

                    ForEach([
                        (AnnotatedModifier.ComponentType.interactive, "Interactive"),
                        (AnnotatedModifier.ComponentType.layout, "Layout"),
                        (AnnotatedModifier.ComponentType.text, "Text"),
                        (AnnotatedModifier.ComponentType.status, "Status"),
                        (AnnotatedModifier.ComponentType.decoration, "Decoration")
                    ], id: \.1) { type, label in
                        HStack(spacing: 6) {
                            Circle()
                                .fill(type.color)
                                .frame(width: 12, height: 12)
                            Text(label)
                                .font(.caption)
                                .foregroundColor(.white.opacity(0.9))
                        }
                    }

                    Text("Tap any label to copy its name")
                        .font(.caption2)
                        .foregroundColor(.white.opacity(0.6))
                        .padding(.top, 4)
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.black.opacity(0.7))
                )
                .transition(.opacity)
            }
        }
    }
}

#endif
