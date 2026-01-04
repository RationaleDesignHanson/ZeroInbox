import SwiftUI

/**
 * GenericActionModal - Universal data-driven modal renderer
 *
 * Replaces 46 hard-coded modal files with a single configurable modal
 * Renders UI dynamically based on ModalConfig JSON
 *
 * Usage:
 * ```swift
 * let config = ModalConfig.load(from: "track_package")
 * let context = ActionContext(card: emailCard, context: action.context)
 * GenericActionModal(config: config, context: context, isPresented: $showModal)
 * ```
 *
 * Features:
 * - Dynamic section rendering (vertical, horizontal, grid layouts)
 * - 12+ field types with formatting
 * - Multiple button actions (openURL, copy, submit, share, dismiss)
 * - Glassmorphic backgrounds
 * - Error handling and validation
 * - Analytics tracking
 */
struct GenericActionModal: View {
    let config: ModalConfig
    let context: ActionContext
    @Binding var isPresented: Bool

    // State
    @State private var showSuccess = false
    @State private var showError = false
    @State private var errorMessage: String?
    @State private var isLoading = false
    @State private var formData: [String: Any] = [:]  // For interactive fields
    @State private var fieldErrors: [String: String] = [:]  // Field validation errors
    @State private var collapsedSections: [String: Bool] = [:]  // Track collapsed state per section
    @State private var showDestructiveConfirmation = false  // Destructive action confirmation

    // Services
    // Using singleton for now
    private let analyticsService = AnalyticsService.shared

