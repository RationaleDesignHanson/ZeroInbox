#!/bin/bash

# Credential Rotation Script - Zero Backend
# Usage: ./rotate-credentials.sh
# WARNING: This will invalidate existing sessions

set -e  # Exit on error

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ENV_FILE="$SCRIPT_DIR/.env"
BACKUP_DIR="$SCRIPT_DIR/.env.backups"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}═══════════════════════════════════════════════════${NC}"
echo -e "${BLUE}   Zero Backend - Credential Rotation Script${NC}"
echo -e "${BLUE}═══════════════════════════════════════════════════${NC}"
echo

# Check if .env exists
if [ ! -f "$ENV_FILE" ]; then
    echo -e "${RED}ERROR: .env file not found at $ENV_FILE${NC}"
    exit 1
fi

# Create backup directory
mkdir -p "$BACKUP_DIR"

# Create backup
BACKUP_FILE="$BACKUP_DIR/.env.backup.$(date +%Y%m%d_%H%M%S)"
cp "$ENV_FILE" "$BACKUP_FILE"
echo -e "${GREEN}✓ Backup created: $BACKUP_FILE${NC}"
echo

# Function to generate JWT secret
generate_jwt_secret() {
    openssl rand -hex 64
}

# Function to update env file
update_env() {
    local key=$1
    local value=$2
    local file=$3

    # Escape special characters in value
    escaped_value=$(echo "$value" | sed 's/[&/\]/\\&/g')

    # Update the file
    sed -i.tmp "s|^${key}=.*|${key}=${escaped_value}|" "$file"
    rm "${file}.tmp"
}

echo -e "${YELLOW}⚠️  WARNING: This will rotate credentials and invalidate existing sessions.${NC}"
echo -e "${YELLOW}   Users will need to log in again.${NC}"
echo
read -p "Continue? (yes/no): " confirm

if [ "$confirm" != "yes" ]; then
    echo -e "${RED}Aborted.${NC}"
    exit 0
fi

echo
echo -e "${BLUE}Starting credential rotation...${NC}"
echo

# 1. JWT_SECRET
echo -e "${YELLOW}[1/4] Rotating JWT_SECRET...${NC}"
NEW_JWT_SECRET=$(generate_jwt_secret)
update_env "JWT_SECRET" "$NEW_JWT_SECRET" "$ENV_FILE"
echo -e "${GREEN}✓ JWT_SECRET rotated${NC}"
echo -e "  New value: ${NEW_JWT_SECRET:0:20}...${NEW_JWT_SECRET: -20}"
echo

# 2. STEEL_API_KEY
echo -e "${YELLOW}[2/4] STEEL_API_KEY rotation...${NC}"
echo -e "  ${BLUE}Manual step required:${NC}"
echo -e "  1. Go to https://app.steel.dev/api-keys"
echo -e "  2. Create new API key named: 'Zero-Production-$(date +%Y-%m-%d)'"
echo -e "  3. Revoke old key (ends with: ...eUP)"
echo
read -p "Paste new Steel API key (or press Enter to skip): " NEW_STEEL_KEY

if [ ! -z "$NEW_STEEL_KEY" ]; then
    update_env "STEEL_API_KEY" "$NEW_STEEL_KEY" "$ENV_FILE"
    echo -e "${GREEN}✓ STEEL_API_KEY updated${NC}"
else
    echo -e "${YELLOW}⚠ STEEL_API_KEY skipped - update manually${NC}"
fi
echo

# 3. CANVAS_API_TOKEN
echo -e "${YELLOW}[3/4] CANVAS_API_TOKEN rotation...${NC}"
echo -e "  ${BLUE}Manual step required:${NC}"
echo -e "  1. Go to https://canvas.instructure.com/profile/settings"
echo -e "  2. Scroll to 'Approved Integrations'"
echo -e "  3. Click '+ New Access Token'"
echo -e "  4. Purpose: 'Zero-Production-$(date +%Y-%m-%d)'"
echo -e "  5. Delete old token (ends with: ...kyX)"
echo
read -p "Paste new Canvas API token (or press Enter to skip): " NEW_CANVAS_TOKEN

