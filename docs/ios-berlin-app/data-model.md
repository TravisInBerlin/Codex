# Data Model (MVP)

Goal: Auto-ingest short sentences from sources, generate explanations, notify hourly, and maintain flashcards.

---

## Entities

### 1) Source
- Represents a feed account (X handle)
- User can add/remove/enable/disable

Fields
- id (uuid)
- handle (string) e.g. "polizeiberlin"
- enabled (bool)
- display_name (string, optional)
- last_sync_at (datetime, optional)
- created_at (datetime)
- updated_at (datetime)

---

### 2) Post
- Raw fetched content from sources
- Used for sentence extraction

Fields
- id (uuid)
- source_id (uuid, FK -> Source)
- external_id (string)  // X post id
- text (string)
- lang (string)
- fetched_at (datetime)
- created_at (datetime)

---

### 3) Sentence
- Short learning unit used for notifications

Fields
- id (uuid)
- post_id (uuid, FK -> Post)
- text_de (string)
- text_ja (string)
- tags (string[]) e.g. ["police", "transport"]
- selected_for_notify (bool)
- created_at (datetime)

---

### 4) Explanation
- Enriched data for a sentence

Fields
- id (uuid)
- sentence_id (uuid, FK -> Sentence)
- summary_ja (string)
- created_at (datetime)

---

### 5) Lexeme
- Term or phrase extracted from a sentence

Fields
- id (uuid)
- sentence_id (uuid, FK -> Sentence)
- text_de (string)
- meaning_ja (string)
- gender (string) // der/die/das/none
- etymology (string)
- pos (string) // noun/verb/adj/phrase
- is_reflexive (bool)
- preposition_pattern (string, optional) // e.g. "bitten um + Akk"
- verb_forms (string, optional) // e.g. "bitten – bat – gebeten"
- example_de (string, optional)
- example_ja (string, optional)
- created_at (datetime)

---

### 6) Card
- Flashcard generated from Lexeme

Fields
- id (uuid)
- lexeme_id (uuid, FK -> Lexeme)
- front (string)
- back (string)
- status (string) // new/due/learned
- ease (float) // default 2.5
- interval_days (int)
- due_at (datetime)
- last_reviewed_at (datetime, optional)
- created_at (datetime)

---

### 7) Review
- One review event

Fields
- id (uuid)
- card_id (uuid, FK -> Card)
- rating (string) // know/unsure/again
- reviewed_at (datetime)

---

### 8) NotificationSchedule
- User preferences for notifications

Fields
- id (uuid)
- active (bool)
- start_hour (int) // 9
- end_hour (int) // 21
- max_sentences (int) // 2
- timezone (string)
- created_at (datetime)
- updated_at (datetime)

---

## Relationships
- Source 1..N Post
- Post 1..N Sentence
- Sentence 1..N Lexeme
- Lexeme 1..1 Card (auto-create)
- Card 1..N Review
- Sentence 1..1 Explanation

---

## Notes
- Sentence is the unit for notifications.
- Lexeme entries always include meaning + gender + etymology.
- Verb/adj grammar fields are optional and only filled when detected.
- Cards are auto-generated from Lexemes and scheduled with a simple SM-2 style system.