    var body: some View {
        VStack(spacing: 0) {
            // Modal header with close button
            ModalHeader(isPresented: $isPresented)

            ScrollView {
                VStack(spacing: DesignTokens.Spacing.card) {
                    // Header section (icon + title + subtitle)
                    headerSection

                    // Dynamic sections based on config
                    ForEach(config.sections) { section in
                        // Check visibility condition
                        if isVisible(section: section) {
                            sectionView(for: section)
                        }
                    }

                    // Primary and secondary buttons
                    buttonsSection
                }
                .padding(DesignTokens.Spacing.card)
            }
            .background(Color.black.opacity(0.05))
        }
        .overlay(alignment: .top) {
            if showSuccess {
                ErrorBanner(
                    message: config.loadingStates?.success ?? "Action completed successfully",
                    dismissAction: { showSuccess = false }
                )
                .transition(.move(edge: .top).combined(with: .opacity))
                .padding(.top, 8)
            }

            if showError, let errorMessage = errorMessage {
                ErrorBanner(
                    message: errorMessage,
                    type: .error,
                    dismissAction: {
                        showError = false
                        self.errorMessage = nil
                    }
                )
                .transition(.move(edge: .top).combined(with: .opacity))
                .padding(.top, 8)
            }
        }
        .overlay {
            if isLoading {
                ZStack {
                    Color.black.opacity(0.4)
                        .edgesIgnoringSafeArea(.all)

                    VStack(spacing: 16) {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .scaleEffect(1.5)

                        if let loadingMessage = config.loadingStates?.submitting {
                            Text(loadingMessage)
                                .font(DesignTokens.Typography.bodyMedium)
                                .foregroundColor(.white)
                        }
                    }
                    .padding(32)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color.black.opacity(0.8))
                    )
                }
            }
        }
        .onAppear {
            trackModalView()
            initializeCollapsedSections()
            initializeDefaultValues()
        }
    }

    // MARK: - Header Section

    @ViewBuilder
    private var headerSection: some View {
        VStack(spacing: DesignTokens.Spacing.component) {
            // Icon
            if let iconConfig = config.icon {
                iconView(for: iconConfig)
                    .padding(.top, DesignTokens.Spacing.element)
            }

            // Title
            Text(config.title)
                .font(DesignTokens.Typography.headingLarge)
                .foregroundColor(DesignTokens.Colors.textPrimary)
                .multilineTextAlignment(.center)

            // Subtitle
            if let subtitle = config.subtitle {
                Text(subtitle)
                    .font(DesignTokens.Typography.bodyMedium)
                    .foregroundColor(DesignTokens.Colors.textSecondary)
                    .multilineTextAlignment(.center)
            }
        }
    }

    // MARK: - Icon View

    private func iconView(for iconConfig: IconConfig) -> some View {
        Image(systemName: iconConfig.systemName)
            .font(.system(size: iconConfig.size.points))
            .foregroundColor(iconColor(for: iconConfig))
            .frame(width: iconConfig.size.points + 20, height: iconConfig.size.points + 20)
    }

    private func iconColor(for iconConfig: IconConfig) -> Color {
        if let colorKey = iconConfig.colorKey,
           let colorValue = context.optionalString(for: colorKey) {
            return colorFromString(colorValue)
        } else if let staticColor = iconConfig.staticColor {
            return colorFromString(staticColor)
        }
        return DesignTokens.Colors.accentBlue
    }

    // MARK: - Section View

    @ViewBuilder
    private func sectionView(for section: ModalSection) -> some View {
        let isCollapsed = collapsedSections[section.id] ?? (section.collapsed ?? false)

        // Check if section is collapsible
        if section.collapsible == true, let title = section.title {
            // Collapsible section with DisclosureGroup
            DisclosureGroup(
                isExpanded: Binding(
                    get: { !isCollapsed },
                    set: { collapsedSections[section.id] = !$0 }
                )
            ) {
                sectionContent(for: section)
                    .padding(.top, DesignTokens.Spacing.element)
            } label: {
                Text(title)
                    .font(DesignTokens.Typography.headingSmall)
                    .foregroundColor(DesignTokens.Colors.textPrimary)
            }
            .padding(DesignTokens.Spacing.component)
            .background(backgroundView(for: section.background))
            .cornerRadius(DesignTokens.Radius.card)
            .tint(DesignTokens.Colors.accentBlue)
        } else {
            // Non-collapsible section
            VStack(alignment: .leading, spacing: DesignTokens.Spacing.component) {
                // Section title
                if let title = section.title {
                    Text(title)
                        .font(DesignTokens.Typography.headingSmall)
                        .foregroundColor(DesignTokens.Colors.textPrimary)
                }

                sectionContent(for: section)
            }
            .padding(DesignTokens.Spacing.component)
            .background(backgroundView(for: section.background))
            .cornerRadius(DesignTokens.Radius.card)
        }
    }

    @ViewBuilder
    private func sectionContent(for section: ModalSection) -> some View {
        // Fields based on layout
        switch section.layout {
        case .vertical:
            VStack(spacing: DesignTokens.Spacing.element) {
                ForEach(section.fields) { field in
                    if isVisible(field: field) {
                        fieldView(for: field)
                    }
                }
            }

        case .horizontal:
            HStack(spacing: DesignTokens.Spacing.element) {
                ForEach(section.fields) { field in
                    if isVisible(field: field) {
                        fieldView(for: field)
                    }
                }
            }

        case .grid:
            LazyVGrid(
                columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible())
                ],
                spacing: DesignTokens.Spacing.element
            ) {
                ForEach(section.fields) { field in
                    if isVisible(field: field) {
                        fieldView(for: field)
                    }
                }
            }
        }
    }

    @ViewBuilder
    private func backgroundView(for style: ModalSection.BackgroundStyle?) -> some View {
        switch style {
        case .glass:
            Color.white.opacity(DesignTokens.Opacity.glassUltraLight)
        case .card:
            Color(.systemGray6)
        case .plain:
            Color.white.opacity(0.05)
        case .some(.none), nil:
            Color.clear
        }
    }

    // MARK: - Field View

    @ViewBuilder
    private func fieldView(for field: FieldConfig) -> some View {
        let value = context.optionalString(for: field.contextKey)

        switch field.type {
        case .text:
            TextFieldView(
                label: field.label,
                value: value,
                placeholder: field.placeholder,
                copyable: field.copyable
            )

        case .textMultiline:
            MultilineTextFieldView(
                label: field.label,
                value: value,
                placeholder: field.placeholder
            )

        case .badge:
            BadgeFieldView(
                label: field.label,
                value: value,
                copyable: field.copyable
            )

        case .statusBadge:
            StatusBadgeFieldView(
                label: field.label,
                value: value,
                colorMapping: field.colorMapping
            )

        case .date:
            DateFieldView(
                label: field.label,
                date: context.date(for: field.contextKey),
                formatting: field.formatting
            )

        case .dateTime:
            DateTimeFieldView(
                label: field.label,
                date: context.date(for: field.contextKey),
                formatting: field.formatting
            )

        case .currency:
            CurrencyFieldView(
                label: field.label,
                value: value
            )

        case .link:
            LinkFieldView(
                label: field.label,
                url: value
            )

        case .button:
            FieldButtonView(
                label: field.label ?? value ?? "Action"
            )

        case .image:
            ImageFieldView(
                url: value
            )

        case .divider:
            Divider()
                .padding(.vertical, DesignTokens.Spacing.element)

        // MARK: Interactive Fields (Phase 2)

        case .textInput:
            InteractiveTextFieldView(
                label: field.label,
                text: binding(for: field.contextKey, default: ""),
                placeholder: field.placeholder,
                required: field.required,
                errorMessage: fieldErrors[field.contextKey]
            )

        case .textInputMultiline:
            InteractiveMultilineTextFieldView(
                label: field.label,
                text: binding(for: field.contextKey, default: ""),
                placeholder: field.placeholder,
                required: field.required,
                errorMessage: fieldErrors[field.contextKey]
            )

        case .datePicker:
            InteractiveDatePickerView(
                label: field.label,
                date: binding(for: field.contextKey, default: Date()),
                required: field.required
            )

        case .timePicker:
            InteractiveTimePickerView(
                label: field.label,
                date: binding(for: field.contextKey, default: Date()),
                required: field.required
            )

        case .dateTimePicker:
            InteractiveDateTimePickerView(
                label: field.label,
                date: binding(for: field.contextKey, default: Date()),
                required: field.required
            )

        case .toggle:
            InteractiveToggleView(
                label: field.label ?? "Toggle",
                isOn: binding(for: field.contextKey, default: false)
            )

        case .picker:
            if let pickerOptions = field.pickerOptions {
                // Enhanced picker with icons and descriptions
                EnhancedPickerView(
                    label: field.label,
                    selection: binding(for: field.contextKey, default: ""),
                    options: pickerOptions,
                    required: field.required,
                    helpText: field.helpText
                )
            } else {
                // Basic picker fallback
                InteractivePickerView(
                    label: field.label,
                    selection: binding(for: field.contextKey, default: ""),
                    options: field.colorMapping?.keys.sorted() ?? [],
                    required: field.required
                )
            }

        case .slider:
            InteractiveSliderView(
                label: field.label,
                value: binding(for: field.contextKey, default: 0.0),
                range: 0...100
            )

        case .checkbox:
            InteractiveCheckboxView(
                label: field.label ?? "Checkbox",
                isChecked: binding(for: field.contextKey, default: false)
            )

        case .segmentedControl:
            InteractiveSegmentedControlView(
                label: field.label,
                selection: binding(for: field.contextKey, default: ""),
                options: field.colorMapping?.keys.sorted() ?? []
            )

        case .stepper:
            InteractiveStepperView(
                label: field.label,
                value: binding(for: field.contextKey, default: 0),
                range: 0...100
            )

        case .rating:
            InteractiveRatingView(
                label: field.label,
                rating: binding(for: field.contextKey, default: 0)
            )

        // MARK: Wave 2 Fields

        case .multiSelect:
            // TODO: Implement multiSelect rendering
            Text("Multi-select field (TODO)")
                .font(DesignTokens.Typography.bodySmall)
                .foregroundColor(DesignTokens.Colors.textSecondary)

        case .searchField:
            // TODO: Implement searchField rendering
            InteractiveTextFieldView(
                label: field.label,
                text: binding(for: field.contextKey, default: ""),
                placeholder: field.placeholder ?? "Search...",
                required: field.required,
                errorMessage: fieldErrors[field.contextKey]
            )

        case .stars:
            // Display-only star rating (read-only)
            if let value = value, let rating = Int(value) {
                StarRatingView(
                    label: field.label,
                    rating: rating
                )
            }

        case .textArea:
            // Enhanced multi-line text with character count
            InteractiveTextAreaView(
                label: field.label,
                text: binding(for: field.contextKey, default: ""),
                placeholder: field.placeholder,
                required: field.required,
                errorMessage: fieldErrors[field.contextKey],
                helpText: field.helpText,
                maxLines: field.maxLines,
                characterLimit: field.characterLimit
            )

        case .calculated:
            // TODO: Implement calculated field rendering
            Text("Calculated: \(value ?? "0")")
                .font(DesignTokens.Typography.bodyMedium)
                .foregroundColor(DesignTokens.Colors.textPrimary)
        }
    }

    // MARK: - Buttons Section

    private var buttonsSection: some View {
        VStack(spacing: DesignTokens.Spacing.element) {
            // Primary button
            primaryButton

            // Secondary button (optional)
            if let secondaryButton = config.secondaryButton {
                secondaryButtonView(secondaryButton)
            }

            // Tertiary button (optional)
            if let tertiaryButton = config.tertiaryButton {
                secondaryButtonView(tertiaryButton)
            }

            // Destructive action (optional)
            if let destructiveAction = config.destructiveAction {
                destructiveActionView(destructiveAction)
            }

            // Cancel button (optional)
            if let cancelButton = config.cancelButton {
                secondaryButtonView(cancelButton)
            }
        }
        .padding(.top, DesignTokens.Spacing.component)
    }

    private var primaryButton: some View {
        Button {
            // Validate all fields before performing action
            if validateAllFields() {
                handleButtonAction(config.primaryButton.action, analytics: config.primaryButton.analytics)
            }
        } label: {
            if isLoading {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
            } else {
                Text(config.primaryButton.title)
                    .font(DesignTokens.Typography.bodyMedium)
                    .foregroundColor(.white)
            }
        }
        .buttonStyle(buttonStyle(for: config.primaryButton.style))
        .disabled(isLoading)
    }

    @ViewBuilder
    private func secondaryButtonView(_ button: ButtonConfig) -> some View {
        Button {
            handleButtonAction(button.action, analytics: button.analytics)
        } label: {
            Text(button.title)
                .font(DesignTokens.Typography.bodyMedium)
                .foregroundColor(buttonTextColor(for: button.style))
        }
        .buttonStyle(buttonStyle(for: button.style))
    }

    @ViewBuilder
    private func destructiveActionView(_ action: DestructiveActionConfig) -> some View {
        Button {
            showDestructiveConfirmation = true
        } label: {
            Text(action.title)
                .font(DesignTokens.Typography.bodyMedium)
                .foregroundColor(.white)
        }
        .buttonStyle(buttonStyle(for: .destructive))
        .confirmationDialog(
            action.confirmationTitle ?? "Are you sure?",
            isPresented: $showDestructiveConfirmation,
            titleVisibility: .visible
        ) {
            Button(action.title, role: .destructive) {
                handleButtonAction(action.action, analytics: action.analytics)
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            if let message = action.confirmationMessage {
                Text(message)
            }
        }
    }

    // MARK: - Button Actions

    private func handleButtonAction(_ action: ButtonAction, analytics: AnalyticsConfig? = nil) {
        // Fire analytics event if provided
        if let analytics = analytics {
            fireAnalyticsEvent(analytics)
        }

        switch action {
        case .openURL(let contextKey):
            handleOpenURL(contextKey: contextKey)

        case .copyToClipboard(let contextKey):
            handleCopyToClipboard(contextKey: contextKey)

        case .submit(let contextKey):
            handleSubmit(contextKey: contextKey)

        case .custom(let contextKey):
            handleCustom(contextKey: contextKey)

        case .share:
            handleShare()

        case .dismiss:
            isPresented = false
        }
    }

    private func fireAnalyticsEvent(_ analytics: AnalyticsConfig) {
        var properties: [String: String] = [:]

        // Substitute placeholders in analytics properties
        if let analyticsProperties = analytics.properties {
            for (key, valueTemplate) in analyticsProperties {
                properties[key] = substitutePlaceholders(in: valueTemplate)
            }
        }

        analyticsService.log(analytics.eventName, properties: properties)
    }

    private func substitutePlaceholders(in template: String) -> String {
        var result = template

        // Find all placeholders in format {key}
        let pattern = "\\{([^}]+)\\}"
        if let regex = try? NSRegularExpression(pattern: pattern) {
            let matches = regex.matches(in: template, range: NSRange(template.startIndex..., in: template))

            for match in matches.reversed() {
                if let range = Range(match.range(at: 1), in: template) {
                    let key = String(template[range])

                    // Get value from formData or context
                    let value: String
                    if let formValue = formData[key] {
                        value = String(describing: formValue)
                    } else if let contextValue = context.optionalString(for: key) {
                        value = contextValue
                    } else {
                        value = ""
                    }

                    // Replace placeholder with value
                    if let fullRange = Range(match.range, in: template) {
                        result = result.replacingOccurrences(of: String(template[fullRange]), with: value)
                    }
                }
            }
        }

        return result
    }

    private func handleOpenURL(contextKey: String) {
        guard let urlString = context.optionalString(for: contextKey),
              let url = URL(string: urlString) else {
            showErrorMessage("Invalid URL")
            return
        }

        UIApplication.shared.open(url)

        analyticsService.log("generic_modal_url_opened", properties: [
            "modal_id": config.id,
            "context_key": contextKey
        ])

        isPresented = false
    }

    private func handleCopyToClipboard(contextKey: String) {
        guard let value = context.optionalString(for: contextKey) else {
            showErrorMessage("Nothing to copy")
            return
        }

        UIPasteboard.general.string = value

        withAnimation {
            showSuccess = true
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            withAnimation {
                showSuccess = false
            }
        }

        analyticsService.log("generic_modal_copied", properties: [
            "modal_id": config.id,
            "context_key": contextKey
        ])
    }

    private func handleSubmit(contextKey: String?) {
        isLoading = true

        Task {
            do {
                // Merge formData with existing context
                let mergedContext = createMergedContext()

                // If contextKey provided, use it to get service call
                if let contextKey = contextKey,
                   let serviceCall = context.optionalString(for: contextKey) {
                    try await ServiceCallExecutor.execute(serviceCall, context: mergedContext)
                } else {
                    // Generic form submission (no specific service call)
                    // Just close the modal after validation
                }

                await MainActor.run {
                    isLoading = false
                    withAnimation {
                        showSuccess = true
                    }

                    analyticsService.log("generic_modal_submitted", properties: [
                        "modal_id": config.id,
                        "context_key": contextKey ?? "none",
                        "form_fields_submitted": formData.keys.sorted().joined(separator: ", ")
                    ])

                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                        isPresented = false
                    }
                }
            } catch {
                await MainActor.run {
                    isLoading = false
                    showErrorMessage(error.localizedDescription)

                    analyticsService.log("generic_modal_error", properties: [
                        "modal_id": config.id,
                        "context_key": contextKey ?? "none",
                        "error": error.localizedDescription
                    ])
                }
            }
        }
    }

    private func handleCustom(contextKey: String) {
        // Custom action - log analytics and dismiss
        analyticsService.log("generic_modal_custom_action", properties: [
            "modal_id": config.id,
            "context_key": contextKey
        ])

        // TODO: Hook into app-level custom action handler
        Logger.info("Custom action triggered: \(contextKey)", category: .action)

        isPresented = false
    }

    /// Create a merged context that combines original context with form data
    private func createMergedContext() -> ActionContext {
        var mergedDict = context.raw

        // Add all form data to the context
        for (key, value) in formData {
            mergedDict[key] = value
        }

        return ActionContext(card: context.card, context: mergedDict)
    }

    private func handleShare() {
        // Create share content from context
        var shareItems: [Any] = []

        if let title = context.optionalString(for: "title") {
            shareItems.append(title)
        }

        if let urlString = context.url, let url = URL(string: urlString) {
            shareItems.append(url)
        }

        guard !shareItems.isEmpty else {
            showErrorMessage("Nothing to share")
            return
        }

        let activityVC = UIActivityViewController(
            activityItems: shareItems,
            applicationActivities: nil
        )

        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let rootVC = windowScene.windows.first?.rootViewController {
            rootVC.present(activityVC, animated: true)
        }

        analyticsService.log("generic_modal_shared", properties: [
            "modal_id": config.id
        ])
    }

    // MARK: - Helpers

    // Binding helpers for interactive fields
    private func binding<T>(for key: String, default defaultValue: T) -> Binding<T> {
        Binding<T>(
            get: {
                if let value = formData[key] as? T {
                    return value
                }
                // Initialize with context value if available
                if let contextValue = context.raw[key] as? T {
                    return contextValue
                }
                return defaultValue
            },
            set: { newValue in
                formData[key] = newValue
                // Clear error when user starts typing
                fieldErrors[key] = nil
            }
        )
    }

    // MARK: - Validation Helpers

    /// Validate a single field
    private func validateField(_ field: FieldConfig) -> Bool {
        // Check required fields
        if field.required {
            if let stringValue = formData[field.contextKey] as? String {
                if stringValue.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    fieldErrors[field.contextKey] = "\(field.label ?? "This field") is required"
                    return false
                }
            } else if formData[field.contextKey] == nil {
                fieldErrors[field.contextKey] = "\(field.label ?? "This field") is required"
                return false
            }
        }

        // Run validation rules for text fields
        if let validation = field.validation,
           let stringValue = formData[field.contextKey] as? String {
            let result = validation.validate(stringValue)
            if !result.isValid {
                fieldErrors[field.contextKey] = result.errorMessage ?? "Invalid input"
                return false
            }
        }

        // Clear error if valid
        fieldErrors[field.contextKey] = nil
        return true
    }

    /// Validate all form fields before submission
    private func validateAllFields() -> Bool {
        var isValid = true

        for section in config.sections {
            for field in section.fields {
                // Only validate interactive input fields
                switch field.type {
                case .textInput, .textInputMultiline, .datePicker, .timePicker,
                     .dateTimePicker, .toggle, .picker, .slider, .checkbox,
                     .segmentedControl, .stepper, .rating:
                    if !validateField(field) {
                        isValid = false
                    }
                default:
                    break
                }
            }
        }

        if !isValid {
            withAnimation {
                showError = true
                errorMessage = "Please fix the errors below"
            }

            DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                withAnimation {
                    showError = false
                }
            }
        }

        return isValid
    }

    private func showErrorMessage(_ message: String) {
        withAnimation {
            errorMessage = message
            showError = true
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
            withAnimation {
                showError = false
            }
        }
    }

    private func trackModalView() {
        analyticsService.log("generic_modal_viewed", properties: [
            "modal_id": config.id,
            "layout": config.layout.rawValue,
            "sections_count": config.sections.count
        ])
    }

    // MARK: - Visibility & Initialization

    private func isVisible(section: ModalSection) -> Bool {
        guard let condition = section.visibilityCondition else { return true }
        return evaluateVisibilityCondition(condition)
    }

    private func isVisible(field: FieldConfig) -> Bool {
        guard let condition = field.visibilityCondition else { return true }
        return evaluateVisibilityCondition(condition)
    }

    private func evaluateVisibilityCondition(_ condition: VisibilityCondition) -> Bool {
        // Get current value of the watched field
        if let currentValue = formData[condition.field] {
            // Compare with expected value
            return matchesValue(currentValue, condition.equals)
        }
        return false
    }

    private func matchesValue(_ currentValue: Any, _ expectedValue: AnyCodableValue) -> Bool {
        switch expectedValue {
        case .string(let expected):
            if let current = currentValue as? String {
                return current == expected
            }
        case .int(let expected):
            if let current = currentValue as? Int {
                return current == expected
            }
        case .double(let expected):
            if let current = currentValue as? Double {
                return current == expected
            }
        case .bool(let expected):
            if let current = currentValue as? Bool {
                return current == expected
            }
        case .null:
            return currentValue is NSNull || (currentValue as? String)?.isEmpty == true
        }
        return false
    }

    private func initializeCollapsedSections() {
        for section in config.sections {
            if let collapsed = section.collapsed {
                collapsedSections[section.id] = collapsed
            }
        }
    }

    private func initializeDefaultValues() {
        for section in config.sections {
            for field in section.fields {
                if let defaultValue = field.defaultValue, formData[field.contextKey] == nil {
                    // Set default value based on type
                    switch defaultValue {
                    case .string(let value):
                        formData[field.contextKey] = value
                    case .int(let value):
                        formData[field.contextKey] = value
                    case .double(let value):
                        formData[field.contextKey] = value
                    case .bool(let value):
                        formData[field.contextKey] = value
                    case .null:
                        break
                    }
                }
            }
        }
    }

    private func colorFromString(_ colorName: String) -> Color {
        switch colorName.lowercased() {
        case "red": return .red
        case "green": return .green
        case "blue": return .blue
        case "yellow": return .yellow
        case "orange": return .orange
        case "purple": return .purple
        case "pink": return .pink
        case "gray", "grey": return .gray
        case "black": return .black
        case "white": return .white
        default: return DesignTokens.Colors.accentBlue
        }
    }

    private func buttonStyle(for style: ButtonConfig.ButtonStyle) -> some ButtonStyle {
        switch style {
        case .primary:
            return AnyButtonStyle(GradientButtonStyle())
        case .secondary:
            return AnyButtonStyle(SecondaryButtonStyle())
        case .tertiary:
            return AnyButtonStyle(TertiaryButtonStyle())
        case .plain:
            return AnyButtonStyle(LinkButtonStyle())
        case .destructive:
            return AnyButtonStyle(DestructiveButtonStyle())
        case .link:
            return AnyButtonStyle(LinkButtonStyle())
        }
    }

    private func buttonTextColor(for style: ButtonConfig.ButtonStyle) -> Color {
        switch style {
        case .primary, .destructive:
            return .white
        case .secondary:
            return DesignTokens.Colors.textPrimary
        case .tertiary:
            return DesignTokens.Colors.textSecondary
        case .plain:
            return DesignTokens.Colors.textPrimary
        case .link:
            return DesignTokens.Colors.accentBlue
        }
    }
}

