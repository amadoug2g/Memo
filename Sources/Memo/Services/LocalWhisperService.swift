import Foundation

// MARK: - Errors

enum LocalWhisperError: LocalizedError {
    case modelNotDownloaded
    case transcriptionFailed(String)
    case downloadFailed(String)
    case unsupportedPlatform

    var errorDescription: String? {
        switch self {
        case .modelNotDownloaded:
            return "Local Whisper model is not downloaded yet. Open Settings to download it."
        case .transcriptionFailed(let detail):
            return "Local transcription failed: \(detail)"
        case .downloadFailed(let detail):
            return "Failed to download the Whisper model: \(detail)"
        case .unsupportedPlatform:
            return "Local transcription requires macOS 14 or later with Apple Silicon."
        }
    }
}

// MARK: - Model state

enum LocalModelState: Equatable {
    case notDownloaded
    case downloading(progress: Double)
    case ready
    case failed(String)
}

// MARK: - Internal engine protocol (for testability)

/// Abstracts the actual WhisperKit calls so tests can inject a mock.
protocol WhisperEngineProtocol: AnyObject {
    func transcribe(audioURL: URL, language: String?) async throws -> String
    func loadModel(progressHandler: @escaping (Double) -> Void) async throws
    var isModelReady: Bool { get }
}

// MARK: - LocalWhisperService

/// Local on-device transcription service using WhisperKit.
/// Implements the same `Transcribing` protocol as `WhisperService` so it can be
/// injected transparently anywhere a `Transcribing` is expected.
///
/// - Note: The `apiKey` parameter is ignored — no network call is made.
final class LocalWhisperService: Transcribing {

    // MARK: State

    @MainActor private(set) var modelState: LocalModelState = .notDownloaded

    // MARK: Private

    private let engine: WhisperEngineProtocol

    // MARK: Init

    /// Production init — creates a real `WhisperKitEngine` when available.
    convenience init() {
        self.init(engine: WhisperKitEngine())
    }

    /// Testable init — accepts any `WhisperEngineProtocol` implementation.
    init(engine: WhisperEngineProtocol) {
        self.engine = engine
    }

    // MARK: - Transcribing

    func transcribe(audioURL: URL, apiKey: String, language: String?) async throws -> String {
        // Ensure model is loaded before transcribing.
        if !engine.isModelReady {
            try await loadModel()
        }
        return try await engine.transcribe(audioURL: audioURL, language: language)
    }

    // MARK: - Model management

    /// Downloads and loads the local model, publishing progress updates.
    func loadModel() async throws {
        await MainActor.run { modelState = .downloading(progress: 0) }

        do {
            try await engine.loadModel { [weak self] progress in
                guard let self else { return }
                Task { @MainActor [weak self] in
                    self?.modelState = .downloading(progress: progress)
                }
            }
            await MainActor.run { modelState = .ready }
        } catch {
            let msg = error.localizedDescription
            await MainActor.run { modelState = .failed(msg) }
            throw LocalWhisperError.downloadFailed(msg)
        }
    }

    /// True when the engine has a model ready for inference.
    var isModelReady: Bool { engine.isModelReady }
}

// MARK: - WhisperKitEngine (production implementation)

/// Wraps the actual WhisperKit library. Compiled out on platforms where WhisperKit
/// is unavailable (Linux, CI). A stub is used instead so the rest of the codebase
/// compiles cleanly on all platforms.
#if canImport(WhisperKit)
import WhisperKit

final class WhisperKitEngine: WhisperEngineProtocol {

    private var whisperKit: WhisperKit?
    private(set) var isModelReady: Bool = false

    func loadModel(progressHandler: @escaping (Double) -> Void) async throws {
        let config = WhisperKitConfig(
            model: "openai_whisper-base",
            downloadBase: nil,
            modelFolder: nil,
            tokenizerFolder: nil,
            verbose: false,
            logLevel: .none,
            prewarm: false,
            load: true,
            download: true,
            useBackgroundDownloadSession: false
        )
        progressHandler(0.1)
        let wk = try await WhisperKit(config)
        progressHandler(1.0)
        whisperKit = wk
        isModelReady = true
    }

    func transcribe(audioURL: URL, language: String?) async throws -> String {
        guard let wk = whisperKit else {
            throw LocalWhisperError.modelNotDownloaded
        }
        let options = DecodingOptions(
            verbose: false,
            language: language,
            temperature: 0,
            temperatureIncrementOnFallback: 0.2,
            temperatureFallbackCount: 5,
            usePrefillPrompt: true,
            usePrefillCache: true,
            skipSpecialTokens: true,
            withoutTimestamps: true,
            maxInitialTimestamp: 1.0
        )
        let results = try await wk.transcribe(audioPath: audioURL.path, decodeOptions: options)
        let text = results.map(\.text).joined(separator: " ")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        if text.isEmpty {
            throw LocalWhisperError.transcriptionFailed("Empty result returned by local model")
        }
        return text
    }
}

#else

// MARK: - Stub engine (used on Linux / CI where WhisperKit is unavailable)

/// No-op stub that always reports the model as not ready and throws on use.
/// This allows the entire codebase to compile on Linux for CI test runs.
final class WhisperKitEngine: WhisperEngineProtocol {

    private(set) var isModelReady: Bool = false

    func loadModel(progressHandler: @escaping (Double) -> Void) async throws {
        throw LocalWhisperError.unsupportedPlatform
    }

    func transcribe(audioURL: URL, language: String?) async throws -> String {
        throw LocalWhisperError.unsupportedPlatform
    }
}

#endif
