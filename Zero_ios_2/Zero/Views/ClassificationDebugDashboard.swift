//
//  ClassificationDebugDashboard.swift
//  Zero
//
//  Comprehensive debug dashboard for classification pipeline inspection
//  Includes all 5 dashboards: Intent, Entities, Rules, Mail/Ads, Pipeline Trace
//

import SwiftUI

#if DEBUG
struct ClassificationDebugDashboard: View {
    let card: EmailCard
    @StateObject private var viewModel = ClassificationDebugViewModel()
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationView {
            ZStack {
                // Dark background
                Color.black.edgesIgnoringSafeArea(.all)

                if viewModel.isLoading {
                    loadingView
                } else if let error = viewModel.error {
                    errorView(error)
                } else if let debugData = viewModel.debugData {
                    dashboardContent(debugData)
                }
            }
            .navigationTitle("Classification Debug")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Close") {
                        dismiss()
                    }
                    .foregroundColor(.white)
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        viewModel.fetchDebugData(for: card)
                    }) {
                        Image(systemName: "arrow.clockwise")
                            .foregroundColor(.white)
                    }
                }
            }
        }
        .onAppear {
            viewModel.fetchDebugData(for: card)
        }
    }

    // MARK: - Loading View

    private var loadingView: some View {
        LoadingSpinner(text: "Analyzing classification pipeline...", size: .medium)
    }

    // MARK: - Error View

    private func errorView(_ error: String) -> some View {
        GenericEmptyState(
            icon: "exclamationmark.triangle",
            title: "Debug Error",
            message: error,
            action: ("Retry", { viewModel.fetchDebugData(for: card) })
        )
    }

    // MARK: - Dashboard Content

    private func dashboardContent(_ debugData: ClassificationDebugData) -> some View {
        VStack(spacing: 0) {
            // Synthetic data warning banner (if applicable)
            if debugData.debugInfo.isMockData == true {
                syntheticDataBanner(debugData.debugInfo.mockDataWarning ?? "Synthetic data")
            }

            TabView {
                // Dashboard 1: Intent Classification Inspector
                IntentClassificationView(debugData: debugData)
                    .tabItem {
                        Label("Intent", systemImage: "target")
                    }

                // Dashboard 2: Entity Extraction Validator
                EntityExtractionView(debugData: debugData)
                    .tabItem {
                        Label("Entities", systemImage: "list.bullet.rectangle")
                    }

                // Dashboard 3: Rules Engine Debug Panel
                RulesEngineView(debugData: debugData)
                    .tabItem {
                        Label("Rules", systemImage: "gearshape.2")
                    }

                // Dashboard 4: Mail vs Ads Accuracy Monitor
                MailAdsClassificationView(debugData: debugData)
                    .tabItem {
                        Label("Mail/Ads", systemImage: "envelope.badge")
                    }

                // Dashboard 5: End-to-End Pipeline Trace
                PipelineTraceView(debugData: debugData)
                    .tabItem {
                        Label("Pipeline", systemImage: "arrow.triangle.branch")
                    }
            }
            .accentColor(.blue)
        }
    }

    private func syntheticDataBanner(_ warning: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundColor(.orange)
                .font(.title3)

            VStack(alignment: .leading, spacing: 4) {
                Text("SYNTHETIC DATA")
                    .font(.caption.bold())
                    .foregroundColor(.orange)

                Text(warning)
                    .font(.caption2)
                    .foregroundColor(.white.opacity(DesignTokens.Opacity.textTertiary))
                    .lineLimit(2)
            }

            Spacer()
        }
        .padding()
        .background(Color.orange.opacity(0.15))
        .overlay(
            Rectangle()
                .fill(Color.orange)
                .frame(height: 3),
            alignment: .top
        )
    }
}

// MARK: - Dashboard 1: Intent Classification Inspector

struct IntentClassificationView: View {
    let debugData: ClassificationDebugData

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // Header
                sectionHeader(
                    title: "Intent Classification",
                    subtitle: "Detected intent with confidence scores and match breakdown"
                )

                // Detected Intent Card
                detectedIntentCard

                // Confidence Thresholds
                confidenceThresholdsCard

                // Match Breakdown
                matchBreakdownCard

