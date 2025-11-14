import SwiftUI

struct ArchetypeBottomSheet: View {
    @Binding var isPresented: Bool
    @Binding var selectedArchetype: CardType
    let selectedArchetypes: [CardType]
    let cards: [EmailCard]
    let onSelect: (CardType) -> Void
    
    var body: some View {
        VStack(spacing: 0) {
            // Handle bar
            RoundedRectangle(cornerRadius: 3)
                .fill(Color.white.opacity(DesignTokens.Opacity.overlayMedium))
                .frame(width: 40, height: 5)
                .padding(.top, 12)
                .padding(.bottom, 20)
            
            // Title
            Text("Switch Archetype")
                .font(.title2.bold())
                .foregroundColor(DesignTokens.Colors.textPrimary)
                .padding(.bottom, DesignTokens.Spacing.card)
            
            // Archetype grid
            ScrollView {
                VStack(spacing: 16) {
                    ForEach(CardType.allCases, id: \.self) { archetype in
                        let isActive = selectedArchetypes.contains(archetype)
                        let isSelected = archetype == selectedArchetype
                        let count = getUnseenCount(for: archetype)
                        
                        ArchetypeRow(
                            archetype: archetype,
                            isActive: isActive,
                            isSelected: isSelected,
                            count: count
                        ) {
                            if isActive {
                                onSelect(archetype)
                                isPresented = false
                            }
                        }
                        .opacity(isActive ? 1.0 : 0.5)
                        .disabled(!isActive)
                    }
                }
                .padding(.horizontal, DesignTokens.Spacing.card)
                .padding(.bottom, 40)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: 600)
        .background(
            LinearGradient(
                colors: [
                    Color(red: 0.1, green: 0.1, blue: 0.15),
                    Color(red: 0.15, green: 0.15, blue: 0.2)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
        )
        .cornerRadius(DesignTokens.Radius.card)
        .shadow(color: .black.opacity(DesignTokens.Opacity.overlayMedium), radius: 20, y: -5)
    }
    
    func getUnseenCount(for type: CardType) -> Int {
        cards.filter { $0.type == type && $0.state == .unseen }.count
    }
}

struct ArchetypeRow: View {
    let archetype: CardType
    let isActive: Bool
    let isSelected: Bool
    let count: Int
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 16) {
                // Icon circle with gradient
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: gradientColors,
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 56, height: 56)
                    
                    Image(systemName: iconName)
                        .font(.title2)
                        .foregroundColor(.white)
                }
                
                // Archetype info
                VStack(alignment: .leading, spacing: 4) {
                    Text(archetype.displayName)
                        .font(.headline)
                        .foregroundColor(.white)
                    
                    if isActive {
                        Text("\(count) unread")
                            .font(.subheadline)
                            .foregroundColor(.white.opacity(DesignTokens.Opacity.textSubtle))
                    } else {
                        Text("Not Active")
                            .font(.subheadline)
                            .foregroundColor(.white.opacity(DesignTokens.Opacity.overlayStrong))
                    }
                }
                
                Spacer()
                
                // Selected checkmark or count badge
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.title3)
                        .foregroundColor(.green)
                } else if count > 0 && isActive {
                    Text("\(count)")
                        .font(.caption.bold())
                        .foregroundColor(.white)
                        .frame(minWidth: 24, minHeight: 24)
                        .background(Color.red)
                        .cornerRadius(DesignTokens.Radius.button)
                }
            }
            .padding(DesignTokens.Spacing.section)
            .background(
                isSelected ? 
                    Color.white.opacity(0.15) :
                    Color.white.opacity(DesignTokens.Opacity.glassUltraLight)
            )
            .cornerRadius(DesignTokens.Radius.container)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .strokeBorder(
                        isSelected ? Color.white.opacity(DesignTokens.Opacity.overlayMedium) : Color.clear,
                        lineWidth: 2
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    var iconName: String {
        let modern = archetype
        switch modern {
        case .mail: return "envelope.fill"
        case .ads: return "megaphone.fill"
        }
    }

    var gradientColors: [Color] {
        let modern = archetype
        switch modern {
        case .mail:
            // Blue/Teal - Primary mail gradient
            return [Color(red: 0.388, green: 0.6, blue: 0.945), Color(red: 0.2, green: 0.714, blue: 0.835)]
        case .ads:
            // Orange/Yellow - Promotional gradient
            return [Color(red: 0.953, green: 0.612, blue: 0.071), Color(red: 0.988, green: 0.765, blue: 0.333)]
        }
    }
}

#Preview {
    ZStack {
        Color.black
            .ignoresSafeArea()

        ArchetypeBottomSheet(
            isPresented: .constant(true),
            selectedArchetype: .constant(.mail),
            selectedArchetypes: [.mail, .ads],
            cards: [
                EmailCard(
                    id: "1",
                    type: .mail,
                    state: .unseen,
                    priority: .high,
                    hpa: "Sign & Send",
                    timeAgo: "2h ago",
                    title: "Field Trip Permission",
                    summary: "Please sign the permission form",
                    metaCTA: "Sign & Send"
                ),
                EmailCard(
                    id: "2",
                    type: .ads,
                    state: .unseen,
                    priority: .medium,
                    hpa: "Shop Deal",
                    timeAgo: "1h ago",
                    title: "50% Off Sale",
                    summary: "Limited time offer",
                    metaCTA: "Shop Deal"
                )
            ],
            onSelect: { _ in }
        )
    }
}

