import AppKit
import Foundation
import Combine

// MARK: - Protocols

/// Implemented by the coordinator that owns `PasteService` and the previous-app reference.
/// Breaks the circular dependency between `AppState` and `AppDelegate`.
@MainActor
protocol PasteOrchestrating: AnyObject {
    func orchestratePaste(_ text: String)
}

// MARK: - State types

enum RecordingState: Equatable {
    case idle
    case recording
    case transcribing
    case editing
    case error(String)
}

enum RecordingMode: String, CaseIterable {
    case pushToTalk = "pushToTalk"
    case toggle     = "toggle"

    var label: String {
        switch self {
        case .pushToTalk: return "Hold to Record"
        case .toggle:     return "Tap to Toggle"
        }
    }

    var hint: String {
        switch self {
        case .pushToTalk: return "Hold ⌥ Space while speaking. Release to transcribe."
        case .toggle:     return "Tap ⌥ Space to start. Tap again to stop and transcribe."
        }
    }
}

// MARK: - AppState

@MainActor
class AppState: ObservableObject {
    // Recording / transcription
    @Published var recordingState: RecordingState = .idle
    @Published var transcribedText: String = ""
    @Published var audioLevel: Float = 0.0

    // Preferences
    @Published var recordingMode: RecordingMode = .pushToTalk
    @Published var autoPasteEnabled: Bool = false
    @Published var selectedLanguage: String = "auto"
    @Published var openAIApiKey: String = ""
    @Published var hotkeyKeyCode: Int = 49      // Space
    @Published var hotkeyModifiers: Int = 2048  // Carbon optionKey

    // Post-processing preferences
    @Published var postProcessingEnabled: Bool = false
    @Published var postProcessingAPI: PostProcessingAPI = .openAI
    @Published var postProcessingPrompt: PostProcessingPrompt = .cleanGrammar
    @Published var postProcessingCustomPrompt: String = ""
    @Published var postProcessingAPIKey: String = ""

    // App status
    @Published var hotkeyConflict: Bool = false

    // Convenience
    var isRecording: Bool    { recordingState == .recording }
    var isTranscribing: Bool { recordingState == .transcribing }
    var isEditing: Bool      { recordingState == .editing }
    var needsSetup: Bool     { openAIApiKey.trimmingCharacters(in: .whitespaces).isEmpty }

    /// Wired by the coordinator (AppDelegate) after init to break circular dependency.
    weak var pasteOrchestrator: PasteOrchestrating?

    // Private services — injected for testability
    private let audioRecorder: any AudioRecording
    private let transcriber: any Transcribing
    let historyStore: any HistoryStoring
    var recordingStartedAt: Date?

    init(
        audioRecorder: any AudioRecording = AudioRecorder(),
        transcriber: any Transcribing = WhisperService(),
        historyStore: any HistoryStoring = HistoryStore()
    ) {
        self.audioRecorder = audioRecorder
        self.transcriber = transcriber
        self.historyStore = historyStore

        // Load UserDefaults synchronously — fast (< 1ms), needed before first render.
        let prefs = PreferencesStore.loadFast()
        selectedLanguage = prefs.language
        recordingMode = prefs.recordingMode
        autoPasteEnabled = prefs.autoPasteEnabled
        hotkeyKeyCode = prefs.hotkeyKeyCode
        hotkeyModifiers = prefs.hotkeyModifiers
        postProcessingEnabled = prefs.postProcessingEnabled
        postProcessingAPI = prefs.postProcessingAPI
        postProcessingPrompt = prefs.postProcessingPrompt
        postProcessingCustomPrompt = prefs.postProcessingCustomPrompt

        // The level timer fires on the main RunLoop (scheduled from @MainActor context),
        // so assumeIsolated is safe and avoids a Task allocation every 50ms.
        self.audioRecorder.onLevelUpdate = { [weak self] level in
            MainActor.assumeIsolated { self?.audioLevel = level }
        }

        // Keychain reads block for 10–50ms — defer past the first rendered frame.
        Task { @MainActor [weak self] in
            self?.openAIApiKey = KeychainService.load(forKey: "openAIApiKey") ?? ""
            self?.postProcessingAPIKey = KeychainService.load(forKey: "postProcessingAPIKey") ?? ""
        }
    }

    // MARK: - Recording lifecycle