                // All Intent Scores
                allIntentScoresCard
            }
            .padding()
        }
        .background(Color.black)
    }

    private var detectedIntentCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Detected Intent")
                .font(.headline)
                .foregroundColor(.white)

            HStack {
                VStack(alignment: .leading, spacing: 8) {
                    Text(debugData.intentClassification.detectedIntent)
                        .font(.title3.bold())
                        .foregroundColor(.blue)

                    HStack {
                        confidenceBadge

                        Text("•")
                            .foregroundColor(.white.opacity(DesignTokens.Opacity.overlayMedium))

                        Text(debugData.intentClassification.source)
                            .font(.caption)
                            .foregroundColor(.white.opacity(DesignTokens.Opacity.textDisabled))

                        Spacer()

                        Text(debugData.intentClassification.processingTime)
                            .font(.caption)
                            .foregroundColor(.white.opacity(DesignTokens.Opacity.textDisabled))
                    }
                }

                Spacer()
            }
        }
        .padding()
        .background(Color.white.opacity(DesignTokens.Opacity.glassUltraLight))
        .cornerRadius(DesignTokens.Radius.button)
    }

    private var confidenceBadge: some View {
        let confidence = debugData.intentClassification.confidence
        let color: Color = confidence >= 0.85 ? .green : confidence >= 0.3 ? .orange : .red

        return HStack(spacing: 4) {
            Circle()
                .fill(color)
                .frame(width: 8, height: 8)

            Text("\(Int(confidence * 100))%")
                .font(.caption.bold())
                .foregroundColor(color)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(color.opacity(DesignTokens.Opacity.overlayLight))
        .cornerRadius(DesignTokens.Radius.chip)
    }

    private var confidenceThresholdsCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Confidence Thresholds")
                .font(.headline)
                .foregroundColor(.white)

            let thresholds = debugData.intentClassification.thresholds

            VStack(spacing: 8) {
                thresholdRow(
                    label: "Minimum Threshold",
                    value: thresholds.minimum,
                    met: thresholds.currentMeetsMinimum
                )

                thresholdRow(
                    label: "High Confidence",
                    value: thresholds.highConfidence,
                    met: thresholds.currentIsHighConfidence
                )

                thresholdRow(
                    label: "Current Confidence",
                    value: debugData.intentClassification.confidence,
                    met: true,
                    isCurrentValue: true
                )
            }
        }
        .padding()
        .background(Color.white.opacity(DesignTokens.Opacity.glassUltraLight))
        .cornerRadius(DesignTokens.Radius.button)
    }

    private func thresholdRow(label: String, value: Double, met: Bool, isCurrentValue: Bool = false) -> some View {
        HStack {
            Text(label)
                .font(.subheadline)
                .foregroundColor(.white.opacity(DesignTokens.Opacity.textTertiary))

            Spacer()

            Text("\(Int(value * 100))%")
                .font(.subheadline.bold())
                .foregroundColor(isCurrentValue ? .blue : .white.opacity(DesignTokens.Opacity.textDisabled))

            if !isCurrentValue {
                Image(systemName: met ? "checkmark.circle.fill" : "xmark.circle.fill")
                    .foregroundColor(met ? .green : .red)
                    .font(.caption)
            }
        }
    }

    private var matchBreakdownCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Match Breakdown")
                .font(.headline)
                .foregroundColor(.white)

            if debugData.intentClassification.matchBreakdown.isEmpty {
                Text("No pattern matches")
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(DesignTokens.Opacity.overlayStrong))
            } else {
                ForEach(Array(debugData.intentClassification.matchBreakdown.enumerated()), id: \.offset) { _, match in
                    matchRow(match)
                }
            }
        }
        .padding()
        .background(Color.white.opacity(DesignTokens.Opacity.glassUltraLight))
        .cornerRadius(DesignTokens.Radius.button)
    }

    private func matchRow(_ match: PatternMatch) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(match.pattern)
                    .font(.subheadline.bold())
                    .foregroundColor(.white)

                Text(match.location)
                    .font(.caption)
                    .foregroundColor(.white.opacity(DesignTokens.Opacity.textDisabled))
            }

            Spacer()

            Text("+\(match.weight)")
                .font(.subheadline.bold())
                .foregroundColor(.blue)
        }
        .padding(.vertical, 4)
    }

    private var allIntentScoresCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("All Intent Scores")
                .font(.headline)
                .foregroundColor(.white)

            ForEach(debugData.intentClassification.topIntents.prefix(5), id: \.intent) { intent, confidence in
                intentScoreRow(intent: intent, confidence: confidence)
            }
        }
        .padding()
        .background(Color.white.opacity(DesignTokens.Opacity.glassUltraLight))
        .cornerRadius(DesignTokens.Radius.button)
    }

    private func intentScoreRow(intent: String, confidence: Double) -> some View {
        HStack {
            Text(intent)
                .font(.subheadline)
                .foregroundColor(.white.opacity(DesignTokens.Opacity.textSecondary))
                .lineLimit(1)

            Spacer()

            ZStack(alignment: .leading) {
                GeometryReader { geo in
                    Rectangle()
                        .fill(Color.white.opacity(DesignTokens.Opacity.glassLight))

                    Rectangle()
                        .fill(Color.blue)
                        .frame(width: geo.size.width * CGFloat(confidence))
                }
            }
            .frame(width: 80, height: 6)
            .cornerRadius(3)

            Text("\(Int(confidence * 100))%")
                .font(.caption)
                .foregroundColor(.white.opacity(DesignTokens.Opacity.textDisabled))
                .frame(width: 40, alignment: .trailing)
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Dashboard 2: Entity Extraction Validator

struct EntityExtractionView: View {
    let debugData: ClassificationDebugData

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                sectionHeader(
                    title: "Entity Extraction",
                    subtitle: "Extracted entities and validation status"
                )

                // Validation Status
                validationStatusCard

                // Required Entities
                if !debugData.entityExtraction.requiredForIntent.isEmpty {
                    requiredEntitiesCard
                }

                // Extracted Entities
                extractedEntitiesCard
            }
            .padding()
        }
        .background(Color.black)
    }

    private var validationStatusCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Validation Status")
                .font(.headline)
                .foregroundColor(.white)

            let validation = debugData.entityExtraction.validation

            VStack(spacing: 8) {
                entityValidationRow(label: "Deadline", present: validation.hasDeadline)
                entityValidationRow(label: "Prices", present: validation.hasPrices)
                entityValidationRow(label: "Tracking Numbers", present: validation.hasTrackingNumbers)
                entityValidationRow(label: "Children", present: validation.hasChildren)
                entityValidationRow(label: "Companies", present: validation.hasCompanies)
            }

            if !debugData.entityExtraction.missingRequiredEntities.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Divider()
                        .background(Color.white.opacity(DesignTokens.Opacity.overlayLight))

                    HStack {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundColor(.orange)

                        Text("Missing Required: \(debugData.entityExtraction.missingRequiredEntities.joined(separator: ", "))")
                            .font(.subheadline)
                            .foregroundColor(.orange)
                    }
                }
            }
        }
        .padding()
        .background(Color.white.opacity(DesignTokens.Opacity.glassUltraLight))
        .cornerRadius(DesignTokens.Radius.button)
    }

    private func entityValidationRow(label: String, present: Bool) -> some View {
        HStack {
            Image(systemName: present ? "checkmark.circle.fill" : "circle")
                .foregroundColor(present ? .green : .white.opacity(DesignTokens.Opacity.overlayMedium))

            Text(label)
                .font(.subheadline)
                .foregroundColor(.white.opacity(DesignTokens.Opacity.textTertiary))

            Spacer()
        }
    }

    private var requiredEntitiesCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Required for Intent")
                .font(.headline)
                .foregroundColor(.white)

            ForEach(debugData.entityExtraction.requiredForIntent, id: \.self) { entity in
                let isMissing = debugData.entityExtraction.missingRequiredEntities.contains(entity)

                HStack {
                    Image(systemName: isMissing ? "xmark.circle.fill" : "checkmark.circle.fill")
                        .foregroundColor(isMissing ? .red : .green)

                    Text(entity)
                        .font(.subheadline)
                        .foregroundColor(.white)

                    Spacer()

                    if isMissing {
                        Text("MISSING")
                            .font(.caption.bold())
                            .foregroundColor(.red)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.red.opacity(DesignTokens.Opacity.overlayLight))
                            .cornerRadius(DesignTokens.Radius.minimal)
                    }
                }
            }
        }
        .padding()
        .background(Color.white.opacity(DesignTokens.Opacity.glassUltraLight))
        .cornerRadius(DesignTokens.Radius.button)
    }

    private var extractedEntitiesCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Extracted Entities")
                .font(.headline)
                .foregroundColor(.white)

            let entities = debugData.entityExtraction.extractedEntities

            if let deadline = entities.deadline {
                entityRow(
                    icon: "calendar",
                    label: "Deadline",
                    value: deadline.text,
                    badge: deadline.isUrgent ? "URGENT" : nil
                )
            }

            if let price = entities.prices.original {
                entityRow(icon: "dollarsign.circle", label: "Price", value: price)
            }

            if !entities.trackingNumbers.isEmpty {
                entityRow(icon: "shippingbox", label: "Tracking", value: entities.trackingNumbers.joined(separator: ", "))
            }

            if !entities.stores.isEmpty {
                entityRow(icon: "storefront", label: "Stores", value: entities.stores.joined(separator: ", "))
            }

            if !entities.children.isEmpty {
                entityRow(icon: "person.2", label: "Children", value: entities.children.joined(separator: ", "))
            }

            if !entities.companies.isEmpty {
                entityRow(icon: "building.2", label: "Companies", value: entities.companies.joined(separator: ", "))
            }

            if entities.trackingNumbers.isEmpty && entities.prices.original == nil && entities.deadline == nil && entities.stores.isEmpty && entities.children.isEmpty && entities.companies.isEmpty {
                Text("No entities extracted")
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(DesignTokens.Opacity.overlayStrong))
            }
        }
        .padding()
        .background(Color.white.opacity(DesignTokens.Opacity.glassUltraLight))
        .cornerRadius(DesignTokens.Radius.button)
    }

    private func entityRow(icon: String, label: String, value: String, badge: String? = nil) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(.blue)
                .frame(width: 24)

            VStack(alignment: .leading, spacing: 4) {
                Text(label)
                    .font(.caption)
                    .foregroundColor(.white.opacity(DesignTokens.Opacity.textDisabled))

                Text(value)
                    .font(.subheadline)
                    .foregroundColor(.white)
            }

            Spacer()

            if let badge = badge {
                Text(badge)
                    .font(.caption2.bold())
                    .foregroundColor(.red)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 3)
                    .background(Color.red.opacity(DesignTokens.Opacity.overlayLight))
                    .cornerRadius(DesignTokens.Radius.minimal)
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Dashboard 3: Rules Engine Debug Panel

