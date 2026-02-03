# iOS App Wireframes (MVP)

Goal: Agent-style German learning from Berlin X posts with hourly notifications, auto-explanations, and flashcards.

## Navigation
- Tab 1: Feed
- Tab 2: Cards
- Tab 3: Sources
- Tab 4: Settings

---

## 1) Feed (通知履歴)

```
[Header]
Berlin Learning Feed
Today • 9:00–21:00 hourly

[Card: New]
Heute in Berlin:
Die Polizei bittet um Hinweise zu einem Vorfall am Alexanderplatz.
JP: 警察はアレクサンダープラッツの事件に関する情報提供を求めている。
Tags: police, incident
CTA: Open Detail

[Card]
Berlin Update:
Die BVG meldet eine Sperrung auf der U2.
JP: BVGはU2の運休を報告。
Tags: transport
CTA: Open Detail

[Bottom]
Floating action: Paste text / Add link
```

Notes
- 2文まで通知。Feedは通知履歴一覧。
- カードは短文＋簡易訳＋タグ。
- “Paste text / Add link” で手動取り込み。

---

## 2) Detail (文 + 解説)

```
[Header]
Sentence Detail
Source: @polizeiberlin • 12:00

[Sentence]
Die Polizei bittet um Hinweise zu einem Vorfall am Alexanderplatz.
JP: 警察はアレクサンダープラッツの事件に関する情報提供を求めている。

[Key Points]
- die Polizei (f.)
  Meaning: 警察
  Etymology: polizei (from Greek/Latin via French)

- um Hinweise bitten
  Meaning: 情報提供を求める
  Pattern: bitten um + Akk.
  Verb forms: bitten – bat – gebeten

- der Vorfall (m.)
  Meaning: 事件・出来事
  Etymology: Vor- + Fall

[Actions]
+ Add to Cards (auto)
Mark as Reviewed

[Mini Drill]
Q: der/die/das Vorfall?
A: der
```

Notes
- 語源 + 性は必須。
- 再帰/前置詞セット/過去形は該当時のみ表示。
- “Mini Drill” は1問だけ。

---

## 3) Cards (フラッシュカード)

```
[Header]
Cards
Filters: All / Due / New / Difficult

[Card View]
Front:
  der Verdächtige
  (Tap to flip)

Back:
  Meaning: 容疑者
  Gender: der
  Etymology: verdächtigen (to suspect)
  Example: Die Polizei sucht einen Verdächtigen.
  Past/Participle: (if verb)
  Prep Pattern: (if any)

[Actions]
Know / Unsure / Again
```

Notes
- 3ボタンで復習強度を記録。
- 例文は元の文脈から流用。

---

## 4) Sources (取得アカウント管理)

```
[Header]
Sources

[Source List]
@polizeiberlin   ON   Last sync: 10 min ago
@berlinerzeitung ON   Last sync: 40 min ago
@BVG            OFF

[Actions]
+ Add source
Reorder (drag)
Toggle ON/OFF
```

Notes
- いつでも追加/削除。
- ON/OFF で取得対象を切替。

---

## 5) Settings (通知・学習)

```
[Header]
Settings

Notifications
- Active: ON
- Time range: 9:00–21:00
- Frequency: Hourly
- Max sentences: 2

Learning
- Required fields: Meaning, Gender, Etymology
- Optional fields: Reflexive, Prepositions, Past forms
- Review intensity: Normal / Strong
```

Notes
- 通知強度やフィールド優先度を調整可能。

---

## Quick UX Principles
- Short, readable sentences only
- One-tap access to key info
- Always show gender + etymology
- Agent feel: “It knows what you need next”
