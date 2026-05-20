import Foundation
@testable import Memo

// MARK: - MockAudioRecorder

final class MockAudioRecorder: AudioRecording {
    var onLevelUpdate: ((Float) -> Void)?

    // Configuration
    var permissionGranted = true
    var startError: Error?
    var stopResult: Result<URL, Error> = .success(URL(fileURLWithPath: "/dev/null"))

    // Spies
    private(set) var prepareCallCount = 0
    private(set) var startCallCount = 0
    private(set) var stopCallCount = 0
    private(set) var cancelCallCount = 0

    func requestPermission(completion: @escaping (Bool) -> Void) {
        completion(permissionGranted)
    }

    func prepareToRecord() {
        prepareCallCount += 1
    }

    func startRecording() throws {
        startCallCount += 1
        if let err = startError { throw err }
    }

    func stopRecording() async throws -> URL {
        stopCallCount += 1
        return try stopResult.get()
    }

    func cancelRecording() {
        cancelCallCount += 1
    }
}

// MARK: - MockTranscriber

final class MockTranscriber: Transcribing {
    var result: Result<String, Error> = .success("Hello world")
    private(set) var callCount = 0

    func transcribe(audioURL: URL, apiKey: String, language: String?) async throws -> String {
        callCount += 1
        return try result.get()
    }
}

// MARK: - MockPostProcessor

final class MockPostProcessor: PostProcessing {
    var result: Result<String, Error> = .success("Processed text")
    private(set) var callCount = 0
    private(set) var lastText: String?
    private(set) var lastPrompt: String?
    private(set) var lastAPIKey: String?
    private(set) var lastAPI: PostProcessingAPI?

    func process(text: String, prompt: String, apiKey: String, api: PostProcessingAPI) async throws -> String {
        callCount += 1
        lastText = text
        lastPrompt = prompt
        lastAPIKey = apiKey
        lastAPI = api
        return try result.get()
    }
}
