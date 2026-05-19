import SwiftUI
import AppKit
import CoreGraphics

private enum KeyTestState: Equatable {
    case idle, testing, valid, invalid(String)
}

struct SettingsView: View {
    @EnvironmentObject var appState: AppState

    @State private var apiKey: String = ""
    @State private var language: String = "auto"
    @State private var mode: RecordingMode = .pushToTalk
    @State private var autoPaste: Bool = false
    @State private var hotkeyKeyCode: Int = 49
    @State private var hotkeyModifiers: Int = 2048
    @State private var saved = false
    @State private var saveFailed = false
    @State private var keyTestState: KeyTestState = .idle

    // Post-processing
    @State private var postProcessingEnabled: Bool = false
    @State private var postProcessingAPI: PostProcessingAPI = .openAI
    @State private var postProcessingPrompt: PostProcessingPrompt = .cleanGrammar
    @State private var postProcessingCustomPrompt: String = ""
    @State private var postProcessingAPIKey: String = ""

    private let languages: [(label: String, code: String)] = [
        ("Auto-detect",  "auto"),
        ("English",      "en"),
        ("Spanish",      "es"),
        ("French",       "fr"),
        ("German",       "de"),
        ("Italian",      "it"),
        ("Portuguese",   "pt"),
        ("Dutch",        "nl"),
        ("Japanese",     "ja"),
        ("Korean",       "ko"),
        ("Chinese",      "zh"),
        ("Arabic",       "ar"),
        ("Russian",      "ru"),
        ("Hindi",        "hi"),
        ("Turkish",      "tr"),
        ("Polish",       "pl"),
        ("Swedish",      "sv"),
        ("Ukrainian",    "uk"),
    ]

