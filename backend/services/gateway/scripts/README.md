# Gateway Scripts

Utility scripts for gateway service management and maintenance.

## Available Scripts

### `migrate-tokens-to-firestore.js`

Migrates OAuth tokens from file-based storage to Firestore.

**Usage:**
```bash
# Preview migration (dry run)
DRY_RUN=true node scripts/migrate-tokens-to-firestore.js

# Run actual migration
node scripts/migrate-tokens-to-firestore.js
```

**Environment Variables:**
- `GOOGLE_CLOUD_PROJECT` - Google Cloud project ID (default: gen-lang-client-0622702687)
- `DRY_RUN=true` - Preview migration without writing to Firestore

**See also:** [FIRESTORE_MIGRATION.md](../../FIRESTORE_MIGRATION.md)

## Future Scripts

Add additional maintenance scripts here:
- Token cleanup/expiration
- User data export
- Analytics reporting
- Health checks
