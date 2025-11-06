/**
 * Credential Vault Database Schema
 * Per-user encrypted credential storage for Thread Finder integrations
 *
 * Security Model:
 * - Master Key Encryption Key (KEK) stored in AWS KMS
 * - Per-user Data Encryption Keys (DEK) encrypted by KEK
 * - Credentials encrypted with user's DEK using AES-256-GCM
 * - Zero-knowledge architecture: Platform never sees plaintext credentials
 */

-- ============================================================================
-- Table: credential_vault
-- Stores encrypted credentials for LMS/sports platforms per user
-- ============================================================================
CREATE TABLE IF NOT EXISTS credential_vault (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

  -- User identification
  user_id VARCHAR(255) NOT NULL,
  parent_email VARCHAR(255) NOT NULL,

  -- Platform identification
  platform VARCHAR(50) NOT NULL, -- 'canvas', 'google_classroom', 'schoology', 'sportsengine', etc.
  platform_domain VARCHAR(255), -- e.g., 'pascack.instructure.com', 'classroom.google.com'

  -- Encrypted credential data
  encrypted_credentials BYTEA NOT NULL, -- AES-256-GCM encrypted JSON blob
  encryption_key_id VARCHAR(255) NOT NULL, -- Reference to user's DEK
  encryption_algorithm VARCHAR(50) NOT NULL DEFAULT 'AES-256-GCM',
  initialization_vector BYTEA NOT NULL, -- IV for AES-GCM (96 bits)
  auth_tag BYTEA NOT NULL, -- Authentication tag for AES-GCM (128 bits)

  -- Credential metadata (plaintext for queries)
  credential_type VARCHAR(50) NOT NULL, -- 'api_token', 'oauth', 'session_cookie'
  expires_at TIMESTAMPTZ, -- Token expiration (if applicable)
  is_active BOOLEAN DEFAULT TRUE,

  -- OAuth-specific fields (if credential_type = 'oauth')
  oauth_refresh_token_encrypted BYTEA, -- Separate encryption for refresh token
  oauth_refresh_token_iv BYTEA,
  oauth_refresh_token_tag BYTEA,
  oauth_scopes TEXT[], -- OAuth scopes granted

  -- Audit fields
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  last_used_at TIMESTAMPTZ,
  last_refreshed_at TIMESTAMPTZ,

  -- Constraints
  CONSTRAINT unique_user_platform UNIQUE (user_id, platform, platform_domain)
);

-- Indexes for performance
CREATE INDEX idx_credential_vault_user_id ON credential_vault(user_id);
CREATE INDEX idx_credential_vault_platform ON credential_vault(platform);
CREATE INDEX idx_credential_vault_expires_at ON credential_vault(expires_at) WHERE expires_at IS NOT NULL;
CREATE INDEX idx_credential_vault_active ON credential_vault(is_active) WHERE is_active = TRUE;

-- ============================================================================
-- Table: encryption_keys
-- Stores per-user Data Encryption Keys (DEKs) encrypted by KMS
-- ============================================================================
CREATE TABLE IF NOT EXISTS encryption_keys (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

  -- User identification
  user_id VARCHAR(255) NOT NULL UNIQUE,

  -- Encrypted DEK
  encrypted_dek BYTEA NOT NULL, -- User's DEK encrypted by AWS KMS KEK
  kms_key_id VARCHAR(255) NOT NULL, -- AWS KMS key ID used for encryption
  kms_region VARCHAR(50) NOT NULL DEFAULT 'us-east-1',

  -- Key metadata
  algorithm VARCHAR(50) NOT NULL DEFAULT 'AES-256-GCM',
  key_status VARCHAR(20) NOT NULL DEFAULT 'active', -- 'active', 'rotated', 'revoked'

  -- Key rotation
  previous_key_id UUID REFERENCES encryption_keys(id),
  rotation_scheduled_at TIMESTAMPTZ,
  rotated_at TIMESTAMPTZ,

  -- Audit fields
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),

  CONSTRAINT valid_key_status CHECK (key_status IN ('active', 'rotated', 'revoked'))
);

CREATE INDEX idx_encryption_keys_user_id ON encryption_keys(user_id);
CREATE INDEX idx_encryption_keys_status ON encryption_keys(key_status) WHERE key_status = 'active';

