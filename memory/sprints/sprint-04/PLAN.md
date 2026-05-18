# Sprint 4 — Features + Revenue Prep (J0 Snapshot)
**Dates :** 19 mai → 25 mai 2026 (1 semaine)
**Sprint Goal :** Ship the two highest-impact features (AI post-processing + local Whisper) and restructure CI/CD pipeline.

---

## Definition of Done

- [ ] AI post-processing (#55) — speak messy → get polished text via Claude/GPT
- [ ] Local Whisper fallback (#32) — offline transcription via WhisperKit, no API key needed
- [ ] CI/CD pipeline split into stages (#53) — each job = one responsibility
- [ ] Onboarding flow (#56) — first-launch wizard

---

## Backlog

| Jour | Objectif | Issue | Statut |
|------|----------|-------|--------|
| J1 — 19/05 | AI post-processing — PostProcessor service + settings UI | #55 | ⬜ A faire |
| J2 — 20/05 | AI post-processing — wire into AppState + panel toggle | #55 | ⬜ A faire |
| J3 — 21/05 | Local Whisper — WhisperKit integration + LocalWhisperService | #32 | ⬜ A faire |
| J4 — 22/05 | Onboarding flow — first-launch wizard | #56 | ⬜ A faire |
| J5 — 23/05 | CI/CD pipeline restructure — split release.yml into stages | #53 | ⬜ A faire |

---

## Contexte technique

- v1.1 publiee et notarisee (signed + notarized DMG via GitHub Release)
- CI : tests + lint requis avant merge (branch protection active)
- Repo propre : 1 branche (main), 0 stale branches
- 52+ tests (46 originaux + 6 HistoryStore)
- SwiftLint passe en CI
- Manager agent lit les GitHub Issues pour planifier
- Reviewer inclut "Closes #XX" pour auto-fermeture des issues

---

## Open GitHub Issues (as of 2026-05-18)

| # | Title | Labels | Priority |
|---|-------|--------|----------|
| 55 | AI post-processing | feat, backlog | **Sprint 4 J1-J2** |
| 32 | Local Whisper fallback | feat, backlog | **Sprint 4 J3** |
| 56 | First-launch onboarding | feat, backlog | **Sprint 4 J4** |
| 53 | CI/CD pipeline split | infra, sprint-4 | **Sprint 4 J5** |
| 31 | Prompt prefixes | feat, backlog | Sprint 5+ |
| 34 | Visual themes | feat, backlog | Sprint 5+ |
| 35 | French localization | feat, backlog | Sprint 5+ |
| 54 | Mac App Store | feat, backlog | Sprint 5+ |
| 57 | Sparkle auto-updates | feat, backlog | Sprint 5+ |
