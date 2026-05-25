# Lessons Learned — Memo

Journal append-only. Ne jamais supprimer ou reecrire une entree.
Format : `## [Pattern|Antipattern]: <nom> — <date> — (coder|reviewer|manager|human)`

Les entrees marquees `[promote]` sont candidates pour le template `ai-project-launchpad`.

---

## Antipattern: .claude/ dans .gitignore — 2026-04-16 — human [promote]
**Context:** Setup initial du workflow agents.
**Observation:** Le `.gitignore` ignorait `.claude/`, rendant les fichiers agents invisibles pour git. Les agents n'auraient jamais ete versionnes ni partages entre sessions.
**Decision/Rule:** Toujours versionner `.claude/agents/` dans git. Seul `.claude/settings.local.json` (secrets locaux) doit etre ignore.
**Outcome:** Corrige au setup. Regle a appliquer des `init` dans tout nouveau projet.

## Antipattern: Modeles d'agents incorrects — 2026-04-16 — human [promote]
**Context:** Brief original utilisait `claude-opus-4` et `claude-sonnet-4-5`.
**Observation:** Ces IDs de modeles sont obsoletes/inexistants. Les agents ne demarrent pas avec des IDs invalides.
**Decision/Rule:** Toujours verifier les IDs de modeles dans la doc Anthropic. IDs corrects au 2026-04 : `claude-opus-4-6`, `claude-sonnet-4-6`.
**Outcome:** Corrige. A documenter dans le template launchpad avec note de mise a jour.

## Antipattern: Keychain verrouille en CI — 2026-04-17 — human [promote]
**Context:** GitHub Actions macOS runner, `swift test`.
**Observation:** Le login Keychain est verrouille par defaut sur GitHub Actions. `SecItemAdd` retourne `errSecInteractionNotAllowed`, faisant echouer silencieusement les tests qui ecrivent/lisent des secrets.
**Decision/Rule:** Toujours creer et deverrouiller un keychain de test dans le workflow CI avant `swift test`. Commande : `security create-keychain -p "" ci-test.keychain && security unlock-keychain`.
**Outcome:** Corrige dans `.github/workflows/ci.yml`.

## Antipattern: NSApplication non initialise dans swift test — 2026-04-17 — human [promote]
**Context:** Tests AppKit (NSPanel, NSWindow) dans un target `swift test` SPM.
**Observation:** `swift test` ne demarre pas de `NSApplication`. Les tests qui creent des panels ou appellent `NSApp.activate()` crashent ou retournent des tailles nulles.
**Decision/Rule:** Ajouter un `XCTestObservation` qui initialise `NSApplication.shared` avant tout test. Fichier : `Tests/*/TestSetup.swift`.
**Outcome:** Corrige via `TestSetup.swift`.

## Antipattern: Skip condition trop large dans DeploymentTests — 2026-04-17 — human
**Context:** `test_appBundle_hasBinary` en CI.
**Observation:** `Memo.app/Contents/Info.plist` est tracke dans git, donc `Memo.app/` existe en CI. Le skip etait base sur `bundlePath` (le dossier) au lieu de `binaryPath` (le binaire absent). Le test echouait au lieu de skiper.
**Decision/Rule:** Les skip conditions dans les DeploymentTests doivent verifier l'existence de l'artefact teste specifiquement, pas du dossier parent.
**Outcome:** Corrige dans `DeploymentTests.swift`.

## Pattern: Fallback SPRINT_CURRENT quand DAILY_GOAL est perime — 2026-05-12 — coder [promote]
**Context:** Sprint 3 J5 — DAILY_GOAL.md date du 04/05, mais nous sommes le 12/05. L'objectif J1 est deja partiellement bloque humain.
**Observation:** Quand la date dans DAILY_GOAL.md est anterieure a la date courante, le prochain item non fait est dans SPRINT_CURRENT.md (colonne Statut != Done). Se fier a DAILY_GOAL.md seul conduit a re-tenter un item deja documente comme bloque.
**Decision/Rule:** Toujours verifier SPRINT_CURRENT.md quand la date de DAILY_GOAL.md < date courante. Identifier le premier item avec Statut "A faire" ou vide — c'est l'objectif reel du jour.
**Outcome:** Applique — J5 (sprint review + retro) correctement identifie comme item restant et complete.

## Antipattern: Stale SPM cache after Xcode runner update — 2026-05-18 — manager [promote]
**Context:** CI "Swift Tests" job failing in ~14 seconds consistently. No Swift code changed. SwiftLint passing.
**Observation:** The macos-14 GitHub Actions runner updated its default Xcode version. The SPM `.build` cache (keyed by `Package.swift` hash only) was built with the previous Xcode. Swift tried to use stale build artifacts from an incompatible toolchain, causing instant build failures.
**Decision/Rule:** (1) Always pin Xcode version in CI via `xcode-select`. (2) Include Xcode version in the SPM cache key so runner image updates automatically bust the cache. (3) A build failure in <20 seconds almost always means toolchain mismatch or cache corruption, not a code error.
**Outcome:** Fixed in ci.yml. Xcode 16.2 pinned, cache key includes `xcode162` prefix. All 4 check runs green.

## Antipattern: Sprint DoD trop ambitieux — 2026-05-25 — manager [promote]
**Context:** Sprint 4 avait 4 items DoD (AI post-processing, Local Whisper, CI/CD split, Onboarding) pour 5 jours.
**Observation:** Seuls 2/4 items livres (50%). Le sprint a pivote mid-week vers App Store (#54, non planifie), laissant 2 items non commences. Le DoD n'a pas ete formellement mis a jour pour refleter le changement de priorite.
**Decision/Rule:** Max 3 items DoD par sprint. Si un pivot mid-sprint se produit, mettre a jour SPRINT_CURRENT.md immediatement pour refleter la realite. Les items deprioritises deviennent "Reporte" (pas "A faire").
**Outcome:** Sprint 5 planifie avec 3 DoD items + 1 cleanup (fermer PR #63).

## Antipattern: PR orpheline non fermee — 2026-05-25 — manager
**Context:** PR #63 (AI post-processing) creee le 20/05. Le travail a ete merge via d'autres commits/PRs.
**Observation:** La PR est restee ouverte 5 jours apres que le code a ete merge par un chemin alternatif. Cree de la confusion sur l'etat reel du projet.
**Decision/Rule:** Quand du travail est merge via un chemin alternatif a la PR originale, fermer la PR immediatement avec un commentaire expliquant que le travail est inclus dans main.
**Outcome:** PR #63 identifiee pour fermeture dans Sprint 5 J1.

## Antipattern: Branches orphelines sans auto-merge — 2026-04-16 — human [promote]
**Context:** Routines agents qui creent des PRs sans les merger.
**Observation:** Sans auto-merge dans le reviewer, les branches s'accumulent (6 branches apres 2 jours). L'humain doit intervenir pour merger -> casse l'autonomie du systeme.
**Decision/Rule:** Le reviewer doit toujours : creer la PR -> merger immediatement (squash) -> supprimer la branche. Cycle ferme sans intervention humaine.
**Outcome:** Corrige dans `reviewer.md`.
