# Golden Test Set Testing Plan

**Date**: December 2, 2024
**Test Set**: 136 emails across 20 categories
**Location**: `/Users/matthanson/Zer0_Inbox/Zero_ios_2/agents/golden-test-set/llm-golden-test-set.json`

---

## Objectives

1. **Validate NetworkService Reliability**: Ensure retry logic, token refresh, and rate limiting work correctly
2. **Test Email Classification Accuracy**: Verify classification system handles all 136 test emails
3. **Monitor Performance**: Track response times and failure rates
4. **Identify Edge Cases**: Find any emails that cause issues

---

## Test Setup

### Prerequisites

1. ✅ NetworkService enhancements implemented
2. ✅ Golden test set generated (136 emails)
3. ⏳ Build Zero app successfully
4. ⏳ Configure authentication
5. ⏳ Enable verbose logging

### Enable Verbose Logging

Add to beginning of test session:
```swift
// In AppDelegate or main entry point
Logger.setLogLevel(.debug, for: .network)
Logger.setLogLevel(.debug, for: .classification)
```

---

## Test Scenarios

### Scenario 1: Normal Operation (Baseline)

**Goal**: Verify all 136 emails classify correctly without errors

**Steps**:
1. Build and run Zero app in simulator
2. Authenticate with test account
3. Load golden test set: `llm-golden-test-set.json`
4. Process all 136 emails through classification
5. Record results for each email

**Expected Results**:
- All 136 emails process successfully
- No NetworkService errors
- Classification accuracy ≥95% for standard categories
- Classification accuracy ≥98% for critical categories

**Metrics to Track**:
- Success rate: __/136 (target: 100%)
- Average response time: ___ ms (target: <500ms)
- Classification accuracy by category
- Any errors or warnings

### Scenario 2: Retry Logic Testing

**Goal**: Verify exponential backoff works correctly

**Steps**:
1. Enable network condition simulation (Charles Proxy or Network Link Conditioner)
2. Configure 20% packet loss
3. Process 20 random emails from test set
4. Monitor NetworkService logs for retry attempts

**Expected Results**:
- Failed requests retry automatically (up to 3 times)
- Backoff timing: 1s → 2s → 4s (±500ms jitter)
- Successful recovery after transient failures
- User sees no errors

**Log Patterns to Verify**:
```
→ POST /classify (attempt 1/3)
Request failed (attempt 1), retrying in 1.2s
→ POST /classify (attempt 2/3)
← POST /classify ✅
```

### Scenario 3: Token Refresh Testing

**Goal**: Verify 401 handling and token refresh

**Steps**:
1. Authenticate with test account
2. Manually expire auth token (or wait for expiry)
3. Process 5 emails from test set
4. Monitor token refresh behavior

**Expected Results**:
- 401 error triggers token refresh
- Refresh completes successfully (or redirects to login)
- Request retries with new token
- No user interruption

**Log Patterns to Verify**:
```
← POST /classify HTTP 401
401 Unauthorized - attempting token refresh
Refreshing auth token...
Token refreshed, retrying request
→ POST /classify (attempt 1/1)
← POST /classify ✅
```

### Scenario 4: Rate Limiting Testing

**Goal**: Verify Retry-After handling

**Steps**:
1. Process emails rapidly (burst of 50+ requests)
2. Monitor for 429 responses
3. Verify backoff respects Retry-After header

**Expected Results**:
- 429 errors handled gracefully
- Retry-After header extracted correctly
- Requests wait specified time before retry
- All emails eventually process successfully

**Log Patterns to Verify**:
```
← POST /classify HTTP 429
Rate limited (429). Retry after: 60s
Request failed (attempt 1), retrying in 60.0s
→ POST /classify (attempt 2/3)
← POST /classify ✅
```

### Scenario 5: Category Accuracy Testing

**Goal**: Validate classification accuracy by category

**Test Categories** (20 total):

**Critical Categories** (Target: 98%+):
- `security_alert` (10 emails)
- `bill_payment` (10 emails)
- `deadline_reminder` (10 emails)

**High Priority** (Target: 95%+):
- `task_request` (10 emails) - Known issue: 78% accuracy
- `follow_up_needed` (10 emails) - Known issue: 82% accuracy
- `calendar_invite` (8 emails)
- `meeting_request` (8 emails)
- `approval_request` (5 emails)
- `personal_message` (5 emails)

**Medium Priority** (Target: 95%+):
- `package_tracking` (5 emails)
- `travel_itinerary` (5 emails)
- `financial_statement` (5 emails)
- `password_reset` (5 emails)
- `subscription_renewal` (5 emails)
- `work_update` (5 emails)

