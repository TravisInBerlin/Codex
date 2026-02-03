# Implementation Plan (MVP)

Goal: iOS app that auto-ingests Berlin X posts, sends hourly notifications with short sentences, and provides flashcards with etymology + gender.

---

## Suggested Stack

- iOS: Swift + SwiftUI
- Local DB: SQLite (via GRDB) or Core Data
- Background tasks: BGTaskScheduler
- Notifications: UNUserNotificationCenter
- LLM: server-side (recommended) or on-device proxy
- Server: minimal API (FastAPI / Node) + scheduler

---

## Milestones

### 1) App Shell
- Tabs: Feed / Cards / Sources / Settings
- Routing + basic UI

### 2) Data Layer
- Local DB schema
- Models: Source, Sentence, Lexeme, Card
- Simple repository layer

### 3) Sources
- Add / remove / toggle sources
- Sync status UI

### 4) Ingestion
- Manual paste input
- Server API integration
- Cache new sentences

### 5) Detail + Lexeme View
- Render sentence + JP + explanation
- Show grammar extras only if present

### 6) Notifications
- Schedule hourly (9–21)
- Max 2 sentences
- Tap opens Detail

### 7) Flashcards
- Review flow (Know/Unsure/Again)
- Apply review algorithm
- Due filtering

### 8) Polish
- Empty states
- Error handling
- Copy/Share actions

---

## Server Plan (minimal)

- /ingest/auto: fetch posts from enabled sources
- /ingest: manual input
- /sentences: recent list
- /sentences/{id}: detail with lexemes
- /cards: review endpoints

---

## Risk Notes

- X API access may require paid plan
- Need fallback ingestion (RSS/news) or manual paste
- Notification schedule must respect iOS limits

---

## Timeline (rough)

- Week 1: App shell + DB + Sources
- Week 2: Ingestion + Detail + LLM integration
- Week 3: Notifications + Flashcards
- Week 4: Polish + Beta
