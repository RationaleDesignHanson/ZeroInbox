import SwiftUI

/// Test view for individual action modals
/// Allows testing with empty or populated context data
struct ActionModalTestView: View {
    let action: TestableAction
    let services: ServiceContainer

    @StateObject private var viewModel: ActionModalTestViewModel
    @Environment(\.dismiss) private var dismiss

    init(action: TestableAction, services: ServiceContainer) {
        self.action = action
        self.services = services
        _viewModel = StateObject(wrappedValue: ActionModalTestViewModel(action: action, services: services))
    }

    private var backgroundGradient: some View {
        LinearGradient(
            gradient: Gradient(colors: [
                Color(red: 0.1, green: 0.1, blue: 0.3),
                Color(red: 0.2, green: 0.1, blue: 0.4)
            ]),
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .ignoresSafeArea()
    }

    var body: some View {
        NavigationView {
            ZStack {
                backgroundGradient

                ScrollView {
                    VStack(spacing: 24) {
                        // Action info
                        actionInfoSection

                        // Context configuration
                        contextConfigSection

                        // Test buttons
                        testButtonsSection

                        // Context preview
                        contextPreviewSection
                    }
                    .padding()
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        dismiss()
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "chevron.left")
                            Text("Gallery")
                        }
                        .foregroundColor(.cyan)
                    }
                }
            }
        }
        .sheet(isPresented: $viewModel.showingModal) {
            if let modal = viewModel.activeModal {
                modalView(for: modal)
            }
        }
    }

    // MARK: - Action Info Section

    private var actionInfoSection: some View {
        VStack(spacing: 16) {
            // Icon and name
            VStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(action.color.opacity(0.2))
                        .frame(width: 80, height: 80)

                    Image(systemName: action.icon)
                        .font(.system(size: 40))
                        .foregroundColor(action.color)
                }

                Text(action.displayName)
                    .font(.title2.bold())
                    .foregroundColor(.white)

                Text(action.actionId)
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.5))
            }

            // Badges
            HStack(spacing: 12) {
                InfoBadge(label: "Mode", value: action.mode.rawValue.uppercased(), color: .blue)
                InfoBadge(label: "Priority", value: "\(action.priority.rawValue)", color: .orange)
                if action.isPremium {
                    InfoBadge(label: "Premium", value: "Yes", color: .yellow)
                }
                if action.hasJSONConfig {
                    InfoBadge(label: "JSON", value: "Yes", color: .green)
                }
            }

            // Modal component
            if let component = action.modalComponent {
                HStack {
                    Image(systemName: "rectangle.on.rectangle")
                        .foregroundColor(.cyan)
                    Text("Component:")
                        .foregroundColor(.white.opacity(0.7))
                    Text(component)
                        .font(.caption.monospaced())
                        .foregroundColor(.cyan)
                }
                .padding(.top, 8)
            }
        }
        .padding(20)
        .background(Color.white.opacity(0.05))
        .cornerRadius(16)
    }

    // MARK: - Context Config Section

    private var contextConfigSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Context Data")
                .font(.headline)
                .foregroundColor(.white)

            // Required keys
            if !action.requiredContextKeys.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Required Keys")
                        .font(.subheadline.bold())
                        .foregroundColor(.red.opacity(0.8))

                    ForEach(action.requiredContextKeys, id: \.self) { key in
                        ContextKeyRow(key: key, isRequired: true, value: viewModel.contextValues[key] ?? "")
                    }
                }
            }

            // Optional keys
            if !action.optionalContextKeys.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Optional Keys")
                        .font(.subheadline.bold())
                        .foregroundColor(.blue.opacity(0.8))

                    ForEach(action.optionalContextKeys, id: \.self) { key in
                        ContextKeyRow(key: key, isRequired: false, value: viewModel.contextValues[key] ?? "")
                    }
                }
            }

            // No context keys
            if action.requiredContextKeys.isEmpty && action.optionalContextKeys.isEmpty {
                HStack {
                    Image(systemName: "info.circle")
                        .foregroundColor(.white.opacity(0.5))
                    Text("This action doesn't require context data")
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.6))
                }
                .padding(.vertical, 8)
            }
        }
        .padding(20)
        .background(Color.white.opacity(0.05))
        .cornerRadius(16)
    }

    // MARK: - Test Buttons Section

    private var testButtonsSection: some View {
        VStack(spacing: 12) {
            // Test with empty context
            Button {
                viewModel.testWithEmptyContext()
            } label: {
                HStack {
                    Image(systemName: "square.dashed")
                    Text("Test with Empty Context")
                        .font(.headline)
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.gray.opacity(0.3))
                .foregroundColor(.white)
                .cornerRadius(12)
            }

            // Test with populated context
            Button {
                viewModel.testWithPopulatedContext()
            } label: {
                HStack {
                    Image(systemName: "square.fill.on.square.fill")
                    Text("Test with Populated Context")
                        .font(.headline)
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(action.color)
                .foregroundColor(.white)
                .cornerRadius(12)
            }

            // Reset
            Button {
                viewModel.reset()
            } label: {
                HStack {
                    Image(systemName: "arrow.counterclockwise")
                    Text("Reset to Default Values")
                }
                .font(.subheadline)
                .foregroundColor(.white.opacity(0.7))
            }
            .padding(.top, 8)
        }
    }

    // MARK: - Context Preview Section

    private var contextPreviewSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Context Preview")
                .font(.headline)
                .foregroundColor(.white)

            ScrollView(.horizontal, showsIndicators: false) {
                Text(viewModel.contextPreviewJSON)
                    .font(.caption.monospaced())
                    .foregroundColor(.green)
                    .padding()
                    .background(Color.black.opacity(0.5))
                    .cornerRadius(8)
            }
        }
        .padding(20)
        .background(Color.white.opacity(0.05))
        .cornerRadius(16)
    }

    // MARK: - Modal View

    @ViewBuilder
    private func modalView(for modal: ActionModal) -> some View {
        // TODO: Implement modal rendering
        // For now, show placeholder that modal was triggered
        VStack(spacing: 20) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 60))
                .foregroundColor(.green)

            Text("Modal Triggered!")
                .font(.title.bold())

            Text("Action: \(action.displayName)")
                .font(.headline)

            Text("The modal infrastructure is working. Full modal rendering will be implemented in Phase 5.")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding()

            Button("Dismiss") {
                viewModel.showingModal = false
            }
            .buttonStyle(.borderedProminent)
        }
        .padding(40)
    }
}

