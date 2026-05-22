# Objectif du jour — 2026-05-19 (Sprint 4, J1)
**Issue GitHub :** #55

## Contexte sprint
Sprint 4 goal : Ship AI post-processing + local Whisper + CI refactor + onboarding.

## Tâche
Implémenter le service `PostProcessor` et l'UI settings pour le post-traitement AI (#55, jour 1/2).

Créer :
1. `Sources/Memo/Services/PostProcessor.swift` — protocole `PostProcessing` + implémentation
   - Envoie le texte transcrit + un prompt système à Claude API ou OpenAI API
   - Retourne le texte post-traité
   - Support des deux APIs (choix dans settings)
2. `Sources/Memo/Views/SettingsView.swift` — ajouter section "Post-processing" :
   - Dropdown de prompts prédéfinis (clean grammar, formal French, translate to English, bullet points, email format)
   - Champ texte pour prompt custom
   - Toggle enable/disable
   - Sélecteur API (Claude / OpenAI)
   - Champ clé API secondaire (si différente de Whisper)
3. Tests : `Tests/MemoTests/PostProcessorTests.swift` avec mock LLM

## Critères de succès
- [ ] `PostProcessor` service créé avec protocole injectable
- [ ] Settings UI avec prompts prédéfinis + custom
- [ ] Toggle enable/disable dans les settings
- [ ] Tests avec mock (au moins 4 tests)
- [ ] `make test` passe

## Fichiers concernés
- `Sources/Memo/Services/PostProcessor.swift` — à créer
- `Sources/Memo/Views/SettingsView.swift` — à modifier (nouvelle section)
- `Tests/MemoTests/PostProcessorTests.swift` — à créer

## Priorité
**Haute** — Feature revenue (#55). J1 de Sprint 4.
