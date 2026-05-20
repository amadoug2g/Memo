Itération: 1
Statut: BLOQUANT

Session 2026-05-20 — AI post-processing J2 : câblage PostProcessor dans AppState + bouton Polish (#55, J2)

## Problème bloquant

**PostProcessingAPI preference ignorée au runtime — la sélection "Anthropic (Claude Haiku)" est non-fonctionnelle.**

Fichier: `Sources/Memo/Models/AppState.swift` ligne 105
Fichier: `Sources/Memo/Services/PostProcessor.swift` ligne 92 et 102

### Description

`PostProcessor` stocke son `api: PostProcessingAPI` comme constante immuable (`private let api`) fixée à la construction. `AppState.init()` crée `PostProcessor()` une seule fois avec la valeur par défaut `.openAI`. Même si l'utilisateur sélectionne "Anthropic (Claude Haiku)" dans les Settings et sauvegarde, le `postProcessor` stocké dans `AppState` pointe toujours vers OpenAI — le code path Claude est inaccessible en production.

La préférence `postProcessingAPI` est chargée depuis UserDefaults et reflétée dans l'UI, mais elle n'est **jamais passée au service PostProcessor** lors de son instanciation ni lors des appels.

### Preuve

```swift
// AppState.swift ligne 105 — PostProcessor toujours créé avec .openAI par défaut
postProcessor: any PostProcessing = PostProcessor(),
```

```swift
// AppDelegate.swift ligne 10 — AppState créé sans argument
let appState = AppState()
// → PostProcessor(api: .openAI) immuable, peu importe ce que choisit l'utilisateur
```

```swift
// PostProcessor.swift ligne 92+102 — api figée à l'init
private let api: PostProcessingAPI  // impossible à changer après init
init(api: PostProcessingAPI = .openAI) { self.api = api }
```

### Action requise

Rendre le service PostProcessor réactif à `postProcessingAPI`. Deux approches acceptables :

**Option A (recommandée)** — Passer l'API au moment de l'appel en paramètre du protocole :
```swift
// Modifier le protocole
protocol PostProcessing: AnyObject {
    func process(text: String, prompt: String, apiKey: String, api: PostProcessingAPI) async throws -> String
}
// PostProcessor n'a plus besoin de stocker api
// AppState passe appState.postProcessingAPI à chaque appel
```

**Option B** — Créer un nouveau PostProcessor à chaque appel avec l'API courante :
```swift
// Dans transcribe() et applyPostProcessing()
let processor = PostProcessor(api: postProcessingAPI)
let result = try? await processor.process(text: text, prompt: systemPrompt, apiKey: apiKey)
```

**Option C** — Exposer une var settable sur le protocole et la mettre à jour avant chaque appel (moins propre, mais acceptable).

L'option A est préférable car elle préserve la testabilité via MockPostProcessor, élimine l'état mutable dans PostProcessor, et rend l'intention explicite dans les appels.

---

## Points corrects (non-bloquants)

- `isPostProcessing @Published` + ProgressView "Polishing…" dans TranscriptionView : correct
- Bouton Polish (`wand.and.sparkles`) conditionnel sur `postProcessingEnabled` : correct
- `applyPostProcessing()` : guard `isEditing && !isPostProcessing`, capture de `inputText` avant Task, defer `isPostProcessing = false` : correct
- Auto post-process dans `transcribe()` avec `try?` silencieux (dégradation gracieuse) : correct
- `resolvedPostProcessingPrompt` (preset vs custom) : correct
- `resolvedPostProcessingAPIKey` (fallback sur openAIApiKey) : correct
- 8 tests AppStateTests couvrant les nouveaux comportements : logiquement corrects
- MockPostProcessor dans Mocks.swift : correct