-- ============================================================================
-- Table: credential_access_log
-- Audit trail for all credential access and modifications
-- ============================================================================
CREATE TABLE IF NOT EXISTS credential_access_log (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

  -- Reference
  credential_id UUID REFERENCES credential_vault(id) ON DELETE CASCADE,
  user_id VARCHAR(255) NOT NULL,

  -- Access details
  operation VARCHAR(50) NOT NULL, -- 'create', 'read', 'update', 'delete', 'refresh', 'decrypt'
  accessed_by VARCHAR(255) NOT NULL, -- Service/admin that accessed credential
  access_reason VARCHAR(255), -- 'thread_finder_extraction', 'admin_view', 'token_refresh'

  -- Request context
  ip_address INET,
  user_agent TEXT,
  request_id VARCHAR(255),

  -- Result
  success BOOLEAN NOT NULL,
  error_message TEXT,

  -- Timestamp
  accessed_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_credential_access_log_credential_id ON credential_access_log(credential_id);
CREATE INDEX idx_credential_access_log_user_id ON credential_access_log(user_id);
CREATE INDEX idx_credential_access_log_accessed_at ON credential_access_log(accessed_at);
CREATE INDEX idx_credential_access_log_operation ON credential_access_log(operation);

-- ============================================================================
-- Table: platform_configs
-- Configuration for each supported platform (Canvas, Google Classroom, etc.)
-- ============================================================================
CREATE TABLE IF NOT EXISTS platform_configs (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

  -- Platform identification
  platform VARCHAR(50) NOT NULL UNIQUE, -- 'canvas', 'google_classroom', 'schoology', 'sportsengine'
  display_name VARCHAR(100) NOT NULL,

  -- Platform metadata
  auth_type VARCHAR(50) NOT NULL, -- 'api_token', 'oauth2', 'session_cookie'
  base_api_url VARCHAR(255), -- e.g., 'https://canvas.instructure.com/api/v1'
  oauth_config JSONB, -- OAuth client ID, authorize URL, token URL, scopes

  -- Features
  supports_assignment_extraction BOOLEAN DEFAULT FALSE,
  supports_course_listing BOOLEAN DEFAULT FALSE,
  supports_grade_fetching BOOLEAN DEFAULT FALSE,

  -- Rate limiting
  rate_limit_requests_per_minute INTEGER DEFAULT 60,

  -- Status
  is_enabled BOOLEAN DEFAULT TRUE,

  -- Audit
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Insert default platform configurations
INSERT INTO platform_configs (platform, display_name, auth_type, supports_assignment_extraction, supports_course_listing) VALUES
('canvas', 'Canvas LMS', 'api_token', TRUE, TRUE),
('google_classroom', 'Google Classroom', 'oauth2', TRUE, TRUE),
('schoology', 'Schoology', 'api_token', TRUE, TRUE),
('sportsengine', 'SportsEngine', 'session_cookie', TRUE, FALSE),
('teamsnap', 'TeamSnap', 'oauth2', TRUE, FALSE)
ON CONFLICT (platform) DO NOTHING;

-- ============================================================================
-- Functions & Triggers
-- ============================================================================

-- Update updated_at timestamp automatically
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER update_credential_vault_updated_at
  BEFORE UPDATE ON credential_vault
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_encryption_keys_updated_at
  BEFORE UPDATE ON encryption_keys
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_platform_configs_updated_at
  BEFORE UPDATE ON platform_configs
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

-- ============================================================================
-- Security: Row-Level Security (RLS) Policies
-- Enable RLS to ensure users can only access their own credentials
-- ============================================================================

ALTER TABLE credential_vault ENABLE ROW LEVEL SECURITY;
ALTER TABLE encryption_keys ENABLE ROW LEVEL SECURITY;

-- Policy: Users can only view their own credentials
CREATE POLICY user_own_credentials ON credential_vault
  FOR SELECT
  USING (user_id = current_setting('app.current_user_id', TRUE));

-- Policy: Users can only view their own encryption keys
CREATE POLICY user_own_encryption_keys ON encryption_keys
  FOR SELECT
  USING (user_id = current_setting('app.current_user_id', TRUE));

-- ============================================================================
-- Views for Admin Dashboard
-- ============================================================================

-- View: Active credentials summary
CREATE OR REPLACE VIEW active_credentials_summary AS
SELECT
  cv.user_id,
  cv.parent_email,
  cv.platform,
  pc.display_name AS platform_name,
  cv.credential_type,
  cv.expires_at,
  cv.last_used_at,
  cv.created_at,
  CASE
    WHEN cv.expires_at IS NULL THEN 'never_expires'
    WHEN cv.expires_at < NOW() THEN 'expired'
    WHEN cv.expires_at < NOW() + INTERVAL '7 days' THEN 'expiring_soon'
    ELSE 'active'
  END AS expiration_status
FROM credential_vault cv
LEFT JOIN platform_configs pc ON cv.platform = pc.platform
WHERE cv.is_active = TRUE;

-- View: Credential health metrics
CREATE OR REPLACE VIEW credential_health_metrics AS
SELECT
  platform,
  COUNT(*) AS total_credentials,
  COUNT(*) FILTER (WHERE is_active = TRUE) AS active_credentials,
  COUNT(*) FILTER (WHERE expires_at IS NOT NULL AND expires_at < NOW()) AS expired_credentials,
  COUNT(*) FILTER (WHERE last_used_at IS NOT NULL AND last_used_at > NOW() - INTERVAL '7 days') AS recently_used,
  AVG(EXTRACT(EPOCH FROM (NOW() - last_used_at))) FILTER (WHERE last_used_at IS NOT NULL) / 86400 AS avg_days_since_use
FROM credential_vault
GROUP BY platform;

-- ============================================================================
-- Comments for documentation
-- ============================================================================

COMMENT ON TABLE credential_vault IS 'Encrypted credential storage for per-user Thread Finder integrations';
COMMENT ON TABLE encryption_keys IS 'Per-user Data Encryption Keys (DEKs) encrypted by AWS KMS';
COMMENT ON TABLE credential_access_log IS 'Audit trail for all credential access and modifications';
COMMENT ON TABLE platform_configs IS 'Configuration for supported educational/sports platforms';

COMMENT ON COLUMN credential_vault.encrypted_credentials IS 'AES-256-GCM encrypted JSON containing access tokens, API keys, or session cookies';
COMMENT ON COLUMN credential_vault.initialization_vector IS '96-bit random IV for AES-GCM encryption';
COMMENT ON COLUMN credential_vault.auth_tag IS '128-bit authentication tag for AES-GCM AEAD';
COMMENT ON COLUMN encryption_keys.encrypted_dek IS 'User Data Encryption Key encrypted by AWS KMS Key Encryption Key';
