/**
 * Google Secret Manager Integration
 * Securely store and retrieve secrets from Google Cloud Secret Manager
 *
 * Setup:
 * 1. Enable Secret Manager API in GCP Console
 * 2. Grant service account 'Secret Manager Secret Accessor' role
 * 3. Run: npm install @google-cloud/secret-manager
 *
 * Usage:
 * const secrets = require('./services/secrets-manager');
 * const apiKey = await secrets.getSecret('STEEL_API_KEY');
 * await secrets.createSecret('NEW_API_KEY', 'secret-value-here');
 */

const { SecretManagerServiceClient } = require('@google-cloud/secret-manager');
const auditLogger = require('./audit-logger');

// Initialize client
const client = new SecretManagerServiceClient();

// Get project ID from environment or default
const PROJECT_ID = process.env.GOOGLE_PROJECT_ID || 'zero-inbox';

/**
 * Get secret value from Secret Manager
 * @param {string} secretName - Name of the secret (e.g., 'STEEL_API_KEY')
 * @param {string} version - Version of secret (default: 'latest')
 * @returns {Promise<string>} Secret value
 */
async function getSecret(secretName, version = 'latest') {
  try {
    const name = `projects/${PROJECT_ID}/secrets/${secretName}/versions/${version}`;
    const [versionResponse] = await client.accessSecretVersion({ name });

    const secretValue = versionResponse.payload.data.toString('utf8');
    console.log(`✅ Retrieved secret: ${secretName}`);

    // Audit log: Credential read from Secret Manager
    auditLogger.auditCredentialRead(secretName, 'secret_manager');

    return secretValue;
  } catch (error) {
    console.error(`❌ Error retrieving secret ${secretName}:`, error.message);

    // Audit log: Secret Manager error
    auditLogger.logAuditEvent(auditLogger.EVENT_TYPES.SECRET_MANAGER_ERROR, {
      secretName,
      error: error.message,
      code: error.code
    });

    // Fallback to environment variable if secret not found
    if (error.code === 5) { // NOT_FOUND
      console.warn(`⚠️  Secret ${secretName} not found in Secret Manager, using .env fallback`);

      // Audit log: Fallback to .env
      auditLogger.auditCredentialRead(secretName, 'env_fallback');

      return process.env[secretName];
    }

    throw error;
  }
}

/**
 * Create or update a secret in Secret Manager
 * @param {string} secretName - Name of the secret
 * @param {string} secretValue - Value to store
 * @param {Object} labels - Optional labels for the secret
 * @returns {Promise<void>}
 */
async function createSecret(secretName, secretValue, labels = {}) {
  try {
    const parent = `projects/${PROJECT_ID}`;

    // Try to create the secret
    try {
      await client.createSecret({
        parent,
        secretId: secretName,
        secret: {
          replication: {
            automatic: {},
          },
          labels: {
            ...labels,
            'created-by': 'zero-inbox',
            'created-at': new Date().toISOString().split('T')[0]
          }
        },
      });
      console.log(`✅ Created secret: ${secretName}`);
    } catch (error) {
      if (error.code !== 6) { // ALREADY_EXISTS
        throw error;
      }
      console.log(`ℹ️  Secret ${secretName} already exists, adding new version`);
    }

    // Add secret version
    const secretPath = `projects/${PROJECT_ID}/secrets/${secretName}`;
    await client.addSecretVersion({
      parent: secretPath,
      payload: {
        data: Buffer.from(secretValue, 'utf8'),
      },
    });

    console.log(`✅ Added new version to secret: ${secretName}`);

    // Audit log: Credential written
    auditLogger.logAuditEvent(auditLogger.EVENT_TYPES.CREDENTIAL_WRITE, {
      secretName,
      action: 'create_or_update'
    });
  } catch (error) {
    console.error(`❌ Error creating/updating secret ${secretName}:`, error.message);
    throw error;
  }
}

/**
 * List all secrets in the project
 * @returns {Promise<Array>} List of secret names
 */
async function listSecrets() {
  try {
    const parent = `projects/${PROJECT_ID}`;
    const [secrets] = await client.listSecrets({ parent });

    return secrets.map(secret => {
      const name = secret.name.split('/').pop();
      return {
        name,
        created: secret.createTime,
        labels: secret.labels
      };
    });
  } catch (error) {
    console.error('❌ Error listing secrets:', error.message);
    throw error;
  }
}

/**
 * Delete a secret from Secret Manager
 * @param {string} secretName - Name of the secret to delete
 * @returns {Promise<void>}
 */
async function deleteSecret(secretName) {
  try {
    const name = `projects/${PROJECT_ID}/secrets/${secretName}`;
    await client.deleteSecret({ name });
    console.log(`✅ Deleted secret: ${secretName}`);

    // Audit log: Credential deleted
    auditLogger.logAuditEvent(auditLogger.EVENT_TYPES.CREDENTIAL_DELETE, {
      secretName
    });
  } catch (error) {
    console.error(`❌ Error deleting secret ${secretName}:`, error.message);
    throw error;
  }
}

/**
 * Rotate a secret by creating a new version
 * @param {string} secretName - Name of the secret
 * @param {string} newValue - New secret value
 * @returns {Promise<void>}
 */
async function rotateSecret(secretName, newValue) {
  console.log(`🔄 Rotating secret: ${secretName}`);
  await createSecret(secretName, newValue, { rotated: 'true' });

  // Audit log: Credential rotated
  auditLogger.auditCredentialRotate(secretName);
}

/**
 * Migrate all secrets from .env to Secret Manager
 * @param {Object} envVars - Object with environment variables
 * @returns {Promise<void>}
 */
async function migrateFromEnv(envVars) {
  console.log('🚀 Starting migration to Secret Manager...');

  const secretsToMigrate = [
    'JWT_SECRET',
    'STEEL_API_KEY',
    'CANVAS_API_TOKEN',
    'GOOGLE_CLASSROOM_CLIENT_ID',
    'GOOGLE_CLASSROOM_CLIENT_SECRET',
    'GOOGLE_CLASSROOM_REFRESH_TOKEN'
  ];

  for (const secretName of secretsToMigrate) {
    if (envVars[secretName] && envVars[secretName] !== `your-${secretName.toLowerCase()}`) {
      try {
        await createSecret(secretName, envVars[secretName]);
      } catch (error) {
        console.error(`Failed to migrate ${secretName}:`, error.message);
      }
    }
  }

  console.log('✅ Migration complete!');
}

/**
 * Load all secrets and return as object
 * @returns {Promise<Object>} Object with secret key-value pairs
 */
async function loadAllSecrets() {
  const secrets = {};

  const secretNames = [
    'JWT_SECRET',
    'STEEL_API_KEY',
    'CANVAS_API_TOKEN',
    'GOOGLE_CLASSROOM_CLIENT_ID',
    'GOOGLE_CLASSROOM_CLIENT_SECRET',
    'GOOGLE_CLASSROOM_REFRESH_TOKEN'
  ];

  for (const secretName of secretNames) {
    try {
      secrets[secretName] = await getSecret(secretName);
    } catch (error) {
      // Secret not found, skip
      console.warn(`⚠️  Could not load ${secretName}, using .env fallback`);
      secrets[secretName] = process.env[secretName];
    }
  }

  return secrets;
}

module.exports = {
  getSecret,
  createSecret,
  listSecrets,
  deleteSecret,
  rotateSecret,
  migrateFromEnv,
  loadAllSecrets
};
