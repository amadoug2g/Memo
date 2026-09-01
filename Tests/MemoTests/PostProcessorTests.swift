import XCTest
@testable import Memo

// MARK: - Tests

final class PostProcessorTests: XCTestCase {

    func testProcessSuccessReturnsProcessedText() async throws {
        let mock = MockPostProcessor()
        mock.result = .success("Corrected text.")

        let output = try await mock.process(text: "helllo wrold", prompt: "Fix grammar", apiKey: "key", api: .openAI)

        XCTAssertEqual(output, "Corrected text.")
        XCTAssertEqual(mock.callCount, 1)
    }

    func testProcessForwardsInputs() async throws {
        let mock = MockPostProcessor()

        _ = try await mock.process(text: "bonjour", prompt: "Translate to English", apiKey: "sk-test", api: .openAI)

        XCTAssertEqual(mock.lastText, "bonjour")
        XCTAssertEqual(mock.lastPrompt, "Translate to English")
        XCTAssertEqual(mock.lastAPIKey, "sk-test")
    }

    func testProcessForwardsAPIParameter() async throws {
        let mock = MockPostProcessor()

        _ = try await mock.process(text: "hello", prompt: "Fix grammar", apiKey: "sk-test", api: .claude)

        XCTAssertEqual(mock.lastAPI, .claude)
    }

