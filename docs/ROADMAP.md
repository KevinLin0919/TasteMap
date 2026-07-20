# Product roadmap

## Product loop

```text
加入地點 → 記錄一次造訪 → 累積個人口味 → 情境搜尋 → 分享推薦 → 再次造訪
```

## M1 — Offline personal journal

- SwiftData local-first models
- Seed places and visits
- Footprints, map, collections, search
- Add visit flow and place detail
- Tested score/search domain logic

## M2 — Real place intake

- Google Maps Share Extension
- Paste a Google Maps URL
- Places provider protocol and Google Places adapter
- Store durable external place ID; refresh display data under provider policy
- Duplicate detection and manual place creation

## M3 — Personal recommendation

- Structured filters: district, budget, category, context and minimum score
- Visit-time and companion context
- Pairwise score calibration
- Explainable ranking with evidence from visits
- Optional LLM query parser behind a provider interface

## M4 — Sync and sharing

- Sign in with Apple
- VPS API, encrypted transport and conflict-safe sync
- Image upload and thumbnail pipeline
- Explicit public recommendation cards and lists
- Data export and account deletion

## M5 — Product hardening

- Offline queue and retry
- Observability, crash reporting and privacy review
- Accessibility, localization and dark mode audit
- App Store assets, TestFlight and beta feedback loop