// MARK: - Type-Erased Button Style

struct AnyButtonStyle: ButtonStyle {
    private let _makeBody: (Configuration) -> AnyView

    init<S: ButtonStyle>(_ style: S) {
        _makeBody = { configuration in
            AnyView(style.makeBody(configuration: configuration))
        }
    }

    func makeBody(configuration: Configuration) -> some View {
        _makeBody(configuration)
    }
}

// MARK: - Destructive Button Style

struct DestructiveButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .frame(maxWidth: .infinity)
            .frame(height: 54)
            .background(Color.red)
            .foregroundColor(.white)
            .cornerRadius(DesignTokens.Radius.button)
    }
}

// MARK: - Secondary Button Style

struct SecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .frame(maxWidth: .infinity)
            .frame(height: 54)
            .background(Color.white.opacity(0.1))
            .foregroundColor(.white)
            .cornerRadius(DesignTokens.Radius.button)
    }
}

// MARK: - Tertiary Button Style

struct TertiaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .frame(maxWidth: .infinity)
            .frame(height: 54)
            .background(Color.clear)
            .foregroundColor(DesignTokens.Colors.textSecondary)
            .cornerRadius(DesignTokens.Radius.button)
    }
}

// MARK: - Link Button Style

struct LinkButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundColor(DesignTokens.Colors.accentBlue)
    }
}

