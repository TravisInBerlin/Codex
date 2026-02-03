# Berlin German Coach (MVP Overview)

## Concept
An agent-style iOS app that auto-ingests short Berlin X posts, delivers hourly notifications (9–21), explains sentences with required etymology + gender, and builds flashcards for long-term retention.

---

## Core Experience
1) Auto-fetch short Berlin sentences
2) Notify hourly (max 2 sentences)
3) Tap to see explanation (meaning, gender, etymology)
4) Auto-generate flashcards
5) Review with simple Know/Unsure/Again

---

## Key Features
- Source list: user can add/remove/reorder accounts anytime
- Notification window: 9:00–21:00 every hour
- Required fields: meaning + gender + etymology
- Optional fields: reflexive, prepositions, past forms (only if present)
- Flashcards: auto-generated from extracted lexemes

---

## Screens
- Feed (notifications history)
- Detail (sentence + explanations)
- Cards (flashcards)
- Sources (account management)
- Settings (notification + learning preferences)

---

## Data Model (Essentials)
- Source → Post → Sentence → Lexeme → Card → Review
- Sentence is notification unit
- Lexeme includes meaning/gender/etymology

---

## LLM Prompt Rules
- Output JSON only
- Extract 2–5 key terms
- Always include gender + etymology
- Add grammar info only if in sentence

---

## Tech Stack (Suggested)
- iOS: SwiftUI
- DB: SQLite (GRDB) or Core Data
- Notifications: UNUserNotificationCenter
- Background: BGTaskScheduler
- Server: minimal API for ingestion + LLM

---

## MVP Milestones
1. App shell + DB
2. Sources management
3. Ingestion + LLM
4. Detail + explanations
5. Notifications
6. Flashcards + review
7. Polish + beta
