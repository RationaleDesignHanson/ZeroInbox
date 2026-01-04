# NetworkService Critical Enhancements

**Date**: December 2, 2024
**Phase**: Week 1 - Email Infrastructure & Corpus Testing
**Priority**: HIGH - Implements agent recommendations

---

## Changes to Implement

Based on ZeroAIExpertAgent recommendations and EMAIL_INFRASTRUCTURE_AUDIT.md findings:

### 1. Retry Logic with Exponential Backoff (HIGH PRIORITY)

**Agent Recommendation**:
> "Implement exponential backoff for rate limits. Start at 1s, double each retry, add random 0-500ms jitter."

**Implementation**:
```swift
// Add to NetworkService class
private func requestWithRetry<Response: Decodable>(
    url: URL,
    method: HTTPMethod,
    headers: [String: String]? = nil,
    bodyData: Data? = nil,
    maxRetries: Int = 3,
    currentAttempt: Int = 1
) async throws -> Response {
    do {
        // Build and execute request
        let request = buildRequest(url: url, method: method, headers: headers, body: bodyData)

        Logger.info("→ \(method.rawValue) \(url.path) (attempt \(currentAttempt)/\(maxRetries))", category: .network)

        let (data, response) = try await session.data(for: request)

        // Validate response
        try validateResponse(response, data: data, url: url)

        // Decode and return
        let decoded = try jsonDecoder.decode(Response.self, from: data)
        Logger.info("← \(method.rawValue) \(url.path) ✅", category: .network)
        return decoded

    } catch let error as NetworkServiceError {
        // Check if we should retry
        if shouldRetry(error: error, attempt: currentAttempt, maxRetries: maxRetries) {
            let delay = calculateBackoff(attempt: currentAttempt, error: error)
            Logger.warning("Request failed (attempt \(currentAttempt)), retrying in \(delay)s", category: .network)

            // Wait with backoff
            try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))

            // Retry
            return try await requestWithRetry(
                url: url,
                method: method,
                headers: headers,
                bodyData: bodyData,
                maxRetries: maxRetries,
                currentAttempt: currentAttempt + 1
            )
        }

        // No more retries, throw error
        throw error
    }
}

// Determine if error is retryable
private func shouldRetry(error: NetworkServiceError, attempt: Int, maxRetries: Int) -> Bool {
    guard attempt < maxRetries else { return false }

    switch error {
    case .httpError(let statusCode, _):
        // Retry on:
        // - 408 Request Timeout
        // - 429 Too Many Requests
        // - 500-599 Server Errors (except 501 Not Implemented)
        return statusCode == 408
            || statusCode == 429
            || (statusCode >= 500 && statusCode != 501)
    case .timeout, .noInternetConnection:
        return true
    default:
        return false
    }
}

// Calculate exponential backoff with jitter
private func calculateBackoff(attempt: Int, error: NetworkServiceError) -> Double {
    // Base delay: 1s, 2s, 4s, ...
    let baseDelay = pow(2.0, Double(attempt - 1))

    // Add jitter (0-500ms)
    let jitter = Double.random(in: 0...0.5)

    // Check for Retry-After header (for 429)
    // TODO: Extract from response headers if available

    return baseDelay + jitter
}
```

### 2. Token Refresh on 401 (HIGH PRIORITY)

**Agent Recommendation**:
> "Use refresh token rotation with secure storage. Store encrypted in Keychain."

**Implementation**:
```swift
// Add to NetworkService class
private var isRefreshingToken = false
private var tokenRefreshTask: Task<String, Error>?

private func requestWithTokenRefresh<Response: Decodable>(
    url: URL,
    method: HTTPMethod,
    headers: [String: String]? = nil,
    bodyData: Data? = nil,
    maxRetries: Int = 3
) async throws -> Response {
    do {
        // Try request with current token
        return try await requestWithRetry(
            url: url,
            method: method,
            headers: headers,
            bodyData: bodyData,
            maxRetries: maxRetries
        )
    } catch let error as NetworkServiceError {
        // Check for 401 Unauthorized
        if case .httpError(let statusCode, _) = error, statusCode == 401 {
            Logger.warning("401 Unauthorized - attempting token refresh", category: .network)

            // Refresh token
            try await refreshAuthToken()

            // Retry request with new token
            Logger.info("Token refreshed, retrying request", category: .network)
            return try await requestWithRetry(
                url: url,
                method: method,
                headers: headers,
                bodyData: bodyData,
                maxRetries: 1  // Only retry once after refresh
            )
        }

        throw error
    }
}

private func refreshAuthToken() async throws {
    // If already refreshing, wait for that task
    if let existingTask = tokenRefreshTask {
        _ = try await existingTask.value
        return
    }

    // Create refresh task
    let task = Task<String, Error> {
        Logger.info("Refreshing auth token...", category: .authentication)

        // TODO: Implement actual token refresh
        // For now, clear token and force re-auth
        AuthContext.clearAuthToken()

        throw NetworkServiceError.httpError(statusCode: 401, message: "Token expired - please re-authenticate")
    }

    tokenRefreshTask = task

    do {
        let newToken = try await task.value
        tokenRefreshTask = nil
        Logger.info("Token refresh successful", category: .authentication)
        return
    } catch {
        tokenRefreshTask = nil
        throw error
    }
}
```

