import AppKit
import XCTest
@testable import Memo

@MainActor
final class AppStateTests: XCTestCase {

    // MARK: - Initial state

    func test_initialState_isIdle() {
        let state = AppState()
        XCTAssertEqual(state.recordingState, .idle)
        XCTAssertFalse(state.isRecording)
        XCTAssertFalse(state.isTranscribing)
        XCTAssertFalse(state.isEditing)
    }

    // MARK: - No-op guards

    func test_stopRecording_whenIdle_isNoop() {
        let state = AppState()
        state.stopRecording()
        XCTAssertEqual(state.recordingState, .idle)
    }

    func test_startRecording_whenNotIdle_isNoop() async {
        let recorder = MockAudioRecorder()
        let state = AppState(audioRecorder: recorder, transcriber: MockTranscriber())
        state.recordingState = .transcribing
        state.startRecording()
        await Task.yield()
        XCTAssertEqual(state.recordingState, .transcribing, "startRecording while not idle must be a no-op")
        XCTAssertEqual(recorder.startCallCount, 0)
    }

    // MARK: - Reset

    func test_reset_clearsTranscriptionAndState() {
        let state = AppState()
        state.transcribedText = "hello"
        state.recordingState = .editing
        state.reset()
        XCTAssertEqual(state.recordingState, .idle)
        XCTAssertEqual(state.transcribedText, "")
        XCTAssertEqual(state.audioLevel, 0)
    }

    func test_reset_fromErrorState_returnsToIdle() {
        let state = AppState()
        state.recordingState = .error("something went wrong")
        state.reset()
        XCTAssertEqual(state.recordingState, .idle)
    }

    // MARK: - Paste

    func test_confirmAndPaste_callsOrchestratorWithText_thenResets() {
        let state = AppState()
        let orchestrator = MockPasteOrchestrator()
        state.pasteOrchestrator = orchestrator
        state.transcribedText = "hello world"
        state.recordingState = .editing
        state.confirmAndPaste()
        XCTAssertEqual(orchestrator.received, "hello world")
        XCTAssertEqual(state.recordingState, .idle)
        XCTAssertEqual(state.transcribedText, "")
    }

    func test_confirmAndPaste_withNoOrchestrator_stillResets() {
        let state = AppState()
        state.transcribedText = "text"
        state.recordingState = .editing
        state.confirmAndPaste()
        XCTAssertEqual(state.recordingState, .idle)
    }

    // MARK: - Recording lifecycle (with mocks)

    func test_startRecording_granted_transitionsToRecording() async {
        let recorder = MockAudioRecorder()
        let state = AppState(audioRecorder: recorder, transcriber: MockTranscriber())
        state.openAIApiKey = "sk-test"
        state.startRecording()
        await waitForState(.recording, on: state)
        XCTAssertEqual(recorder.startCallCount, 1)
    }

    func test_startRecording_denied_transitionsToError() async {
        let recorder = MockAudioRecorder()
        recorder.permissionGranted = false
        let state = AppState(audioRecorder: recorder, transcriber: MockTranscriber())
        state.startRecording()
        await waitForState(.error(""), on: state, matchPrefix: true)
        if case .error(let msg) = state.recordingState {
            XCTAssertTrue(msg.contains("Microphone"), "Error should mention microphone, got: \(msg)")
        }
    }

    func test_minDurationCancel_returnsToIdle() async {
        let recorder = MockAudioRecorder()
        let state = AppState(audioRecorder: recorder, transcriber: MockTranscriber())
        state.recordingMode = .pushToTalk
        state.openAIApiKey = "sk-test"

        state.startRecording()
        await waitForState(.recording, on: state)

        // recordingStartedAt is just set — well within 500ms — so stopRecording should cancel
        state.stopRecording()
        await waitForState(.idle, on: state)
        XCTAssertEqual(recorder.cancelCallCount, 1)
        XCTAssertEqual(recorder.stopCallCount, 0)
    }

    func test_fullCoreLoop_recordingToClipboard() async {
        let recorder = MockAudioRecorder()
        let transcriber = MockTranscriber()
        transcriber.result = .success("Transcribed text")
        let state = AppState(audioRecorder: recorder, transcriber: transcriber)
        state.openAIApiKey = "sk-test"

        state.startRecording()
        await waitForState(.recording, on: state)

        // Back-date start so min-duration check passes
        state.recordingStartedAt = Date().addingTimeInterval(-1)
        state.stopRecording()

        await waitForState(.idle, on: state)
        XCTAssertEqual(transcriber.callCount, 1)
        let clipboard = NSPasteboard.general.string(forType: .string)
        XCTAssertEqual(clipboard, "Transcribed text")
    }

