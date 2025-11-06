/**
 * Credential Manager
 * High-level API for managing encrypted credentials in the vault
 *
 * Responsibilities:
 * - Store/retrieve credentials with automatic encryption/decryption
 * - Manage credential lifecycle (creation, updates, expiration, rotation)
 * - Audit all credential access
 * - OAuth token refresh automation
 *
 * Usage:
 * const credentialManager = require('./credential-manager');
 * await credentialManager.storeCredential(userId, 'canvas', { api_token: 'xxx' });
 * const credentials = await credentialManager.getCredential(userId, 'canvas');
 */

const { encryptionService } = require('./encryption-service');
const { Pool } = require('pg');
const logger = require('../classifier/shared/config/logger');

// Database connection pool
const pool = new Pool({
  connectionString: process.env.DATABASE_URL,
  ssl: process.env.NODE_ENV === 'production' ? { rejectUnauthorized: false } : false,
  max: 20,
  idleTimeoutMillis: 30000,
  connectionTimeoutMillis: 10000
});

class CredentialManager {
  /**
   * Store new credential for a user
   *
   * @param {string} userId - User identifier
   * @param {string} parentEmail - Parent's email address
   * @param {string} platform - Platform name ('canvas', 'google_classroom', etc.)
   * @param {Object} credentialData - Plaintext credential data
   * @param {Object} options - Additional options
   * @returns {Promise<string>} - Credential ID
   */
  async storeCredential(userId, parentEmail, platform, credentialData, options = {}) {
    const client = await pool.connect();

    try {
      await client.query('BEGIN');

      // Step 1: Check if user has an encryption key, create if not
      let encryptedDek = await this._getOrCreateEncryptionKey(client, userId);

      // Step 2: Encrypt credentials
      const {
        encryptedCredentials,
        encryptedDek: newEncryptedDek,
        iv,
        authTag,
        kmsKeyId,
        algorithm
      } = await encryptionService.encryptCredentialComplete(credentialData, userId);

      // Update encryption key if new one was generated
      if (newEncryptedDek) {
        await this._storeEncryptionKey(client, userId, newEncryptedDek, kmsKeyId, algorithm);
      }

      // Step 3: Store encrypted credentials in vault
      const insertQuery = `
        INSERT INTO credential_vault (
          user_id,
          parent_email,
          platform,
          platform_domain,
          encrypted_credentials,
          encryption_key_id,
          encryption_algorithm,
          initialization_vector,
          auth_tag,
          credential_type,
          expires_at,
          oauth_refresh_token_encrypted,
          oauth_refresh_token_iv,
          oauth_refresh_token_tag,
          oauth_scopes
        ) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, $13, $14, $15)
        ON CONFLICT (user_id, platform, platform_domain)
        DO UPDATE SET
          encrypted_credentials = EXCLUDED.encrypted_credentials,
          initialization_vector = EXCLUDED.initialization_vector,
          auth_tag = EXCLUDED.auth_tag,
          expires_at = EXCLUDED.expires_at,
          oauth_refresh_token_encrypted = EXCLUDED.oauth_refresh_token_encrypted,
          oauth_refresh_token_iv = EXCLUDED.oauth_refresh_token_iv,
          oauth_refresh_token_tag = EXCLUDED.oauth_refresh_token_tag,
          oauth_scopes = EXCLUDED.oauth_scopes,
          updated_at = NOW()
        RETURNING id
      `;

      // Handle OAuth refresh token separately if present
      let refreshTokenEncrypted = null;
      let refreshTokenIv = null;
      let refreshTokenTag = null;

      if (credentialData.refresh_token) {
        const refreshTokenResult = encryptionService.encryptCredentials(
          { refresh_token: credentialData.refresh_token },
          newEncryptedDek
        );
        refreshTokenEncrypted = refreshTokenResult.ciphertext;
        refreshTokenIv = refreshTokenResult.iv;
        refreshTokenTag = refreshTokenResult.authTag;
      }

      const result = await client.query(insertQuery, [
        userId,
        parentEmail,
        platform,
        options.platformDomain || null,
        encryptedCredentials,
        userId, // encryption_key_id references user's key
        algorithm,
        iv,
        authTag,
        options.credentialType || 'api_token',
        options.expiresAt || null,
        refreshTokenEncrypted,
        refreshTokenIv,
        refreshTokenTag,
        options.oauthScopes || null
      ]);

      const credentialId = result.rows[0].id;

      // Step 4: Log access
      await this._logAccess(client, credentialId, userId, 'create', 'credential_manager', 'store_new_credential', true);

      await client.query('COMMIT');

      logger.info('Credential stored successfully', {
        userId,
        platform,
        credentialId,
        credentialType: options.credentialType || 'api_token'
      });

      return credentialId;
    } catch (error) {
      await client.query('ROLLBACK');

      logger.error('Failed to store credential', {
        userId,
        platform,
        error: error.message
      });

      throw new Error(`Credential storage failed: ${error.message}`);
    } finally {
      client.release();
    }
  }

