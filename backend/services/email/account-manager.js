/**
 * Account Manager
 * Manages multiple email accounts for a user
 * Stores OAuth tokens, account metadata, and sync state
 */

const logger = require('./shared/config/logger');

// In-memory storage for development (replace with database in production)
const userAccounts = new Map();

/**
 * Account structure:
 * {
 *   accountId: string,
 *   email: string,
 *   provider: 'gmail' | 'outlook' | 'yahoo',
 *   accessToken: string,
 *   refreshToken: string,
 *   tokenExpiry: Date,
 *   isPrimary: boolean,
 *   enabled: boolean,
 *   lastSynced: Date,
 *   metadata: object
 * }
 */

/**
 * Get all accounts for a user
 */
function getAccounts(userId) {
  if (!userAccounts.has(userId)) {
    return [];
  }
  return userAccounts.get(userId);
}

/**
 * Get a specific account
 */
function getAccount(userId, accountId) {
  const accounts = getAccounts(userId);
  return accounts.find(a => a.accountId === accountId);
}

/**
 * Add or update an account
 */
function saveAccount(userId, account) {
  let accounts = getAccounts(userId);

  // If no accounts exist, make this primary
  if (accounts.length === 0) {
    account.isPrimary = true;
  }

  // Check if account already exists
  const existingIndex = accounts.findIndex(a => a.accountId === account.accountId);

  if (existingIndex >= 0) {
    // Update existing account
    accounts[existingIndex] = { ...accounts[existingIndex], ...account };
    logger.info('Account updated', { userId, accountId: account.accountId, email: account.email });
  } else {
    // Add new account
    accounts.push(account);
    logger.info('Account added', { userId, accountId: account.accountId, email: account.email });
  }

  userAccounts.set(userId, accounts);
  return account;
}

/**
 * Remove an account
 */
function removeAccount(userId, accountId) {
  let accounts = getAccounts(userId);
  const initialLength = accounts.length;

  accounts = accounts.filter(a => a.accountId !== accountId);

  if (accounts.length < initialLength) {
    // If removed account was primary, make first remaining account primary
    if (accounts.length > 0 && !accounts.some(a => a.isPrimary)) {
      accounts[0].isPrimary = true;
    }

    userAccounts.set(userId, accounts);
    logger.info('Account removed', { userId, accountId, remainingAccounts: accounts.length });
    return true;
  }

  logger.warn('Account not found for removal', { userId, accountId });
  return false;
}

/**
 * Set an account as primary
 */
function setPrimaryAccount(userId, accountId) {
  let accounts = getAccounts(userId);

  // Remove primary flag from all accounts
  accounts.forEach(a => { a.isPrimary = false; });

  // Set specified account as primary
  const account = accounts.find(a => a.accountId === accountId);
  if (account) {
    account.isPrimary = true;
    userAccounts.set(userId, accounts);
    logger.info('Primary account updated', { userId, accountId, email: account.email });
    return account;
  }

  logger.warn('Account not found for setPrimary', { userId, accountId });
  return null;
}

/**
 * Enable or disable an account
 */
function setAccountEnabled(userId, accountId, enabled) {
  let accounts = getAccounts(userId);
  const account = accounts.find(a => a.accountId === accountId);

  if (account) {
    account.enabled = enabled;
    userAccounts.set(userId, accounts);
    logger.info('Account enabled status updated', { userId, accountId, enabled });
    return account;
  }

  logger.warn('Account not found for setEnabled', { userId, accountId });
  return null;
}

/**
 * Update account sync timestamp
 */
function updateSyncTimestamp(userId, accountId) {
  let accounts = getAccounts(userId);
  const account = accounts.find(a => a.accountId === accountId);

  if (account) {
    account.lastSynced = new Date();
    userAccounts.set(userId, accounts);
    return account;
  }

  return null;
}

/**
 * Update account tokens (after refresh)
 */
function updateTokens(userId, accountId, tokens) {
  let accounts = getAccounts(userId);
  const account = accounts.find(a => a.accountId === accountId);

  if (account) {
    account.accessToken = tokens.accessToken;
    if (tokens.refreshToken) {
      account.refreshToken = tokens.refreshToken;
    }
    if (tokens.tokenExpiry) {
      account.tokenExpiry = tokens.tokenExpiry;
    }

    userAccounts.set(userId, accounts);
    logger.info('Account tokens updated', { userId, accountId });
    return account;
  }

  logger.warn('Account not found for updateTokens', { userId, accountId });
  return null;
}

/**
 * Get enabled accounts
 */
function getEnabledAccounts(userId) {
  return getAccounts(userId).filter(a => a.enabled);
}

/**
 * Get primary account
 */
function getPrimaryAccount(userId) {
  const accounts = getAccounts(userId);
  return accounts.find(a => a.isPrimary) || accounts[0];
}

/**
 * Check if user has any accounts
 */
function hasAccounts(userId) {
  return getAccounts(userId).length > 0;
}

/**
 * Generate unique account ID
 */
function generateAccountId() {
  return `account-${Date.now()}-${Math.random().toString(36).substr(2, 9)}`;
}

/**
 * Migration: Convert single token to first account
 * Used for migrating existing users
 */
function migrateToMultiAccount(userId, email, accessToken, refreshToken) {
  // Check if migration already done
  if (hasAccounts(userId)) {
    logger.info('User already has accounts, skipping migration', { userId });
    return getAccounts(userId);
  }

  // Create first account from existing token
  const account = {
    accountId: generateAccountId(),
    email,
    provider: 'gmail', // Assume Gmail for now
    accessToken,
    refreshToken,
    tokenExpiry: null, // Will be set on next refresh
    isPrimary: true,
    enabled: true,
    lastSynced: new Date(),
    metadata: {
      migratedFrom: 'single-account',
      migratedAt: new Date()
    }
  };

  saveAccount(userId, account);
  logger.info('Migrated user to multi-account', { userId, email });

  return [account];
}

/**
 * Export accounts data (for debugging/admin)
 */
function exportUserAccounts(userId) {
  const accounts = getAccounts(userId);

  // Redact sensitive tokens
  return accounts.map(account => ({
    accountId: account.accountId,
    email: account.email,
    provider: account.provider,
    isPrimary: account.isPrimary,
    enabled: account.enabled,
    lastSynced: account.lastSynced,
    tokenExpiry: account.tokenExpiry,
    hasAccessToken: !!account.accessToken,
    hasRefreshToken: !!account.refreshToken
  }));
}

module.exports = {
  getAccounts,
  getAccount,
  saveAccount,
  removeAccount,
  setPrimaryAccount,
  setAccountEnabled,
  updateSyncTimestamp,
  updateTokens,
  getEnabledAccounts,
  getPrimaryAccount,
  hasAccounts,
  generateAccountId,
  migrateToMultiAccount,
  exportUserAccounts
};
