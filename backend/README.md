# BerlinCoach API (Local)

## Setup

```bash
python3 -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt
```

## Run

```bash
uvicorn main:app --reload --port 8000
```

## DB (SQLite)

Default path:
```text
backend/berlincoach.sqlite
```

You can override with:
```bash
export DB_PATH="/custom/path/berlincoach.sqlite"
```

Tables created:
- sentences
- lexemes
- cards

## X API Setup

```bash
export X_BEARER_TOKEN="YOUR_TOKEN_HERE"
# optional
export X_BASE_URL="https://api.x.com/2"
```

## LLM (Ollama) Setup

```bash
# Install and run Ollama, then pull a model
# https://ollama.com
ollama pull llama3.1
export OLLAMA_BASE_URL="http://localhost:11434"
export OLLAMA_MODEL="llama3.1"
export USE_LLM=1
```

## Backfill Translations

If existing sentences show "(未翻訳)", you can backfill them:

```bash
curl -X POST "http://localhost:8000/admin/backfill-translations?limit=30"
```

## Abbreviation Tuning (Optional)

You can add extra abbreviations to avoid sentence splitting.

```bash
export ABBREVIATIONS_EXTRA="vgl.,z.T.,sog."
```

## Abbreviation API (Optional)

```bash
curl http://localhost:8000/settings/abbreviations
curl -X PUT http://localhost:8000/settings/abbreviations \\
  -H \"Content-Type: application/json\" \\
  -d '{\"abbreviations\":[\"vgl.\",\"z.T.\",\"sog.\"]}'
```

## Debug RSS Logging (Optional)

```bash
export DEBUG_RSS=1
```

## Notes
- This is a mock-backed API for local development.
- Endpoints follow the MVP API design in docs.
- RSS sources are enabled by default in `main.py` (Berlin.de police, Berliner Zeitung Polizei, ADFC Berlin).
