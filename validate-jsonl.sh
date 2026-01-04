#!/bin/bash
# JSONL Export Validation Script
# Automatically checks for PII leakage in zero-feedback-export.jsonl
# Usage: ./validate-jsonl.sh <path-to-jsonl-file>

set -e

JSONL_FILE="${1:-$HOME/Documents/zero-feedback-export.jsonl}"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}======================================${NC}"
echo -e "${BLUE}Zero JSONL Export Validation${NC}"
echo -e "${BLUE}======================================${NC}"
echo ""

# Check if file exists
if [ ! -f "$JSONL_FILE" ]; then
    echo -e "${RED}❌ Error: File not found: $JSONL_FILE${NC}"
    echo ""
    echo "Usage: $0 <path-to-jsonl-file>"
    echo "Example: $0 ~/Documents/zero-feedback-export.jsonl"
    exit 1
fi

echo -e "${GREEN}✓ File found: $JSONL_FILE${NC}"
echo ""

# Count lines
LINE_COUNT=$(wc -l < "$JSONL_FILE" | tr -d ' ')
echo -e "📊 ${BLUE}Total samples:${NC} $LINE_COUNT"

# Get file size
FILE_SIZE=$(du -h "$JSONL_FILE" | cut -f1)
echo -e "💾 ${BLUE}File size:${NC} $FILE_SIZE"
echo ""

# Initialize counters
ERRORS=0
WARNINGS=0

echo -e "${BLUE}======================================${NC}"
echo -e "${BLUE}Format Validation${NC}"
echo -e "${BLUE}======================================${NC}"
echo ""

# Test 1: Valid JSON per line
echo -ne "Testing JSON format per line... "
INVALID_JSON=0
LINE_NUM=1
while IFS= read -r line; do
    if [ -n "$line" ]; then
        if ! echo "$line" | jq empty 2>/dev/null; then
            echo -e "${RED}✗${NC}"
            echo -e "  ${RED}Invalid JSON on line $LINE_NUM${NC}"
            INVALID_JSON=$((INVALID_JSON + 1))
            ERRORS=$((ERRORS + 1))
        fi
    fi
    LINE_NUM=$((LINE_NUM + 1))
done < "$JSONL_FILE"

if [ $INVALID_JSON -eq 0 ]; then
    echo -e "${GREEN}✓${NC}"
else
    echo -e "  ${RED}Found $INVALID_JSON invalid JSON lines${NC}"
fi

# Test 2: Required fields present
echo -ne "Checking required fields... "
MISSING_FIELDS=0
while IFS= read -r line; do
    if [ -n "$line" ]; then
        # Check for required fields
        for field in emailId timestamp subject from sanitizationApplied sanitizationVersion classifiedCategory correctedCategory; do
            if ! echo "$line" | jq -e ".$field" > /dev/null 2>&1; then
                echo -e "${RED}✗${NC}"
                echo -e "  ${RED}Missing field: $field${NC}"
                MISSING_FIELDS=$((MISSING_FIELDS + 1))
                ERRORS=$((ERRORS + 1))
                break
            fi
        done
    fi
done < "$JSONL_FILE"

if [ $MISSING_FIELDS -eq 0 ]; then
    echo -e "${GREEN}✓${NC}"
fi

# Test 3: Sanitization flags
echo -ne "Verifying sanitization applied... "
UNSANITIZED=0
while IFS= read -r line; do
    if [ -n "$line" ]; then
        SANITIZED=$(echo "$line" | jq -r '.sanitizationApplied')
        if [ "$SANITIZED" != "true" ]; then
            echo -e "${RED}✗${NC}"
            echo -e "  ${RED}Found entry with sanitizationApplied=false${NC}"
            UNSANITIZED=$((UNSANITIZED + 1))
            ERRORS=$((ERRORS + 1))
            break
        fi
    fi
done < "$JSONL_FILE"

if [ $UNSANITIZED -eq 0 ]; then
    echo -e "${GREEN}✓${NC}"
fi

echo ""
echo -e "${BLUE}======================================${NC}"
echo -e "${BLUE}PII Detection (Critical)${NC}"
echo -e "${BLUE}======================================${NC}"
echo ""

# Test 4: Email addresses (should be redacted)
echo -ne "Checking for email addresses... "
if grep -E '[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}' "$JSONL_FILE" | grep -v '"fromDomain"' | grep -v '<EMAIL>' > /dev/null 2>&1; then
    echo -e "${RED}✗ FOUND!${NC}"
    echo -e "  ${RED}⚠️  CRITICAL: Actual email addresses detected!${NC}"
    grep -n -E '[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}' "$JSONL_FILE" | grep -v '"fromDomain"' | grep -v '<EMAIL>' | head -3
    ERRORS=$((ERRORS + 1))
else
    echo -e "${GREEN}✓${NC}"
fi

