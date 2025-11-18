#!/bin/bash

# Verify Modal Config Integrity
# Checks that all actions with modalConfigJSON have corresponding config files

echo "🔍 Verifying Modal Config Files..."
echo "=================================="
echo

MODAL_DIR="/Users/matthanson/Zer0_Inbox/Zero_ios_2/Zero/Config/ModalConfigs"
MISSING=0
FOUND=0

# Actions that should have modal configs (from ActionRegistry.swift)
declare -a CONFIGS=(
  "track_package"
  "pay_invoice"
  "check_in_flight"
  "write_review"
  "contact_driver"
  "view_pickup_details"
  "sign_form"
  "quick_reply"
  "add_to_calendar"
  "schedule_meeting"
  "add_reminder"
  "newsletter_summary"
  "scheduled_purchase"
  "browse_shopping"
  "cancel_subscription"
  "add_to_wallet"
  "save_contact"
  "send_message"
)

for config in "${CONFIGS[@]}"; do
  FILE="$MODAL_DIR/$config.json"
  if [ -f "$FILE" ]; then
    echo "✅ $config.json"
    ((FOUND++))
  else
    echo "❌ MISSING: $config.json"
    ((MISSING++))
  fi
done

echo
echo "=================================="
echo "Summary: $FOUND found, $MISSING missing"
echo

if [ $MISSING -gt 0 ]; then
  echo "⚠️  Some modal configs are missing!"
  echo "These actions will fail when triggered."
  exit 1
else
  echo "✅ All modal configs present!"
  exit 0
fi