    var body: some View {
        Form {

            // MARK: API Key
            Section {
                SecureField("sk-…", text: $apiKey)
                    .textFieldStyle(.roundedBorder)
                    .font(.system(.body, design: .monospaced))
                    .accessibilityLabel("OpenAI API Key")
                    .onChange(of: apiKey) { _ in keyTestState = .idle }

                HStack(spacing: 8) {
                    Image(systemName: "lock.fill")
                        .foregroundStyle(.secondary)
                        .accessibilityHidden(true)
                    Text("Stored securely in the system Keychain.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Spacer()
                    keyTestResultBadge
                    Button("Test Key") { testAPIKey() }
                        .buttonStyle(.borderless)
                        .disabled(apiKey.trimmingCharacters(in: .whitespaces).isEmpty
                                  || keyTestState == .testing)
                }
            } header: {
                Text("OpenAI API Key")
            }

            // MARK: Recording Mode
            Section {
                Picker("Mode", selection: $mode) {
                    ForEach(RecordingMode.allCases, id: \.self) { modeOption in
                        Text(modeOption.label).tag(modeOption)
                    }
                }
                .pickerStyle(.radioGroup)
                Text(mode.hint)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            } header: {
                Text("Input Mode")
            }

            // MARK: Behavior
            Section {
                Toggle("Auto-paste (skip review)", isOn: $autoPaste)
                Text("Transcription is pasted immediately without showing the review panel.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } header: {
                Text("Behavior")
            }

            // MARK: Language
            Section {
                Picker("Language", selection: $language) {
                    ForEach(languages, id: \.code) { lang in
                        Text(lang.label).tag(lang.code)
                    }
                }
                .pickerStyle(.menu)
                Text("Specifying a language improves accuracy and reduces latency.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } header: {
                Text("Transcription Language")
            }

            // MARK: Hotkey
            Section {
                HotkeyRecorderView(keyCode: $hotkeyKeyCode, modifiers: $hotkeyModifiers)
            } header: {
                Text("Hotkey")
            }

            // MARK: Save / Done
            HStack {
                Spacer()
                if saveFailed {
                    Label("Keychain error — key not saved", systemImage: "xmark.circle.fill")
                        .foregroundStyle(.red)
                        .font(.system(size: 13, weight: .medium))
                        .transition(.opacity)
                } else if saved {
                    Label("Saved", systemImage: "checkmark.circle.fill")
                        .foregroundStyle(.green)
                        .font(.system(size: 13, weight: .medium))
                        .transition(.opacity)
                }
                Button("Save") { save() }
                    .buttonStyle(.bordered)
                    .keyboardShortcut(.return, modifiers: .command)
                Button("Done") { saveAndClose() }
                    .buttonStyle(.borderedProminent)
                    .keyboardShortcut("w", modifiers: .command)
            }
            .padding(.top, 4)
        }
        .formStyle(.grouped)
        .frame(minWidth: 440, maxWidth: 440, minHeight: 360)
        .padding()
        .onAppear {
            loadFromAppState()
            bringToFront()
        }
    }

    // MARK: - Key test result badge

    @ViewBuilder
    private var keyTestResultBadge: some View {
        switch keyTestState {
        case .idle:
            EmptyView()
        case .testing:
            ProgressView()
                .scaleEffect(0.7)
                .frame(width: 20, height: 20)
        case .valid:
            Label("Valid", systemImage: "checkmark.circle.fill")
                .foregroundStyle(.green)
                .font(.caption)
                .transition(.opacity)
        case .invalid(let msg):
            Label(msg, systemImage: "xmark.circle.fill")
                .foregroundStyle(.red)
                .font(.caption)
                .lineLimit(1)
                .transition(.opacity)
        }
    }

    // MARK: - Helpers

    private func keyBadge(_ label: String) -> some View {
        Text(label)
            .font(.callout.weight(.medium).monospaced())
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(.quaternary, in: RoundedRectangle(cornerRadius: 5))
    }

    private func bringToFront() {
        // Accessory apps (.accessory activation policy) don't own the active
        // space, so windows silently open behind everything. The deprecated
        // activate(ignoringOtherApps:) is the only reliable way to force an
        // accessory app to the front on all macOS versions.
        NSApp.activate(ignoringOtherApps: true)

        // The Settings scene window may not be key yet — wait one runloop
        // tick, then find it and force it to front with orderFrontRegardless().
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
            // Find the Settings window: it's a non-panel, visible window.
            let settingsWindow = NSApp.windows.first(where: {
                !($0 is NSPanel) && $0.isVisible
            }) ?? NSApp.keyWindow

            guard let window = settingsWindow else { return }

            // Move to the screen containing the cursor.
            let mouse = NSEvent.mouseLocation
            let screen = NSScreen.screens.first { $0.frame.contains(mouse) }
                ?? NSScreen.main
            if let screen {
                let sf = screen.visibleFrame
                let origin = NSPoint(
                    x: sf.midX - window.frame.width / 2,
                    y: sf.midY - window.frame.height / 2
                )
                window.setFrameOrigin(origin)
            }

            window.makeKeyAndOrderFront(nil)
            window.orderFrontRegardless()
        }
    }

    private func saveAndClose() {
        save()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            let window = NSApp.windows.first(where: {
                !($0 is NSPanel) && $0.isVisible
            }) ?? NSApp.keyWindow
            window?.close()
        }
    }

    private func loadFromAppState() {
        apiKey          = appState.openAIApiKey
        language        = appState.selectedLanguage
        mode            = appState.recordingMode
        autoPaste       = appState.autoPasteEnabled
        hotkeyKeyCode   = appState.hotkeyKeyCode
        hotkeyModifiers = appState.hotkeyModifiers
    }

    private func save() {
        appState.openAIApiKey     = apiKey
        appState.selectedLanguage = language
        appState.recordingMode    = mode
        appState.autoPasteEnabled = autoPaste
        appState.hotkeyKeyCode    = hotkeyKeyCode
        appState.hotkeyModifiers  = hotkeyModifiers
        let ok = appState.savePreferences()

        if ok {
            withAnimation { saved = true; saveFailed = false }
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                withAnimation { saved = false }
            }
        } else {
            withAnimation { saveFailed = true; saved = false }
            DispatchQueue.main.asyncAfter(deadline: .now() + 4) {
                withAnimation { saveFailed = false }
            }
        }
    }