# Test 5: Phone numbers
echo -ne "Checking for phone numbers... "
if grep -E '\(?\d{3}\)?[-.\s]?\d{3}[-.\s]?\d{4}' "$JSONL_FILE" | grep -v '<PHONE>' > /dev/null 2>&1; then
    echo -e "${RED}✗ FOUND!${NC}"
    echo -e "  ${RED}⚠️  CRITICAL: Phone numbers detected!${NC}"
    grep -n -E '\(?\d{3}\)?[-.\s]?\d{3}[-.\s]?\d{4}' "$JSONL_FILE" | grep -v '<PHONE>' | head -3
    ERRORS=$((ERRORS + 1))
else
    echo -e "${GREEN}✓${NC}"
fi

# Test 6: Credit card numbers
echo -ne "Checking for credit card numbers... "
if grep -E '\b\d{4}[\s-]?\d{4}[\s-]?\d{4}[\s-]?\d{4}\b' "$JSONL_FILE" | grep -v '<CARD>' > /dev/null 2>&1; then
    echo -e "${RED}✗ FOUND!${NC}"
    echo -e "  ${RED}⚠️  CRITICAL: Credit card patterns detected!${NC}"
    grep -n -E '\b\d{4}[\s-]?\d{4}[\s-]?\d{4}[\s-]?\d{4}\b' "$JSONL_FILE" | grep -v '<CARD>' | head -3
    ERRORS=$((ERRORS + 1))
else
    echo -e "${GREEN}✓${NC}"
fi

# Test 7: SSN patterns
echo -ne "Checking for SSN patterns... "
if grep -E '\b\d{3}-\d{2}-\d{4}\b' "$JSONL_FILE" | grep -v '<SSN>' > /dev/null 2>&1; then
    echo -e "${RED}✗ FOUND!${NC}"
    echo -e "  ${RED}⚠️  CRITICAL: SSN patterns detected!${NC}"
    grep -n -E '\b\d{3}-\d{2}-\d{4}\b' "$JSONL_FILE" | grep -v '<SSN>' | head -3
    ERRORS=$((ERRORS + 1))
else
    echo -e "${GREEN}✓${NC}"
fi

# Test 8: Full URLs (should be domain only)
echo -ne "Checking for full URLs... "
if grep -E 'https?://[^\s"]+' "$JSONL_FILE" | grep -v '<URL:' > /dev/null 2>&1; then
    echo -e "${YELLOW}⚠${NC}"
    echo -e "  ${YELLOW}Warning: Full URLs found (should be <URL:domain>)${NC}"
    grep -n -E 'https?://[^\s"]+' "$JSONL_FILE" | grep -v '<URL:' | head -3
    WARNINGS=$((WARNINGS + 1))
else
    echo -e "${GREEN}✓${NC}"
fi

# Test 9: IP addresses
echo -ne "Checking for IP addresses... "
if grep -E '\b\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}\b' "$JSONL_FILE" | grep -v '<IP>' > /dev/null 2>&1; then
    echo -e "${YELLOW}⚠${NC}"
    echo -e "  ${YELLOW}Warning: IP addresses found${NC}"
    grep -n -E '\b\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}\b' "$JSONL_FILE" | grep -v '<IP>' | head -3
    WARNINGS=$((WARNINGS + 1))
else
    echo -e "${GREEN}✓${NC}"
fi

echo ""
echo -e "${BLUE}======================================${NC}"
echo -e "${BLUE}Sample Data Inspection${NC}"
echo -e "${BLUE}======================================${NC}"
echo ""

# Show first sample
echo -e "${BLUE}First sample (formatted):${NC}"
head -1 "$JSONL_FILE" | jq '.'
echo ""

# Statistics
echo -e "${BLUE}Field statistics:${NC}"
echo -ne "  Categories: "
cat "$JSONL_FILE" | jq -r '.correctedCategory' | sort | uniq -c
echo ""
echo -ne "  Avg confidence: "
cat "$JSONL_FILE" | jq -r '.classificationConfidence' | awk '{sum+=$1} END {print sum/NR}'
echo ""
echo -ne "  Samples with notes: "
cat "$JSONL_FILE" | jq -r 'select(.notes != null) | .notes' | wc -l | tr -d ' '
echo ""
echo -ne "  Samples with missed actions: "
cat "$JSONL_FILE" | jq -r 'select(.missedActions != null) | .missedActions' | wc -l | tr -d ' '
echo ""

# Final summary
echo ""
echo -e "${BLUE}======================================${NC}"
echo -e "${BLUE}Validation Summary${NC}"
echo -e "${BLUE}======================================${NC}"
echo ""

if [ $ERRORS -eq 0 ]; then
    echo -e "${GREEN}✅ PASSED - No critical issues found${NC}"
    echo -e "${GREEN}   Safe to share this file for training${NC}"
    exit 0
else
    echo -e "${RED}❌ FAILED - $ERRORS critical issue(s) found${NC}"
    echo -e "${RED}   DO NOT share this file externally${NC}"
    echo -e "${RED}   Review issues above and regenerate export${NC}"
    exit 1
fi

if [ $WARNINGS -gt 0 ]; then
    echo -e "${YELLOW}⚠️  $WARNINGS warning(s) - review recommended${NC}"
fi
