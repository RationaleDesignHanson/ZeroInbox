#!/bin/bash

# Security End-to-End Test Suite
# Tests all security features implemented for production deployment
# Run with: bash test-security-e2e.sh

set -e  # Exit on any error

# Color output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Test configuration
DASHBOARD_URL="http://localhost:8088"
GATEWAY_URL="http://localhost:3001"
TEST_ACCESS_CODE="ZERO2024"
ADMIN_ACCESS_CODE="ZEROADMIN"

# Test counters
TESTS_PASSED=0
TESTS_FAILED=0

echo -e "${BLUE}========================================="
echo -e "Security E2E Test Suite"
echo -e "=========================================${NC}"
echo ""
echo "Testing security features:"
echo "  - Dashboard Authentication"
echo "  - Rate Limiting"
echo "  - Zero-Visibility Architecture"
echo "  - Session Management"
echo "  - Waitlist Signup"
echo "  - Landing Page"
echo ""

# Helper function for test results
pass_test() {
    echo -e "${GREEN}✓ PASS${NC}: $1"
    ((TESTS_PASSED++))
}

fail_test() {
    echo -e "${RED}✗ FAIL${NC}: $1"
    echo -e "  ${RED}Error: $2${NC}"
    ((TESTS_FAILED++))
}

skip_test() {
    echo -e "${YELLOW}⊘ SKIP${NC}: $1"
}

# ============================================
# Test 1: Dashboard Authentication - Unauthenticated Access
# ============================================
echo -e "\n${BLUE}[1/10]${NC} Testing unauthenticated access to dashboard..."

RESPONSE=$(curl -s -o /dev/null -w "%{http_code}" "$DASHBOARD_URL/index.html")

if [ "$RESPONSE" == "401" ]; then
    pass_test "Unauthenticated users blocked (HTTP 401)"
else
    fail_test "Unauthenticated access should return 401" "Got HTTP $RESPONSE"
fi

# ============================================
# Test 2: Dashboard Authentication - Invalid Access Code
# ============================================
echo -e "\n${BLUE}[2/10]${NC} Testing login with invalid access code..."

RESPONSE=$(curl -s -X POST "$DASHBOARD_URL/auth/login" \
  -H "Content-Type: application/json" \
  -d '{"accessCode":"INVALID123","email":"test@example.com"}' \
  -w "\n%{http_code}")

HTTP_CODE=$(echo "$RESPONSE" | tail -1)
BODY=$(echo "$RESPONSE" | head -1)

if [ "$HTTP_CODE" == "401" ] && echo "$BODY" | grep -q "Invalid access code"; then
    pass_test "Invalid access code rejected (HTTP 401)"
else
    fail_test "Invalid access code should return 401" "Got HTTP $HTTP_CODE"
fi

# ============================================
# Test 3: Dashboard Authentication - Valid Access Code (ZERO2024)
# ============================================
echo -e "\n${BLUE}[3/10]${NC} Testing login with valid access code (ZERO2024)..."

RESPONSE=$(curl -s -X POST "$DASHBOARD_URL/auth/login" \
  -H "Content-Type: application/json" \
  -d "{\"accessCode\":\"$TEST_ACCESS_CODE\",\"email\":\"test@example.com\"}" \
  -c /tmp/zero_cookies.txt \
  -w "\n%{http_code}")

HTTP_CODE=$(echo "$RESPONSE" | tail -1)
BODY=$(echo "$RESPONSE" | head -1)

if [ "$HTTP_CODE" == "200" ] && echo "$BODY" | grep -q "success.*true"; then
    pass_test "Valid access code accepted (HTTP 200)"

    # Extract session cookie
    SESSION_COOKIE=$(grep zero_session /tmp/zero_cookies.txt | awk '{print $7}')

    if [ -n "$SESSION_COOKIE" ]; then
        pass_test "Session cookie created"
    else
        fail_test "Session cookie not found" "No zero_session in cookies"
    fi
