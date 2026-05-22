# Memo — Roadmap

**Vision :** Polished indie macOS dictation app with AI post-processing. Free tier (local Whisper) + paid tier (AI refinement).

---

## Completed

### v1.0 — Core app (April 2026)
- [x] Global hotkey (⌥ Space), push-to-talk + toggle modes
- [x] Audio recording (AVFoundation, AAC 16 kHz)
- [x] Whisper API transcription (gpt-4o-mini-transcribe)
- [x] Floating panel (compact pill + full editor)
- [x] Paste via CGEvent (⌘V simulation)
- [x] API key in Keychain
- [x] 18 languages (auto-detection)
- [x] Sandbox + entitlements + PrivacyInfo.xcprivacy
- [x] Ad-hoc signing with TCC preservation

### v1.1 — Infrastructure + Polish (May 2026)
- [x] CI GitHub Actions (tests + SwiftLint, branch protection)
- [x] Developer ID signing + Apple notarization (automated in CI)
- [x] DMG packaging + GitHub Release workflow
- [x] Landing page (GitHub Pages)
- [x] Transcription history with search (#33)
- [x] UI polish — blur, animations, rounded corners, better icons (#45)
- [x] LICENSE, issue templates, CODEOWNERS, SECURITY.md
- [x] Dependabot for GitHub Actions
- [x] Agent workflow connected to GitHub Issues

---

## Sprint 4 — 19-25 mai 2026 : Features + Revenue Prep

- [ ] **AI post-processing** (#55) — speak messy → get polished text via Claude/GPT (revenue feature)
- [ ] **Local Whisper** (#32) — WhisperKit offline transcription (free tier)
- [ ] **Onboarding flow** (#56) — first-launch wizard
- [ ] **CI/CD split into stages** (#53) — proper pipeline architecture

## Sprint 5+ — June-July 2026 : Ship to Users

- [ ] **Prompt prefixes** (#31) — Whisper prompt parameter
- [ ] **Mac App Store** (#54) — listing, screenshots, privacy policy, submit
- [ ] **Sparkle auto-updates** (#57) — for DMG users
- [ ] **Visual themes** (#34) — light/dark/system
- [ ] **French localization** (#35)

---

## Hors scope (v2.0+)

- iOS companion app
- Meeting mode (system audio transcription)
- Multi-backend (Deepgram, AssemblyAI)
- Custom fine-tuned models
- Team features