  /**
   * Retrieve and decrypt credential for a user
   *
   * @param {string} userId - User identifier
   * @param {string} platform - Platform name
   * @param {Object} options - Additional options
   * @returns {Promise<Object>} - Decrypted credential data
   */
  async getCredential(userId, platform, options = {}) {
    const client = await pool.connect();

    try {
      // Step 1: Fetch encrypted credential from vault
      const selectQuery = `
        SELECT
          cv.id,
          cv.encrypted_credentials,
          cv.initialization_vector AS iv,
          cv.auth_tag,
          cv.credential_type,
          cv.expires_at,
          cv.oauth_refresh_token_encrypted,
          cv.oauth_refresh_token_iv,
          cv.oauth_refresh_token_tag,
          cv.oauth_scopes,
          cv.last_used_at,
          ek.encrypted_dek
        FROM credential_vault cv
        JOIN encryption_keys ek ON cv.encryption_key_id = ek.user_id
        WHERE cv.user_id = $1
          AND cv.platform = $2
          AND cv.is_active = TRUE
          AND ek.key_status = 'active'
          ${options.platformDomain ? 'AND cv.platform_domain = $3' : ''}
        ORDER BY cv.updated_at DESC
        LIMIT 1
      `;

      const params = options.platformDomain
        ? [userId, platform, options.platformDomain]
        : [userId, platform];

      const result = await client.query(selectQuery, params);

      if (result.rows.length === 0) {
        logger.warn('No credential found', {
          userId,
          platform,
          platformDomain: options.platformDomain
        });
        return null;
      }

      const row = result.rows[0];
      const credentialId = row.id;

      // Check if credential expired
      if (row.expires_at && new Date(row.expires_at) < new Date()) {
        logger.warn('Credential expired', {
          userId,
          platform,
          credentialId,
          expiresAt: row.expires_at
        });

        // Attempt OAuth refresh if applicable
        if (row.credential_type === 'oauth' && row.oauth_refresh_token_encrypted) {
          logger.info('Attempting OAuth token refresh', {
            userId,
            platform,
            credentialId
          });

          const refreshed = await this._refreshOAuthToken(client, userId, platform, row);
          if (refreshed) {
            return await this.getCredential(userId, platform, options);
          }
        }

        await this._logAccess(client, credentialId, userId, 'read', 'credential_manager', 'expired_credential', false, 'Credential expired');
        throw new Error('Credential expired and refresh failed');
      }

      // Step 2: Decrypt credentials
      const credentialData = await encryptionService.decryptCredentialComplete(
        {
          encryptedCredentials: row.encrypted_credentials,
          encryptedDek: row.encrypted_dek,
          iv: row.iv,
          authTag: row.auth_tag
        },
        userId
      );

      // Step 3: Update last_used_at
      await client.query(
        'UPDATE credential_vault SET last_used_at = NOW() WHERE id = $1',
        [credentialId]
      );

      // Step 4: Log access
      await this._logAccess(client, credentialId, userId, 'read', 'credential_manager', options.accessReason || 'credential_retrieval', true);

      logger.info('Credential retrieved successfully', {
        userId,
        platform,
        credentialId,
        lastUsed: row.last_used_at
      });

      return {
        ...credentialData,
        credentialType: row.credential_type,
        expiresAt: row.expires_at,
        oauthScopes: row.oauth_scopes
      };
    } catch (error) {
      logger.error('Failed to retrieve credential', {
        userId,
        platform,
        error: error.message
      });

      throw new Error(`Credential retrieval failed: ${error.message}`);
    } finally {
      client.release();
    }
  }