// MARK: - Supporting Views

struct InfoBadge: View {
    let label: String
    let value: String
    let color: Color

    var body: some View {
        VStack(spacing: 4) {
            Text(label)
                .font(.caption2)
                .foregroundColor(.white.opacity(0.6))
            Text(value)
                .font(.caption.bold())
                .foregroundColor(color)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(color.opacity(0.15))
        .cornerRadius(8)
    }
}

struct ContextKeyRow: View {
    let key: String
    let isRequired: Bool
    let value: String

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: isRequired ? "exclamationmark.circle.fill" : "circle")
                .foregroundColor(isRequired ? .red.opacity(0.6) : .blue.opacity(0.6))
                .font(.caption)

            Text(key)
                .font(.caption.monospaced())
                .foregroundColor(.white.opacity(0.8))

            Spacer()

            if !value.isEmpty {
                Text(value)
                    .font(.caption2)
                    .foregroundColor(.green.opacity(0.8))
                    .lineLimit(1)
            } else {
                Text("(empty)")
                    .font(.caption2)
                    .foregroundColor(.white.opacity(0.3))
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Test ViewModel

@MainActor
class ActionModalTestViewModel: ObservableObject {
    let action: TestableAction
    let services: ServiceContainer

    @Published var showingModal = false
    @Published var activeModal: ActionModal?
    @Published var contextValues: [String: String] = [:]

    init(action: TestableAction, services: ServiceContainer) {
        self.action = action
        self.services = services
        loadDefaultValues()
    }

    var contextPreviewJSON: String {
        guard !contextValues.isEmpty else {
            return "{}"
        }

        let sortedKeys = contextValues.keys.sorted()
        let jsonLines = sortedKeys.map { key in
            let value = contextValues[key] ?? ""
            return "  \"\(key)\": \"\(value)\""
        }

        return "{\n" + jsonLines.joined(separator: ",\n") + "\n}"
    }

    func testWithEmptyContext() {
        contextValues = [:]
        openModal()
    }

    func testWithPopulatedContext() {
        loadDefaultValues()
        openModal()
    }

    func reset() {
        contextValues = [:]
        loadDefaultValues()
    }

    private func openModal() {
        // Disabled - API mismatch with current EmailAction/ActionRouter
        // let mockCard = createMockEmailCard()
        // let emailAction = EmailAction(...)
        // activeModal = services.actionRouter.buildModalForAction(emailAction, card: mockCard)
        // showingModal = true

        // Temporary stub
        print("ActionModalTestView disabled - needs API updates")
    }

    private func createMockEmailCard() -> EmailCard {
        // Disabled - EmailCard initializer API has changed
        // Return stub using decoder (EmailCard is Codable)
        fatalError("createMockEmailCard not implemented - needs EmailCard API update")
    }

    private func loadDefaultValues() {
        // Provide realistic mock data for each context key
        var defaults: [String: String] = [:]

        for key in action.requiredContextKeys + action.optionalContextKeys {
            defaults[key] = mockValueForKey(key)
        }

        contextValues = defaults
    }

    private func mockValueForKey(_ key: String) -> String {
        // Provide realistic mock values based on key name
        switch key.lowercased() {
        case "trackingnumber": return "1Z999AA10123456784"
        case "carrier": return "UPS"
        case "url", "trackingurl", "invoiceurl": return "https://example.com/track/123"
        case "expecteddelivery": return "2025-12-25"
        case "currentstatus": return "In Transit"
        case "invoiceid": return "INV-2025-001234"
        case "amount": return "$149.99"
        case "merchant": return "Acme Corp"
        case "duedate": return "2025-12-31"
        case "flightnumber": return "AA 1234"
        case "airline": return "American Airlines"
        case "departuretime": return "2025-12-20 14:30"
        case "productname": return "Premium Widget"
        case "reviewlink": return "https://example.com/review"
        case "drivername": return "John Doe"
        case "phone": return "+1 (555) 123-4567"
        case "vehicleinfo": return "Toyota Camry - ABC123"
        case "pickuplocation": return "123 Main St, San Francisco, CA"
        case "scheduledtime": return "2025-12-20 15:00"
        case "instructions": return "Ring doorbell twice"
        case "recipientemail": return "recipient@example.com"
        case "subject": return "Re: Test Email"
        case "eventtitle": return "Team Meeting"
        case "eventdate": return "2025-12-25"
        case "eventlocation": return "Conference Room A"
        default: return "Mock value for \(key)"
        }
    }
}

// MARK: - Preview

#if DEBUG
struct ActionModalTestView_Previews: PreviewProvider {
    static var previews: some View {
        ActionModalTestView(
            action: TestableAction(
                id: "track_package",
                actionId: "track_package",
                displayName: "Track Package",
                mode: .mail,
                priority: .veryHigh,
                isPremium: true,
                hasJSONConfig: true,
                modalComponent: "TrackPackageModal",
                requiredContextKeys: ["trackingNumber", "carrier"],
                optionalContextKeys: ["url", "expectedDelivery"],
                icon: "shippingbox.fill",
                color: .blue
            ),
            services: ServiceContainer()
        )
    }
}
#endif
