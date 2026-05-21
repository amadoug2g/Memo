import XCTest
@testable import Memo

// MARK: - Mock engine

final class MockWhisperEngine: WhisperEngineProtocol {
    var transcribeResult: Result<String, Error> = .success("Hello from local model")
    var loadModelError: Error?
    private(set) var transcribeCallCount = 0
    private(set) var loadModelCallCount = 0
    private(set) var lastLanguageCalled = false
    private(set) var lastLanguageValue: String?
    private(set) var lastAudioURL: URL?

    var isModelReady: Bool = false

    func loadModel(progressHandler: @escaping (Double) -> Void) async throws {
        loadModelCallCount += 1
        if let error = loadModelError {
            throw error
        }
        progressHandler(0.5)
        progressHandler(1.0)
        isModelReady = true
    }

    func transcribe(audioURL: URL, language: String?) async throws -> String {
        transcribeCallCount += 1
        lastAudioURL = audioURL
        lastLanguageCalled = true
        lastLanguageValue = language
        return try transcribeResult.get()
    }
}

// MARK: - Tests

final class LocalWhisperServiceTests: XCTestCase {

    // MARK: - Protocol conformance

    func test_conformsToTranscribing() {
        let engine = MockWhisperEngine()
        engine.isModelReady = true
        let service = LocalWhisperService(engine: engine)
        let _: any Transcribing = service   // compile-time check
        XCTAssertTrue(service.isModelReady)
    }

    // MARK: - Transcribe when model is ready

    func test_transcribe_returnsText_whenModelReady() async throws {
        let engine = MockWhisperEngine()
        engine.isModelReady = true
        engine.transcribeResult = .success("Transcribed text")
        let service = LocalWhisperService(engine: engine)

        let result = try await service.transcribe(
            audioURL: URL(fileURLWithPath: "/tmp/audio.m4a"),
            apiKey: "",       // ignored for local
            language: "en"
        )

        XCTAssertEqual(result, "Transcribed text")
        XCTAssertEqual(engine.transcribeCallCount, 1)
    }

    // MARK: - Auto-load model when not ready

    func test_transcribe_autoLoadsModel_whenNotReady() async throws {
        let engine = MockWhisperEngine()
        engine.isModelReady = false
        engine.transcribeResult = .success("Auto-loaded result")
        let service = LocalWhisperService(engine: engine)

        _ = try await service.transcribe(
            audioURL: URL(fileURLWithPath: "/tmp/audio.m4a"),
            apiKey: "",
            language: nil
        )

        XCTAssertEqual(engine.loadModelCallCount, 1, "loadModel should be called when model is not ready")
        XCTAssertEqual(engine.transcribeCallCount, 1)
    }

    // MARK: - Language forwarding

    func test_transcribe_forwardsLanguage() async throws {
        let engine = MockWhisperEngine()
        engine.isModelReady = true
        let service = LocalWhisperService(engine: engine)

        _ = try await service.transcribe(
            audioURL: URL(fileURLWithPath: "/tmp/audio.m4a"),
            apiKey: "",
            language: "fr"
        )

        XCTAssertTrue(engine.lastLanguageCalled)
        XCTAssertEqual(engine.lastLanguageValue, "fr")
    }

    func test_transcribe_forwardsNilLanguage() async throws {
        let engine = MockWhisperEngine()
        engine.isModelReady = true
        let service = LocalWhisperService(engine: engine)

        _ = try await service.transcribe(
            audioURL: URL(fileURLWithPath: "/tmp/audio.m4a"),
            apiKey: "",
            language: nil
        )

        XCTAssertTrue(engine.lastLanguageCalled)
        XCTAssertNil(engine.lastLanguageValue)
    }

    // MARK: - Error propagation

    func test_transcribe_propagatesEngineError() async {
        let engine = MockWhisperEngine()
        engine.isModelReady = true
        engine.transcribeResult = .failure(LocalWhisperError.transcriptionFailed("something went wrong"))
        let service = LocalWhisperService(engine: engine)

        do {
            _ = try await service.transcribe(
                audioURL: URL(fileURLWithPath: "/tmp/audio.m4a"),
                apiKey: "",
                language: nil
            )
            XCTFail("Expected error to be thrown")
        } catch LocalWhisperError.transcriptionFailed(let detail) {
            XCTAssertEqual(detail, "something went wrong")
        } catch {
            XCTFail("Unexpected error type: \(error)")
        }
    }

    // MARK: - loadModel state transitions

    @MainActor
    func test_loadModel_setsStateToReady_onSuccess() async throws {
        let engine = MockWhisperEngine()
        let service = LocalWhisperService(engine: engine)

        XCTAssertEqual(service.modelState, .notDownloaded)

        try await service.loadModel()

        XCTAssertEqual(service.modelState, .ready)
    }

    @MainActor
    func test_loadModel_setsStateToFailed_onError() async {
        let engine = MockWhisperEngine()
        engine.loadModelError = LocalWhisperError.downloadFailed("network error")
        let service = LocalWhisperService(engine: engine)

        do {
            try await service.loadModel()
            XCTFail("Expected error to be thrown")
        } catch LocalWhisperError.downloadFailed(let detail) {
            XCTAssertTrue(detail.contains("network error"))
        } catch {
            XCTFail("Unexpected error: \(error)")
        }

        if case .failed = service.modelState {
            // expected
        } else {
            XCTFail("Expected modelState to be .failed, got \(service.modelState)")
        }
    }

    // MARK: - isModelReady convenience

    func test_isModelReady_mirrosEngineState() {
        let engine = MockWhisperEngine()
        engine.isModelReady = false
        let service = LocalWhisperService(engine: engine)
        XCTAssertFalse(service.isModelReady)

        engine.isModelReady = true
        XCTAssertTrue(service.isModelReady)
    }

    // MARK: - Error descriptions

    func test_errorDescriptions_areNonEmpty() {
        XCTAssertNotNil(LocalWhisperError.modelNotDownloaded.errorDescription)
        XCTAssertNotNil(LocalWhisperError.transcriptionFailed("x").errorDescription)
        XCTAssertNotNil(LocalWhisperError.downloadFailed("y").errorDescription)
        XCTAssertNotNil(LocalWhisperError.unsupportedPlatform.errorDescription)
    }

    func test_unsupportedPlatformError_mentionsMacOS() {
        let msg = LocalWhisperError.unsupportedPlatform.errorDescription ?? ""
        XCTAssertTrue(msg.contains("macOS"), "Should mention macOS requirement")
    }

    func test_modelNotDownloaded_mentionsSettings() {
        let msg = LocalWhisperError.modelNotDownloaded.errorDescription ?? ""
        XCTAssertTrue(msg.contains("Settings"), "Should direct user to Settings")
    }

    // MARK: - LocalModelState equatable

    func test_localModelState_equatable() {
        XCTAssertEqual(LocalModelState.notDownloaded, .notDownloaded)
        XCTAssertEqual(LocalModelState.ready, .ready)
        XCTAssertEqual(LocalModelState.downloading(progress: 0.5), .downloading(progress: 0.5))
        XCTAssertNotEqual(LocalModelState.downloading(progress: 0.1), .downloading(progress: 0.9))
        XCTAssertEqual(LocalModelState.failed("err"), .failed("err"))
        XCTAssertNotEqual(LocalModelState.notDownloaded, .ready)
    }
}