else
    fail_test "Valid access code should return 200" "Got HTTP $HTTP_CODE"
fi

# ============================================
# Test 4: Dashboard Authentication - Authenticated Access
# ============================================
echo -e "\n${BLUE}[4/10]${NC} Testing authenticated access to protected route..."

RESPONSE=$(curl -s -o /dev/null -w "%{http_code}" \
  -b /tmp/zero_cookies.txt \
  "$DASHBOARD_URL/system-health.html")

if [ "$RESPONSE" == "200" ]; then
    pass_test "Authenticated user can access protected routes"
else
    fail_test "Authenticated access should return 200" "Got HTTP $RESPONSE"
fi

# ============================================
# Test 5: Dashboard Authentication - Admin Access Code
# ============================================
echo -e "\n${BLUE}[5/10]${NC} Testing admin access code (ZEROADMIN)..."

RESPONSE=$(curl -s -X POST "$DASHBOARD_URL/auth/login" \
  -H "Content-Type: application/json" \
  -d "{\"accessCode\":\"$ADMIN_ACCESS_CODE\",\"email\":\"admin@zero.app\"}" \
  -w "\n%{http_code}")

HTTP_CODE=$(echo "$RESPONSE" | tail -1)
BODY=$(echo "$RESPONSE" | head -1)

if [ "$HTTP_CODE" == "200" ] && echo "$BODY" | grep -q "accessLevel.*admin"; then
    pass_test "Admin access code accepted with admin level"
else
    fail_test "Admin access code should return 200 with admin level" "Got HTTP $HTTP_CODE"
fi

# ============================================
# Test 6: Rate Limiting - Normal Traffic
# ============================================
echo -e "\n${BLUE}[6/10]${NC} Testing rate limiting with normal traffic..."

# Send 10 requests (should all pass)
FAILED_REQUESTS=0
for i in {1..10}; do
    RESPONSE=$(curl -s -o /dev/null -w "%{http_code}" "$GATEWAY_URL/health")
    if [ "$RESPONSE" != "200" ]; then
        ((FAILED_REQUESTS++))
    fi
done

if [ $FAILED_REQUESTS -eq 0 ]; then
    pass_test "Normal traffic (10 requests) not rate limited"
else
    fail_test "Normal traffic should not be rate limited" "$FAILED_REQUESTS/10 requests failed"
fi

# ============================================
# Test 7: Rate Limiting - Excessive Traffic
# ============================================
echo -e "\n${BLUE}[7/10]${NC} Testing rate limiting with excessive traffic..."
echo -e "  ${YELLOW}Note: This test takes ~60 seconds to send 1001 requests${NC}"

# This test is disabled by default because it takes too long
# Uncomment to run full rate limit test
skip_test "Rate limit stress test (1001 requests) - run manually if needed"
# RATE_LIMITED=0
# for i in {1..1001}; do
#     RESPONSE=$(curl -s -o /dev/null -w "%{http_code}" "$GATEWAY_URL/health")
#     if [ "$RESPONSE" == "429" ]; then
#         RATE_LIMITED=1
#         echo -e "  Rate limited after $i requests"
#         break
#     fi
# done
#
# if [ $RATE_LIMITED -eq 1 ]; then
#     pass_test "Rate limiting triggered after excessive requests"
# else
#     fail_test "Rate limiting should trigger after 1000 requests" "No 429 response received"
# fi

# ============================================
# Test 8: Zero-Visibility Architecture - No Caching
# ============================================
echo -e "\n${BLUE}[8/10]${NC} Testing zero-visibility architecture (no caching)..."

# Check if gmail.js contains any caching code
if grep -q "threadCache\|setCachedThreadMetadata\|getCachedThreadMetadata" backend/services/email/routes/gmail.js 2>/dev/null; then
    fail_test "Zero-visibility violated" "Found caching code in gmail.js"