**Low Priority** (Target: 90%+):
- `newsletter` (10 emails) - Known issue: 85% accuracy
- `promotional` (5 emails)
- `receipt` (5 emails)
- `social_notification` (5 emails)
- `feedback_request` (5 emails)

**Steps**:
1. Process all emails in each category
2. Compare predicted category vs expected category
3. Calculate accuracy per category
4. Identify misclassified emails for analysis

**Expected Results**:
- Overall accuracy ≥95%
- Critical categories ≥98%
- Known problem categories improve from baseline

---

## Test Execution

### Option 1: Manual Testing (Recommended First)

**Duration**: 30-45 minutes

1. Build app in Xcode
2. Run in iOS Simulator (iPhone 15 Pro)
3. Authenticate with test account
4. Import golden test set through debug menu
5. Process emails and observe console logs
6. Record results in spreadsheet

### Option 2: Automated Testing (Future)

**Duration**: 5 minutes

Create automated test that:
1. Loads golden test set
2. Processes each email through classification
3. Compares results to expected values
4. Generates accuracy report

```swift
func testGoldenSet() async throws {
    let testEmails = try loadGoldenTestSet()
    var results: [TestResult] = []

    for email in testEmails {
        let classification = try await emailClassifier.classify(email)
        let result = TestResult(
            email: email,
            expectedCategory: email.category,
            predictedCategory: classification.category,
            correct: email.category == classification.category
        )
        results.append(result)
    }

    let accuracy = results.filter { $0.correct }.count / results.count
    XCTAssertGreaterThan(accuracy, 0.95, "Accuracy should be >95%")
}
```

---

## Results Template

### Classification Results

| Category | Count | Correct | Accuracy | Notes |
|----------|-------|---------|----------|-------|
| security_alert | 10 | ___ | ___% | |
| bill_payment | 10 | ___ | ___% | Known issue: 88% baseline |
| task_request | 10 | ___ | ___% | Known issue: 78% baseline |
| follow_up_needed | 10 | ___ | ___% | Known issue: 82% baseline |
| newsletter | 10 | ___ | ___% | Known issue: 85% baseline |
| ... | | | | |
| **TOTAL** | **136** | **___** | **___%** | Target: 95%+ |

### NetworkService Performance

| Metric | Value | Target | Status |
|--------|-------|--------|--------|
| Total requests | ___ | 136 | |
| Successful (no retry) | ___ | >90% | |
| Retried (1x) | ___ | <5% | |
| Retried (2x) | ___ | <2% | |
| Retried (3x) | ___ | <1% | |
| Failed after retry | ___ | 0 | |
| Token refreshes | ___ | 0-1 | |
| Rate limits (429) | ___ | 0 | |
| Avg response time | ___ ms | <500ms | |

### Issues Found

1. **Issue**: ___
   - Category: ___
   - Email ID: ___
   - Expected: ___
   - Predicted: ___
   - Root cause: ___

---

## Success Criteria

- ✅ All 136 emails process without fatal errors
- ✅ Overall classification accuracy ≥95%
- ✅ Critical categories accuracy ≥98%
- ✅ Retry logic handles transient failures correctly
- ✅ Token refresh works (if tested)
- ✅ Rate limiting respects Retry-After
- ✅ Average response time <500ms
- ✅ No crashes or hangs

---

## Troubleshooting

### Build Fails
- Check NetworkService.swift for syntax errors
- Verify all imports are available
- Clean build folder: `Cmd+Shift+K`

### Authentication Issues
- Use test account with valid credentials
- Check token storage in Keychain
- Verify backend is accessible

### Classification Errors
- Check API endpoint is correct
- Verify request/response format
- Enable debug logging for classifier

### Network Errors
- Check internet connectivity
- Verify backend is running
- Look for firewall/proxy issues

---

## Next Steps After Testing

1. **If accuracy ≥95%**: ✅ Move to production testing with real accounts
2. **If accuracy <95%**:
   - Analyze misclassified emails
   - Identify patterns in failures
   - Improve classification prompts
   - Re-test with updated classifier

3. **If NetworkService issues**:
   - Review retry logic
   - Check backoff timing
   - Verify error handling
   - Add more logging

4. **Production Rollout**:
   - Test with 3-5 real user accounts
   - Monitor corpus analytics
   - Track reliability metrics
   - Gather user feedback

---

## Files

- Test set: `/Users/matthanson/Zer0_Inbox/Zero_ios_2/agents/golden-test-set/llm-golden-test-set.json`
- Test plan: `/Users/matthanson/Zer0_Inbox/GOLDEN_TEST_SET_TESTING_PLAN.md`
- Results: `/Users/matthanson/Zer0_Inbox/GOLDEN_TEST_SET_RESULTS.md` (create after testing)