// MARK: - Star Rating View (Read-Only)

struct StarRatingView: View {
    let label: String?
    let rating: Int

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            if let label = label {
                Text(label)
                    .font(DesignTokens.Typography.bodySmall)
                    .foregroundColor(DesignTokens.Colors.textSecondary)
            }

            HStack(spacing: 4) {
                ForEach(1...5, id: \.self) { star in
                    Image(systemName: star <= rating ? "star.fill" : "star")
                        .font(.system(size: 20))
                        .foregroundColor(star <= rating ? .yellow : DesignTokens.Colors.textSecondary.opacity(0.3))
                }
            }
        }
    }
}

// MARK: - Interactive Field Views (Phase 2)

/// Generic wrapper for all interactive fields - handles label, required indicator, error messages, help text, and styling
struct InteractiveFieldWrapper<Content: View>: View {
    let label: String?
    let required: Bool
    let errorMessage: String?
    let helpText: String?
    let showBackground: Bool
    @ViewBuilder let content: () -> Content

    init(label: String? = nil, required: Bool = false, errorMessage: String? = nil, helpText: String? = nil, showBackground: Bool = true, @ViewBuilder content: @escaping () -> Content) {
        self.label = label
        self.required = required
        self.errorMessage = errorMessage
        self.helpText = helpText
        self.showBackground = showBackground
        self.content = content
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            if let label = label {
                HStack(spacing: 4) {
                    Text(label)
                        .font(DesignTokens.Typography.bodySmall)
                        .foregroundColor(DesignTokens.Colors.textSecondary)
                    if required {
                        Text("*")
                            .foregroundColor(.red)
                            .font(DesignTokens.Typography.bodySmall)
                    }
                }
            }

            Group {
                content()
            }
            .if(showBackground) { view in
                view
                    .padding(12)
                    .background(Color.white.opacity(0.1))
                    .cornerRadius(DesignTokens.Radius.button)
            }
            .overlay(
                RoundedRectangle(cornerRadius: DesignTokens.Radius.button)
                    .stroke(errorMessage != nil ? Color.red : Color.clear, lineWidth: 1)
            )

            if let errorMessage = errorMessage {
                Text(errorMessage)
                    .font(DesignTokens.Typography.bodySmall)
                    .foregroundColor(.red)
            } else if let helpText = helpText {
                Text(helpText)
                    .font(DesignTokens.Typography.bodySmall)
                    .foregroundColor(DesignTokens.Colors.textSecondary.opacity(0.7))
            }
        }
    }
}