  /**
   * Delete credential from vault
   *
   * @param {string} userId - User identifier
   * @param {string} platform - Platform name
   * @returns {Promise<boolean>} - Success status
   */
  async deleteCredential(userId, platform) {
    const client = await pool.connect();

    try {
      const deleteQuery = `
        DELETE FROM credential_vault
        WHERE user_id = $1 AND platform = $2
        RETURNING id
      `;

      const result = await client.query(deleteQuery, [userId, platform]);

      if (result.rows.length === 0) {
        logger.warn('No credential found to delete', {
          userId,
          platform
        });
        return false;
      }

      const credentialId = result.rows[0].id;

      await this._logAccess(client, credentialId, userId, 'delete', 'credential_manager', 'user_requested_deletion', true);

      logger.info('Credential deleted successfully', {
        userId,
        platform,
        credentialId
      });

      return true;
    } catch (error) {
      logger.error('Failed to delete credential', {
        userId,
        platform,
        error: error.message
      });

      throw new Error(`Credential deletion failed: ${error.message}`);
    } finally {
      client.release();
    }
  }

  /**
   * List all platforms with stored credentials for a user
   *
   * @param {string} userId - User identifier
   * @returns {Promise<Array>} - Array of platform summaries
   */
  async listUserCredentials(userId) {
    try {
      const selectQuery = `
        SELECT
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
          END AS status
        FROM credential_vault cv
        LEFT JOIN platform_configs pc ON cv.platform = pc.platform
        WHERE cv.user_id = $1 AND cv.is_active = TRUE
        ORDER BY cv.platform
      `;

      const result = await pool.query(selectQuery, [userId]);

      logger.info('Listed user credentials', {
        userId,
        credentialCount: result.rows.length
      });

      return result.rows;
    } catch (error) {
      logger.error('Failed to list user credentials', {
        userId,
        error: error.message
      });

      throw new Error(`Credential listing failed: ${error.message}`);
    }
  }

  /**
   * Get or create encryption key for user
   * @private
   */
  async _getOrCreateEncryptionKey(client, userId) {
    const selectQuery = `
      SELECT encrypted_dek FROM encryption_keys
      WHERE user_id = $1 AND key_status = 'active'
    `;

    const result = await client.query(selectQuery, [userId]);

    if (result.rows.length > 0) {
      return result.rows[0].encrypted_dek;
    }

    return null; // Will be created during encryption
  }

  /**
   * Store encryption key for user
   * @private
   */
  async _storeEncryptionKey(client, userId, encryptedDek, kmsKeyId, algorithm) {
    const insertQuery = `
      INSERT INTO encryption_keys (user_id, encrypted_dek, kms_key_id, algorithm)
      VALUES ($1, $2, $3, $4)
      ON CONFLICT (user_id) DO UPDATE SET
        encrypted_dek = EXCLUDED.encrypted_dek,
        kms_key_id = EXCLUDED.kms_key_id,
        updated_at = NOW()
    `;

    await client.query(insertQuery, [userId, encryptedDek, kmsKeyId, algorithm]);
  }

  /**
   * Log credential access for audit trail
   * @private
   */
  async _logAccess(client, credentialId, userId, operation, accessedBy, accessReason, success, errorMessage = null) {
    const insertQuery = `
      INSERT INTO credential_access_log (
        credential_id,
        user_id,
        operation,
        accessed_by,
        access_reason,
        success,
        error_message
      ) VALUES ($1, $2, $3, $4, $5, $6, $7)
    `;

    await client.query(insertQuery, [
      credentialId,
      userId,
      operation,
      accessedBy,
      accessReason,
      success,
      errorMessage
    ]);
  }

  /**
   * Refresh OAuth token using refresh token
   * @private
   */
  async _refreshOAuthToken(client, userId, platform, credentialRow) {
    try {
      // TODO: Implement OAuth refresh logic per platform
      // This would decrypt refresh token, make OAuth refresh request, store new tokens

      logger.info('OAuth token refresh not yet implemented', {
        userId,
        platform
      });

      return false;
    } catch (error) {
      logger.error('OAuth token refresh failed', {
        userId,
        platform,
        error: error.message
      });

      return false;
    }
  }
}

// Singleton instance
const credentialManager = new CredentialManager();

module.exports = credentialManager;
module.exports.CredentialManager = CredentialManager;