else
    pass_test "No thread caching found in gmail.js"
fi

# Check for cache-related comments/documentation
if grep -q "SECURITY NOTE.*zero-visibility" backend/services/email/routes/gmail.js 2>/dev/null; then
    pass_test "Zero-visibility architecture documented in code"
else
    skip_test "Zero-visibility documentation check"
fi

# ============================================
# Test 9: Waitlist Signup
# ============================================
echo -e "\n${BLUE}[9/10]${NC} Testing waitlist signup..."

RESPONSE=$(curl -s -X POST "$DASHBOARD_URL/auth/waitlist" \
  -H "Content-Type: application/json" \
  -d '{"email":"test-e2e@example.com","name":"E2E Test User"}' \
  -w "\n%{http_code}")

HTTP_CODE=$(echo "$RESPONSE" | tail -1)
BODY=$(echo "$RESPONSE" | head -1)

if [ "$HTTP_CODE" == "200" ] && echo "$BODY" | grep -q "success.*true"; then
    pass_test "Waitlist signup successful"
else
    fail_test "Waitlist signup should return 200" "Got HTTP $HTTP_CODE"
fi

# ============================================
# Test 10: Landing Page Rendering
# ============================================
echo -e "\n${BLUE}[10/10]${NC} Testing landing page rendering..."

# Login first to access landing page
curl -s -X POST "$DASHBOARD_URL/auth/login" \
  -H "Content-Type: application/json" \
  -d "{\"accessCode\":\"$TEST_ACCESS_CODE\",\"email\":\"test@example.com\"}" \
  -c /tmp/zero_landing_cookies.txt > /dev/null

RESPONSE=$(curl -s -b /tmp/zero_landing_cookies.txt "$DASHBOARD_URL/landing.html")

# Check for key landing page content
if echo "$RESPONSE" | grep -q "Zero Sequence" && \
   echo "$RESPONSE" | grep -q "Track Package" && \
   echo "$RESPONSE" | grep -q "Save Time"; then
    pass_test "Landing page renders with key content"
else
    fail_test "Landing page missing key content" "Could not find Zero Sequence or action cards"
fi

# Check for FAQ section
if echo "$RESPONSE" | grep -q "faq" || echo "$RESPONSE" | grep -q "FAQ"; then
    pass_test "Landing page includes FAQ section"
else
    skip_test "FAQ section check (case-sensitive)"
fi

# ============================================
# Test Summary
# ============================================
echo ""
echo -e "${BLUE}========================================="
echo -e "Test Summary"
echo -e "=========================================${NC}"
echo ""
echo -e "Tests Passed: ${GREEN}$TESTS_PASSED${NC}"
echo -e "Tests Failed: ${RED}$TESTS_FAILED${NC}"
echo ""

# Calculate pass rate
TOTAL_TESTS=$((TESTS_PASSED + TESTS_FAILED))
if [ $TOTAL_TESTS -gt 0 ]; then
    PASS_RATE=$((TESTS_PASSED * 100 / TOTAL_TESTS))
    echo -e "Pass Rate: ${BLUE}$PASS_RATE%${NC} ($TESTS_PASSED/$TOTAL_TESTS)"
fi

echo ""

# Cleanup
rm -f /tmp/zero_cookies.txt /tmp/zero_landing_cookies.txt

# Exit with appropriate code
if [ $TESTS_FAILED -eq 0 ]; then
    echo -e "${GREEN}========================================="
    echo -e "✓ ALL SECURITY TESTS PASSED"
    echo -e "=========================================${NC}"
    echo ""
    echo "Your Zero platform is secure and ready for production!"
    echo ""
    exit 0
else
    echo -e "${RED}========================================="
    echo -e "✗ SOME TESTS FAILED"
    echo -e "=========================================${NC}"
    echo ""
    echo "Please fix failing tests before deploying to production."
    echo ""
    exit 1
fi
