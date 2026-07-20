# Architecture

## Principles

- Local-first: recording a visit never requires network access.
- Visit is the source of truth: a place score is derived from its visits.
- Provider boundaries: Google Places, map display, sync and AI remain replaceable services.
- Evidence-backed recommendation: results explain which visits, tags and scores caused the ranking.
- Private by default: sharing creates an explicit projection instead of exposing raw visit data.

## Layers

```text
SwiftUI feature views
        ↓
SwiftData Place / Visit models
        ↓
TasteMapCore score and search domain logic

Future adapters:
PlacesProvider · SyncClient · ImageStore · QueryInterpreter
```

## Data model

`Place` owns stable location identity and a collection of `Visit` records. `Visit` owns the subjective data: score, revisit intent, context tags, note and timestamp. Collections should initially be computed from these records; explicit saved collections can be introduced when sharing arrives.