// Helper extension for conditional view modifiers
extension View {
    @ViewBuilder func `if`<Content: View>(_ condition: Bool, transform: (Self) -> Content) -> some View {
        if condition {
            transform(self)
        } else {
            self
        }
    }
}

struct InteractiveTextFieldView: View {
    let label: String?
    @Binding var text: String
    let placeholder: String?
    let required: Bool
    let errorMessage: String?

    var body: some View {
        InteractiveFieldWrapper(label: label, required: required, errorMessage: errorMessage) {
            TextField(placeholder ?? "", text: $text)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .font(DesignTokens.Typography.bodyMedium)
                .foregroundColor(DesignTokens.Colors.textPrimary)
        }
    }
}

struct InteractiveMultilineTextFieldView: View {
    let label: String?
    @Binding var text: String
    let placeholder: String?
    let required: Bool
    let errorMessage: String?

    var body: some View {
        InteractiveFieldWrapper(label: label, required: required, errorMessage: errorMessage, showBackground: false) {
            TextEditor(text: $text)
                .font(DesignTokens.Typography.bodyMedium)
                .foregroundColor(DesignTokens.Colors.textPrimary)
                .frame(minHeight: 100)
                .padding(8)
                .background(Color.white.opacity(0.1))
                .cornerRadius(DesignTokens.Radius.button)
        }
    }
}