    func test_transcription_alwaysCopiesTextToClipboard() async {
        let recorder = MockAudioRecorder()
        let transcriber = MockTranscriber()
        transcriber.result = .success("clipboard test")
        let state = AppState(audioRecorder: recorder, transcriber: transcriber)
        state.openAIApiKey = "sk-test"
        state.autoPasteEnabled = false

        state.startRecording()
        await waitForState(.recording, on: state)
        state.recordingStartedAt = Date().addingTimeInterval(-1)
        state.stopRecording()

        await waitForState(.idle, on: state)

        let clipboard = NSPasteboard.general.string(forType: .string)
        XCTAssertEqual(clipboard, "clipboard test", "Transcribed text must always be copied to clipboard")
    }

    func test_transcription_clipboardSetEvenWithAutoPaste() async {
        let recorder = MockAudioRecorder()
        let transcriber = MockTranscriber()
        transcriber.result = .success("auto paste text")
        let state = AppState(audioRecorder: recorder, transcriber: transcriber)
        state.openAIApiKey = "sk-test"
        state.autoPasteEnabled = true
        state.pasteOrchestrator = MockPasteOrchestrator()

        state.startRecording()
        await waitForState(.recording, on: state)
        state.recordingStartedAt = Date().addingTimeInterval(-1)
        state.stopRecording()

        await waitForState(.idle, on: state)

        let clipboard = NSPasteboard.general.string(forType: .string)
        XCTAssertEqual(clipboard, "auto paste text", "Clipboard must contain transcribed text even when auto-paste triggers")
    }

    func test_transcriptionFailure_setsErrorState() async {
        let recorder = MockAudioRecorder()
        let transcriber = MockTranscriber()
        transcriber.result = .failure(WhisperError.missingAPIKey)
        let state = AppState(audioRecorder: recorder, transcriber: transcriber)
        state.openAIApiKey = "sk-test"

        state.startRecording()
        await waitForState(.recording, on: state)
        state.recordingStartedAt = Date().addingTimeInterval(-1)
        state.stopRecording()

        await waitForState(.error(""), on: state, matchPrefix: true)
        if case .error(let msg) = state.recordingState {
            XCTAssertFalse(msg.isEmpty)
        } else {
            XCTFail("Expected error state")
        }
    }

    func test_preWarm_calledBeforeRecording() async {
        let recorder = MockAudioRecorder()
        let state = AppState(audioRecorder: recorder, transcriber: MockTranscriber())
        state.openAIApiKey = "sk-test"
        state.startRecording()
        await waitForState(.recording, on: state)
        XCTAssertGreaterThanOrEqual(recorder.prepareCallCount, 1)
    }

    // MARK: - Preferences round-trip

    func test_saveAndLoadPreferences_roundtrip() async throws {
        let langKey  = "selectedLanguage"
        let modeKey  = "recordingMode"
        defer {
            UserDefaults.standard.removeObject(forKey: langKey)
            UserDefaults.standard.removeObject(forKey: modeKey)
        }

        let state = AppState()
        state.openAIApiKey = "sk-test-123"
        state.selectedLanguage = "fr"
        state.recordingMode = .toggle
        state.savePreferences()

        let loaded = AppState()
        // API key is loaded from Keychain in a deferred Task — yield to let it run.
        await Task.yield()
        XCTAssertEqual(loaded.openAIApiKey, "sk-test-123")
        XCTAssertEqual(loaded.selectedLanguage, "fr")
        XCTAssertEqual(loaded.recordingMode, .toggle)
    }

    // MARK: - Helper

    /// Polls `appState.recordingState` until it matches, yielding the main actor on
    /// each iteration so pending `Task { @MainActor }` work can run.
    /// Using `fulfillment(of:timeout:)` is unreliable on macOS Tahoe — it can block
    /// the main thread via RunLoop, preventing Swift concurrency tasks from executing.
    private func waitForState(
        _ expected: RecordingState,
        on appState: AppState,
        matchPrefix: Bool = false,
        timeout: TimeInterval = 2
    ) async {
        func matches(_ s: RecordingState) -> Bool {
            if matchPrefix {
                switch (s, expected) {
                case (.error, .error): return true
                default: return s == expected
                }
            }
            return s == expected
        }
        let deadline = Date().addingTimeInterval(timeout)
        while !matches(appState.recordingState) {
            guard Date() < deadline else {
                XCTFail("Timed out waiting for state: \(expected). Current: \(appState.recordingState)")
                return
            }
            try? await Task.sleep(nanoseconds: 10_000_000) // 10ms — yields to pending tasks
        }
    }
}

// MARK: - Mock helpers

@MainActor
final class MockPasteOrchestrator: PasteOrchestrating {
    private(set) var received: String?
    func orchestratePaste(_ text: String) { received = text }
}

// MARK: - RecordingState tests

final class RecordingStateTests: XCTestCase {

    func test_equatable() {
        XCTAssertEqual(RecordingState.idle, .idle)
        XCTAssertEqual(RecordingState.error("a"), .error("a"))
        XCTAssertNotEqual(RecordingState.error("a"), .error("b"))
        XCTAssertNotEqual(RecordingState.idle, .recording)
    }
}
