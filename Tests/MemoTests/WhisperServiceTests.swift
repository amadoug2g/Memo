import XCTest
@testable import Memo

final class WhisperServiceTests: XCTestCase {
    private let service = WhisperService()

    // MARK: - API Key validation

    func test_transcribe_throwsMissingKey_whenEmpty() async {
        await assertThrowsMissingAPIKey(apiKey: "")
    }

    func test_transcribe_throwsMissingKey_whenWhitespaceOnly() async {
        await assertThrowsMissingAPIKey(apiKey: "   ")
    }

    // MARK: - Error descriptions

    func test_missingAPIKey_descriptionMentionsSettings() {
        let err = WhisperError.missingAPIKey
        XCTAssertTrue(err.errorDescription?.contains("Settings") ?? false)
    }

    func test_emptyResponse_hasDescription() {
        XCTAssertNotNil(WhisperError.emptyResponse.errorDescription)
    }

    func test_httpError_parsesOpenAIErrorJSON() {
        let body = #"{"error":{"message":"Invalid API key","type":"invalid_request_error"}}"#
        let err = WhisperError.httpError(401, body)
        XCTAssertTrue(err.errorDescription?.contains("Invalid API key") ?? false)
    }

    func test_httpError_fallsBackToRawBody_whenNotJSON() {
        let err = WhisperError.httpError(500, "Internal Server Error")
        XCTAssertTrue(err.errorDescription?.contains("500") ?? false)
        XCTAssertTrue(err.errorDescription?.contains("Internal Server Error") ?? false)
    }

    func test_httpError_fallsBackToRawBody_whenJSONMalformed() {
        let err = WhisperError.httpError(400, "{not valid json}")
        XCTAssertTrue(err.errorDescription?.contains("400") ?? false)
    }

    // MARK: - Timeout error description

    func test_timeout_hasUserFriendlyDescription() {
        let err = WhisperError.timeout
        XCTAssertNotNil(err.errorDescription)
        XCTAssertTrue(err.errorDescription?.contains("timed out") ?? false)
    }

    // MARK: - Retry behavior

    func test_transcribe_retriesOnTimeout_thenSucceeds() async throws {
        MockURLProtocol.reset()
        MockURLProtocol.responses = [
            (error: URLError(.timedOut), data: nil, statusCode: nil),
            (error: nil, data: "Hello world".data(using: .utf8), statusCode: 200)
        ]
        let service = WhisperService(session: makeMockSession(), maxAttempts: 3, baseRetryDelay: 0.01)
        let result = try await service.transcribe(audioURL: testAudioURL(), apiKey: "sk-test", language: nil)
        XCTAssertEqual(result, "Hello world")
        XCTAssertEqual(MockURLProtocol.requestCount, 2)
    }

    func test_transcribe_retriesOnServerError_thenSucceeds() async throws {
        MockURLProtocol.reset()
        MockURLProtocol.responses = [
            (error: nil, data: "overloaded".data(using: .utf8), statusCode: 503),
            (error: nil, data: "Bonjour".data(using: .utf8), statusCode: 200)
        ]
        let service = WhisperService(session: makeMockSession(), maxAttempts: 3, baseRetryDelay: 0.01)
        let result = try await service.transcribe(audioURL: testAudioURL(), apiKey: "sk-test", language: nil)
        XCTAssertEqual(result, "Bonjour")
        XCTAssertEqual(MockURLProtocol.requestCount, 2)
    }

    func test_transcribe_throwsTimeout_afterAllRetriesExhausted() async {
        MockURLProtocol.reset()
        MockURLProtocol.responses = [
            (error: URLError(.timedOut), data: nil, statusCode: nil)
        ]
        let service = WhisperService(session: makeMockSession(), maxAttempts: 3, baseRetryDelay: 0.01)
        do {
            _ = try await service.transcribe(audioURL: testAudioURL(), apiKey: "sk-test", language: nil)
            XCTFail("Expected WhisperError.timeout")
        } catch WhisperError.timeout {
            XCTAssertEqual(MockURLProtocol.requestCount, 3)
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    func test_transcribe_doesNotRetryOn4xx() async {
        MockURLProtocol.reset()
        MockURLProtocol.responses = [
            (error: nil, data: "Unauthorized".data(using: .utf8), statusCode: 401)
        ]
        let service = WhisperService(session: makeMockSession(), maxAttempts: 3, baseRetryDelay: 0.01)
        do {
            _ = try await service.transcribe(audioURL: testAudioURL(), apiKey: "sk-test", language: nil)
            XCTFail("Expected WhisperError.httpError")
        } catch WhisperError.httpError(let code, _) {
            XCTAssertEqual(code, 401)
            XCTAssertEqual(MockURLProtocol.requestCount, 1)
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    func test_transcribe_doesNotRetryOnEmptyResponse() async {
        MockURLProtocol.reset()
        MockURLProtocol.responses = [
            (error: nil, data: "".data(using: .utf8), statusCode: 200)
        ]
        let service = WhisperService(session: makeMockSession(), maxAttempts: 3, baseRetryDelay: 0.01)
        do {
            _ = try await service.transcribe(audioURL: testAudioURL(), apiKey: "sk-test", language: nil)
            XCTFail("Expected WhisperError.emptyResponse")
        } catch WhisperError.emptyResponse {
            XCTAssertEqual(MockURLProtocol.requestCount, 1)
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    func test_transcribe_retriesOnNetworkConnectionLost() async throws {
        MockURLProtocol.reset()
        MockURLProtocol.responses = [
            (error: URLError(.networkConnectionLost), data: nil, statusCode: nil),
            (error: nil, data: "Recovered".data(using: .utf8), statusCode: 200)
        ]
        let service = WhisperService(session: makeMockSession(), maxAttempts: 3, baseRetryDelay: 0.01)
        let result = try await service.transcribe(audioURL: testAudioURL(), apiKey: "sk-test", language: nil)
        XCTAssertEqual(result, "Recovered")
        XCTAssertEqual(MockURLProtocol.requestCount, 2)
    }

    // MARK: - Helpers

    private func testAudioURL() -> URL {
        let url = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent("test.m4a")
        if !FileManager.default.fileExists(atPath: url.path) {
            FileManager.default.createFile(atPath: url.path, contents: Data([0x00, 0x01, 0x02]))
        }
        return url
    }

    private func assertThrowsMissingAPIKey(apiKey: String, file: StaticString = #file, line: UInt = #line) async {
        do {
            _ = try await service.transcribe(
                audioURL: URL(fileURLWithPath: "/dev/null"),
                apiKey: apiKey,
                language: nil
            )
            XCTFail("Expected WhisperError.missingAPIKey", file: file, line: line)
        } catch WhisperError.missingAPIKey {
            // expected
        } catch {
            XCTFail("Unexpected error: \(error)", file: file, line: line)
        }
    }
}
