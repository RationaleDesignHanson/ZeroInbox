-- ============================================================================
-- CORPUS ANALYTICS DATABASE SCHEMA
-- Purpose: Track email classifications, user actions, and patterns for ML training
-- Version: 1.0
-- Created: October 30, 2025
-- ============================================================================

-- ============================================================================
-- TABLE: corpus_emails
-- Purpose: Store classified emails with all extracted metadata
-- ============================================================================
CREATE TABLE IF NOT EXISTS corpus_emails (
    -- Primary Keys
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    email_id VARCHAR(255) NOT NULL,           -- Gmail/Outlook message ID
    user_id VARCHAR(255) NOT NULL,             -- User identifier

    -- Email Metadata
    subject TEXT NOT NULL,
    from_email VARCHAR(500) NOT NULL,
    from_name VARCHAR(255),
    to_emails TEXT[],
    received_at TIMESTAMP NOT NULL,
    has_attachments BOOLEAN DEFAULT FALSE,

    -- Classification Results
    intent VARCHAR(100) NOT NULL,              -- e.g., "shipping.tracking.update"
    intent_confidence DECIMAL(5, 4),           -- 0.0000 to 1.0000
    category VARCHAR(50) NOT NULL,             -- "mail" or "ads"
    priority VARCHAR(20),                      -- "critical", "high", "medium", "low"

    -- Extracted Entities (JSONB for flexibility)
    entities JSONB,                            -- { "trackingNumber": "1Z999...", "carrier": "UPS" }

    -- Suggested Actions
    suggested_actions JSONB,                   -- [{ "actionId": "track_package", ... }]
    primary_action VARCHAR(100),               -- actionId of primary suggested action

    -- User Behavior
    user_action_taken VARCHAR(100),            -- actionId user actually executed
    action_taken_at TIMESTAMP,
    was_action_suggested BOOLEAN,             -- Did we suggest the action user took?
    time_to_action_seconds INTEGER,           -- Time from email open to action

    -- Email Body (for retraining)
    body_snippet TEXT,                         -- First 1000 chars
    body_full TEXT,                            -- Full body (if user opts in)

    -- Timestamps
    created_at TIMESTAMP DEFAULT NOW(),
    classified_at TIMESTAMP DEFAULT NOW(),

    -- Indexes for fast queries
    CONSTRAINT unique_email_per_user UNIQUE (user_id, email_id)
);

-- Indexes for performance
CREATE INDEX idx_corpus_user_id ON corpus_emails(user_id);
CREATE INDEX idx_corpus_intent ON corpus_emails(intent);
CREATE INDEX idx_corpus_category ON corpus_emails(category);
CREATE INDEX idx_corpus_primary_action ON corpus_emails(primary_action);
CREATE INDEX idx_corpus_user_action ON corpus_emails(user_action_taken);
CREATE INDEX idx_corpus_received_at ON corpus_emails(received_at DESC);
CREATE INDEX idx_corpus_classified_at ON corpus_emails(classified_at DESC);

-- GIN index for JSONB queries (entities and actions)
CREATE INDEX idx_corpus_entities ON corpus_emails USING GIN (entities);
CREATE INDEX idx_corpus_suggested_actions ON corpus_emails USING GIN (suggested_actions);


-- ============================================================================
-- TABLE: user_action_logs
-- Purpose: Detailed log of every user action for behavior analysis
-- ============================================================================
CREATE TABLE IF NOT EXISTS user_action_logs (
    -- Primary Keys
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id VARCHAR(255) NOT NULL,
    email_id VARCHAR(255) NOT NULL,            -- Links to corpus_emails

    -- Action Details
    action_id VARCHAR(100) NOT NULL,           -- e.g., "track_package"
    action_type VARCHAR(20) NOT NULL,          -- "GO_TO" or "IN_APP"
    was_suggested BOOLEAN NOT NULL,            -- Was this action suggested by system?
    suggestion_rank INTEGER,                   -- If suggested, what rank? (1 = primary)

    -- Context
    action_context JSONB,                      -- Context data passed to action

    -- Outcome
    success BOOLEAN,                           -- Did action complete successfully?
    error_message TEXT,                        -- If failed, why?

    -- Timing
    performed_at TIMESTAMP DEFAULT NOW(),
    duration_ms INTEGER,                       -- How long action took

    -- Device/Platform
    platform VARCHAR(20),                      -- "ios", "web", "android"
    app_version VARCHAR(20),

    CONSTRAINT fk_email FOREIGN KEY (email_id)
        REFERENCES corpus_emails(email_id) ON DELETE CASCADE
);

