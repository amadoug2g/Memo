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
