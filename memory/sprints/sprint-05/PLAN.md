# Sprint 5 — Ship to Users (J0 Snapshot)
**Dates :** 26 mai -> 1 juin 2026 (1 semaine)
**Sprint Goal :** Fix CI, complete onboarding, restructure CI/CD pipeline, and close the stale PR. Stabilize the app for real users.

---

## Definition of Done

- [ ] Fix CI green (#60) -- Swift tests + SwiftLint passing on macOS-14
- [ ] CI/CD pipeline split into stages (#53) -- each job = one responsibility
- [ ] Onboarding flow (#56) -- first-launch wizard
- [ ] Stale PR #63 closed

---

## Backlog

| Jour | Objectif | Issue | Statut |
|------|----------|-------|--------|
| J1 -- 26/05 | Fix CI -- get Swift tests + SwiftLint green | #60 | A faire |
| J2 -- 27/05 | CI/CD pipeline split -- restructure release.yml into stages | #53 | A faire |
| J3 -- 28/05 | Onboarding flow -- first-launch wizard (part 1) | #56 | A faire |
| J4 -- 29/05 | Onboarding flow -- permissions + guided first recording (part 2) | #56 | A faire |
| J5 -- 30/05 | Sprint review + retro | -- | A faire |

---

## Contexte technique

- v1.0 publiee (GitHub Release, Memo-v1.0.dmg 1.85 MB)
- App Store pipeline (appstore.yml) operational -- 13 PRs merged during Sprint 4
- AI post-processing (#55) et Local Whisper (#32) livres en Sprint 4
- Toggle recording mode, auto-merge CI, French landing page livres en Sprint 4
- 58+ tests (46 originaux + 12 PostProcessor + ~14 LocalWhisper + extras)
- SwiftLint en CI
- PR #63 orpheline a fermer

---

## Open GitHub Issues (as of 2026-05-25)

| # | Title | Labels | Priority |
|---|-------|--------|----------|
| 60 | Fix CI green | bug, ci | **Sprint 5 J1 -- BLOQUANT** |
| 53 | CI/CD pipeline split | infra, sprint-4 | **Sprint 5 J2** |
| 56 | First-launch onboarding | feat, backlog | **Sprint 5 J3-J4** |
| 31 | Prompt prefixes | feat, backlog | Sprint 6+ |
| 34 | Visual themes | feat, backlog | Sprint 6+ |
| 35 | French localization | feat, backlog | Sprint 6+ |
| 54 | Mac App Store | feat, backlog | Sprint 6+ |
| 57 | Sparkle auto-updates | feat, backlog | Sprint 6+ |

---

## Lessons from Sprint 4

- Max 3 DoD items per sprint (Sprint 4 had 4, only 2 delivered)
- Formally re-scope when priorities shift mid-sprint
- Close stale PRs immediately when work merges via alternate path
- Keep DAILY_GOAL.md updated throughout the sprint, not just J1