struct RulesEngineView: View {
    let debugData: ClassificationDebugData

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                sectionHeader(
                    title: "Rules Engine",
                    subtitle: "Intent → Actions mapping and validation"
                )

                // Rule Match Status
                ruleMatchCard

                // Suggested Actions
                if !debugData.rulesEngine.suggestedActions.isEmpty {
                    suggestedActionsCard
                }

                // Action Validation
                if !debugData.rulesEngine.actionValidation.isEmpty {
                    actionValidationCard
                }
            }
            .padding()
        }
        .background(Color.black)
    }

    private var ruleMatchCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: debugData.rulesEngine.matchedRule ? "checkmark.circle.fill" : "xmark.circle.fill")
                    .foregroundColor(debugData.rulesEngine.matchedRule ? .green : .red)
                    .font(.title2)

                VStack(alignment: .leading, spacing: 4) {
                    Text(debugData.rulesEngine.matchedRule ? "Rule Matched" : "No Rule Match")
                        .font(.headline)
                        .foregroundColor(.white)

                    Text(debugData.rulesEngine.intent)
                        .font(.caption)
                        .foregroundColor(.white.opacity(DesignTokens.Opacity.textDisabled))
                }

                Spacer()

                Text(debugData.rulesEngine.processingTime)
                    .font(.caption)
                    .foregroundColor(.white.opacity(DesignTokens.Opacity.textDisabled))
            }

            Text(debugData.rulesEngine.reasoning)
                .font(.subheadline)
                .foregroundColor(.white.opacity(DesignTokens.Opacity.textTertiary))
                .padding(.top, 8)
        }
        .padding()
        .background(Color.white.opacity(DesignTokens.Opacity.glassUltraLight))
        .cornerRadius(DesignTokens.Radius.button)
    }

    private var suggestedActionsCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Suggested Actions (\(debugData.rulesEngine.suggestedActions.count))")
                .font(.headline)
                .foregroundColor(.white)

            ForEach(debugData.rulesEngine.suggestedActions, id: \.actionId) { action in
                actionCard(action)
            }
        }
        .padding()
        .background(Color.white.opacity(DesignTokens.Opacity.glassUltraLight))
        .cornerRadius(DesignTokens.Radius.button)
    }

    private func actionCard(_ action: SuggestedAction) -> some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(action.displayName)
                        .font(.subheadline.bold())
                        .foregroundColor(.white)

                    if action.isPrimary {
                        Text("PRIMARY")
                            .font(.caption2.bold())
                            .foregroundColor(.blue)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.blue.opacity(DesignTokens.Opacity.overlayLight))
                            .cornerRadius(DesignTokens.Radius.minimal)
                    }
                }

                Text(action.actionId)
                    .font(.caption)
                    .foregroundColor(.white.opacity(DesignTokens.Opacity.overlayStrong))

                Text(action.endpoint)
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.4))
            }

            Spacer()

            VStack(alignment: .trailing) {
                Text("P\(action.priority)")
                    .font(.caption.bold())
                    .foregroundColor(.blue)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.blue.opacity(DesignTokens.Opacity.overlayLight))
                    .cornerRadius(DesignTokens.Radius.minimal)
            }
        }
        .padding()
        .background(Color.white.opacity(DesignTokens.Opacity.glassUltraLight))
        .cornerRadius(DesignTokens.Radius.chip)
    }

    private var actionValidationCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Action Validation")
                .font(.headline)
                .foregroundColor(.white)

            ForEach(debugData.rulesEngine.actionValidation, id: \.actionId) { validation in
                validationRow(validation)
            }
        }
        .padding()
        .background(Color.white.opacity(DesignTokens.Opacity.glassUltraLight))
        .cornerRadius(DesignTokens.Radius.button)
    }

    private func validationRow(_ validation: ActionValidation) -> some View {
        HStack {
            Image(systemName: validation.endpointExists ? "checkmark.circle.fill" : "xmark.circle.fill")
                .foregroundColor(validation.endpointExists ? .green : .red)

            VStack(alignment: .leading, spacing: 4) {
                Text(validation.displayName)
                    .font(.subheadline)
                    .foregroundColor(.white)

                Text(validation.endpoint)
                    .font(.caption)
                    .foregroundColor(.white.opacity(DesignTokens.Opacity.overlayStrong))
            }

            Spacer()
        }
    }
}

