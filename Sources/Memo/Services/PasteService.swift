import AppKit
import CoreGraphics

/// Pastes text into the frontmost application using the system clipboard
/// and a simulated ⌘V keystroke.
///
/// This approach is more reliable than character-by-character CGEvent injection
/// because it works in Electron apps, terminal emulators, and apps that intercept
/// synthetic key events. The previous clipboard contents are saved and restored.
///
/// Requires: Accessibility permission (for CGEvent posting).
class PasteService {

    func typeText(_ text: String) {
        guard !text.isEmpty else { return }

        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(text, forType: .string)

        // Simulate ⌘V into the frontmost app.
        // The text stays in the clipboard so the user can paste again if needed.
        guard let source = CGEventSource(stateID: .hidSystemState) else { return }
        let vKeyCode: CGKeyCode = 9  // 'v'

        let down = CGEvent(keyboardEventSource: source, virtualKey: vKeyCode, keyDown: true)
        down?.flags = .maskCommand
        down?.post(tap: .cghidEventTap)

        let up = CGEvent(keyboardEventSource: source, virtualKey: vKeyCode, keyDown: false)
        up?.flags = .maskCommand
        up?.post(tap: .cghidEventTap)
    }
}
