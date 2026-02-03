# Codex Playground 🎮✨🚀

Welcome to my little Codex-powered playground! 🎉
This repo is where I mess around, explore ideas, and build fun things with Codex. 🧪🛠️

## What's This? 🤔💡
- A personal sandbox for experimenting with Codex
- A place to build random, useful, and sometimes silly stuff
- A growing collection of mini projects, cheatsheets, and creative experiments

## Current Vibes 🌈🎨
- Hands-on learning by building
- Trying new UI styles and layouts
- Keeping things playful, practical, and fast to iterate

## Why It Exists 🧭💬
Because making things is fun, and Codex makes it even more fun. 🧡
This repo is my space to try ideas without pressure and keep shipping tiny wins. 🏃‍♀️💨

## Status 📌
Always evolving. Always tinkering. 🧩🔁

---

Thanks for stopping by! 👋😄
# BerlinCoach Setup Guide

This project uses a local backend + Ollama on the Mac (host) and an iOS client on iPhone.
Below is a step‑by‑step guide for both sides so anyone can run it.

## 1) Mac (Host) Setup

### Requirements
- Python 3.12+ (venv)
- Ollama (local LLM)
- Tailscale (for iPhone access)
- Xcode (for iOS build)

### Backend: start API server
```bash
cd /Users/Tatsuya/書類/git/Codex/backend
source .venv/bin/activate
export USE_LLM=1
export OLLAMA_BASE_URL="http://127.0.0.1:11434"
export OLLAMA_MODEL="gemma3:4b"
uvicorn main:app --reload --host 0.0.0.0 --port 8000
```

### Ollama: start server + model
In another terminal:
```bash
ollama serve
ollama pull gemma3:4b
```

#### Where the model is specified
- `OLLAMA_MODEL` env var (example above)
- Default in code: `backend/main.py` (uses `OLLAMA_MODEL`)

### Tailscale: enable for iPhone access
```bash
sudo tailscale up
tailscale status
tailscale serve --bg http://localhost:8000
```

Your Tailnet URL will look like:
```
https://<your-mac>.tail<id>.ts.net
```

## 2) iPhone Setup

### Tailscale
1. Install Tailscale on iPhone
2. Sign in to the same Tailnet
3. Keep VPN ON (required for access)

### App API URL
The iOS app uses the Tailnet URL:
```
BerlinCoach/AppEnvironment.swift
```
Update `apiBaseURL` if your Tailnet hostname changes.

### Build in Xcode
1. Open `BerlinCoach.xcodeproj`
2. Set signing team if needed
3. Run on device

## 3) Common Commands

### Fetch new RSS immediately
```bash
curl -X POST "http://localhost:8000/ingest/auto"
```

### Backfill translations
```bash
curl -X POST "http://localhost:8000/admin/backfill-translations?limit=50"
```

### Backfill lexemes (keywords)
```bash
curl -X POST "http://localhost:8000/admin/backfill-lexemes?limit=50"
```

## 4) Notes
- iOS notifications are scheduled locally on device.
- For off‑site use, Tailscale VPN must be active on iPhone.
- Some RSS feeds may be slow or blocked; try another URL if ingestion times out.
