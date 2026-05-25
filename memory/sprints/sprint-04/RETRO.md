# Sprint 4 Retrospective — Features + Revenue Prep
**Dates:** 19 mai - 25 mai 2026
**DoD Score:** 2/4 (50%)

---

## Keep

- **Feature delivery velocity:** #55 (AI post-processing) and #32 (Local Whisper) both delivered in J1-J3, ahead of schedule. High-quality implementations with 36+ tests combined.
- **Scope pivot handled well:** Mid-sprint pivot to App Store pipeline (#54) was managed pragmatically. 13 PRs merged (#67-#81) to get the App Store submission pipeline working.
- **Review quality:** All code sessions got LGTM. Protocol injection pattern (PostProcessing, WhisperEngineProtocol) consistently applied.
- **Unplanned value:** Toggle recording mode, auto-merge CI, French landing page -- all delivered as bonus work beyond the sprint goal.

## Improve

- **DoD accuracy:** 2/4 DoD items completed (50%). The sprint pivoted to App Store work, leaving #53 and #56 untouched. Better to either (a) officially re-scope the sprint when priorities shift, or (b) keep the pivot items as stretch goals.
- **Sprint scope was too ambitious:** 4 major features in 5 days is unrealistic. Sprint 5 should have 2-3 items max, with clear priority ordering.
- **Stale PR cleanup:** PR #63 is orphaned (work merged via other paths). Should have been closed immediately when the merge strategy changed.
- **DAILY_GOAL staleness:** Goal was last updated 2026-05-19 (J1). The daily goal was not maintained through the rest of the sprint -- sessions worked off SPRINT_CURRENT and issue context instead.

## Add

- **Mid-sprint re-scoping ceremony:** When a priority change happens (like the App Store pivot), formally update SPRINT_CURRENT.md to reflect the new reality. Do not leave original items marked "A faire" when they have been knowingly deprioritized.
- **Max 3 DoD items per sprint:** Keep the definition of done focused and achievable. Stretch goals go in a separate section.
- **Close stale PRs immediately:** When work is merged via an alternate path, close the orphaned PR in the same session.

---

## Sprint Score: 20/25

| Category | Score | Notes |
|----------|-------|-------|
| Goal achievement | 3/5 | 2/4 DoD, but significant unplanned value delivered |
| Code quality | 5/5 | All LGTM, 36+ tests added, protocol patterns |
| Process discipline | 3/5 | DAILY_GOAL went stale, PR #63 orphaned |
| Velocity | 5/5 | 17 commits, ~15 PRs merged, 2 features + App Store pipeline |
| Risk management | 4/5 | Pivot was pragmatic, but DoD was not formally updated |
