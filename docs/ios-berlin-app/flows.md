# Screen Flows (MVP)

Goal: Agent-style German learning from Berlin X posts with hourly notifications, auto-explanations, and flashcards.

## Global Navigation
- Tabs: Feed / Cards / Sources / Settings
- Notification tap always opens Detail
- Floating action on Feed: Paste text / Add link

---

## Flow A: Auto Notification -> Detail -> Review

1. User receives notification (9:00–21:00, hourly)
2. Tap notification
3. Detail opens (Sentence + Explanation)
4. User taps "Mark as Reviewed"
5. System records review timestamp and updates card schedule

---

## Flow B: Feed -> Detail -> Card Auto-Create

1. Open app
2. Feed shows latest sentence cards
3. Tap a card
4. Detail opens
5. App auto-creates cards for extracted words/phrases
6. User can optionally pin a word (favorite)

---

## Flow C: Manual Import (Paste / Link)

1. Tap floating action on Feed
2. Choose: Paste text / Add link
3. Input screen
   - Paste text (X post or short paragraph)
   - Or paste URL
4. Confirm
5. System processes text with LLM
6. New sentence appears at top of Feed

---

## Flow D: Cards Review Session

1. Open Cards tab
2. Select filter: Due / New / Difficult
3. Review cards
   - Front: German term
   - Tap to flip
   - Back: meaning, gender, etymology, optional grammar
4. Rate: Know / Unsure / Again
5. Schedule next review based on rating

---

## Flow E: Manage Sources

1. Open Sources tab
2. See list of accounts
3. Toggle ON/OFF
4. Reorder by drag
5. Add source
   - Enter handle
   - Validate (light check)
   - Save
6. Remove source

---

## Flow F: Settings

1. Open Settings tab
2. Notifications
   - ON/OFF
   - Time range: 9:00–21:00
   - Frequency: Hourly
   - Max sentences: 2
3. Learning
   - Required fields: Meaning, Gender, Etymology
   - Optional fields: Reflexive, Prepositions, Past forms
4. Save

---

## Error / Edge Flows

- Source fetch fails
  - Show toast: "Sync failed"
  - Keep previous cache

- LLM returns no candidates
  - Show message: "No suitable sentence found"

- Duplicate sentence
  - Skip or merge with existing

- Very long post
  - Auto-trim to 1-2 sentences

---

## State Summary

Feed Card states
- New
- Reviewed
- Saved

Card states
- New
- Due
- Learned

Notification states
- Scheduled
- Delivered
- Opened