// MARK: - Dashboard 4: Mail vs Ads Classification

struct MailAdsClassificationView: View {
    let debugData: ClassificationDebugData

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                sectionHeader(
                    title: "Mail vs Ads Classification",
                    subtitle: "Binary classification with detection signals"
                )

                // Final Decision
                finalDecisionCard

                // Detection Signals
                detectionSignalsCard

                // Reasoning Breakdown
                reasoningCard
            }
            .padding()
        }
        .background(Color.black)
    }

    private var finalDecisionCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Final Classification")
                        .font(.headline)
                        .foregroundColor(.white)

                    HStack(spacing: 12) {
                        Text(debugData.mailAdsClassification.finalCategory)
                            .font(.title.bold())
                            .foregroundColor(debugData.mailAdsClassification.finalCategory == "mail" ? .blue : .orange)

                        confidenceIndicator
                    }
                }

                Spacer()

                Text(debugData.mailAdsClassification.processingTime)
                    .font(.caption)
                    .foregroundColor(.white.opacity(DesignTokens.Opacity.textDisabled))
            }

            Text(debugData.mailAdsClassification.classificationReason)
                .font(.subheadline)
                .foregroundColor(.white.opacity(DesignTokens.Opacity.textTertiary))
                .padding(.top, 8)
        }
        .padding()
        .background(Color.white.opacity(DesignTokens.Opacity.glassUltraLight))
        .cornerRadius(DesignTokens.Radius.button)
    }

    private var confidenceIndicator: some View {
        let isHighConfidence = debugData.mailAdsClassification.accuracy.confidence == "high"

        return HStack(spacing: 4) {
            Circle()
                .fill(isHighConfidence ? Color.green : Color.orange)
                .frame(width: 8, height: 8)

            Text(debugData.mailAdsClassification.accuracy.confidence.uppercased())
                .font(.caption.bold())
                .foregroundColor(isHighConfidence ? .green : .orange)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background((isHighConfidence ? Color.green : Color.orange).opacity(DesignTokens.Opacity.overlayLight))
        .cornerRadius(DesignTokens.Radius.minimal)
    }

    private var detectionSignalsCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Detection Signals")
                .font(.headline)
                .foregroundColor(.white)

            let signals = debugData.mailAdsClassification.signals

            signalRow(
                icon: "link",
                label: "Unsubscribe Link",
                active: signals.unsubscribeLink
            )

            signalRow(
                icon: "tag",
                label: "Promo Keywords (\(signals.promoKeywords.count)/\(signals.promoKeywords.threshold))",
                active: signals.promoKeywords.count >= signals.promoKeywords.threshold,
                detail: signals.promoKeywords.matches.isEmpty ? nil : signals.promoKeywords.matches.joined(separator: ", ")
            )

            signalRow(
                icon: "envelope.badge",
                label: "Marketing Sender",
                active: signals.marketingSender
            )

            signalRow(
                icon: "target",
                label: "Intent-Based",
                active: signals.intentBased
            )
        }
        .padding()
        .background(Color.white.opacity(DesignTokens.Opacity.glassUltraLight))
        .cornerRadius(DesignTokens.Radius.button)
    }

    private func signalRow(icon: String, label: String, active: Bool, detail: String? = nil) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(active ? .orange : .white.opacity(DesignTokens.Opacity.overlayMedium))
                    .frame(width: 24)

                Text(label)
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(DesignTokens.Opacity.textTertiary))

                Spacer()

                Image(systemName: active ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(active ? .orange : .white.opacity(DesignTokens.Opacity.overlayMedium))
            }

            if let detail = detail {
                Text(detail)
                    .font(.caption)
                    .foregroundColor(.white.opacity(DesignTokens.Opacity.overlayStrong))
                    .padding(.leading, 36)
            }
        }
        .padding(.vertical, 4)
    }

    private var reasoningCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Detailed Reasoning")
                .font(.headline)
                .foregroundColor(.white)

            let reasoning = debugData.mailAdsClassification.reasoning

            reasoningDetailRow(label: "Unsubscribe Header", value: reasoning.hasUnsubscribeHeader)
            reasoningDetailRow(label: "Unsubscribe Link", value: reasoning.hasUnsubscribeLink)
            reasoningDetailRow(label: "Promo Keyword Matches", value: "\(reasoning.promoKeywordMatches)")

            if !reasoning.matchedPromoKeywords.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Matched Keywords:")
                        .font(.caption)
                        .foregroundColor(.white.opacity(DesignTokens.Opacity.textDisabled))

                    Text(reasoning.matchedPromoKeywords.joined(separator: ", "))
                        .font(.caption)
                        .foregroundColor(.white.opacity(DesignTokens.Opacity.overlayStrong))
                }
                .padding(.vertical, 4)
            }

            reasoningDetailRow(label: "Marketing Sender", value: reasoning.marketingSenderMatch)

            if let pattern = reasoning.matchedSenderPattern {
                Text("Pattern: \(pattern)")
                    .font(.caption)
                    .foregroundColor(.white.opacity(DesignTokens.Opacity.overlayStrong))
                    .padding(.leading, 16)
            }

            reasoningDetailRow(label: "Intent-Based Detection", value: reasoning.intentBased)
        }
        .padding()
        .background(Color.white.opacity(DesignTokens.Opacity.glassUltraLight))
        .cornerRadius(DesignTokens.Radius.button)
    }

    private func reasoningDetailRow(label: String, value: Any) -> some View {
        HStack {
            Text(label)
                .font(.subheadline)
                .foregroundColor(.white.opacity(DesignTokens.Opacity.textTertiary))

            Spacer()

            if let boolValue = value as? Bool {
                Text(boolValue ? "YES" : "NO")
                    .font(.subheadline.bold())
                    .foregroundColor(boolValue ? .green : .white.opacity(DesignTokens.Opacity.overlayStrong))
            } else {
                Text("\(value)")
                    .font(.subheadline.bold())
                    .foregroundColor(.white)
            }
        }
    }
}

