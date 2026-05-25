# Objectif du jour -- 2026-05-26 (Sprint 5, J1)
**Issue GitHub :** #60

## Contexte sprint
Sprint 5 goal : Fix CI, complete onboarding, restructure CI/CD pipeline. Stabilize for real users.

## Tache
Corriger le CI pour que les deux jobs (Swift Tests + SwiftLint) passent au vert sur macOS-14.

Issue #60 documente le probleme : le pipeline CI (`ci.yml`) a deux jobs -- Swift Tests (build + test sur macos-14, Xcode 16.2, keychain de test) et SwiftLint. Le dernier fix connu (commit ae6be28) pin Xcode et bust le cache SPM, mais l'etat actuel doit etre verifie.

Actions :
1. Lire `.github/workflows/ci.yml` et verifier la config (Xcode pin, cache key, keychain setup)
2. Verifier si les derniers runs CI sur main sont verts ou rouges via MCP GitHub
3. Si rouge : diagnostiquer la root cause (stale cache, Xcode version, test failures, lint violations)
4. Appliquer le fix necessaire
5. Verifier que le fix passe en CI (PR + branch protection)

## Criteres de succes
- [ ] Job `test` passe au vert sur macOS-14
- [ ] Job `lint` passe au vert
- [ ] PR mergeable (branch protection satisfied)
- [ ] `make test` passe localement si Swift disponible

## Fichiers concernes
- `.github/workflows/ci.yml` -- configuration CI principale
- `Package.swift` -- dependances SPM (cache key)
- `Tests/MemoTests/` -- tests potentiellement en echec

## Priorite
**Haute** -- CI casse = bloquant numero 1 (regle de priorisation #1). Aucun autre travail ne peut etre merge tant que CI est rouge.
