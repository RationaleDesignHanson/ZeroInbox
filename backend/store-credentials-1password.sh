#!/bin/bash
# Store Zero Inbox Credentials in 1Password
# Run this script after unlocking 1Password app
# Usage: bash store-credentials-1password.sh

set -e

echo "🔐 Storing Zero Inbox credentials in 1Password..."
echo ""

# Dashboard Access Codes (already created)
echo "✅ Dashboard Access Codes - Already created"

# JWT Secret
echo "📝 Creating JWT Secret..."
op item create --category "Secure Note" --title "Zero Inbox - JWT Secret" --vault Private \
  'jwt_secret[password]=d627cf81c3211cd9106f5383508047fd7946f93e6db28cd05f40e6b224c77105bc4b5b8f1d930f7a4e1d0a57f95606b09b9da163ad8a39526a6cac895531bf92' \
  'rotation_date[text]=2025-11-06' \
  'next_rotation[text]=2026-02-06' \
  'location[text]=/backend/.env line 38' \
  "notes[text]=JWT secret for session authentication. 128 chars (64 bytes). Algorithm: HMAC-SHA256."

echo "✅ JWT Secret created"

# Steel.dev API Key
echo "📝 Creating Steel.dev API Key..."
op item create --category "API Credential" --title "Zero Inbox - Steel.dev API Key" --vault Private \
  'credential[password]=ste-XoV1UrRCXSpPYE5WgmrM9ZsgxE1lsYNs12s9nsdNn0lGuKafWrj6Yt3rUqwDqmOihsNUPeZ8AixEkxaYwguY4ta0fMZHi0n2eUP' \
  'service[text]=Steel.dev Browser Automation' \
  'status[text]=ACTIVE' \
  'location[text]=/backend/.env line 69' \
  "notes[text]=Steel.dev API key for shopping automation (Amazon, Target, Walmart, Best Buy, etc.). Pay-per-session pricing. Rotate quarterly."

echo "✅ Steel.dev API Key created"

# Canvas LMS Token
echo "📝 Creating Canvas LMS Token..."
op item create --category "API Credential" --title "Zero Inbox - Canvas LMS Token" --vault Private \
  'credential[password]=7~6rPNPrmPUfCRALFLGmMAAXk3RhZnMrHVVyBZJkZ4RBxk2yFtvJCJF4XKUn6J3kyX' \
  'service[text]=Canvas LMS Integration' \
  'domain[text]=canvas.instructure.com' \
  'status[text]=ACTIVE' \
  'location[text]=/backend/.env line 50' \
  "notes[text]=Canvas LMS API token for Thread Finder integration. Fetches course assignments and deadlines. Rate limit: 3000 req/hour."

echo "✅ Canvas LMS Token created"

# Google Classroom OAuth
echo "📝 Creating Google Classroom OAuth credentials..."
op item create --category "Secure Note" --title "Zero Inbox - Google Classroom OAuth" --vault Private \
  'client_id[text]=514014482017-8icfgg4vag0ic0u028cb9est0r5pgvne.apps.googleusercontent.com' \
  'client_secret[password]=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' \
  'refresh_token[password]=1//01QBIW3lhBzGpCgYIARAAGAESNwF-L9Ir1Rs6gJJLpu9mMkCMb41r0MWKf2I8V3dBq40yB9dzJ3tb6Kk8lw6XcE0mkeR0Kg6OrYQ' \
  'auto_rotation[text]=Yes (every 50 minutes)' \
  'rotation_script[text]=/backend/services/google-classroom-token-rotation.js' \
  "notes[text]=Google Classroom OAuth credentials. Access tokens auto-rotate every 50 minutes. Refresh token is long-lived. Scopes: classroom.courses.readonly, classroom.coursework.readonly"

echo "✅ Google Classroom OAuth created"

echo ""
echo "🎉 All credentials stored in 1Password!"
echo ""
echo "📋 Summary:"
echo "  ✅ Dashboard Access Codes"
echo "  ✅ JWT Secret"
echo "  ✅ Steel.dev API Key"
echo "  ✅ Canvas LMS Token"
echo "  ✅ Google Classroom OAuth"
echo ""
echo "💡 Tip: View all items with: op item list --categories 'Secure Note,API Credential' --tags zero-inbox"