// MARK: - Dashboard 5: Pipeline Trace

struct PipelineTraceView: View {
    let debugData: ClassificationDebugData

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                sectionHeader(
                    title: "Pipeline Trace",
                    subtitle: "End-to-end classification pipeline steps"
                )

                // Overall Status
                overallStatusCard

                // Pipeline Steps
                pipelineStepsCard
            }
            .padding()
        }
        .background(Color.black)
    }

    private var overallStatusCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: debugData.pipelineTrace.allStepsSuccessful ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
                    .foregroundColor(debugData.pipelineTrace.allStepsSuccessful ? .green : .orange)
                    .font(.title2)

                VStack(alignment: .leading, spacing: 4) {
                    Text(debugData.pipelineTrace.allStepsSuccessful ? "All Steps Successful" : "Pipeline Issues")
                        .font(.headline)
                        .foregroundColor(.white)

                    Text("\(debugData.pipelineTrace.steps.count) steps • \(debugData.pipelineTrace.totalTime)")
                        .font(.caption)
                        .foregroundColor(.white.opacity(DesignTokens.Opacity.textDisabled))
                }

                Spacer()
            }

            if !debugData.pipelineTrace.errors.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    Divider()
                        .background(Color.white.opacity(DesignTokens.Opacity.overlayLight))

                    Text("Errors:")
                        .font(.caption.bold())
                        .foregroundColor(.red)

                    ForEach(debugData.pipelineTrace.errors, id: \.self) { error in
                        Text("• \(error)")
                            .font(.caption)
                            .foregroundColor(.red.opacity(DesignTokens.Opacity.textTertiary))
                    }
                }
            }
        }
        .padding()
        .background(Color.white.opacity(DesignTokens.Opacity.glassUltraLight))
        .cornerRadius(DesignTokens.Radius.button)
    }

    private var pipelineStepsCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Pipeline Steps")
                .font(.headline)
                .foregroundColor(.white)

            ForEach(debugData.pipelineTrace.steps, id: \.step) { step in
                pipelineStepRow(step)
            }
        }
        .padding()
        .background(Color.white.opacity(DesignTokens.Opacity.glassUltraLight))
        .cornerRadius(DesignTokens.Radius.button)
    }

    private func pipelineStepRow(_ step: PipelineStep) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                // Step number
                Text("\(step.step)")
                    .font(.caption.bold())
                    .foregroundColor(.blue)
                    .frame(width: 24, height: 24)
                    .background(Color.blue.opacity(DesignTokens.Opacity.overlayLight))
                    .clipShape(Circle())

                // Step name
                Text(step.name)
                    .font(.subheadline.bold())
                    .foregroundColor(.white)

                Spacer()

                // Status badge
                statusBadge(step.status)

                // Time
                Text(step.time)
                    .font(.caption)
                    .foregroundColor(.white.opacity(DesignTokens.Opacity.textDisabled))
            }

            // Result
            Text(step.result)
                .font(.caption)
                .foregroundColor(.white.opacity(DesignTokens.Opacity.textSubtle))
                .padding(.leading, 36)

            // Reasoning (if any)
            if let reasoning = step.reasoning, !reasoning.isEmpty {
                VStack(alignment: .leading, spacing: 2) {
                    ForEach(reasoning, id: \.self) { reason in
                        Text("• \(reason)")
                            .font(.caption)
                            .foregroundColor(.white.opacity(DesignTokens.Opacity.overlayStrong))
                    }
                }
                .padding(.leading, 36)
            }

            // Error (if any)
            if let error = step.error {
                Text("Error: \(error)")
                    .font(.caption)
                    .foregroundColor(.red.opacity(DesignTokens.Opacity.textTertiary))
                    .padding(.leading, 36)
            }
        }
        .padding(.vertical, 8)
    }

    private func statusBadge(_ status: String) -> some View {
        let (color, icon): (Color, String) = {
            switch status {
            case "success":
                return (.green, "checkmark")
            case "found":
                return (.green, "checkmark.circle.fill")
            case "not-found":
                return (.gray, "circle")
            case "no-match":
                return (.orange, "exclamationmark.circle")
            default:
                return (.blue, "circle")
            }
        }()

        return HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.caption2)

            Text(status.uppercased())
                .font(.caption2.bold())
        }
        .foregroundColor(color)
        .padding(.horizontal, 6)
        .padding(.vertical, 3)
        .background(color.opacity(DesignTokens.Opacity.overlayLight))
        .cornerRadius(DesignTokens.Radius.minimal)
    }
}

