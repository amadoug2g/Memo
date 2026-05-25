# Session Log — Memo

Format par entrée :
```
## YYYY-MM-DD
- Objectif: <description>
- Statut: ✅ LGTM | ❌ Bloquant | ⏭️ Ignoré
- PR: #<numéro> (si créée)
- Tests: <X passed, Y failed>
- Notes: <commentaires optionnels>
```

---

## 2026-05-25 — Weekly Strategic Review (manager)
- Objectif: Revue strategique hebdomadaire — cloture Sprint 4, lancement Sprint 5
- Statut: Review completee
- Tests: N/A
- Notes:
  - **25 jours post-deadline originale.** v1.0 livree a temps (29/04). Projet en phase post-release features.
  - **Sprint 4 clos.** DoD 2/4 (50%) : #55 AI post-processing et #32 Local Whisper livres. #53 CI/CD split et #56 Onboarding reportes.
  - Sprint 4 : pivot mid-sprint vers App Store pipeline (#54). 13 PRs (#67-#81), toggle mode, auto-merge CI, French landing page livres en bonus.
  - Archive Sprint 4 dans memory/sprints/sprint-04/ (PLAN, SPRINT_REVIEW, RETRO).
  - **Sprint 5 demarre : "Ship to Users"** (26 mai - 1 juin).
  - Backlog Sprint 5 : J1=#60 (Fix CI, BLOQUANT), J2=#53 (CI/CD split), J3-J4=#56 (Onboarding), J5=review+retro.
  - 8 issues GitHub ouvertes. 3 planifiees Sprint 5, 5 en backlog Sprint 6+.
  - PR #63 orpheline identifiee — a fermer (travail deja merge via autres commits).
  - ROADMAP mis a jour (Sprint 4 items coches, Sprint 5 ajoute).
  - DAILY_GOAL confirme : J1 26/05, issue #60, fix CI (priorite #1 = CI casse).
  - Lessons Sprint 4 : max 3 DoD items, re-scoper quand pivot, fermer PRs orphelines, maintenir DAILY_GOAL.

## 2026-05-21
- Objectif: Sprint 4 J3 — Local Whisper fallback (#32) : WhisperKit integration + LocalWhisperService + Settings UI + AppState wiring
- Statut: ✅ LGTM
- Tests: swift non disponible sur Linux — 14 nouveaux tests LocalWhisperServiceTests vérifiés syntaxiquement et logiquement (protocol conformance, auto-load, language forwarding, error propagation, state transitions, LocalModelState equatable)
- Notes: LocalWhisperService implémente Transcribing via WhisperEngineProtocol (injectable). WhisperKitEngine réel sous #if canImport(WhisperKit), stub no-op pour Linux/CI. Package.swift: dépendance WhisperKit 0.9.0, condition .when(platforms: [.macOS]) correcte. AppState: useLocalTranscription, localModelState, transcriber dynamique. PreferencesStore: useLocalTranscription persisté UserDefaults. SettingsView: section "Local Transcription" avec toggle + statusRow (4 états). Suggestion non-bloquante: vérifier la signature exacte de WhisperKitConfig() contre l'API WhisperKit 0.9.x lors d'un build macOS.

## 2026-05-22 — Sprint 4 J1 — Review finale : PostProcessor service + settings UI (#55)
- Objectif: Valider l'implémentation PostProcessor (issue #55, J1) sur branche claude/tender-einstein-sDRP6
- Statut: ✅ LGTM
- PR: à créer vers main (Closes #55)
- Tests: 12 tests PostProcessorTests (swift non disponible sur Linux — vérifié syntaxiquement et logiquement ; cohérent avec toutes les sessions précédentes)
- Notes:
  - Tous les critères de succès DAILY_GOAL remplis : protocole PostProcessing injectable, 6 presets, toggle enable/disable, 12 tests (min 4 requis), sécurité Keychain correcte.
  - PostProcessor.swift : validation apiKey/prompt avant réseau, URLSession.ephemeral, gestion httpError/emptyResponse/emptyPrompt.
  - PreferencesStore.swift : 5 champs post-processing, postProcessingAPIKey via Keychain (save/delete symétrique).
  - AppState.swift : 5 @Published vars, loadFast() UserDefaults, Keychain différé Task @MainActor.
  - SettingsView.swift : section Post-processing complète (toggle, prompt picker, custom conditionnel, API picker segmented, SecureField).
  - Suggestion non-bloquante : J2 devra passer systemPrompt résolu (pas rawValue) lors du câblage AppState.

## 2026-05-19 — Sprint 4 J1 — AI post-processing: PostProcessor service + settings UI (coder + reviewer)
- Objectif: Issue #55 — PostProcessor service + UI settings pour le post-traitement AI (J1/2)
- Statut: ✅ LGTM
- Tests: 12 tests PostProcessorTests (swift non disponible sur Linux — vérifié syntaxiquement et logiquement)
- Notes:
  - PostProcessor.swift créé : protocole PostProcessing injectable, 6 presets PostProcessingPrompt, PostProcessingAPI (openAI/claude), implémentation callOpenAI (gpt-4o-mini) + callClaude (claude-haiku-4-5), validation apiKey/prompt avant réseau, erreurs localisées.
  - PreferencesStore.swift étendu : 5 champs post-processing, postProcessingAPIKey via Keychain.
  - AppState.swift étendu : 5 @Published vars, chargement UserDefaults/Keychain, savePreferences() complet.
  - SettingsView.swift : section "Post-processing" complète (toggle, prompt picker, custom prompt conditionnel, API picker segmented, SecureField clé API secondaire).
  - Sécurité : aucune clé en dur, Keychain utilisé correctement, URLSession.ephemeral.
  - Suggestions non-bloquantes : (1) J2 devra passer systemPrompt résolu (pas rawValue) lors du câblage AppState ; (2) vérifier model ID "claude-haiku-4-5" en production.

## 2026-05-18 — Weekly Strategic Review #2 (manager)
- Objectif: Revue strategique hebdomadaire — confirmation Sprint 4 plan, merge PR #59, fix CI
- Statut: ✅ Review completee
- PR: #59 (merged, squash)
- Tests: Swift Tests PASS (52 tests), SwiftLint PASS — apres fix CI
- Notes:
  - Sprint 4 plan confirme : J1=#55 (AI post-processing), J2=#55, J3=#32 (Local Whisper), J4=#56 (Onboarding), J5=#53 (CI/CD split).
  - 9 issues GitHub ouvertes. 4 planifiees Sprint 4, 5 en backlog Sprint 5+.
  - **CI FIX** : "Swift Tests" echouait en ~14s (3 runs consecutifs). Root cause = cache SPM stale apres mise a jour Xcode sur le runner macos-14. Fix : pin Xcode 16.2 via xcode-select + nouveau cache key incluant version Xcode. 4/4 checks green apres fix.
  - PR #59 mergee (squash) dans main : commit a7591b8.
  - LESSONS_LEARNED mis a jour avec pattern "Stale SPM cache after Xcode runner update".
  - DAILY_GOAL.md valide : cible J1 19/05, issue #55, PostProcessor service + settings UI.
  - Sprint 4 pret pour demarrage lundi 19/05. CI fonctionnel.

## 2026-05-18 — Weekly Strategic Review (manager)
- Objectif: Revue strategique hebdomadaire — validation Sprint 4 setup, priorisation semaine
- Statut: Review completee
- Tests: N/A
- Notes:
  - **Post-deadline (18 jours).** v1.0 publiee le 29/04, v1.1 (infra + polish) livree en Sprint 3.
  - Sprint 3 clos (3/5 DoD livres, 2 bloquants humain — GitHub Pages + branch cleanup). Archive dans memory/sprints/sprint-03/.
  - **Sprint 4 demarre demain (19/05) : "Features + Revenue Prep"** (19-25 mai).
  - Backlog Sprint 4 derive des issues GitHub ouvertes : J1-J2=#55 (AI post-processing), J3=#32 (Local Whisper), J4=#56 (Onboarding), J5=#53 (CI/CD split).
  - 9 issues ouvertes sur GitHub. 4 planifiees Sprint 4, 5 en backlog Sprint 5+.
  - PLAN.md snapshot J0 cree dans memory/sprints/sprint-04/.
  - DAILY_GOAL.md confirme : J1 19/05, issue #55, PostProcessor service + settings UI.
  - Branche claude/affectionate-cerf-0aQJ6 : 11 commits ahead de main (inclut Sprint 4 setup + features v1.1).
  - **Aucune urgence CI** — pipeline fonctionnel (tests + lint + release + smoke test).
  - **Priorite #1 cette semaine** : AI post-processing (#55) = feature revenue, 2 jours planifies.

## 2026-05-14 — Post-Sprint 3 — Deuxieme handoff (coder)
- Objectif: DAILY_GOAL.md perime (date 2026-05-04, 10 jours), Sprint 3 entierement clos — pas de Sprint 4 defini
- Statut: Done (aucun item implementable)
- Tests: swift non disponible sur Linux — 46 tests inchanges (aucune modification Swift)
- Notes:
  - DAILY_GOAL.md date du 04/05, Sprint 3 completement clos (J1-J5 tous Done ou Bloque humain).
  - Branche claude/tender-einstein-QEg1r : 2 commits ahead de main (c169e8c Sprint 3 J5, 86f8079 handoff 2026-05-13) — commits non merges dans main.
  - Aucun item implementable par l'agent — en attente de definition Sprint 4 par le manager.
  - SESSION_LOG.md et CODER_SUMMARY.md mis a jour.
  - Bloquants humain restants inchanges : (1) GitHub Pages verification navigateur ; (2) Suppression 4 branches orphelines (push --delete bloque sandbox 403).

## 2026-05-13 — Post-Sprint 3 — Handoff (coder)
- Objectif: DAILY_GOAL.md perime (date 2026-05-04), Sprint 3 entierement clos — documenter l'etat et preparer la prochaine iteration
- Statut: ✅ LGTM
- PR: #24 (https://github.com/amadoug2g/whisper-input/pull/24)
- Tests: swift non disponible sur Linux — 46 tests inchanges (aucune modification Swift)
- Notes:
  - DAILY_GOAL.md date du 04/05 (9 jours perime). Sprint 3 completement clos (J1-J5 tous Done ou Bloque humain).
  - SPRINT_CURRENT.md : tous les items J1-J5 traites. 2 bloquants humain restants (GitHub Pages verification + branch cleanup).
  - Aucun item implementable par l'agent sans Sprint 4 defini par le manager.
  - ACTION REQUISE : lancer le subagent `manager` pour definir Sprint 4 / mettre a jour DAILY_GOAL.md.
  - SESSION_LOG.md mis a jour. CODER_SUMMARY.md ecrit.
  - Branche feature/20260513-session-handoff creee.

## 2026-05-12 — Sprint 3 J5 — Review (reviewer)
- Objectif: Valider la sprint review et retrospective Sprint 3
- Statut: LGTM
- Tests: swift non disponible sur Linux — 46 tests inchanges (aucune modification Swift)
- Notes: SPRINT_REVIEW.md et RETRO.md complets et coherents. DoD 3/5 exact, bloquants humain documentes avec commandes precises. RETRO Keep/Improve/Add actionnable, score 23/25 coherent. LESSONS_LEARNED pattern [promote] bien forme. Sprint 3 entierement clos.

## 2026-05-12 — Sprint 3 J5 — Sprint review + retro (coder)
- Objectif: Ecrire la sprint review et la retrospective Sprint 3, marquer J5 Done
- Statut: Done
- Tests: swift non disponible sur Linux — 46 tests inchanges (aucune modification Swift)
- Notes:
  - SPRINT_REVIEW.md cree : bilan DoD (3/5 livres, 2 bloquants humain), backlog J1-J5, livrables techniques (smoke-test CI, body_path CHANGELOG, README), bloquants documentes avec instructions precises, metriques sprint, score 3/5 DoD.
  - RETRO.md cree : format Keep/Improve/Add. Keep: smoke test CI, MCP GitHub sans navigateur, groupage J3+J4, LGTM 100%. Improve: anticiper bloquants sandbox, DAILY_GOAL dates, sync PLAN.md/SPRINT_CURRENT.md. Add: test connectivite git en debut de session. Score global 23/25.
  - PLAN.md et SPRINT_CURRENT.md : J5 marque Done.
  - Sprint 3 entierement clos. 4 branches orphelines et verification GitHub Pages restent bloquants humain.

## 2026-05-11 — Sprint 3 J3+J4 — Review (reviewer)
- Objectif: Valider release body CHANGELOG.md (body_path) et retrait section Screenshots README
- Statut: LGTM
- Tests: swift non disponible sur Linux — 46 tests inchanges (aucune modification Swift)
- Notes: body_path: CHANGELOG.md correct (fichier present a la racine, compatible softprops/action-gh-release@v2). README section Screenshots retiree proprement. SPRINT_CURRENT J3+J4 Done, DoD items coches. Suggestion non-bloquante : enrichir CHANGELOG.md avant chaque prochaine release pour que le body_path reste pertinent.

## 2026-05-11 — Sprint 3 J3+J4 — Release body CHANGELOG + README screenshots (coder)
- Objectif: Enrichir le release body avec CHANGELOG.md (body_path), retirer section Screenshots placeholder du README
- Statut: Done
- Tests: swift non disponible sur Linux — 46 tests inchanges (aucune modification Swift)
- Notes:
  - release.yml : remplacement du body inline par `body_path: CHANGELOG.md` dans le job build-and-release. La prochaine release utilisera automatiquement le contenu de CHANGELOG.md comme description.
  - README.md : section "Screenshots" placeholder retiree (etait marquee "a venir depuis Sprint 1 J5").
  - SPRINT_CURRENT.md : J3 et J4 marques Done, DoD items correspondants coches.
  - Branche : claude/tender-einstein-bJrkk.

## 2026-05-05 — Sprint 3 J2 — CI smoke test DMG (reviewer)
- Objectif: Valider le job smoke-test DMG dans release.yml
- Statut: LGTM
- PR: #21 (https://github.com/amadoug2g/whisper-input/pull/21) — merged
- Tests: swift non disponible sur Linux — 46 tests inchanges (aucune modification Swift)
- Notes: Job smoke-test correct — needs:build-and-release, version extraction identique au job build, gh release download avec GH_TOKEN, hdiutil attach -nobrowse -noautoopen, verification Memo.app, codesign --verify --verbose, detach. Suggestion non-bloquante : ajouter un trap pour garantir hdiutil detach meme si codesign echoue (le runner est ephemere donc sans consequence pratique, mais serait plus robuste). Sprint 3 J2 Done, DoD item CI coche.

## 2026-05-05 — Sprint 3 J2 — CI smoke test DMG (coder)
- Objectif: Ajouter un job `smoke-test` dans release.yml : monte le DMG via hdiutil, verifie Memo.app, verifie la signature ad-hoc, demonte
- Statut: Done
- Tests: swift non disponible sur Linux — 46 tests inchanges (aucune modification Swift)
- Notes:
  - Job `smoke-test` ajoute dans `.github/workflows/release.yml`, apres `build-and-release` (needs: build-and-release).
  - Etapes : (1) checkout, (2) extract version (identique au job build), (3) `gh release download` avec GH_TOKEN pour telecharger le DMG publie, (4) `hdiutil attach -nobrowse -noautoopen` + parse mount point, (5) verifie presence de `Memo.app`, (6) `codesign --verify --verbose`, (7) `hdiutil detach`. Nettoyage garanti (detach dans le cas d'echec de l'assertion).
  - SPRINT_CURRENT.md : J2 marque Done, DoD item CI coche.

## 2026-05-04 — Sprint 3 J1 — Review (reviewer)
- Objectif: Valider la verification GitHub Pages, CTA DMG, et nettoyage branches orphelines
- Statut: LGTM
- Tests: swift non disponible sur Linux — 46 tests inchanges (aucune modification Swift)
- Notes: pages.yml confirme correct (configure-pages@v5, deploy-pages@v4, permissions minimales). docs/index.html CTA pointe vers releases/latest/download/Memo-v1.0.dmg (DMG v1.0 confirme 1.85 MB, 2 downloads). 4 branches orphelines non supprimees — bloquees par proxy 403 dans sandbox, aucun outil MCP de suppression de branche disponible. Blockers correctement documentes avec instructions humaines precises. Seuls fichiers memory/ modifies. SESSION_LOG et SPRINT_CURRENT mis a jour. LGTM — blockers sont des contraintes environnementales, pas des echecs d'implementation.

## 2026-05-04 — Sprint 3 J1 — GitHub Pages verification + branch cleanup (coder)
- Objectif: Verifier GitHub Pages, verifier CTA DMG, supprimer 5 branches orphelines
- Statut: Partiellement bloque (humain)
- Tests: swift non disponible sur Linux — 46 tests inchanges (aucune modification Swift)
- Notes:
  - pages.yml confirme correct sur main (uses actions/configure-pages@v5 + actions/deploy-pages@v4, deploie docs/, permissions minimales OK).
  - Dernier commit touchant docs/ : 313ac9e (2026-04-30, favicon update) — pages.yml aurait du etre declenche si Pages est active via "GitHub Actions" source.
  - CTA docs/index.html verifie : pointe vers releases/latest/download/Memo-v1.0.dmg — correct (release v1.0 confirme avec DMG 1.85 MB, 2 downloads).
  - 4 branches orphelines trouvees sur remote : claude/affectionate-cerf-gMClj, claude/tender-einstein-QyVHC, claude/affectionate-cerf-DWEYt, claude/affectionate-cerf-PScAP. (5eme claude/affectionate-cerf-26dE4 n'existe plus.)
  - BLOCKERS HUMAIN :
    1. Verifier GitHub Pages actif : Settings > Pages > Source = "GitHub Actions". Si inactif, activer et lancer workflow_dispatch sur pages.yml.
    2. Confirmer URL live : https://amadoug2g.github.io/whisper-input/ dans un navigateur.
    3. Supprimer les 4 branches orphelines (push --delete bloque par proxy 403 dans cet environnement) :
       git push origin --delete claude/affectionate-cerf-gMClj claude/tender-einstein-QyVHC claude/affectionate-cerf-DWEYt claude/affectionate-cerf-PScAP

## 2026-05-04 — Weekly Strategic Review (manager)
- Objectif: Revue strategique hebdomadaire — cloture Sprint 2, lancement Sprint 3
- Statut: Review completee
- Tests: N/A
- Notes:
  - **Deadline 30 avril 2026 : RESPECTEE.** Memo v1.0 publie le 29 avril (GitHub Release id 315149842, Memo-v1.0.dmg 1.85 MB).
  - Sprint 2 : entierement clos, archive dans memory/sprints/sprint-02/ (SPRINT_REVIEW, RETRO, PLAN). DoD 6/6.
  - Local main mis a jour (etait 13 commits derriere remote, fast-forward vers 00cca63).
  - **Sprint 3 demarre : "Post-Release Polish"** (4-11 mai, 1 semaine).
  - Backlog Sprint 3 : J1=GitHub Pages verification + branch cleanup, J2=smoke test DMG CI, J3=release body enrichi, J4=README screenshots, J5=review+retro.
  - DAILY_GOAL : verifier GitHub Pages + nettoyer branches orphelines (4 branches a supprimer).
  - **Aucune urgence deadline** — focus qualite, CI hardening, polish.
  - 5 branches orphelines identifiees sur remote a nettoyer (4 anciennes + claude/affectionate-cerf-26dE4 post-merge).
  - PR #19 creee et mergee (squash) dans main : Sprint 3 setup (commit 6865913).
  - DAILY_GOAL mis a jour avec 5eme branche a nettoyer.

## 2026-05-01 — Post-Sprint 2 — Verification (reviewer)
- Objectif: Valider la session post-deadline du coder (documentation et SESSION_LOG)
- Statut: LGTM
- Tests: swift non disponible sur Linux — 46 tests inchanges (aucune modification Swift)

## 2026-05-01 — Post-Sprint 2 — Verification et documentation finale (coder)
- Objectif: Verifier l'etat du projet post-deadline, s'assurer que tout est documente et la branche a jour
- Statut: Done
- Tests: swift non disponible sur Linux — 46 tests inchanges (aucune modification Swift)
- Notes: Sprint 2 entierement clos. Branche claude/tender-einstein-Tjlvc a jour avec commit b8d0570 (SPRINT_REVIEW, RETRO, PLAN DoD). Aucune action restante pour l'agent — seule verification humaine restante : confirmer GitHub Pages dans un navigateur (https://amadoug2g.github.io/whisper-input/). Memo v1.0 est public (GitHub Release id 315149842, Memo-v1.0.dmg 1.85 MB).

## 2026-04-30 — Sprint 2 J4 (DEADLINE) — Review (reviewer)
- Objectif: Valider la confirmation GitHub Release v1.0 et cloturer Sprint 2
- Statut: LGTM
- Tests: swift non disponible sur Linux — 46 tests inchanges (aucune modification Swift)
- Notes: GitHub Release v1.0 CONFIRME (id 315149842, Memo-v1.0.dmg 1.85 MB, publie 2026-04-29T11:39:02Z, 1 download). Seuls memory/ modifies (CODER_SUMMARY, ROADMAP, SESSION_LOG, SPRINT_CURRENT). Sprint 2 clos avant la deadline du 30 avril 2026. Reste humain : verifier GitHub Pages dans un navigateur.

## 2026-04-30 — Sprint 2 J4 (DEADLINE) — Confirmation release v1.0 (coder)
- Objectif: Confirmer GitHub Release v1.0 live + DMG attache, cloturer Sprint 2
- Statut: Done
- Tests: swift non disponible sur Linux — 46 tests inchanges (aucune modification Swift)
- Notes:
  - GitHub Release v1.0 CONFIRME via MCP GitHub : id 315149842, tag v1.0, publie 2026-04-29T11:39:02Z, cree par github-actions[bot].
  - DMG confirme : Memo-v1.0.dmg, 1.85 MB (1853348 octets), state=uploaded, sha256:3e83d3e3b13fe0fba5e7d96d9e18f617bc13e4e9df3406ba307be76d47eda9f6, 1 telechargement.
  - Release URL : https://github.com/amadoug2g/whisper-input/releases/tag/v1.0
  - DMG URL : https://github.com/amadoug2g/whisper-input/releases/download/v1.0/Memo-v1.0.dmg
  - SPRINT_CURRENT.md : DoD items GitHub Release et CTA coches.
  - Sprint 2 clos. Memo v1.0 est publiquement disponible avant la deadline du 30 avril 2026.
  - Reste humain : verifier GitHub Pages https://amadoug2g.github.io/whisper-input/ dans un navigateur.

## 2026-04-29 — Sprint 2 J3 — Review (reviewer)
- Objectif: Valider la session J3 — smoke test, diagnostic release, fix release.yml
- Statut: LGTM
- Tests: swift non disponible sur Linux — 46 tests inchanges (aucune modification Swift)
- Notes: Root cause correctement identifie (permissions:contents:write absent dans release.yml sur main au moment du tag push). Fix correct: permissions:write + workflow_dispatch + tag_name pour dispatch manuel. docs/index.html et pages.yml confirmes corrects. Actions humaines clairement documentees. Branche claude/tender-einstein-edD15 mergee dans main.

## 2026-04-29 — Sprint 2 J3 — GitHub Pages + smoke test + correctifs (coder)
- Objectif: Verifier GitHub Pages live, smoke test CTA liens, correctifs derniere minute
- Statut: Done (bloquants humain identifies)
- Tests: swift non disponible sur Linux — 46 tests inchanges (aucune modification Swift)
- Notes:
  - Tag v1.0 confirme sur remote (pointe vers e775ac1) via MCP GitHub. Releases: 0 (GitHub Release toujours absente).
  - Diagnostic: release.yml sur remote main (e775ac1) est l'ancienne version sans permissions:contents:write — c'est pourquoi la release n'a pas ete creee.
  - Fix confirme sur branche locale claude/tender-einstein-edD15 (commit e48b990): release.yml avec permissions:write + workflow_dispatch.
  - docs/index.html verifie : CTA pointe vers releases/latest/download/Memo-v1.0.dmg (correct), pages.yml present et correct.
  - ACTIONS REQUISES HUMAIN (dans l'ordre):
    1. Merger la PR de claude/tender-einstein-edD15 dans main (contient release.yml corrige)
    2. Depuis GitHub Actions UI > Release > Run workflow : version=1.0 pour creer la GitHub Release avec le DMG
    3. Verifier GitHub Pages : https://amadoug2g.github.io/whisper-input/ (necessite navigateur)

## 2026-04-28 — Sprint 2 J2 — Tag v1.0 (reviewer)
- Objectif: Valider la session J2 — confirmer etat tag/release, merger memory/ dans main
- Statut: ✅ LGTM
- Tests: swift non disponible sur Linux — 46 tests inchanges (aucune modification Swift)
- Notes: Release infrastructure confirmee correcte (release.yml trigger v*, macos-14, softprops/action-gh-release@v2, CHANGELOG.md, docs/index.html). Seul bloquant : push tag sandbox 403. ACTION REQUISE : `git push origin v1.0` depuis machine locale pour declencher release.yml.

## 2026-04-28 — Sprint 2 J2 — Tag v1.0 (coder)
- Objectif: Pousser le tag `v1.0` sur main pour declencher release.yml (GitHub Release + DMG)
- Statut: Bloque — tag local pret, push sandbox 403
- Tests: swift non disponible sur Linux — 46 tests inchanges (aucune modification Swift)
- Notes:
  - SPRINT_CURRENT.md corrige : DoD item 3 marque bloque (tag local OK, push sandbox 403).
  - Tag annote `v1.0` cree localement sur ff06f7f (HEAD de main remote).
  - Push bloque par proxy sandbox HTTP 403 — aucune modification de code Swift.
  - Action requise humain : `git push origin v1.0` depuis machine locale.
  - Une fois pousse, release.yml se declenche automatiquement (build DMG macos-14, publie GitHub Release).

## 2026-04-27 — Sprint 2 J1 — Review (reviewer)
- Objectif: Valider la pre-release checklist et merger les changements memory/ dans main
- Statut: ✅ LGTM
- PR: feat: Sprint 2 J1 — pre-release checklist complete, CHANGELOG v1.0 added
- Tests: swift non disponible sur Linux — 46 tests inchanges (aucune modification Swift)
- Notes: Tous les artefacts confirmes OK (.gitignore ligne 38, release.yml, pages.yml, docs/index.html CTA, ROADMAP.md, CHANGELOG.md cree). Sprint 2 J1 marque Done. Branche claude/tender-einstein-f2bwP mergee dans main.

## 2026-04-27 — Sprint 2 J1 — Pre-release checklist (coder)
- Objectif: Finaliser la pre-release checklist, verifier tous les artefacts de distribution, preparer le changelog
- Statut: Done
- Tests: swift non disponible sur Linux — 46 tests inchanges (aucune modification Swift)
- Notes:
  - Verification complete des artefacts : `.gitignore` (*.dmg ligne 38 OK), `release.yml` (trigger v*, macos-14, make dmg, softprops/action-gh-release@v2 OK), `pages.yml` (trigger push main + docs/**, permissions minimales OK), `docs/index.html` (CTA pointe vers releases/latest/download/Memo-v1.0.dmg OK), `ROADMAP.md` (items Sprint 1 coches OK).
  - `CHANGELOG.md` cree pour v1.0 (features, config, distribution, technique).
  - `SPRINT_CURRENT.md` : J1 marque Done.
  - `memory/sprints/sprint-02/PLAN.md` : DoD items 1 et 2 coches (*.dmg .gitignore + ROADMAP a jour).
  - Branche : `claude/tender-einstein-f2bwP`.
  - Prochain : J2 (28/04) — pousser le tag `v1.0` sur main.

## 2026-04-27 — Weekly Strategic Review (manager)
- Objectif: Revue strategique hebdomadaire — cloture Sprint 1, lancement Sprint 2
- Statut: ✅ Review completee
- Tests: N/A
- Notes:
  - **3 jours restants avant deadline (30 avril 2026)**
  - Sprint 1 termine (6/6 DoD). Archive dans `memory/sprints/sprint-01/`. Retro et review deja faites le 24/04.
  - Sprint 2 demarre : "Ship v1.0 Final Release" (27-30 avril, 3 jours).
  - ROADMAP.md mis a jour (items Sprint 1 tous coches, localisation FR reportee hors v1.0).
  - Backlog Sprint 2 : J1=pre-release checklist, J2=push tag v1.0, J3=verification Pages+liens.
  - **Risque principal** : release.yml jamais testee, pas de macOS pour smoke test.
  - **Decision** : regle #3 appliquee (deadline < 7 jours -> uniquement distribution).
  - **Aucun tag v1.0 pousse** — ca reste l'action critique de J2 (28 avril).
  - Branche courante : `claude/affectionate-cerf-gMClj` (meme commit que `main`).

## 2026-04-24
- Objectif: Sprint 1 J7 — Sprint Review + Retrospective
- Statut: ✅ Done
- Tests: swift non disponible sur Linux — 46 tests inchanges (aucune modification Swift)
- Notes: memory/sprints/sprint-01/SPRINT_REVIEW.md et RETRO.md crees (DoD 6/6, score sprint 23/25). *.dmg ajoute au .gitignore. SPRINT_CURRENT.md mis a jour (J7 Done, tous les DoD items coches). Sprint 1 termine — prochaines etapes: smoke test macOS, tag v1.0.

## 2026-04-21
- Objectif: GitHub Pages activation + README polish (Sprint 1 J4)
- Statut: ✅ LGTM
- Tests: swift non disponible sur Linux — 46 tests inchanges (aucune modification Swift)
- Notes: pages.yml cree — deploie docs/ sur GitHub Pages a chaque push sur main avec filtre path docs/**, plus workflow_dispatch. Permissions minimales (contents:read, pages:write, id-token:write), concurrency guard, actions a jour. README: badges CI/release/macOS/license, section Telecharger avec lien DMG direct, Screenshots placeholder (J5), make dmg dans les commandes, test count 27->46, roadmap mise a jour (DMG/release.yml/landing page coches). Suggestion non-bloquante: le filtre path docs/** sur pages.yml est intentionnel et correct; le lien DMG reste fixe a Memo-v1.0.dmg, coherent avec release.yml.

## 2026-04-20
- Objectif: Workflow `release.yml` (J2) + landing page `docs/index.html` (J3) — Sprint 1
- Statut: LGTM
- Tests: swift non disponible sur Linux — 46 tests inchanges (aucune modification Swift)
- Notes: release.yml declenche sur tag v*, version extraite via GITHUB_REF_NAME, make dmg VERSION=X, softprops/action-gh-release@v2 publie le DMG. Landing page HTML statique avec hero, features grid, how-it-works, download CTA vers releases/latest. Suggestion non-bloquante: CTA pointe vers Memo-v1.0.dmg en dur — pas de rupture pour v1.0 mais a mettre a jour pour les releases suivantes.

## 2026-04-17 — DMG Packaging Script (reviewer)
- Objectif: Creer `scripts/package-dmg.sh` + target `make dmg` (Sprint 1 J1)
- Statut: LGTM
- Tests: swift non disponible sur Linux — 46 tests inchanges (aucune modification Swift)
- Notes: Script bash correct, set -euo pipefail, nettoyage temp, validation mount. Suggestions non-bloquantes: (1) double appel make app (script + Makefile dep); (2) *.dmg absent du .gitignore.

## 2026-04-17 — Weekly Strategic Review #2 (manager)
- Objectif: Revue strategique complete — evaluation Sprint 1 et priorisation
- Statut: ✅ Review completee
- Tests: N/A
- Notes:
  - **Branche non mergee (CRITIQUE)** : 9 commits sur `claude/affectionate-cerf-UZCzX` toujours pas dans `main`. Inclut CI, sprint infra, weekly review. Bloquer numero 1.
  - Sprint 1 DoD : 1/6 items done (CI). DMG, release.yml, landing page, README, review tous a faire.
  - DMG script (`scripts/package-dmg.sh`) pas encore cree — reste J1 priorite haute.
  - Calendrier : J1=DMG(17/04), J2=release.yml(18/04), J3=landing(20/04), J4=README(21/04), J5=smoke(22/04), J7=review(24/04).
  - DAILY_GOAL mis a jour : DMG packaging + blocker merge branche ajoute.
  - **Blocker resolu** : PR #8 creee et mergee (squash) dans `main`. 10 commits integres. `main` est a jour.

## 2026-04-17 — Weekly Strategic Review (manager)
- Objectif: Revue stratégique hebdomadaire — évaluation progrès vs deadline
- Statut: ✅ Review complétée
- Tests: N/A
- Notes:
  - 13 jours restants avant deadline (30 avril 2026)
  - Sprint 1 (Ship v1.0-rc1) démarré aujourd'hui — backlog de 6 items
  - CI complété (1/6 DoD items done). DMG script = prochain item critique.
  - ROADMAP mis à jour (CI coché). SPRINT_CURRENT mis à jour (CI DoD coché).
  - Risque : 8 commits sur branche `claude/affectionate-cerf-UZCzX` pas encore mergés dans main.
  - DAILY_GOAL confirmé : DMG packaging script (J1, priorité haute, chemin critique).

## 2026-04-17
- Objectif: Créer un workflow GitHub Actions CI (swift test sur push/PR) + badge README
- Statut: ✅ LGTM
- PR: #7
- Tests: swift test non exécutable en local (Linux) — 46 tests attendus sur macos-14 via CI
- Notes: .github/workflows/ci.yml créé (macos-14, Keychain setup, swift test); badge CI ajouté au README; TestSetup.swift ajouté pour initialiser NSApplication.shared avant les tests AppKit

## 2026-04-16
- Objectif: Setup agent workflow (CLAUDE.md, agents, memory, CI)
- Statut: ✅ Setup initial complété — mergé sur main (PR #6)
- Tests: N/A (pas de Swift local, CI GitHub Actions configuré)
- Notes: .gitignore corrigé, agents créés, memory initialisée, .github/workflows/ci.yml créé
