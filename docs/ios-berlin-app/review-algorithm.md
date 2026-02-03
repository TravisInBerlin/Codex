# Review Algorithm (MVP)

Goal: Simple and effective flashcard scheduling for German lexemes.

---

## Approach
Use a light SM-2 style system with 3 ratings: Know / Unsure / Again.

- `ease` starts at 2.5
- `interval_days` starts at 0
- `due_at` is calculated based on rating

---

## Rating Rules

### 1) Again
- interval_days = 0
- due_at = now + 10 minutes
- ease = max(1.3, ease - 0.2)

### 2) Unsure
- interval_days = max(1, round(interval_days * 0.9))
- due_at = now + interval_days days
- ease = max(1.3, ease - 0.05)

### 3) Know
- if interval_days == 0:
  - interval_days = 1
- else if interval_days == 1:
  - interval_days = 3
- else:
  - interval_days = round(interval_days * ease)
- due_at = now + interval_days days
- ease = min(2.7, ease + 0.1)

---

## Status Mapping

- new: never reviewed
- due: due_at <= now
- learned: interval_days >= 21 (optional threshold)

---

## Example

Initial state
- ease: 2.5
- interval_days: 0

User taps Know
- interval_days: 1
- due_at: tomorrow

Next review: Know
- interval_days: 3
- due_at: +3 days

---

## Notes
- Keep it simple for MVP
- Can later add daily cap or streak-based boost
- Ratings should be quick, 1 tap only