if [ ! -z "$NEW_CANVAS_TOKEN" ]; then
    update_env "CANVAS_API_TOKEN" "$NEW_CANVAS_TOKEN" "$ENV_FILE"
    echo -e "${GREEN}✓ CANVAS_API_TOKEN updated${NC}"
else
    echo -e "${YELLOW}⚠ CANVAS_API_TOKEN skipped - update manually${NC}"
fi
echo

# 4. GOOGLE_CLASSROOM credentials
echo -e "${YELLOW}[4/4] GOOGLE_CLASSROOM credentials rotation...${NC}"
echo -e "  ${BLUE}Manual steps required:${NC}"
echo -e "  1. Go to https://console.cloud.google.com/apis/credentials"
echo -e "  2. Find client: 514014482017-8icfgg4vag0ic0u028cb9est0r5pgvne"
echo -e "  3. Add new client secret, delete old secret (GOCSPX-GJmD...)"
echo
read -p "Paste new CLIENT_SECRET (or press Enter to skip): " NEW_GC_SECRET

if [ ! -z "$NEW_GC_SECRET" ]; then
    update_env "GOOGLE_CLASSROOM_CLIENT_SECRET" "$NEW_GC_SECRET" "$ENV_FILE"
    echo -e "${GREEN}✓ GOOGLE_CLASSROOM_CLIENT_SECRET updated${NC}"

    echo
    echo -e "  ${BLUE}OAuth flow required for new tokens:${NC}"
    echo -e "  Run: ${YELLOW}node scripts/google-classroom-auth.js${NC}"
    echo -e "  Or see CREDENTIAL_ROTATION_GUIDE.md for manual OAuth flow"
else
    echo -e "${YELLOW}⚠ GOOGLE_CLASSROOM credentials skipped - update manually${NC}"
fi
echo

echo -e "${BLUE}═══════════════════════════════════════════════════${NC}"
echo -e "${GREEN}✓ Credential rotation complete!${NC}"
echo -e "${BLUE}═══════════════════════════════════════════════════${NC}"
echo

echo -e "${YELLOW}Next steps:${NC}"
echo "1. Review updated .env file: $ENV_FILE"
echo "2. Update Google Secret Manager (if using)"
echo "3. Restart services: pm2 restart all"
echo "4. Verify integrations work"
echo "5. Complete manual OAuth flow for Google Classroom (if needed)"
echo
echo -e "${BLUE}Backup location:${NC} $BACKUP_FILE"
echo -e "${BLUE}Detailed guide:${NC} $(dirname $SCRIPT_DIR)/CREDENTIAL_ROTATION_GUIDE.md"
echo

# Show summary of changes
echo -e "${BLUE}═══════════════════════════════════════════════════${NC}"
echo -e "${BLUE}Summary of Changes:${NC}"
echo -e "${BLUE}═══════════════════════════════════════════════════${NC}"
echo -e "JWT_SECRET:                    ${GREEN}ROTATED${NC}"
if [ ! -z "$NEW_STEEL_KEY" ]; then
    echo -e "STEEL_API_KEY:                 ${GREEN}UPDATED${NC}"
else
    echo -e "STEEL_API_KEY:                 ${YELLOW}MANUAL UPDATE NEEDED${NC}"
fi
if [ ! -z "$NEW_CANVAS_TOKEN" ]; then
    echo -e "CANVAS_API_TOKEN:              ${GREEN}UPDATED${NC}"
else
    echo -e "CANVAS_API_TOKEN:              ${YELLOW}MANUAL UPDATE NEEDED${NC}"
fi
if [ ! -z "$NEW_GC_SECRET" ]; then
    echo -e "GOOGLE_CLASSROOM_CLIENT_SECRET: ${GREEN}UPDATED${NC}"
    echo -e "GOOGLE_CLASSROOM tokens:       ${YELLOW}OAUTH FLOW NEEDED${NC}"
else
    echo -e "GOOGLE_CLASSROOM credentials:  ${YELLOW}MANUAL UPDATE NEEDED${NC}"
fi
echo -e "${BLUE}═══════════════════════════════════════════════════${NC}"
echo

echo -e "${YELLOW}⚠️  Important: Users will need to re-authenticate on next app launch${NC}"
echo
