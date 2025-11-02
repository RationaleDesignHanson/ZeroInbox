//
//  ClassificationDebugData.swift
//  Zero
//
//  Comprehensive debug model for classification pipeline inspection
//  Matches backend /api/classify/debug response structure
//

import Foundation

// MARK: - Main Debug Response

struct ClassificationDebugData: Codable {
    let debugInfo: DebugInfo
    let email: EmailInput
    let intentClassification: IntentClassification
    let entityExtraction: EntityExtraction
    let rulesEngine: RulesEngine
    let mailAdsClassification: MailAdsClassification
    let pipelineTrace: PipelineTrace
    let finalClassification: FinalClassification
    let actualClassifierOutput: ActualClassifierOutput?
    let matchesActual: MatchesActual?
}

// MARK: - Debug Info

struct DebugInfo: Codable {
    let timestamp: String
    let totalProcessingTime: String
    let version: String
    let classifierMode: String?
    let isMockData: Bool?
    let mockDataWarning: String?

    enum CodingKeys: String, CodingKey {
        case timestamp, totalProcessingTime, version, classifierMode, isMockData, mockDataWarning
    }
}

// MARK: - Email Input

struct EmailInput: Codable {
    let id: String
    let subject: String
    let from: String
    let snippet: String
    let hasHtmlBody: Bool
}

// MARK: - Dashboard 1: Intent Classification

struct IntentClassification: Codable {
    let detectedIntent: String
    let confidence: Double
    let source: String
    let processingTime: String
    let allIntentScores: [String: IntentScore]
    let matchBreakdown: [PatternMatch]
    let thresholds: ConfidenceThresholds
}

struct IntentScore: Codable {
    let score: Double
    let matches: [PatternMatch]
    let confidence: Double
}

struct PatternMatch: Codable {
    let location: String
    let pattern: String
    let weight: Int
}

struct ConfidenceThresholds: Codable {
    let minimum: Double
    let highConfidence: Double
    let currentMeetsMinimum: Bool
    let currentIsHighConfidence: Bool
}

// MARK: - Dashboard 2: Entity Extraction

struct EntityExtraction: Codable {
    let extractedEntities: ExtractedEntities
    let processingTime: String
    let validation: EntityValidation
    let requiredForIntent: [String]
    let missingRequiredEntities: [String]
}

struct ExtractedEntities: Codable {
    let deadline: Deadline?
    let prices: Prices
    let stores: [String]
    let promoCodes: [String]
    let children: [String]
    let companies: [String]
    let accounts: [String]
    let flights: [String]
    let hotels: [String]
    let trackingNumbers: [String]
}

struct Deadline: Codable {
    let text: String
    let isUrgent: Bool
}

struct Prices: Codable {
    let original: String?
}

struct EntityValidation: Codable {
    let hasDeadline: Bool
    let hasPrices: Bool
    let hasTrackingNumbers: Bool
    let hasChildren: Bool
    let hasCompanies: Bool
}

// MARK: - Dashboard 3: Rules Engine

struct RulesEngine: Codable {
    let matchedRule: Bool
    let intent: String
    let suggestedActions: [SuggestedAction]
    let processingTime: String
    let actionValidation: [ActionValidation]
    let reasoning: String
}

struct SuggestedAction: Codable {
    let actionId: String
    let displayName: String
    let isPrimary: Bool
    let priority: Int
    let endpoint: String
}

struct ActionValidation: Codable {
    let actionId: String
    let displayName: String
    let isPrimary: Bool
    let priority: Int
    let endpoint: String
    let endpointExists: Bool
}

// MARK: - Dashboard 4: Mail vs Ads Classification

struct MailAdsClassification: Codable {
    let finalCategory: String
    let processingTime: String
    let reasoning: AdDetectionReasoning
    let signals: AdDetectionSignals
    let accuracy: AccuracyInfo
}

struct AdDetectionReasoning: Codable {
    let hasUnsubscribeHeader: Bool
    let hasUnsubscribeLink: Bool
    let promoKeywordMatches: Int
    let matchedPromoKeywords: [String]
    let marketingSenderMatch: Bool
    let matchedSenderPattern: String?
    let intentBased: Bool
    let finalDecision: String
}

