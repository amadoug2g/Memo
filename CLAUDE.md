# Memo — Claude Code Project Guide

## What is Memo?

Memo is a macOS menu-bar-only voice dictation app. Global shortcut (⌥ Space) → records audio → sends to OpenAI Whisper API → shows floating panel for review → pastes text into any app via ⌘V simulation.

**Goal:** Publish before April 30, 2026 — GitHub Release (DMG) + GitHub Pages landing page.

---

## Stack

| Layer | Technology |
|-------|-----------|
| Language | Swift 5.9 |
| UI | SwiftUI + MenuBarExtra + AppKit NSPanel |
| Global hotkey | Carbon Event Manager |
| Audio | AVFoundation (AVAudioRecorder, m4a, 16 kHz mono) |
| Transcription | OpenAI Whisper API (`gpt-4o-mini-transcribe`) |
| Paste | CGEvent keyboard simulation (⌘V) |
| Secure storage | macOS Keychain Services |
| Build | Swift Package Manager + Makefile |

---

## Project Structure

```
Sources/Memo/
├── MemoApp.swift              # SwiftUI entry, MenuBarExtra scene
├── AppDelegate.swift          # Hotkey wiring, paste orchestration
├── Models/
│   └── AppState.swift         # Central @MainActor ObservableObject
├── Views/
│   ├── TranscriptionView.swift  # Floating edit panel
│   └── SettingsView.swift       # API key, language, hotkey prefs
└── Services/
    ├── AudioRecorder.swift      # AVAudioRecorder wrapper (protocol: AudioRecording)
    ├── WhisperService.swift     # Whisper API client (protocol: Transcribing)
    ├── HotkeyManager.swift      # Carbon global shortcut manager
    ├── PanelController.swift    # NSPanel lifecycle
    ├── PreferencesStore.swift   # UserDefaults + Keychain persistence
    ├── KeychainService.swift    # Keychain read/write/delete
    └── PasteService.swift       # Clipboard + CGEvent paste

Sources/MemoMain/
└── main.swift                 # Entry point: MemoApp.main()

Tests/MemoTests/               # 46 tests
├── AppStateTests.swift
├── DeploymentTests.swift
├── PanelControllerTests.swift
├── PreferencesStoreTests.swift
├── WhisperServiceTests.swift
└── Mocks.swift
```

---

## Core State Machine

```
idle → recording → transcribing → editing → idle
                              └→ error(String) → idle (auto after 4s)
```

Transitions enforced in AppState.swift. All state changes are `@MainActor`.

---

## Build Commands

```bash
make test      # swift test — run all 46 tests
make app       # release build → scripts/package-app.sh → Memo.app (ad-hoc signed)
make install   # copies Memo.app to /Applications
make dev       # swift run MemoMain (debug)
make clean     # rm -rf .build
./run.sh       # smart build + sign (preserves Accessibility TCC across restarts)
```

---

## Key Configuration

- **Bundle ID:** `com.memo.app`
- **Minimum macOS:** 13 Ventura
- **Entitlements:** sandbox, microphone (`audio-input`), network client
- **Privacy manifest:** `Sources/Memo/Resources/PrivacyInfo.xcprivacy`
- **Signing:** ad-hoc only (`codesign --force --sign -`)
- **No Dock presence:** `LSUIElement = true` in Info.plist

---

## Testing Patterns

- Protocol injection: `AudioRecording`, `Transcribing` for mockability
- `@MainActor` on all test classes that touch AppState
- Custom `waitForState()` helper (polls + yields, avoids RunLoop blocking)
- Mock classes in `Mocks.swift` with call counts and configurable results

---

## Commit Conventions

Use conventional commits:
- `feat:` new feature
- `fix:` bug fix
- `ci:` CI/CD changes
- `docs:` documentation
- `refactor:` code restructure (no behavior change)
- `test:` test additions/fixes

---

## Agent Workflow

See `memory/` directory:
- `DAILY_GOAL.md` — current day's implementation objective
- `ARCHITECTURE.md` — detailed architecture reference
- `ROADMAP.md` — release milestones and deadline
- `SESSION_LOG.md` — daily log of completed work
- `CODER_SUMMARY.md` — coder's output (read by reviewer)
- `REVIEWER_FEEDBACK.md` — reviewer's feedback when not LGTM

Branching: coder creates `feature/YYYYMMDD-<slug>`, reviewer opens PR to `main`.

---

## Agent Limits

Agents work with least privilege. The rules are versioned in the repo, so every agent session gets the same ones.

| Layer | Where | What it does |
|-------|-------|--------------|
| Permissions | `.claude/settings.json` | Allows build, test, lint, commits and pushes to `feature/*` only. Denies reading `.env` and signing files, force push, push to `main`, `git reset --hard`, `rm -rf` and Keychain commands. |
| Hook | `.claude/hooks/guard-bash.sh` | Runs before every Bash command. Blocks push to `main`, force push, history rewrites and `--no-verify`, even inside chained commands the deny list could miss. |
| Branch protection | GitHub ruleset "Protect main" | `main` only changes through a pull request with green "Swift Tests" and "SwiftLint" checks. Force push and branch deletion are blocked. Auto-merge cannot merge a red PR. |
| Secrets | GitHub secret scanning + push protection | A commit containing a key is rejected before it lands. The Whisper API key lives in the macOS Keychain, never in the repo. |

When a rule blocks an agent, the agent stops and reports. Changing these files is a human decision, made through a reviewed pull request.
