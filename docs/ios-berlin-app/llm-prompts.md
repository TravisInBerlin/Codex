# LLM Prompt Design (MVP)

Goal: From a short German sentence, extract learning-ready explanations with required fields (meaning, gender, etymology) and optional grammar details.

---

## Output Format (JSON)

```json
{
  "sentence": {
    "text_de": "",
    "text_ja": "",
    "tags": [""],
    "summary_ja": ""
  },
  "lexemes": [
    {
      "text_de": "",
      "meaning_ja": "",
      "gender": "der|die|das|none",
      "etymology": "",
      "pos": "noun|verb|adj|phrase|other",
      "is_reflexive": true,
      "preposition_pattern": "",
      "verb_forms": "",
      "example_de": "",
      "example_ja": ""
    }
  ]
}
```

---

## System Prompt (Core)

You are a German language coach for a Japanese learner living in Berlin.
Your job: explain short German sentences in a friendly, concise, and practical way.
Always provide meaning, grammatical gender, and a short etymology for each noun or key term.
Only include reflexive or preposition patterns when they appear in the sentence.
Only include verb forms when the verb appears in the sentence.
Keep explanations short and clear for quick review.

---

## User Prompt Template

INPUT (German sentence):
"{TEXT_DE}"

Task:
1) Translate the sentence into Japanese.
2) Select 2-5 key terms/phrases that are useful for daily learning.
3) For each key term/phrase, provide:
   - meaning in Japanese
   - gender (der/die/das or none)
   - short etymology (1 short line)
   - part of speech
   - if reflexive, mark is_reflexive true
   - if a verb/adj takes a fixed preposition, include preposition_pattern
   - if verb appears, include its past form and past participle
4) Output strictly in JSON using the provided schema.

Constraints:
- Required fields: meaning_ja, gender, etymology
- Optional fields only if relevant
- Keep etymology short and not academic
- Use Berlin context tags if possible (police, transport, politics, events)

---

## Example

INPUT:
"Die Polizei bittet um Hinweise zu einem Vorfall am Alexanderplatz."

OUTPUT:
```json
{
  "sentence": {
    "text_de": "Die Polizei bittet um Hinweise zu einem Vorfall am Alexanderplatz.",
    "text_ja": "警察はアレクサンダープラッツの事件に関する情報提供を求めている。",
    "tags": ["police", "events"],
    "summary_ja": "警察が事件について情報提供を求めている。"
  },
  "lexemes": [
    {
      "text_de": "die Polizei",
      "meaning_ja": "警察",
      "gender": "die",
      "etymology": "ギリシャ語→ラテン語経由で警察組織を指す語。",
      "pos": "noun",
      "is_reflexive": false,
      "preposition_pattern": "",
      "verb_forms": "",
      "example_de": "Die Polizei ermittelt.",
      "example_ja": "警察が捜査している。"
    },
    {
      "text_de": "um Hinweise bitten",
      "meaning_ja": "情報提供を求める",
      "gender": "none",
      "etymology": "bitten（頼む）+ um（〜を求めて）。",
      "pos": "phrase",
      "is_reflexive": false,
      "preposition_pattern": "bitten um + Akk.",
      "verb_forms": "bitten – bat – gebeten",
      "example_de": "Wir bitten um Hinweise.",
      "example_ja": "情報提供をお願いします。"
    },
    {
      "text_de": "der Vorfall",
      "meaning_ja": "事件・出来事",
      "gender": "der",
      "etymology": "vor（前）+ Fall（出来事）。",
      "pos": "noun",
      "is_reflexive": false,
      "preposition_pattern": "",
      "verb_forms": "",
      "example_de": "Der Vorfall wurde gemeldet.",
      "example_ja": "その事件が報告された。"
    }
  ]
}
```

---

## Detection Rules (short)
- Nouns: always include gender + short etymology
- Verbs: include past forms only if verb present
- Reflexive: set is_reflexive true if verb uses "sich"
- Prepositions: include fixed pattern only when required by verb/adj
- Limit lexemes to 2-5 for readability