    func testProcessPropagatesError() async {
        let mock = MockPostProcessor()
        mock.result = .failure(PostProcessorError.missingAPIKey)

        do {
            _ = try await mock.process(text: "hello", prompt: "Fix grammar", apiKey: "", api: .openAI)
            XCTFail("Expected error to be thrown")
        } catch PostProcessorError.missingAPIKey {
            // expected
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    func testPostProcessingPromptLabelsAreUnique() {
        let labels = PostProcessingPrompt.allCases.map(\.label)
        XCTAssertEqual(labels.count, Set(labels).count)
    }

    func testPostProcessingPromptCustomHasEmptySystemPrompt() {
        XCTAssertEqual(PostProcessingPrompt.custom.systemPrompt, "")
    }

    func testPostProcessingAPILabelsAreUnique() {
        let labels = PostProcessingAPI.allCases.map(\.label)
        XCTAssertEqual(labels.count, Set(labels).count)
    }

    func testPostProcessorErrorDescriptions() {
        XCTAssertNotNil(PostProcessorError.missingAPIKey.errorDescription)
        XCTAssertNotNil(PostProcessorError.emptyResponse.errorDescription)
        XCTAssertNotNil(PostProcessorError.emptyPrompt.errorDescription)
        XCTAssertNotNil(PostProcessorError.httpError(401, "Unauthorized").errorDescription)
    }

    // MARK: - PostProcessor input validation (no network calls)

    func testProcessThrowsMissingAPIKeyWhenKeyIsEmpty() async {
        let sut = PostProcessor()
        do {
            _ = try await sut.process(text: "hello", prompt: "Fix grammar", apiKey: "", api: .openAI)
            XCTFail("Expected PostProcessorError.missingAPIKey")
        } catch PostProcessorError.missingAPIKey {
            // expected
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    func testProcessThrowsMissingAPIKeyWhenKeyIsWhitespace() async {
        let sut = PostProcessor()
        do {
            _ = try await sut.process(text: "hello", prompt: "Fix", apiKey: "   ", api: .claude)
            XCTFail("Expected PostProcessorError.missingAPIKey")
        } catch PostProcessorError.missingAPIKey {
            // expected
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    func testProcessThrowsEmptyPromptWhenPromptIsEmpty() async {
        let sut = PostProcessor()
        do {
            _ = try await sut.process(text: "hello", prompt: "", apiKey: "sk-valid", api: .openAI)
            XCTFail("Expected PostProcessorError.emptyPrompt")
        } catch PostProcessorError.emptyPrompt {
            // expected
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    func testProcessThrowsEmptyPromptWhenPromptIsWhitespace() async {
        let sut = PostProcessor()
        do {
            _ = try await sut.process(text: "hello", prompt: "   ", apiKey: "sk-valid", api: .openAI)
            XCTFail("Expected PostProcessorError.emptyPrompt")
        } catch PostProcessorError.emptyPrompt {
            // expected
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    // MARK: - Timeout error description

    func testTimeoutErrorHasDescription() {
        let err = PostProcessorError.timeout
        XCTAssertNotNil(err.errorDescription)
        XCTAssertTrue(err.errorDescription?.contains("timed out") ?? false)
    }

    // MARK: - Retry behavior (real PostProcessor with MockURLProtocol)

    func testOpenAIRetriesOnTimeout_thenSucceeds() async throws {
        MockURLProtocol.reset()
        let successBody = #"{"choices":[{"message":{"content":"Fixed text"}}]}"#
        MockURLProtocol.responses = [
            (error: URLError(.timedOut), data: nil, statusCode: nil),
            (error: nil, data: successBody.data(using: .utf8), statusCode: 200)
        ]
        let sut = PostProcessor(session: makeMockSession(), maxAttempts: 3, baseRetryDelay: 0.01)
        let result = try await sut.process(text: "helllo", prompt: "Fix grammar", apiKey: "sk-test", api: .openAI)
        XCTAssertEqual(result, "Fixed text")
        XCTAssertEqual(MockURLProtocol.requestCount, 2)
    }

    func testOpenAIThrowsTimeoutAfterExhaustedRetries() async {
        MockURLProtocol.reset()
        MockURLProtocol.responses = [
            (error: URLError(.timedOut), data: nil, statusCode: nil)
        ]
        let sut = PostProcessor(session: makeMockSession(), maxAttempts: 3, baseRetryDelay: 0.01)
        do {
            _ = try await sut.process(text: "hello", prompt: "Fix grammar", apiKey: "sk-test", api: .openAI)
            XCTFail("Expected PostProcessorError.timeout")
        } catch PostProcessorError.timeout {
            XCTAssertEqual(MockURLProtocol.requestCount, 3)
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    func testOpenAIDoesNotRetryOn4xx() async {
        MockURLProtocol.reset()
        MockURLProtocol.responses = [
            (error: nil, data: "Unauthorized".data(using: .utf8), statusCode: 401)
        ]
        let sut = PostProcessor(session: makeMockSession(), maxAttempts: 3, baseRetryDelay: 0.01)
        do {
            _ = try await sut.process(text: "hello", prompt: "Fix grammar", apiKey: "sk-test", api: .openAI)
            XCTFail("Expected PostProcessorError.httpError")
        } catch PostProcessorError.httpError(let code, _) {
            XCTAssertEqual(code, 401)
            XCTAssertEqual(MockURLProtocol.requestCount, 1)
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    func testClaudeRetriesOnServerError_thenSucceeds() async throws {
        MockURLProtocol.reset()
        let successBody = #"{"content":[{"type":"text","text":"Corrected"}]}"#
        MockURLProtocol.responses = [
            (error: nil, data: "overloaded".data(using: .utf8), statusCode: 503),
            (error: nil, data: successBody.data(using: .utf8), statusCode: 200)
        ]
        let sut = PostProcessor(session: makeMockSession(), maxAttempts: 3, baseRetryDelay: 0.01)
        let result = try await sut.process(text: "helllo", prompt: "Fix grammar", apiKey: "sk-test", api: .claude)
        XCTAssertEqual(result, "Corrected")
        XCTAssertEqual(MockURLProtocol.requestCount, 2)
    }

    // MARK: - PostProcessingPrompt system prompts

    func testPresetPromptsAllHaveNonEmptySystemPrompt() {
        for preset in PostProcessingPrompt.allCases where preset != .custom {
            XCTAssertFalse(
                preset.systemPrompt.isEmpty,
                "systemPrompt is empty for preset: \(preset.rawValue)"
            )
        }
    }
}
