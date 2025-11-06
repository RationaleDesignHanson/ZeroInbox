/**
 * Encryption Service for Credential Vault
 * Uses AWS KMS for key management with envelope encryption pattern
 *
 * Security Architecture:
 * 1. Master Key Encryption Key (KEK) stored in AWS KMS (never leaves KMS)
 * 2. Per-user Data Encryption Keys (DEK) generated and encrypted by KEK
 * 3. Credentials encrypted locally with user's DEK using AES-256-GCM
 * 4. Encrypted DEK stored in database, plaintext DEK never persisted
 *
 * This provides:
 * - Key isolation: Each user has unique encryption key
 * - Key rotation: Can rotate DEKs without re-encrypting all data
 * - Compliance: Meets GDPR/HIPAA requirements for encryption at rest
 * - Performance: Local encryption with AES, minimal KMS calls
 */

const crypto = require('crypto');
const { KMSClient, GenerateDataKeyCommand, DecryptCommand } = require('@aws-sdk/client-kms');
const logger = require('../classifier/shared/config/logger');

// AWS KMS Configuration
const KMS_KEY_ID = process.env.AWS_KMS_KEY_ID || 'alias/zero-credential-vault';
const KMS_REGION = process.env.AWS_KMS_REGION || 'us-east-1';

// Encryption constants
const ALGORITHM = 'aes-256-gcm';
const KEY_LENGTH = 32; // 256 bits
const IV_LENGTH = 12; // 96 bits (recommended for GCM)
const AUTH_TAG_LENGTH = 16; // 128 bits

class EncryptionService {
  constructor() {
    this.kmsClient = new KMSClient({
      region: KMS_REGION,
      // AWS SDK will automatically use IAM role credentials
      // from EC2 instance metadata or environment variables
    });
  }

  /**
   * Generate a new Data Encryption Key (DEK) for a user
   * Uses AWS KMS to generate a 256-bit key and returns both plaintext and encrypted versions
   *
   * @param {string} userId - User identifier for audit trail
   * @returns {Promise<{plaintextKey: Buffer, encryptedKey: Buffer, kmsKeyId: string}>}
   */
  async generateDataKey(userId) {
    try {
      const startTime = Date.now();

      const command = new GenerateDataKeyCommand({
        KeyId: KMS_KEY_ID,
        KeySpec: 'AES_256', // Generate 256-bit key
        EncryptionContext: {
          userId,
          purpose: 'credential-vault',
          service: 'thread-finder'
        }
      });

      const response = await this.kmsClient.send(command);

      const duration = Date.now() - startTime;

      logger.info('Generated new Data Encryption Key via KMS', {
        userId,
        kmsKeyId: response.KeyId,
        durationMs: duration
      });

      return {
        plaintextKey: Buffer.from(response.Plaintext), // Use immediately, then discard
        encryptedKey: Buffer.from(response.CiphertextBlob), // Store in database
        kmsKeyId: response.KeyId
      };
    } catch (error) {
      logger.error('Failed to generate Data Encryption Key', {
        userId,
        error: error.message,
        kmsKeyId: KMS_KEY_ID
      });
      throw new Error(`KMS key generation failed: ${error.message}`);
    }
  }

  /**
   * Decrypt a Data Encryption Key using AWS KMS
   * Only called when needed to decrypt credentials - plaintext DEK never stored
   *
   * @param {Buffer} encryptedKey - Encrypted DEK from database
   * @param {string} userId - User identifier for audit and encryption context
   * @returns {Promise<Buffer>} - Plaintext DEK (256-bit key)
   */
  async decryptDataKey(encryptedKey, userId) {
    try {
      const startTime = Date.now();

      const command = new DecryptCommand({
        CiphertextBlob: encryptedKey,
        EncryptionContext: {
          userId,
          purpose: 'credential-vault',
          service: 'thread-finder'
        }
      });

      const response = await this.kmsClient.send(command);

      const duration = Date.now() - startTime;

      logger.info('Decrypted Data Encryption Key via KMS', {
        userId,
        kmsKeyId: response.KeyId,
        durationMs: duration
      });

      return Buffer.from(response.Plaintext);
    } catch (error) {
      logger.error('Failed to decrypt Data Encryption Key', {
        userId,
        error: error.message,
        errorCode: error.code
      });
      throw new Error(`KMS key decryption failed: ${error.message}`);
    }
  }

  /**
   * Encrypt credential data using AES-256-GCM
   * Uses envelope encryption: credentials encrypted with DEK, DEK encrypted with KMS
   *
   * @param {Object} credentialData - Plaintext credential data
   * @param {Buffer} dataKey - 256-bit Data Encryption Key (plaintext)
   * @returns {Object} - {ciphertext, iv, authTag}
   */
  encryptCredentials(credentialData, dataKey) {
    try {
      // Generate random initialization vector (96 bits for GCM)
      const iv = crypto.randomBytes(IV_LENGTH);

      // Create cipher with AES-256-GCM
      const cipher = crypto.createCipheriv(ALGORITHM, dataKey, iv);

      // Convert credential data to JSON buffer
      const plaintext = Buffer.from(JSON.stringify(credentialData), 'utf8');

      // Encrypt
      const encrypted = Buffer.concat([cipher.update(plaintext), cipher.final()]);

      // Get authentication tag (AEAD - Authenticated Encryption with Associated Data)
      const authTag = cipher.getAuthTag();

      logger.info('Encrypted credentials', {
        credentialSize: plaintext.length,
        encryptedSize: encrypted.length,
        algorithm: ALGORITHM
      });

      return {
        ciphertext: encrypted,
        iv,
        authTag
      };
    } catch (error) {
      logger.error('Credential encryption failed', {
        error: error.message
      });
      throw new Error(`Encryption failed: ${error.message}`);
    }
  }