-- Indexes
CREATE INDEX idx_action_logs_user_id ON user_action_logs(user_id);
CREATE INDEX idx_action_logs_email_id ON user_action_logs(email_id);
CREATE INDEX idx_action_logs_action_id ON user_action_logs(action_id);
CREATE INDEX idx_action_logs_performed_at ON user_action_logs(performed_at DESC);


-- ============================================================================
-- TABLE: intent_statistics
-- Purpose: Aggregated statistics per intent for quick lookups
-- ============================================================================
CREATE TABLE IF NOT EXISTS intent_statistics (
    -- Primary Keys
    intent VARCHAR(100) PRIMARY KEY,

    -- Frequency Stats
    total_count INTEGER DEFAULT 0,
    user_count INTEGER DEFAULT 0,              -- How many unique users

    -- Action Stats
    most_common_action VARCHAR(100),
    action_success_rate DECIMAL(5, 4),         -- % of suggested actions taken

    -- Entity Stats
    common_entities JSONB,                     -- { "trackingNumber": 0.95, "carrier": 0.92 }

    -- Classification Stats
    avg_confidence DECIMAL(5, 4),

    -- Performance Stats
    avg_time_to_action_seconds INTEGER,

    -- Last Updated
    last_updated TIMESTAMP DEFAULT NOW()
);


-- ============================================================================
-- TABLE: action_statistics
-- Purpose: Track performance of each action type
-- ============================================================================
CREATE TABLE IF NOT EXISTS action_statistics (
    -- Primary Keys
    action_id VARCHAR(100) PRIMARY KEY,

    -- Frequency Stats
    times_suggested INTEGER DEFAULT 0,
    times_executed INTEGER DEFAULT 0,
    execution_rate DECIMAL(5, 4),              -- times_executed / times_suggested

    -- User Stats
    unique_users INTEGER DEFAULT 0,

    -- Performance Stats
    avg_duration_ms INTEGER,
    success_rate DECIMAL(5, 4),

    -- Context Stats
    common_intents JSONB,                      -- Top 5 intents that trigger this action
    required_entities JSONB,                   -- Entities needed for this action

    -- Last Updated
    last_updated TIMESTAMP DEFAULT NOW()
);


-- ============================================================================
-- TABLE: keyword_analytics
-- Purpose: Track keyword effectiveness for pattern detection
-- ============================================================================
CREATE TABLE IF NOT EXISTS keyword_analytics (
    -- Primary Keys
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    category VARCHAR(50) NOT NULL,             -- "events", "urgency", "promotional"
    keyword VARCHAR(255) NOT NULL,

    -- Frequency Stats
    occurrences INTEGER DEFAULT 0,
    true_positives INTEGER DEFAULT 0,          -- Correctly detected pattern
    false_positives INTEGER DEFAULT 0,         -- Incorrectly flagged

    -- Precision
    precision DECIMAL(5, 4),                   -- TP / (TP + FP)

    -- TF-IDF Stats
    tfidf_score DECIMAL(10, 6),

    -- Last Updated
    last_updated TIMESTAMP DEFAULT NOW(),

    CONSTRAINT unique_keyword_category UNIQUE (category, keyword)
);

-- Indexes
CREATE INDEX idx_keyword_category ON keyword_analytics(category);
CREATE INDEX idx_keyword_precision ON keyword_analytics(precision DESC);