struct InteractiveTextAreaView: View {
    let label: String?
    @Binding var text: String
    let placeholder: String?
    let required: Bool
    let errorMessage: String?
    let helpText: String?
    let maxLines: Int?
    let characterLimit: Int?

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Label with required indicator
            if let label = label {
                HStack(spacing: 4) {
                    Text(label)
                        .font(DesignTokens.Typography.bodySmall)
                        .foregroundColor(DesignTokens.Colors.textSecondary)
                    if required {
                        Text("*")
                            .foregroundColor(.red)
                            .font(DesignTokens.Typography.bodySmall)
                    }
                }
            }

            // Text editor with background
            ZStack(alignment: .topLeading) {
                if text.isEmpty, let placeholder = placeholder {
                    Text(placeholder)
                        .font(DesignTokens.Typography.bodyMedium)
                        .foregroundColor(DesignTokens.Colors.textSecondary.opacity(0.5))
                        .padding(.horizontal, 12)
                        .padding(.vertical, 16)
                }

                TextEditor(text: $text)
                    .font(DesignTokens.Typography.bodyMedium)
                    .foregroundColor(DesignTokens.Colors.textPrimary)
                    .frame(minHeight: 100)
                    .padding(8)
                    .scrollContentBackground(.hidden)
                    .background(Color.clear)
                    .onChange(of: text) { newValue in
                        // Enforce character limit
                        if let limit = characterLimit, newValue.count > limit {
                            text = String(newValue.prefix(limit))
                        }
                    }
            }
            .background(Color.white.opacity(0.1))
            .cornerRadius(DesignTokens.Radius.button)
            .overlay(
                RoundedRectangle(cornerRadius: DesignTokens.Radius.button)
                    .stroke(errorMessage != nil ? Color.red : Color.clear, lineWidth: 1)
            )

