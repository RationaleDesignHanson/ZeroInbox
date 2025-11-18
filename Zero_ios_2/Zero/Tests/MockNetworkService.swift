import Foundation

/// Mock NetworkService for testing
/// Allows tests to control network responses without making actual HTTP requests
class MockNetworkService {

    // MARK: - Mock Configuration

    /// Mock response to return
    var mockResponse: MockResponse?

    /// Mock error to throw
    var mockError: Error?

    /// Track all requests made
    var capturedRequests: [(url: URL, method: HTTPMethod, body: Data?, headers: [String: String]?)] = []

    /// Should throw error instead of returning response
    var shouldThrowError: Bool = false

    /// Delay before returning response (simulates network latency)
    var responseDelay: TimeInterval = 0

    // MARK: - Mock Response Configuration

    struct MockResponse {
        let data: Data
        let statusCode: Int
        let headers: [String: String]?

        init(data: Data, statusCode: Int = 200, headers: [String: String]? = nil) {
            self.data = data
            self.statusCode = statusCode
            self.headers = headers
        }

        init(json: [String: Any], statusCode: Int = 200, headers: [String: String]? = nil) {
            self.data = (try? JSONSerialization.data(withJSONObject: json)) ?? Data()
            self.statusCode = statusCode
            self.headers = headers
        }

        init(string: String, statusCode: Int = 200, headers: [String: String]? = nil) {
            self.data = string.data(using: .utf8) ?? Data()
            self.statusCode = statusCode
            self.headers = headers
        }
    }

    // MARK: - Initialization

    init() {}

    /// Reset mock state
    func reset() {
        mockResponse = nil
        mockError = nil
        capturedRequests = []
        shouldThrowError = false
        responseDelay = 0
    }

    // MARK: - Mock Request Methods

    /// Mock async request
    func request<T: Decodable>(
        url: URL,
        method: HTTPMethod,
        body: Data? = nil,
        headers: [String: String]? = nil
    ) async throws -> T {
        // Capture request
        capturedRequests.append((url, method, body, headers))

        // Simulate delay
        if responseDelay > 0 {
            try await Task.sleep(nanoseconds: UInt64(responseDelay * 1_000_000_000))
        }

        // Throw error if configured
        if shouldThrowError, let error = mockError {
            throw error
        }

        // Return mock response
        guard let response = mockResponse else {
            throw MockNetworkError.noMockResponseConfigured
        }

        // Check status code
        guard (200...299).contains(response.statusCode) else {
            throw MockNetworkError.httpError(response.statusCode)
        }

        // Decode response
        do {
            let decoder = JSONDecoder()
            return try decoder.decode(T.self, from: response.data)
        } catch {
            throw MockNetworkError.decodingFailed(error)
        }
    }

    /// Mock request with Void response
    func request(
        url: URL,
        method: HTTPMethod,
        body: Data? = nil,
        headers: [String: String]? = nil
    ) async throws {
        // Capture request
        capturedRequests.append((url, method, body, headers))

        // Simulate delay
        if responseDelay > 0 {
            try await Task.sleep(nanoseconds: UInt64(responseDelay * 1_000_000_000))
        }

        // Throw error if configured
        if shouldThrowError, let error = mockError {
            throw error
        }

        // Check status code if response configured
        if let response = mockResponse {
            guard (200...399).contains(response.statusCode) else {
                throw MockNetworkError.httpError(response.statusCode)
            }
        }
    }

    /// Mock data request (returns raw data)
    func dataRequest(
        url: URL,
        method: HTTPMethod,
        body: Data? = nil,
        headers: [String: String]? = nil
    ) async throws -> Data {
        // Capture request
        capturedRequests.append((url, method, body, headers))

        // Simulate delay
        if responseDelay > 0 {
            try await Task.sleep(nanoseconds: UInt64(responseDelay * 1_000_000_000))
        }

        // Throw error if configured
        if shouldThrowError, let error = mockError {
            throw error
        }

        // Return mock response data
        guard let response = mockResponse else {
            throw MockNetworkError.noMockResponseConfigured
        }

        guard (200...299).contains(response.statusCode) else {
            throw MockNetworkError.httpError(response.statusCode)
        }

        return response.data
    }

    // MARK: - Convenience Configuration Methods

    /// Configure a successful JSON response
    func mockSuccess<T: Encodable>(_ value: T, statusCode: Int = 200) {
        let encoder = JSONEncoder()
        if let data = try? encoder.encode(value) {
            mockResponse = MockResponse(data: data, statusCode: statusCode)
        }
        shouldThrowError = false
    }

    /// Configure a successful response with dictionary
    func mockSuccess(json: [String: Any], statusCode: Int = 200) {
        mockResponse = MockResponse(json: json, statusCode: statusCode)
        shouldThrowError = false
    }

    /// Configure an error response
    func mockFailure(error: Error) {
        mockError = error
        shouldThrowError = true
    }

    /// Configure an HTTP error with status code
    func mockHTTPError(statusCode: Int) {
        mockResponse = MockResponse(data: Data(), statusCode: statusCode)
        shouldThrowError = false
    }

    /// Get the last captured request
    var lastRequest: (url: URL, method: HTTPMethod, body: Data?, headers: [String: String]?)? {
        return capturedRequests.last
    }

    /// Get count of captured requests
    var requestCount: Int {
        return capturedRequests.count
    }
}

// MARK: - Mock Errors

enum MockNetworkError: Error, LocalizedError {
    case noMockResponseConfigured
    case httpError(Int)
    case decodingFailed(Error)

    var errorDescription: String? {
        switch self {
        case .noMockResponseConfigured:
            return "No mock response was configured"
        case .httpError(let code):
            return "HTTP error with status code: \(code)"
        case .decodingFailed(let error):
            return "Decoding failed: \(error.localizedDescription)"
        }
    }
}

// MARK: - HTTP Method

enum HTTPMethod: String {
    case get = "GET"
    case post = "POST"
    case put = "PUT"
    case delete = "DELETE"
    case patch = "PATCH"
}