    func startRecording() {
        guard recordingState == .idle else { return }

        audioRecorder.requestPermission { [weak self] granted in
            Task { @MainActor [weak self] in
                guard let self else { return }
                guard self.recordingState == .idle else { return }

                guard granted else {
                    self.transition(to: .error("Microphone access denied — open System Settings › Privacy & Security › Microphone to allow access."))
                    self.announce("Microphone access denied")
                    return
                }

                do {
                    self.audioRecorder.prepareToRecord()
                    try self.audioRecorder.startRecording()
                    self.recordingStartedAt = Date()
                    self.transition(to: .recording)
                    self.announce("Recording started")
                } catch {
                    self.transition(to: .error(error.localizedDescription))
                    self.announce(error.localizedDescription)
                }
            }
        }
    }

    func stopRecording() {
        guard recordingState == .recording else { return }

        // Discard accidental taps shorter than 500 ms
        if let startedAt = recordingStartedAt,
           Date().timeIntervalSince(startedAt) < 0.5 {
            audioRecorder.cancelRecording()
            audioRecorder.prepareToRecord()
            recordingStartedAt = nil
            transition(to: .idle)
            return
        }
        recordingStartedAt = nil
        transition(to: .transcribing)
        audioLevel = 0
        announce("Transcribing audio")

        Task {
            do {
                let url = try await audioRecorder.stopRecording()
                audioRecorder.prepareToRecord()
                await transcribe(audioURL: url)
            } catch {
                transition(to: .error(error.localizedDescription))
                announce(error.localizedDescription)
            }
        }
    }

    // MARK: - Transcription

    private func transcribe(audioURL: URL) async {
        defer { try? FileManager.default.removeItem(at: audioURL) }

        do {
            let text = try await transcriber.transcribe(
                audioURL: audioURL,
                apiKey: openAIApiKey,
                language: selectedLanguage == "auto" ? nil : selectedLanguage
            )
            transcribedText = text

            // Persist to history regardless of auto-paste setting.
            let entry = TranscriptionEntry(
                text: text,
                language: selectedLanguage == "auto" ? nil : selectedLanguage
            )
            historyStore.add(entry: entry)

            if autoPasteEnabled {
                confirmAndPaste()
            } else {
                transition(to: .editing)
                announce("Transcription ready for review")
            }
        } catch {
            transition(to: .error(error.localizedDescription))
            announce(error.localizedDescription)
        }
    }

    // MARK: - Paste

    func confirmAndPaste() {
        let text = transcribedText
        reset()
        pasteOrchestrator?.orchestratePaste(text)
    }

    // MARK: - Reset

    func reset() {
        transcribedText = ""
        transition(to: .idle)
        audioLevel = 0
        recordingStartedAt = nil
    }

    // MARK: - Preferences

    /// Saves preferences. Returns `false` if any Keychain write fails.
    @discardableResult
    func savePreferences() -> Bool {
        PreferencesStore(
            apiKey: openAIApiKey,
            language: selectedLanguage,
            recordingMode: recordingMode,
            autoPasteEnabled: autoPasteEnabled,
            hotkeyKeyCode: hotkeyKeyCode,
            hotkeyModifiers: hotkeyModifiers,
            postProcessingEnabled: postProcessingEnabled,
            postProcessingAPI: postProcessingAPI,
            postProcessingPrompt: postProcessingPrompt,
            postProcessingCustomPrompt: postProcessingCustomPrompt,
            postProcessingAPIKey: postProcessingAPIKey
        ).save()
    }

    // MARK: - State machine

    private func transition(to newState: RecordingState) {
        #if DEBUG
        assertValidTransition(from: recordingState, to: newState)
        #endif
        recordingState = newState
        if case .error = newState { scheduleErrorAutoDismissal() }
    }

    private func scheduleErrorAutoDismissal() {
        Task { @MainActor [weak self] in
            try? await Task.sleep(for: .seconds(4))
            guard let self, case .error = self.recordingState else { return }
            self.reset()
        }
    }

    #if DEBUG
    private func assertValidTransition(from: RecordingState, to: RecordingState) {
        let valid: Bool
        switch (from, to) {
        case (.idle, .recording),
             (.idle, .error),
             (.recording, .transcribing),
             (.recording, .idle),
             (.recording, .error),
             (.transcribing, .editing),
             (.transcribing, .error),
             (_, .idle):
            valid = true
        default:
            valid = false
        }
        assert(valid, "Invalid state transition: \(from) → \(to)")
    }
    #endif

    // MARK: - Accessibility

    private func announce(_ message: String) {
        NSAccessibility.post(
            element: NSApp as AnyObject,
            notification: .announcementRequested,
            userInfo: [.announcement: message, .priority: NSAccessibilityPriorityLevel.high]
        )
    }
}