// MARK: - Shared Components

private func sectionHeader(title: String, subtitle: String) -> some View {
    VStack(alignment: .leading, spacing: 4) {
        Text(title)
            .font(.title2.bold())
            .foregroundColor(.white)

        Text(subtitle)
            .font(.subheadline)
            .foregroundColor(.white.opacity(DesignTokens.Opacity.textDisabled))
    }
}

// MARK: - View Model

class ClassificationDebugViewModel: ObservableObject {
    @Published var debugData: ClassificationDebugData?
    @Published var isLoading = false
    @Published var error: String?

    func fetchDebugData(for card: EmailCard) {
        isLoading = true
        error = nil

        Task {
            do {
                let debugData = try await callDebugAPI(for: card)
                await MainActor.run {
                    self.debugData = debugData
                    self.isLoading = false
                }
            } catch {
                Logger.warning("Debug API failed, using synthetic mock data: \(error)", category: .app)

                // Fallback to mock data for development/testing
                let mockData = createMockDebugData(for: card)
                await MainActor.run {
                    self.debugData = mockData
                    self.isLoading = false
                }
            }
        }
    }

    private func callDebugAPI(for card: EmailCard) async throws -> ClassificationDebugData {
        // Week 6 Service Layer Cleanup: Using centralized NetworkService
        // Get classifier service URL from Constants (auto-selects dev/prod)
        let baseURL = Constants.API.classifierServiceURL
        let urlString = "\(baseURL)/classify/debug"

        guard let url = URL(string: urlString) else {
            throw DebugAPIError.invalidURL
        }

        // Create type-safe request structure
        struct DebugAPIRequest: Codable {
            let email: EmailPayload

            struct EmailPayload: Codable {
                let id: String
                let subject: String
                let from: String
                let snippet: String
                let body: String
                let htmlBody: String
            }
        }

        let requestBody = DebugAPIRequest(
            email: DebugAPIRequest.EmailPayload(
                id: card.id,
                subject: card.title,
                from: card.sender?.name ?? "Unknown Sender",
                snippet: card.summary,
                body: card.body ?? "",
                htmlBody: card.htmlBody ?? ""
            )
        )

        Logger.info("Calling debug API: \(urlString)", category: .app)

        do {
            let debugData: ClassificationDebugData = try await NetworkService.shared.request(
                url: url,
                method: .post,
                body: requestBody
            )

            Logger.info("Debug data received successfully", category: .app)
            return debugData

        } catch let error as NetworkServiceError {
            if let statusCode = error.statusCode {
                Logger.error("Debug API error (\(statusCode))", category: .app)
                throw DebugAPIError.httpError(statusCode: statusCode)
            }
            throw DebugAPIError.invalidResponse
        } catch {
            throw DebugAPIError.invalidResponse
        }
    }
}