-- ============================================================================
-- TABLE: corpus_snapshots
-- Purpose: Periodic snapshots of corpus metrics for trend analysis
-- ============================================================================
CREATE TABLE IF NOT EXISTS corpus_snapshots (
    -- Primary Keys
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    snapshot_at TIMESTAMP DEFAULT NOW(),

    -- Corpus Size
    total_emails INTEGER,
    total_users INTEGER,

    -- Classification Metrics
    intents_detected JSONB,                    -- { "shipping.tracking": 1250, ... }
    categories_breakdown JSONB,                -- { "mail": 7500, "ads": 2500 }

    -- Action Metrics
    actions_suggested JSONB,                   -- { "track_package": 350, ... }
    actions_executed JSONB,                    -- { "track_package": 280, ... }
    overall_action_rate DECIMAL(5, 4),

    -- Classification Accuracy
    avg_intent_confidence DECIMAL(5, 4),
    high_confidence_rate DECIMAL(5, 4),        -- % of classifications > 0.9 confidence

    -- Entity Extraction
    entities_extracted JSONB,                  -- Count per entity type

    -- Performance
    avg_classification_time_ms INTEGER,
    avg_action_execution_time_ms INTEGER
);

-- Indexes
CREATE INDEX idx_snapshots_at ON corpus_snapshots(snapshot_at DESC);


-- ============================================================================
-- MATERIALIZED VIEW: Daily Intent Summary
-- Purpose: Fast access to daily intent patterns
-- ============================================================================
CREATE MATERIALIZED VIEW daily_intent_summary AS
SELECT
    DATE(received_at) as date,
    intent,
    COUNT(*) as email_count,
    COUNT(DISTINCT user_id) as user_count,
    AVG(intent_confidence) as avg_confidence,
    COUNT(CASE WHEN user_action_taken IS NOT NULL THEN 1 END) as actions_taken,
    AVG(CASE WHEN user_action_taken IS NOT NULL THEN time_to_action_seconds END) as avg_time_to_action
FROM corpus_emails
WHERE received_at >= CURRENT_DATE - INTERVAL '90 days'
GROUP BY DATE(received_at), intent
ORDER BY date DESC, email_count DESC;

CREATE UNIQUE INDEX idx_daily_intent ON daily_intent_summary(date, intent);


-- ============================================================================
-- MATERIALIZED VIEW: Action Performance Summary
-- Purpose: Quick dashboard of action effectiveness
-- ============================================================================
CREATE MATERIALIZED VIEW action_performance_summary AS
SELECT
    primary_action as action_id,
    COUNT(*) as times_suggested,
    COUNT(CASE WHEN user_action_taken = primary_action THEN 1 END) as times_executed,
    ROUND(
        COUNT(CASE WHEN user_action_taken = primary_action THEN 1 END)::DECIMAL /
        NULLIF(COUNT(*), 0),
        4
    ) as execution_rate,
    COUNT(DISTINCT user_id) as unique_users,
    AVG(CASE WHEN user_action_taken = primary_action THEN time_to_action_seconds END) as avg_time_to_action,
    ARRAY_AGG(DISTINCT intent) as common_intents
FROM corpus_emails
WHERE primary_action IS NOT NULL
GROUP BY primary_action
ORDER BY times_suggested DESC;


-- ============================================================================
-- FUNCTIONS: Helper functions for analytics
-- ============================================================================

-- Function: Refresh materialized views
CREATE OR REPLACE FUNCTION refresh_corpus_views()
RETURNS void AS $$
BEGIN
    REFRESH MATERIALIZED VIEW CONCURRENTLY daily_intent_summary;
    REFRESH MATERIALIZED VIEW CONCURRENTLY action_performance_summary;
END;
$$ LANGUAGE plpgsql;


-- Function: Log user action with automatic linking
CREATE OR REPLACE FUNCTION log_user_action(
    p_user_id VARCHAR,
    p_email_id VARCHAR,
    p_action_id VARCHAR,
    p_action_type VARCHAR,
    p_was_suggested BOOLEAN,
    p_context JSONB DEFAULT '{}'::JSONB
) RETURNS UUID AS $$
DECLARE
    v_log_id UUID;