            // Character counter and help text row
            HStack {
                // Help text or error message
                if let errorMessage = errorMessage {
                    Text(errorMessage)
                        .font(DesignTokens.Typography.bodySmall)
                        .foregroundColor(.red)
                } else if let helpText = helpText {
                    Text(helpText)
                        .font(DesignTokens.Typography.bodySmall)
                        .foregroundColor(DesignTokens.Colors.textSecondary.opacity(0.7))
                }

                Spacer()

                // Character counter
                if let limit = characterLimit {
                    Text("\(text.count)/\(limit)")
                        .font(DesignTokens.Typography.bodySmall)
                        .foregroundColor(
                            text.count >= limit
                                ? .orange
                                : DesignTokens.Colors.textSecondary.opacity(0.7)
                        )
                }
            }
        }
    }
}

struct InteractiveDatePickerView: View {
    let label: String?
    @Binding var date: Date
    let required: Bool

    var body: some View {
        InteractiveFieldWrapper(label: label, required: required, errorMessage: nil) {
            DatePicker("", selection: $date, displayedComponents: [.date])
                .datePickerStyle(.compact)
                .labelsHidden()
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

struct InteractiveTimePickerView: View {
    let label: String?
    @Binding var date: Date
    let required: Bool

    var body: some View {
        InteractiveFieldWrapper(label: label, required: required, errorMessage: nil) {
            DatePicker("", selection: $date, displayedComponents: [.hourAndMinute])
                .datePickerStyle(.compact)
                .labelsHidden()
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

struct InteractiveDateTimePickerView: View {
    let label: String?
    @Binding var date: Date
    let required: Bool

    var body: some View {
        InteractiveFieldWrapper(label: label, required: required, errorMessage: nil) {
            DatePicker("", selection: $date, displayedComponents: [.date, .hourAndMinute])
                .datePickerStyle(.compact)
                .labelsHidden()
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

struct InteractiveToggleView: View {
    let label: String
    @Binding var isOn: Bool

    var body: some View {
        InteractiveFieldWrapper(label: label, required: false, errorMessage: nil, showBackground: false) {
            HStack {
                Text(label)
                    .font(DesignTokens.Typography.bodyMedium)
                    .foregroundColor(DesignTokens.Colors.textPrimary)
                Spacer()
                Toggle("", isOn: $isOn)
                    .labelsHidden()
                    .tint(DesignTokens.Colors.accentBlue)
            }
            .padding(12)
            .background(Color.white.opacity(0.1))
            .cornerRadius(DesignTokens.Radius.button)
        }
    }
}

struct InteractivePickerView: View {
    let label: String?
    @Binding var selection: String
    let options: [String]
    let required: Bool

    var body: some View {
        InteractiveFieldWrapper(label: label, required: required, errorMessage: nil) {
            Picker("", selection: $selection) {
                ForEach(options, id: \.self) { option in
                    Text(option).tag(option)
                }
            }
            .pickerStyle(.menu)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

struct EnhancedPickerView: View {
    let label: String?
    @Binding var selection: String
    let options: [PickerOption]
    let required: Bool
    let helpText: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Label with required indicator
            if let label = label {
                HStack(spacing: 4) {
                    Text(label)
                        .font(DesignTokens.Typography.bodySmall)
                        .foregroundColor(DesignTokens.Colors.textSecondary)
                    if required {
                        Text("*")
                            .foregroundColor(.red)
                            .font(DesignTokens.Typography.bodySmall)
                    }
                }
            }

            // Enhanced picker with icons
            Menu {
                ForEach(options) { option in
                    Button {
                        selection = option.value
                    } label: {
                        HStack {
                            if let icon = option.icon {
                                Image(systemName: icon)
                            }
                            VStack(alignment: .leading) {
                                Text(option.label)
                                if let description = option.description {
                                    Text(description)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }
                        }
                    }
                }
            } label: {
                HStack {
                    // Show selected option with icon
                    if let selectedOption = options.first(where: { $0.value == selection }) {
                        if let icon = selectedOption.icon {
                            Image(systemName: icon)
                                .foregroundColor(DesignTokens.Colors.accentBlue)
                        }
                        Text(selectedOption.label)
                            .font(DesignTokens.Typography.bodyMedium)
                            .foregroundColor(DesignTokens.Colors.textPrimary)
                    } else {
                        Text("Select option")
                            .font(DesignTokens.Typography.bodyMedium)
                            .foregroundColor(DesignTokens.Colors.textSecondary)
                    }
                    Spacer()
                    Image(systemName: "chevron.down")
                        .font(.system(size: 14))
                        .foregroundColor(DesignTokens.Colors.textSecondary)
                }
                .padding(12)
                .background(Color.white.opacity(0.1))
                .cornerRadius(DesignTokens.Radius.button)
            }

            // Help text
            if let helpText = helpText {
                Text(helpText)
                    .font(DesignTokens.Typography.bodySmall)
                    .foregroundColor(DesignTokens.Colors.textSecondary.opacity(0.7))
            }
        }
    }
}

struct InteractiveSliderView: View {
    let label: String?
    @Binding var value: Double
    let range: ClosedRange<Double>

    var body: some View {
        InteractiveFieldWrapper(label: nil, required: false, errorMessage: nil, showBackground: false) {
            VStack(alignment: .leading, spacing: 8) {
                if let label = label {
                    HStack {
                        Text(label)
                            .font(DesignTokens.Typography.bodySmall)
                            .foregroundColor(DesignTokens.Colors.textSecondary)
                        Spacer()
                        Text(String(format: "%.0f", value))
                            .font(DesignTokens.Typography.bodyMedium)
                            .foregroundColor(DesignTokens.Colors.textPrimary)
                    }
                }
                Slider(value: $value, in: range)
                    .tint(DesignTokens.Colors.accentBlue)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(Color.white.opacity(0.1))
                    .cornerRadius(DesignTokens.Radius.button)
            }
        }
    }
}

struct InteractiveCheckboxView: View {
    let label: String
    @Binding var isChecked: Bool

    var body: some View {
        InteractiveFieldWrapper(label: nil, required: false, errorMessage: nil, showBackground: false) {
            Button {
                isChecked.toggle()
            } label: {
                HStack(spacing: 12) {
                    Image(systemName: isChecked ? "checkmark.square.fill" : "square")
                        .font(.system(size: 22))
                        .foregroundColor(isChecked ? DesignTokens.Colors.accentBlue : DesignTokens.Colors.textSecondary)
                    Text(label)
                        .font(DesignTokens.Typography.bodyMedium)
                        .foregroundColor(DesignTokens.Colors.textPrimary)
                    Spacer()
                }
                .padding(12)
                .background(Color.white.opacity(0.1))
                .cornerRadius(DesignTokens.Radius.button)
            }
        }
    }
}

// MARK: - Advanced Interactive Field Views (Phase 2.2)

struct InteractiveSegmentedControlView: View {
    let label: String?
    @Binding var selection: String
    let options: [String]

    var body: some View {
        InteractiveFieldWrapper(label: label, required: false, errorMessage: nil, showBackground: false) {
            Picker("", selection: $selection) {
                ForEach(options, id: \.self) { option in
                    Text(option).tag(option)
                }
            }
            .pickerStyle(.segmented)
            .padding(.vertical, 4)
        }
    }
}

struct InteractiveStepperView: View {
    let label: String?
    @Binding var value: Int
    let range: ClosedRange<Int>

    var body: some View {
        InteractiveFieldWrapper(label: nil, required: false, errorMessage: nil) {
            HStack {
                if let label = label {
                    Text(label)
                        .font(DesignTokens.Typography.bodyMedium)
                        .foregroundColor(DesignTokens.Colors.textPrimary)
                }
                Spacer()
                Stepper(
                    value: $value,
                    in: range,
                    step: 1
                ) {
                    Text("\(value)")
                        .font(DesignTokens.Typography.bodyMedium)
                        .foregroundColor(DesignTokens.Colors.textPrimary)
                }
            }
        }
    }
}

struct InteractiveRatingView: View {
    let label: String?
    @Binding var rating: Int

    var body: some View {
        InteractiveFieldWrapper(label: label, required: false, errorMessage: nil) {
            HStack(spacing: 12) {
                ForEach(1...5, id: \.self) { star in
                    Button {
                        rating = star
                    } label: {
                        Image(systemName: star <= rating ? "star.fill" : "star")
                            .font(.system(size: 28))
                            .foregroundColor(star <= rating ? .yellow : DesignTokens.Colors.textSecondary)
                    }
                }
            }
        }
    }
}

// MARK: - Preview

#if DEBUG
struct GenericActionModal_Previews: PreviewProvider {
    static var previews: some View {
        Text("Preview not available - use in running app")
            .foregroundColor(.white)
    }
}
#endif