// MARK: - Debug API Errors

enum DebugAPIError: LocalizedError {
    case invalidURL
    case invalidResponse
    case httpError(statusCode: Int)

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid classifier service URL"
        case .invalidResponse:
            return "Invalid response from classifier service"
        case .httpError(let statusCode):
            return "Classifier service error (HTTP \(statusCode))"
        }
    }
}

// MARK: - Mock Data Generator

extension ClassificationDebugViewModel {
    /// Creates synthetic debug data for development/testing when backend is unavailable
    /// All data is clearly marked as SYNTHETIC to prevent confusion
    private func createMockDebugData(for card: EmailCard) -> ClassificationDebugData {
        // Determine mock intent based on card type
        let mockIntent: String
        let mockConfidence: Double
        let mockCategory: String

        switch card.type {
        case .mail:
            mockIntent = "education.permission.form"
            mockConfidence = 0.87
            mockCategory = "mail"
        case .ads:
            mockIntent = "e-commerce.promotion"
            mockConfidence = 0.92
            mockCategory = "ads"
        }

        return ClassificationDebugData(
            debugInfo: DebugInfo(
                timestamp: ISO8601DateFormatter().string(from: Date()),
                totalProcessingTime: "45ms",
                version: "v1.10-SYNTHETIC",
                classifierMode: "mock",
                isMockData: true,
                mockDataWarning: "⚠️ SYNTHETIC DATA - Backend unavailable. Start services: cd backend && npm run start:all"
            ),
            email: EmailInput(
                id: card.id,
                subject: card.title,
                from: card.sender?.name ?? "Mock Sender",
                snippet: card.summary,
                hasHtmlBody: card.htmlBody != nil
            ),
            intentClassification: IntentClassification(
                detectedIntent: mockIntent,
                confidence: mockConfidence,
                source: "pattern-matching",
                processingTime: "12ms",
                allIntentScores: [
                    mockIntent: IntentScore(
                        score: mockConfidence,
                        matches: [PatternMatch(location: "subject", pattern: "mock-pattern", weight: 40)],
                        confidence: mockConfidence
                    )
                ],
                matchBreakdown: [
                    PatternMatch(location: "subject", pattern: "mock-pattern", weight: 40),
                    PatternMatch(location: "snippet", pattern: "synthetic-data", weight: 25)
                ],
                thresholds: ConfidenceThresholds(
                    minimum: 0.3,
                    highConfidence: 0.85,
                    currentMeetsMinimum: true,
                    currentIsHighConfidence: mockConfidence >= 0.85
                )
            ),
            entityExtraction: EntityExtraction(
                extractedEntities: ExtractedEntities(
                    deadline: Deadline(text: "Oct 25, 2025", isUrgent: false),
                    prices: Prices(original: "$15.00"),
                    stores: ["Mock Store"],
                    promoCodes: [],
                    children: [],
                    companies: ["Mock Company"],
                    accounts: [],
                    flights: [],
                    hotels: [],
                    trackingNumbers: []
                ),
                processingTime: "8ms",
                validation: EntityValidation(
                    hasDeadline: true,
                    hasPrices: true,
                    hasTrackingNumbers: false,
                    hasChildren: false,
                    hasCompanies: true
                ),
                requiredForIntent: ["deadline", "price"],
                missingRequiredEntities: []
            ),
            rulesEngine: RulesEngine(
                matchedRule: true,
                intent: mockIntent,
                suggestedActions: [
                    SuggestedAction(
                        actionId: "sign_form",
                        displayName: "Sign Form",
                        isPrimary: true,
                        priority: 1,
                        endpoint: "/api/actions/sign-form"
                    )
                ],
                processingTime: "5ms",
                actionValidation: [
                    ActionValidation(
                        actionId: "sign_form",
                        displayName: "Sign Form",
                        isPrimary: true,
                        priority: 1,
                        endpoint: "/api/actions/sign-form",
                        endpointExists: true
                    )
                ],
                reasoning: "Mock rule matched based on synthetic intent"
            ),
            mailAdsClassification: MailAdsClassification(
                finalCategory: mockCategory,
                processingTime: "10ms",
                reasoning: AdDetectionReasoning(
                    hasUnsubscribeHeader: mockCategory == "ads",
                    hasUnsubscribeLink: mockCategory == "ads",
                    promoKeywordMatches: mockCategory == "ads" ? 3 : 0,
                    matchedPromoKeywords: mockCategory == "ads" ? ["sale", "discount", "offer"] : [],
                    marketingSenderMatch: mockCategory == "ads",
                    matchedSenderPattern: mockCategory == "ads" ? "marketing@" : nil,
                    intentBased: true,
                    finalDecision: mockCategory.uppercased()
                ),
                signals: AdDetectionSignals(
                    unsubscribeLink: mockCategory == "ads",
                    promoKeywords: PromoKeywordSignal(
                        count: mockCategory == "ads" ? 3 : 0,
                        threshold: 2,
                        matches: mockCategory == "ads" ? ["sale", "discount", "offer"] : []
                    ),
                    marketingSender: mockCategory == "ads",
                    intentBased: true
                ),
                accuracy: AccuracyInfo(
                    expectedCategory: mockCategory,
                    confidence: mockConfidence >= 0.85 ? "high" : "medium"
                )
            ),
            pipelineTrace: PipelineTrace(
                steps: [
                    PipelineStep(step: 1, name: "Schema.org Check", status: "not-found", time: "2ms", result: "No structured data", reasoning: ["SYNTHETIC"], error: nil),
                    PipelineStep(step: 2, name: "Intent Classification", status: "success", time: "12ms", result: mockIntent, reasoning: ["Mock pattern matching"], error: nil),
                    PipelineStep(step: 3, name: "Entity Extraction", status: "success", time: "8ms", result: "2 entities found", reasoning: nil, error: nil),
                    PipelineStep(step: 4, name: "Rules Engine", status: "success", time: "5ms", result: "1 action suggested", reasoning: nil, error: nil),
                    PipelineStep(step: 5, name: "Mail/Ads Detection", status: "success", time: "10ms", result: mockCategory.uppercased(), reasoning: nil, error: nil),
                    PipelineStep(step: 6, name: "Priority Assignment", status: "success", time: "3ms", result: "Priority 2", reasoning: nil, error: nil),
                    PipelineStep(step: 7, name: "HPA Detection", status: "success", time: "2ms", result: "HPA: true", reasoning: nil, error: nil),
                    PipelineStep(step: 8, name: "Urgency Scoring", status: "success", time: "2ms", result: "Urgency: medium", reasoning: nil, error: nil),
                    PipelineStep(step: 9, name: "Enrichment", status: "success", time: "1ms", result: "Metadata added", reasoning: nil, error: nil),
                    PipelineStep(step: 10, name: "Final Output", status: "success", time: "0ms", result: "Classification complete", reasoning: nil, error: nil)
                ],
                totalTime: "45ms",
                allStepsSuccessful: true,
                errors: []
            ),
            finalClassification: FinalClassification(
                type: mockCategory,
                intent: mockIntent,
                intentConfidence: mockConfidence,
                suggestedActions: [
                    SuggestedAction(
                        actionId: "sign_form",
                        displayName: "Sign Form",
                        isPrimary: true,
                        priority: 1,
                        endpoint: "/api/actions/sign-form"
                    )
                ],
                priority: "2",
                hpa: "true",
                metaCTA: "Sign Form",
                urgent: false,
                urgentKeywords: [],
                confidence: mockConfidence
            ),
            actualClassifierOutput: nil,
            matchesActual: nil
        )
    }
}
#endif
