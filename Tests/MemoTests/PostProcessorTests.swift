import XCTest
@testable import Memo

// MARK: - Mock

final class MockPostProcessor: PostProcessing {
    var result: Result<String, Error> = .success("Processed text")
    private(set) var callCount = 0
    private(set) var lastText: String?
    private(set) var lastPrompt: String?
    private(set) var lastAPIKey: String?

    func process(text: String, prompt: String, apiKey: String) async throws -> String {
        callCount += 1
        lastText = text
        lastPrompt = prompt
        lastAPIKey = apiKey
        return try result.get()
    }
}

// MARK: - Tests

final class PostProcessorTests: XCTestCase {

    func testProcessSuccessReturnsProcessedText() async throws {
        let mock = MockPostProcessor()
        mock.result = .success("Corrected text.")

        let output = try await mock.process(text: "helllo wrold", prompt: "Fix grammar", apiKey: "key")

        XCTAssertEqual(output, "Corrected text.")
        XCTAssertEqual(mock.callCount, 1)
    }

    func testProcessForwardsInputs() async throws {
        let mock = MockPostProcessor()

        _ = try await mock.process(text: "bonjour", prompt: "Translate to English", apiKey: "sk-test")

        XCTAssertEqual(mock.lastText, "bonjour")
        XCTAssertEqual(mock.lastPrompt, "Translate to English")
        XCTAssertEqual(mock.lastAPIKey, "sk-test")
    }

    func testProcessPropagatesError() async {
        let mock = MockPostProcessor()
        mock.result = .failure(PostProcessorError.missingAPIKey)

        do {
            _ = try await mock.process(text: "hello", prompt: "Fix grammar", apiKey: "")
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
}