struct AdDetectionSignals: Codable {
    let unsubscribeLink: Bool
    let promoKeywords: PromoKeywordSignal
    let marketingSender: Bool
    let intentBased: Bool
}

struct PromoKeywordSignal: Codable {
    let count: Int
    let threshold: Int
    let matches: [String]
}

struct AccuracyInfo: Codable {
    let expectedCategory: String
    let confidence: String
}

// MARK: - Dashboard 5: Pipeline Trace

struct PipelineTrace: Codable {
    let steps: [PipelineStep]
    let totalTime: String
    let allStepsSuccessful: Bool
    let errors: [String]
}

struct PipelineStep: Codable {
    let step: Int
    let name: String
    let status: String
    let time: String
    let result: String
    let reasoning: [String]?
    let error: String?
}

// MARK: - Final Classification

struct FinalClassification: Codable {
    let type: String
    let intent: String
    let intentConfidence: Double
    let suggestedActions: [SuggestedAction]
    let priority: String
    let hpa: String
    let metaCTA: String
    let urgent: Bool
    let urgentKeywords: [String]
    let confidence: Double
}

struct ActualClassifierOutput: Codable {
    let type: String
    let intent: String?
    let priority: String
    let confidence: Double
}

struct MatchesActual: Codable {
    let type: Bool
    let intent: Bool
    let priority: Bool
}

// MARK: - Helper Extensions

extension ClassificationDebugData {
    /// Format for display in UI
    var summary: String {
        """
        Classification: \(finalClassification.type)
        Intent: \(finalClassification.intent)
        Confidence: \(String(format: "%.1f%%", finalClassification.confidence * 100))
        Priority: \(finalClassification.priority)
        Actions: \(finalClassification.suggestedActions.count)
        Processing Time: \(debugInfo.totalProcessingTime)
        """
    }

    /// Check if classification confidence is low
    var isLowConfidence: Bool {
        return finalClassification.intentConfidence < intentClassification.thresholds.minimum
    }

    /// Check if there are missing entities
    var hasMissingEntities: Bool {
        return !entityExtraction.missingRequiredEntities.isEmpty
    }

    /// Check if Mail/Ads classification is correct
    var isAdClassificationConfident: Bool {
        return mailAdsClassification.accuracy.confidence == "high"
    }

    /// Get all warnings/issues
    var warnings: [String] {
        var warns: [String] = []

        if isLowConfidence {
            warns.append("Low confidence: \(String(format: "%.1f%%", finalClassification.intentConfidence * 100))")
        }

        if hasMissingEntities {
            warns.append("Missing entities: \(entityExtraction.missingRequiredEntities.joined(separator: ", "))")
        }

        if !rulesEngine.matchedRule {
            warns.append("No matching rule for intent: \(rulesEngine.intent)")
        }

        if !pipelineTrace.allStepsSuccessful {
            warns.append("Pipeline errors: \(pipelineTrace.errors.joined(separator: ", "))")
        }

        return warns
    }
}

extension IntentClassification {
    /// Get top 3 intent matches sorted by confidence
    var topIntents: [(intent: String, confidence: Double)] {
        return allIntentScores
            .map { ($0.key, $0.value.confidence) }
            .sorted { $0.1 > $1.1 }
            .prefix(3)
            .map { $0 }
    }
}

extension MailAdsClassification {
    /// Human-readable reason why email was classified as Mail or Ads
    var classificationReason: String {
        var reasons: [String] = []

        if signals.unsubscribeLink {
            reasons.append("Has unsubscribe link")
        }

        if signals.promoKeywords.count >= signals.promoKeywords.threshold {
            reasons.append("\(signals.promoKeywords.count) promotional keywords")
        }

        if signals.marketingSender {
            reasons.append("Marketing sender domain")
        }

        if signals.intentBased {
            reasons.append("Marketing/promo intent")
        }

        if reasons.isEmpty {
            return "No promotional signals detected"
        }

        return reasons.joined(separator: ", ")
    }
}