  /**
   * Decrypt credential data using AES-256-GCM
   * Verifies authentication tag to ensure data integrity
   *
   * @param {Buffer} ciphertext - Encrypted credential data
   * @param {Buffer} dataKey - 256-bit Data Encryption Key (plaintext)
   * @param {Buffer} iv - Initialization vector used for encryption
   * @param {Buffer} authTag - Authentication tag for AEAD verification
   * @returns {Object} - Decrypted credential data
   */
  decryptCredentials(ciphertext, dataKey, iv, authTag) {
    try {
      // Create decipher with AES-256-GCM
      const decipher = crypto.createDecipheriv(ALGORITHM, dataKey, iv);

      // Set authentication tag for AEAD verification
      decipher.setAuthTag(authTag);

      // Decrypt
      const decrypted = Buffer.concat([decipher.update(ciphertext), decipher.final()]);

      // Parse JSON
      const credentialData = JSON.parse(decrypted.toString('utf8'));

      logger.info('Decrypted credentials', {
        encryptedSize: ciphertext.length,
        decryptedSize: decrypted.length,
        algorithm: ALGORITHM
      });

      return credentialData;
    } catch (error) {
      logger.error('Credential decryption failed', {
        error: error.message,
        errorType: error.code
      });

      // Differentiate between authentication failures and other errors
      if (error.message.includes('Unsupported state or unable to authenticate data')) {
        throw new Error('Decryption failed: Data tampered or corrupted (authentication failed)');
      }

      throw new Error(`Decryption failed: ${error.message}`);
    }
  }

  /**
   * Complete encryption workflow: Generate DEK, encrypt credentials
   * This is the primary method for storing new credentials
   *
   * @param {Object} credentialData - Plaintext credential data
   * @param {string} userId - User identifier
   * @returns {Promise<Object>} - {encryptedCredentials, encryptedDek, iv, authTag, kmsKeyId}
   */
  async encryptCredentialComplete(credentialData, userId) {
    try {
      const startTime = Date.now();

      // Step 1: Generate new DEK via KMS
      const { plaintextKey, encryptedKey, kmsKeyId } = await this.generateDataKey(userId);

      // Step 2: Encrypt credentials with DEK
      const { ciphertext, iv, authTag } = this.encryptCredentials(credentialData, plaintextKey);

      // Step 3: Zero out plaintext key from memory (security best practice)
      plaintextKey.fill(0);

      const duration = Date.now() - startTime;

      logger.info('Complete credential encryption successful', {
        userId,
        durationMs: duration
      });

      return {
        encryptedCredentials: ciphertext,
        encryptedDek: encryptedKey,
        iv,
        authTag,
        kmsKeyId,
        algorithm: ALGORITHM
      };
    } catch (error) {
      logger.error('Complete credential encryption failed', {
        userId,
        error: error.message
      });
      throw error;
    }
  }

  /**
   * Complete decryption workflow: Decrypt DEK, decrypt credentials
   * This is the primary method for retrieving stored credentials
   *
   * @param {Object} encryptedData - {encryptedCredentials, encryptedDek, iv, authTag}
   * @param {string} userId - User identifier
   * @returns {Promise<Object>} - Decrypted credential data
   */
  async decryptCredentialComplete(encryptedData, userId) {
    try {
      const startTime = Date.now();

      const { encryptedCredentials, encryptedDek, iv, authTag } = encryptedData;

      // Step 1: Decrypt DEK via KMS
      const plaintextKey = await this.decryptDataKey(encryptedDek, userId);

      // Step 2: Decrypt credentials with DEK
      const credentialData = this.decryptCredentials(
        encryptedCredentials,
        plaintextKey,
        iv,
        authTag
      );

      // Step 3: Zero out plaintext key from memory
      plaintextKey.fill(0);

      const duration = Date.now() - startTime;

      logger.info('Complete credential decryption successful', {
        userId,
        durationMs: duration
      });

      return credentialData;
    } catch (error) {
      logger.error('Complete credential decryption failed', {
        userId,
        error: error.message
      });
      throw error;
    }
  }

  /**
   * Rotate user's Data Encryption Key
   * Generates new DEK, re-encrypts all credentials, updates database
   *
   * @param {string} userId - User identifier
   * @param {Array<Object>} credentials - Array of {id, data} to re-encrypt
   * @returns {Promise<Object>} - {newEncryptedDek, reencryptedCredentials}
   */
  async rotateDataKey(userId, credentials) {
    try {
      logger.info('Starting DEK rotation', {
        userId,
        credentialCount: credentials.length
      });

      // Generate new DEK
      const { plaintextKey, encryptedKey, kmsKeyId } = await this.generateDataKey(userId);

      // Re-encrypt all credentials with new key
      const reencryptedCredentials = credentials.map(cred => {
        const { ciphertext, iv, authTag } = this.encryptCredentials(cred.data, plaintextKey);
        return {
          id: cred.id,
          encryptedCredentials: ciphertext,
          iv,
          authTag
        };
      });

      // Zero out plaintext key
      plaintextKey.fill(0);

      logger.info('DEK rotation successful', {
        userId,
        newKmsKeyId: kmsKeyId,
        reencryptedCount: reencryptedCredentials.length
      });

      return {
        newEncryptedDek: encryptedKey,
        newKmsKeyId: kmsKeyId,
        reencryptedCredentials
      };
    } catch (error) {
      logger.error('DEK rotation failed', {
        userId,
        error: error.message
      });
      throw new Error(`Key rotation failed: ${error.message}`);
    }
  }
}

// Singleton instance
const encryptionService = new EncryptionService();

module.exports = {
  encryptionService,
  EncryptionService
};
