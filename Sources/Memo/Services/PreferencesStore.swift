import Foundation

/// Encapsulates all user preference persistence: UserDefaults + Keychain.
/// Keeps `AppState` free of persistence concerns.
struct PreferencesStore {
    var apiKey: String
    var language: String
    var recordingMode: RecordingMode
    var autoPasteEnabled: Bool
    var hotkeyKeyCode: Int
    var hotkeyModifiers: Int

    // Post-processing
    var postProcessingEnabled: Bool
    var postProcessingAPI: PostProcessingAPI
    var postProcessingPrompt: PostProcessingPrompt
    var postProcessingCustomPrompt: String
    var postProcessingAPIKey: String

    init(
        apiKey: String = "",
        language: String = "auto",
        recordingMode: RecordingMode = .pushToTalk,
        autoPasteEnabled: Bool = false,
        hotkeyKeyCode: Int = 49,
        hotkeyModifiers: Int = 2048,
        postProcessingEnabled: Bool = false,
        postProcessingAPI: PostProcessingAPI = .openAI,
        postProcessingPrompt: PostProcessingPrompt = .cleanGrammar,
        postProcessingCustomPrompt: String = "",
        postProcessingAPIKey: String = ""
    ) {
        self.apiKey = apiKey
        self.language = language
        self.recordingMode = recordingMode
        self.autoPasteEnabled = autoPasteEnabled
        self.hotkeyKeyCode = hotkeyKeyCode
        self.hotkeyModifiers = hotkeyModifiers
        self.postProcessingEnabled = postProcessingEnabled
        self.postProcessingAPI = postProcessingAPI
        self.postProcessingPrompt = postProcessingPrompt
        self.postProcessingCustomPrompt = postProcessingCustomPrompt
        self.postProcessingAPIKey = postProcessingAPIKey
    }

    /// Full load — includes Keychain (10–50ms). Use only when launch latency is not a concern.
    static func load() -> PreferencesStore {
        var prefs = loadFast()
        prefs.apiKey = KeychainService.load(forKey: "openAIApiKey") ?? ""
        prefs.postProcessingAPIKey = KeychainService.load(forKey: "postProcessingAPIKey") ?? ""
        return prefs
    }

    /// Fast load — UserDefaults only (< 1ms). Use during app init to avoid blocking the launch path.
    static func loadFast() -> PreferencesStore {
        let ud = UserDefaults.standard

        let language = ud.string(forKey: "selectedLanguage") ?? "auto"
        var recordingMode = RecordingMode.pushToTalk
        if let raw = ud.string(forKey: "recordingMode"),
           let mode = RecordingMode(rawValue: raw) {
            recordingMode = mode
        }
        let autoPaste = ud.bool(forKey: "autoPasteEnabled")
        let kc = ud.integer(forKey: "hotkeyKeyCode")
        let km = ud.integer(forKey: "hotkeyModifiers")

        let ppEnabled = ud.bool(forKey: "postProcessingEnabled")
        var ppAPI = PostProcessingAPI.openAI
        if let raw = ud.string(forKey: "postProcessingAPI"),
           let api = PostProcessingAPI(rawValue: raw) {
            ppAPI = api
        }
        var ppPrompt = PostProcessingPrompt.cleanGrammar
        if let raw = ud.string(forKey: "postProcessingPrompt"),
           let p = PostProcessingPrompt(rawValue: raw) {
            ppPrompt = p
        }
        let ppCustomPrompt = ud.string(forKey: "postProcessingCustomPrompt") ?? ""

        return PreferencesStore(
            apiKey: "",
            language: language,
            recordingMode: recordingMode,
            autoPasteEnabled: autoPaste,
            hotkeyKeyCode: kc > 0 ? kc : 49,
            hotkeyModifiers: km > 0 ? km : 2048,
            postProcessingEnabled: ppEnabled,
            postProcessingAPI: ppAPI,
            postProcessingPrompt: ppPrompt,
            postProcessingCustomPrompt: ppCustomPrompt,
            postProcessingAPIKey: ""
        )
    }

    /// Persists all preferences. Returns `false` if any Keychain write fails.
    @discardableResult
    func save() -> Bool {
        let ud = UserDefaults.standard

        // Keychain: Whisper API key
        let whisperOK: Bool
        if apiKey.isEmpty {
            KeychainService.delete(forKey: "openAIApiKey")
            whisperOK = true
        } else {
            whisperOK = KeychainService.save(apiKey, forKey: "openAIApiKey")
        }

        // Keychain: post-processing API key
        let ppKeyOK: Bool
        if postProcessingAPIKey.isEmpty {
            KeychainService.delete(forKey: "postProcessingAPIKey")
            ppKeyOK = true
        } else {
            ppKeyOK = KeychainService.save(postProcessingAPIKey, forKey: "postProcessingAPIKey")
        }

        ud.set(language,               forKey: "selectedLanguage")
        ud.set(recordingMode.rawValue,  forKey: "recordingMode")
        ud.set(autoPasteEnabled,        forKey: "autoPasteEnabled")
        ud.set(hotkeyKeyCode,           forKey: "hotkeyKeyCode")
        ud.set(hotkeyModifiers,         forKey: "hotkeyModifiers")
        ud.set(postProcessingEnabled,               forKey: "postProcessingEnabled")
        ud.set(postProcessingAPI.rawValue,          forKey: "postProcessingAPI")
        ud.set(postProcessingPrompt.rawValue,       forKey: "postProcessingPrompt")
        ud.set(postProcessingCustomPrompt,          forKey: "postProcessingCustomPrompt")

        return whisperOK && ppKeyOK
    }
}