    // MARK: - API Key test

    private func testAPIKey() {
        keyTestState = .testing
        let trimmedKey = apiKey.trimmingCharacters(in: .whitespaces)
        Task {
            do {
                let session = URLSession(configuration: .ephemeral)
                guard let apiURL = URL(string: "https://api.openai.com/v1/models") else { return }
                var request = URLRequest(url: apiURL)
                request.setValue("Bearer \(trimmedKey)", forHTTPHeaderField: "Authorization")
                request.timeoutInterval = 10
                let (_, response) = try await session.data(for: request)
                if let http = response as? HTTPURLResponse {
                    withAnimation {
                        keyTestState = http.statusCode == 200
                            ? .valid
                            : .invalid("Invalid key — check your OpenAI account")
                    }
                }
            } catch {
                withAnimation {
                    keyTestState = .invalid("Couldn't reach OpenAI — check your connection")
                }
            }
            try? await Task.sleep(for: .seconds(4))
            withAnimation { keyTestState = .idle }
        }
    }
}

// MARK: - HotkeyRecorderView

private struct HotkeyRecorderView: View {
    @Binding var keyCode: Int
    @Binding var modifiers: Int
    @State private var isRecording = false
    @State private var monitor: Any?

    var body: some View {
        HStack {
            Text("Global shortcut")
            Spacer()
            if isRecording {
                Text("Press keys…")
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(.quaternary, in: RoundedRectangle(cornerRadius: 5))
                Button("Cancel") { stopRecording() }
                    .buttonStyle(.plain)
                    .foregroundStyle(.secondary)
            } else {
                Text(displayString(keyCode: keyCode, modifiers: modifiers))
                    .font(.system(size: 12, weight: .medium, design: .monospaced))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(.quaternary, in: RoundedRectangle(cornerRadius: 5))
                Button("Change") { startRecording() }
                    .buttonStyle(.plain)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private func startRecording() {
        isRecording = true
        monitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { event in
            guard event.modifierFlags.intersection([.command, .option, .control, .shift]) != [],
                  !isModifierOnlyKey(event.keyCode) else { return event }
            keyCode   = Int(event.keyCode)
            modifiers = carbonModifiers(from: event.modifierFlags)
            stopRecording()
            return nil
        }
    }

    private func stopRecording() {
        if let eventMonitor = monitor { NSEvent.removeMonitor(eventMonitor); monitor = nil }
        isRecording = false
    }

    private func carbonModifiers(from flags: NSEvent.ModifierFlags) -> Int {
        var result = 0
        if flags.contains(.option)  { result |= 2048 }
        if flags.contains(.command) { result |= 256  }
        if flags.contains(.control) { result |= 4096 }
        if flags.contains(.shift)   { result |= 512  }
        return result
    }

    private func isModifierOnlyKey(_ code: UInt16) -> Bool {
        [54, 55, 56, 57, 58, 59, 60, 61, 62, 63].contains(code)
    }

    private func displayString(keyCode: Int, modifiers: Int) -> String {
        var display = ""
        if modifiers & 4096 != 0 { display += "⌃" }
        if modifiers & 2048 != 0 { display += "⌥" }
        if modifiers & 512  != 0 { display += "⇧" }
        if modifiers & 256  != 0 { display += "⌘" }
        display += keyName(for: keyCode)
        return display
    }

    private func keyName(for code: Int) -> String {
        switch code {
        case 49: return "Space"
        case 36: return "↩"
        case 48: return "⇥"
        case 51: return "⌫"
        case 53: return "⎋"
        default:
            let src = CGEventSource(stateID: .hidSystemState)
            let evt = CGEvent(keyboardEventSource: src, virtualKey: CGKeyCode(code), keyDown: true)
            var len = 0
            var chars = [UniChar](repeating: 0, count: 4)
            evt?.keyboardGetUnicodeString(maxStringLength: 4, actualStringLength: &len, unicodeString: &chars)
            return (NSString(characters: chars, length: len) as String).uppercased()
        }
    }
}