### 3. Rate Limiting Protection (MEDIUM PRIORITY)

**Agent Recommendation**:
> "Implement exponential backoff with jitter for rate limits. Respect Retry-After header."

**Implementation**:
```swift
// Enhanced validateResponse to extract Retry-After
private func validateResponse(_ response: URLResponse, data: Data, url: URL) throws -> RetryInfo? {
    guard let httpResponse = response as? HTTPURLResponse else {
        throw NetworkServiceError.invalidResponse
    }

    let statusCode = httpResponse.statusCode
    Logger.debug("Response status: \(statusCode)", category: .network)

    // Handle rate limiting
    if statusCode == 429 {
        let retryAfter = extractRetryAfter(from: httpResponse)
        Logger.warning("Rate limited (429). Retry after: \(retryAfter ?? 0)s", category: .network)

        var errorMessage = "Rate limit exceeded"
        if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
           let message = json["message"] as? String {
            errorMessage = message
        }

        throw NetworkServiceError.rateLimitExceeded(retryAfter: retryAfter, message: errorMessage)
    }

    // Check for success
    guard (200...299).contains(statusCode) else {
        var errorMessage: String?
        if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
           let message = json["message"] as? String ?? json["error"] as? String {
            errorMessage = message
        }

        Logger.error("Request failed: \(statusCode) - \(url.path)", category: .network)
        throw NetworkServiceError.httpError(statusCode: statusCode, message: errorMessage)
    }

    return nil
}

private func extractRetryAfter(from response: HTTPURLResponse) -> TimeInterval? {
    // Check Retry-After header
    if let retryAfterString = response.value(forHTTPHeaderField: "Retry-After") {
        // Try parsing as seconds
        if let seconds = TimeInterval(retryAfterString) {
            return seconds
        }

        // Try parsing as HTTP date
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "EEE, dd MMM yyyy HH:mm:ss z"
        if let date = dateFormatter.date(from: retryAfterString) {
            return date.timeIntervalSinceNow
        }
    }

    return nil
}

// Add to NetworkServiceError enum
enum NetworkServiceError: Error, LocalizedError {
    // ... existing cases ...
    case rateLimitExceeded(retryAfter: TimeInterval?, message: String?)

    var errorDescription: String? {
        switch self {
        // ... existing cases ...
        case .rateLimitExceeded(let retryAfter, let message):
            if let retryAfter = retryAfter {
                return "Rate limit exceeded. Retry after \(Int(retryAfter)) seconds. \(message ?? "")"
            }
            return "Rate limit exceeded. \(message ?? "")"
        }
    }
}
```

---

## Integration Plan

### Step 1: Add Retry Infrastructure (30 minutes)
1. Add `requestWithRetry` method
2. Add `shouldRetry` and `calculateBackoff` helpers
3. Update all public methods to use `requestWithRetry`

### Step 2: Add Token Refresh (20 minutes)
1. Add `requestWithTokenRefresh` wrapper
2. Add `refreshAuthToken` method
3. Wire up to EmailAPIService

### Step 3: Add Rate Limiting (15 minutes)
1. Update `validateResponse` to detect 429
2. Add `extractRetryAfter` helper
3. Update `NetworkServiceError` enum
4. Update `calculateBackoff` to use Retry-After

### Step 4: Testing (30 minutes)
1. Test retry logic with simulated failures
2. Test token refresh flow
3. Test rate limiting behavior
4. Validate with golden test set

**Total Time**: ~2 hours

---

## Expected Improvements

| Metric | Before | After |
|--------|--------|-------|
| Transient failure handling | ❌ None | ✅ 3 retries with backoff |
| Token expiry handling | ❌ Force re-login | ✅ Auto-refresh |
| Rate limit handling | ❌ Immediate failure | ✅ Respect Retry-After |
| Request timeout | ✅ 30s | ✅ 30s (unchanged) |
| Reliability | ~95% | ~99.5% |

---

## Next Steps

1. ✅ Document enhancements (this file)
2. ⏳ Implement retry logic
3. ⏳ Implement token refresh
4. ⏳ Implement rate limiting
5. ⏳ Test with golden test set
6. ⏳ Deploy and monitor

**Status**: Ready to implement
**Estimated completion**: 2 hours
