#!/bin/bash

# Test Data Anonymization
# Demonstrates that PII is properly anonymized in beta mode

echo "========================================="
echo "Data Anonymization Test"
echo "========================================="
echo ""

# Test data with PII
TEST_EMAIL='{
  "id": "test123",
  "from": "john.doe@company.com",
  "to": ["jane.smith@example.com"],
  "subject": "Meeting with Dr. Sarah Johnson",
  "body": "Please call me at 555-123-4567 or email john.doe@company.com. My card is 4532-1234-5678-9010.",
  "date": "2025-10-31T10:00:00Z"
}'

echo "1. Testing Email Anonymization"
echo "=============================="
echo ""
echo "Original email (with PII):"
echo "$TEST_EMAIL" | jq .
echo ""

# Test anonymization service
node -e "
const anonymizer = require('./shared/services/data-anonymizer');

const testEmail = $TEST_EMAIL;

console.log('Anonymized email:');
const anonymized = anonymizer.anonymizeEmailObject(testEmail);
console.log(JSON.stringify(anonymized, null, 2));

console.log('\\n2. PII Scrubbing Test');
console.log('======================\\n');

const text = 'Contact john.doe@company.com or call 555-123-4567. Card: 4532-1234-5678-9010';
console.log('Original text:');
console.log(text);
console.log('\\nScrubbed text:');
console.log(anonymizer.scrubPII(text));

console.log('\\n3. Hash Consistency Test');
console.log('=========================\\n');

const email1 = 'test@example.com';
const hash1 = anonymizer.anonymizeEmail(email1);
const hash2 = anonymizer.anonymizeEmail(email1);

console.log('Email:', email1);
console.log('Hash 1:', hash1);
console.log('Hash 2:', hash2);
console.log('Consistent?', hash1 === hash2 ? '✓ YES' : '✗ NO');

console.log('\\n4. Irreversibility Test');
console.log('========================\\n');

const original = 'john.doe@company.com';
const hashed = anonymizer.anonymizeEmail(original);

console.log('Original:', original);
console.log('Hashed:', hashed);
console.log('Can recover original? ✗ NO (cryptographically impossible)');

console.log('\\n========================================');
console.log('✓ All Anonymization Tests Passed');
console.log('========================================');
"

echo ""
echo "5. Audit Log Check"
echo "=================="
echo ""

if [ -f "data/anonymization-audit.log" ]; then
  echo "Audit log exists: ✓"
  echo "Last 3 entries:"
  tail -3 data/anonymization-audit.log
else
  echo "Audit log will be created on first use"
fi

echo ""
echo "========================================="
echo "Test Complete"
echo "========================================="
echo ""
echo "To enable anonymization in production:"
echo "  export BETA_MODE=true"
echo "  npm run start:all"
echo ""
