# Sprint 4 Review — Features + Revenue Prep
**Dates:** 19 mai - 25 mai 2026
**Sprint Goal:** Ship the two highest-impact features (AI post-processing + local Whisper) and restructure CI/CD pipeline.

---

## DoD Assessment: 2/4 delivered

| DoD Item | Status | Notes |
|----------|--------|-------|
| AI post-processing (#55) | DONE | PostProcessor service + settings UI + AppState wiring + TranscriptionView polish button. 22 tests. Merged via PRs on 05/19 and 05/22. |
| Local Whisper fallback (#32) | DONE | WhisperKit integration + LocalWhisperService + Settings UI + AppState wiring. 14 tests. Merged 05/21. |
| CI/CD pipeline split (#53) | NOT DONE | Carried over to Sprint 5. However, significant CI work happened on App Store pipeline (PRs #67-#81). |
| Onboarding flow (#56) | NOT DONE | Carried over to Sprint 5. No work started. |

---

## Unplanned work delivered (scope change mid-sprint)

The sprint pivoted mid-week toward App Store submission (#54, originally Sprint 5+):

- **App Store pipeline** (appstore.yml): build, sign, notarize, package .pkg, upload to App Store Connect. 13 PRs (#67-#81) fixing signing, entitlements, TestFlight validation, asset catalog, provisioning profiles.
- **Toggle recording mode** (#79): push-to-talk + toggle modes in AppState + AudioRecorder + PasteService.
- **Auto-merge CI** (#80): auto-merge workflow for PRs.
- **French landing page** (#81): docs/index.fr.html (434 lines).
- **Auto-deploy** (#79): skip compliance + auto-deploy configuration.

---

## Backlog execution

| Jour | Objectif | Issue | Statut |
|------|----------|-------|--------|
| J1 -- 19/05 | AI post-processing -- PostProcessor service + settings UI | #55 | DONE |
| J2 -- 20/05 | AI post-processing -- wire into AppState + panel toggle | #55 | DONE |
| J3 -- 21/05 | Local Whisper -- WhisperKit integration + LocalWhisperService | #32 | DONE |
| J4 -- 22/05 | Onboarding flow -- first-launch wizard | #56 | NOT DONE (pivoted to App Store CI) |
| J5 -- 23/05 | CI/CD pipeline restructure | #53 | NOT DONE (pivoted to App Store CI fixes) |

---

## Issues closed this sprint

- #55 -- AI post-processing
- #32 -- Local Whisper fallback

---

## Metrics

- **Commits on main this sprint:** 17
- **PRs merged:** ~15 (including #55 work, #67-#81 App Store fixes, #79-#81)
- **Tests added:** ~36 (12 PostProcessor + 10 AppState post-processing + 14 LocalWhisper)
- **DoD score:** 2/4 (50%)
- **Unplanned deliverables:** 5 (App Store pipeline, toggle mode, auto-merge, French landing page, auto-deploy)

---

## Carry-over to Sprint 5

- #53 -- CI/CD pipeline split into stages
- #56 -- Onboarding flow
- #60 -- Fix CI (bug, highest priority)
- PR #63 -- orphaned, should be closed
