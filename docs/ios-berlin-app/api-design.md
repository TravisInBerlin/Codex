# API Design (MVP)

Goal: Ingest X posts, extract short sentences, enrich with LLM, notify hourly, and manage flashcards.

---

## Overview

- Fetch sources periodically
- Extract 1–2 short sentences
- Enrich with LLM and store
- Schedule hourly notifications
- Provide card review endpoints

---

## 1) Source Management

### GET /sources
Returns list of sources

Response
```json
[
  {
    "id": "uuid",
    "handle": "polizeiberlin",
    "enabled": true,
    "last_sync_at": "2026-02-02T11:00:00Z"
  }
]
```

### POST /sources
Add a source

Request
```json
{
  "handle": "berlinerzeitung"
}
```

### PATCH /sources/{id}
Update source (enable/disable, rename)

Request
```json
{
  "enabled": false
}
```

### DELETE /sources/{id}
Remove source

---

## 2) Ingestion

### POST /ingest
Manual input (text or URL)

Request
```json
{
  "text": "Die Polizei bittet um Hinweise...",
  "source": "manual"
}
```

### POST /ingest/auto
Fetch latest posts from enabled sources

Response
```json
{
  "fetched": 12,
  "stored": 4
}
```

---

## 3) Sentence & Explanation

### GET /sentences
Returns recent sentences for Feed

Response
```json
[
  {
    "id": "uuid",
    "text_de": "Die Polizei bittet um Hinweise...",
    "text_ja": "警察は情報提供を求めている。",
    "tags": ["police"],
    "created_at": "2026-02-02T10:00:00Z"
  }
]
```

### GET /sentences/{id}
Returns sentence detail with explanation + lexemes

Response
```json
{
  "sentence": { "id": "uuid", "text_de": "...", "text_ja": "..." },
  "explanation": { "summary_ja": "..." },
  "lexemes": [
    {
      "text_de": "die Polizei",
      "meaning_ja": "警察",
      "gender": "die",
      "etymology": "...",
      "pos": "noun"
    }
  ]
}
```

---

## 4) Cards

### GET /cards
Query cards by status

Params
- status: new|due|learned

Response
```json
[
  {
    "id": "uuid",
    "front": "der Vorfall",
    "back": "意味/性/語源...",
    "status": "due",
    "due_at": "2026-02-03T09:00:00Z"
  }
]
```

### POST /cards/{id}/review
Record review result

Request
```json
{
  "rating": "know"
}
```

Response
```json
{
  "next_due_at": "2026-02-06T09:00:00Z",
  "status": "learned"
}
```

---

## 5) Notifications

### GET /notifications/schedule

Response
```json
{
  "active": true,
  "start_hour": 9,
  "end_hour": 21,
  "max_sentences": 2
}
```

### PATCH /notifications/schedule

Request
```json
{
  "active": true,
  "start_hour": 9,
  "end_hour": 21,
  "max_sentences": 2
}
```

---

## Internal Jobs

- Fetch job: every 15–30 minutes
- LLM enrichment: on new sentence
- Notification job: hourly between 9–21 local time

---

## Notes

- /ingest/auto requires auth to X API or scraper proxy
- When LLM yields no useful sentence, mark as skipped
- Use caching for recent sentences