BEGIN
    -- Insert action log
    INSERT INTO user_action_logs (
        user_id, email_id, action_id, action_type,
        was_suggested, action_context
    ) VALUES (
        p_user_id, p_email_id, p_action_id, p_action_type,
        p_was_suggested, p_context
    ) RETURNING id INTO v_log_id;

    -- Update corpus_emails with user action
    UPDATE corpus_emails
    SET
        user_action_taken = p_action_id,
        action_taken_at = NOW(),
        was_action_suggested = p_was_suggested,
        time_to_action_seconds = EXTRACT(EPOCH FROM (NOW() - received_at))::INTEGER
    WHERE email_id = p_email_id AND user_id = p_user_id;

    RETURN v_log_id;
END;
$$ LANGUAGE plpgsql;


-- Function: Get top keywords for a category
CREATE OR REPLACE FUNCTION get_top_keywords(
    p_category VARCHAR,
    p_limit INTEGER DEFAULT 20
) RETURNS TABLE (
    keyword VARCHAR,
    occurrences INTEGER,
    precision DECIMAL(5, 4),
    tfidf_score DECIMAL(10, 6)
) AS $$
BEGIN
    RETURN QUERY
    SELECT
        ka.keyword,
        ka.occurrences,
        ka.precision,
        ka.tfidf_score
    FROM keyword_analytics ka
    WHERE ka.category = p_category
    ORDER BY ka.tfidf_score DESC
    LIMIT p_limit;
END;
$$ LANGUAGE plpgsql;


-- ============================================================================
-- INITIAL DATA SEEDING (for testing)
-- ============================================================================

-- Seed intent_statistics with initial entries for all known intents
INSERT INTO intent_statistics (intent, total_count) VALUES
    ('shipping.tracking.update', 0),
    ('billing.invoice.due', 0),
    ('education.permission.form', 0),
    ('travel.flight.check-in', 0),
    ('account.security.alert', 0),
    ('generic.newsletter', 0),
    ('e-commerce.promotion', 0)
ON CONFLICT (intent) DO NOTHING;

-- Seed action_statistics with initial entries for all known actions
INSERT INTO action_statistics (action_id, times_suggested, times_executed) VALUES
    ('track_package', 0, 0),
    ('pay_invoice', 0, 0),
    ('sign_form', 0, 0),
    ('check_in_flight', 0, 0),
    ('quick_reply', 0, 0),
    ('view_details', 0, 0)
ON CONFLICT (action_id) DO NOTHING;


-- ============================================================================
-- GRANTS (adjust based on your database roles)
-- ============================================================================

-- Grant permissions to application role
-- GRANT SELECT, INSERT, UPDATE ON ALL TABLES IN SCHEMA public TO app_role;
-- GRANT USAGE ON ALL SEQUENCES IN SCHEMA public TO app_role;
-- GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA public TO app_role;


-- ============================================================================
-- COMMENTS (for documentation)
-- ============================================================================

COMMENT ON TABLE corpus_emails IS 'Master table storing all classified emails with full metadata for ML training and analytics';
COMMENT ON TABLE user_action_logs IS 'Detailed log of every user action for behavior pattern analysis';
COMMENT ON TABLE intent_statistics IS 'Aggregated statistics per intent type for quick dashboard queries';
COMMENT ON TABLE action_statistics IS 'Performance metrics for each action type to guide prioritization';
COMMENT ON TABLE keyword_analytics IS 'Keyword effectiveness tracking for pattern detection improvements';
COMMENT ON TABLE corpus_snapshots IS 'Periodic snapshots of overall corpus health for trend analysis';

COMMENT ON FUNCTION log_user_action IS 'Helper function to log user actions and automatically update corpus_emails';
COMMENT ON FUNCTION get_top_keywords IS 'Returns top-performing keywords for a given category ranked by TF-IDF score';
COMMENT ON FUNCTION refresh_corpus_views IS 'Refreshes all materialized views - run daily via cron job';


-- ============================================================================
-- END OF SCHEMA
-- ============================================================================
