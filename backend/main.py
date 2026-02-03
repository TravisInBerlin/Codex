from __future__ import annotations

from datetime import datetime, timezone
import os
import re
import json
import sqlite3
from typing import List, Optional
from uuid import uuid4

import httpx
import feedparser
from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel, Field

app = FastAPI(title="BerlinCoach API", version="0.1.0")

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

X_BASE_URL = os.getenv("X_BASE_URL", "https://api.x.com/2")
X_BEARER_TOKEN = os.getenv("X_BEARER_TOKEN")
DEBUG_RSS = os.getenv("DEBUG_RSS", "0") == "1"
DB_PATH = os.getenv("DB_PATH", os.path.join(os.path.dirname(__file__), "berlincoach.sqlite"))
OLLAMA_BASE_URL = os.getenv("OLLAMA_BASE_URL", "http://localhost:11434")
OLLAMA_MODEL = os.getenv("OLLAMA_MODEL", "llama3.1")
USE_LLM = os.getenv("USE_LLM", "1") == "1"

# ------------------------
# Data Models
# ------------------------

class SentenceDTO(BaseModel):
    id: str
    textDe: str
    textJa: str
    tags: List[str] = Field(default_factory=list)


class LexemeDTO(BaseModel):
    id: Optional[str] = None
    textDe: str
    meaningJa: str
    gender: str
    etymology: str
    prepositionPattern: Optional[str] = None
    verbForms: Optional[str] = None


class SentenceDetailDTO(BaseModel):
    sentence: SentenceDTO
    lexemes: List[LexemeDTO]


class SourceDTO(BaseModel):
    id: str
    handle: str
    enabled: bool
    lastSyncAt: Optional[str] = None
    type: Optional[str] = None
    rssUrl: Optional[str] = None


class CardDTO(BaseModel):
    id: str
    front: str
    back: str
    status: str
    dueAt: Optional[str] = None


class NotificationScheduleDTO(BaseModel):
    active: bool
    startHour: int
    startMinute: int = 0
    endHour: int
    endMinute: int = 0
    maxSentences: int
    intervalMinutes: int = 60


class UpdateSourceRequest(BaseModel):
    enabled: Optional[bool] = None
    handle: Optional[str] = None
    rssUrl: Optional[str] = None


class DeleteSourceRequest(BaseModel):
    id: str


class CreateSourceRequest(BaseModel):
    handle: str
    type: str = "rss"
    rssUrl: str


class SourcePreviewDTO(BaseModel):
    ok: bool
    title: Optional[str] = None
    items: List[str] = Field(default_factory=list)


class ReviewCardRequest(BaseModel):
    rating: str


class IngestRequest(BaseModel):
    text: str
    source: Optional[str] = "manual"


class CreateCardRequest(BaseModel):
    lexemeId: str


class AbbreviationsDTO(BaseModel):
    abbreviations: List[str]


# ------------------------
# In-memory Store
# ------------------------

now = datetime.now(timezone.utc)

def iso(dt: datetime) -> str:
    return dt.astimezone(timezone.utc).isoformat()

sources = [
    {
        "id": str(uuid4()),
        "handle": "berlin.de/polizeimeldungen",
        "enabled": True,
        "lastSyncAt": "10分前",
        "type": "rss",
        "rss_url": "https://www.berlin.de/polizei/polizeimeldungen/index.php/rss",
    },
    {
        "id": str(uuid4()),
        "handle": "berliner-zeitung (polizei)",
        "enabled": True,
        "lastSyncAt": "40分前",
        "type": "rss",
        "rss_url": "https://www.berliner-zeitung.de/feed.id_news-polizei.xml",
    },
    {
        "id": str(uuid4()),
        "handle": "adfc berlin",
        "enabled": True,
        "lastSyncAt": "60分前",
        "type": "rss",
        "rss_url": "https://berlin.adfc.de/aktuelles/rss",
    },
]

sentences = [
    {
        "id": str(uuid4()),
        "textDe": "Die Polizei bittet um Hinweise zu einem Vorfall am Alexanderplatz.",
        "textJa": "警察はアレクサンダープラッツの事件に関する情報提供を求めている。",
        "tags": ["police", "events"],
        "lexemes": [
            {
                "textDe": "die Polizei",
                "meaningJa": "警察",
                "gender": "die",
                "etymology": "ギリシャ語→ラテン語経由で警察組織を指す語。",
            },
            {
                "textDe": "um Hinweise bitten",
                "meaningJa": "情報提供を求める",
                "gender": "none",
                "etymology": "bitten（頼む）+ um（〜を求めて）。",
                "prepositionPattern": "bitten um + Akk.",
                "verbForms": "bitten – bat – gebeten",
            },
        ],
    },
    {
        "id": str(uuid4()),
        "textDe": "Die BVG meldet eine Sperrung auf der U2.",
        "textJa": "BVGはU2の運休を報告。",
        "tags": ["transport"],
        "lexemes": [
            {
                "textDe": "die Sperrung",
                "meaningJa": "封鎖・運休",
                "gender": "die",
                "etymology": "sperren（閉じる）由来。",
            },
            {
                "textDe": "auf der U2",
                "meaningJa": "U2線で",
                "gender": "none",
                "etymology": "路線名は交通系の固有名詞。",
                "prepositionPattern": "auf + Dat.",
            },
        ],
    },
]

cards = [
    {
        "id": str(uuid4()),
        "front": "der Verdächtige",
        "back": "意味: 容疑者 / 性: der / 語源: verdächtigen（疑う）由来",
        "status": "due",
        "dueAt": iso(now),
    },
    {
        "id": str(uuid4()),
        "front": "die Sperrung",
        "back": "意味: 封鎖・運休 / 性: die / 語源: sperren（閉じる）",
        "status": "new",
        "dueAt": None,
    },
]

schedule = {
    "active": True,
    "startHour": 9,
    "startMinute": 0,
    "endHour": 21,
    "endMinute": 0,
    "maxSentences": 2,
    "intervalMinutes": 60,
}

abbreviations_extra: list[str] = []

user_id_cache: dict[str, str] = {}


# ------------------------
# LLM Helpers (Ollama)
# ------------------------

def call_ollama(text_de: str) -> list[dict]:
    if not USE_LLM:
        return []
    if len(text_de or "") > 400:
        return []
    prompt = (
        "あなたはベルリン在住の日本人学習者向けのドイツ語コーチです。"
        "以下の短いドイツ語文から、学習上重要な語や句を2〜5個抽出してください。"
        "各項目に必ず含める: textDe, meaningJa, gender(der/die/das/none), etymology。"
        "meaningJaとetymologyは必ず日本語で、語源はできるだけ深掘りして説明すること。"
        "前置詞の定型がある場合は prepositionPattern を必ず追加。"
        "動詞の場合は verbForms を必ず追加（例: sehen – sah – gesehen）。"
        "出力はJSONのみで厳密に: {\"lexemes\": [ ... ]}。英語は禁止。\n"
        "例:\n"
        "{\"lexemes\":[{\"textDe\":\"die Polizei\",\"meaningJa\":\"警察\",\"gender\":\"die\","
        "\"etymology\":\"ギリシャ語polis（都市）由来のpoliteiaがラテン語経由で定着。\","
        "\"prepositionPattern\":null,\"verbForms\":null}]}\n"
        "Sentence:\n" + text_de
    )
    payload = {
        "model": OLLAMA_MODEL,
        "prompt": prompt,
        "stream": False,
        "format": "json",
    }
    try:
        with httpx.Client(timeout=120) as client:
            res = client.post(f"{OLLAMA_BASE_URL}/api/generate", json=payload)
            res.raise_for_status()
            data = res.json().get("response", "")
            obj = json.loads(data)
            return obj.get("lexemes", [])
    except Exception:
        return []


def translate_ollama(text_de: str) -> str:
    if not USE_LLM:
        return "(未翻訳)"
    if len(text_de or "") > 800:
        return "(未翻訳)"
    prompt = (
        "Translate the following German text into natural Japanese. "
        "Return only the Japanese translation, no extra text.\n"
        "German:\n" + text_de
    )
    payload = {
        "model": OLLAMA_MODEL,
        "prompt": prompt,
        "stream": False,
    }
    try:
        with httpx.Client(timeout=120) as client:
            res = client.post(f"{OLLAMA_BASE_URL}/api/generate", json=payload)
            res.raise_for_status()
            return res.json().get("response", "").strip() or "(未翻訳)"
    except Exception:
        return "(未翻訳)"


def needs_japanese(text: str) -> bool:
    if not text:
        return False
    if re.search(r"[ぁ-んァ-ン一-龠]", text):
        return False
    return re.search(r"[A-Za-z]", text) is not None


def normalize_lexemes_japanese(lexemes: list[dict]) -> list[dict]:
    normalized = []
    for lex in lexemes:
        meaning = lex.get("meaningJa", "")
        ety = lex.get("etymology", "")
        if needs_japanese(meaning):
            lex["meaningJa"] = translate_ollama(meaning)
        if needs_japanese(ety):
            lex["etymology"] = translate_ollama(ety)
        normalized.append(lex)
    return normalized


def looks_like_verb(text: str) -> bool:
    t = (text or "").strip().lower()
    if t.startswith("sich "):
        return True
    return t.endswith("en")


# ------------------------
# X API Helpers
# ------------------------

def get_db() -> sqlite3.Connection:
    conn = sqlite3.connect(DB_PATH)
    conn.row_factory = sqlite3.Row
    return conn


def init_db() -> None:
    with get_db() as conn:
        conn.execute(
            """
            CREATE TABLE IF NOT EXISTS sentences (
                id TEXT PRIMARY KEY,
                text_de TEXT NOT NULL,
                text_ja TEXT NOT NULL,
                tags_json TEXT NOT NULL,
                source_handle TEXT NOT NULL,
                created_at TEXT NOT NULL
            )
            """
        )
        conn.execute(
            """
            CREATE TABLE IF NOT EXISTS lexemes (
                id TEXT PRIMARY KEY,
                sentence_id TEXT NOT NULL,
                text_de TEXT NOT NULL,
                meaning_ja TEXT NOT NULL,
                gender TEXT NOT NULL,
                etymology TEXT NOT NULL,
                preposition_pattern TEXT,
                verb_forms TEXT,
                created_at TEXT NOT NULL,
                FOREIGN KEY(sentence_id) REFERENCES sentences(id)
            )
            """
        )
        conn.execute(
            """
            CREATE TABLE IF NOT EXISTS cards (
                id TEXT PRIMARY KEY,
                lexeme_id TEXT NOT NULL,
                front TEXT NOT NULL,
                back TEXT NOT NULL,
                status TEXT NOT NULL,
                due_at TEXT,
                created_at TEXT NOT NULL,
                FOREIGN KEY(lexeme_id) REFERENCES lexemes(id)
            )
            """
        )
        conn.execute(
            """
            CREATE TABLE IF NOT EXISTS sources (
                id TEXT PRIMARY KEY,
                handle TEXT NOT NULL,
                type TEXT NOT NULL,
                rss_url TEXT,
                enabled INTEGER NOT NULL,
                last_sync_at TEXT,
                created_at TEXT NOT NULL
            )
            """
        )
        conn.commit()

    seed_sources_if_empty()


def insert_sentence(text_de: str, text_ja: str, tags: list[str], source_handle: str) -> tuple[str, bool]:
    with get_db() as conn:
        existing = conn.execute(
            "SELECT id FROM sentences WHERE text_de = ?",
            (text_de,),
        ).fetchone()
        if existing:
            return existing["id"], False
        new_id = str(uuid4())
        conn.execute(
            """
            INSERT INTO sentences (id, text_de, text_ja, tags_json, source_handle, created_at)
            VALUES (?, ?, ?, ?, ?, ?)
            """,
            (new_id, text_de, text_ja, json.dumps(tags), source_handle, iso(datetime.now(timezone.utc))),
        )
        conn.commit()
        return new_id, True


def insert_lexemes(sentence_id: str, lexemes: list[dict]) -> None:
    with get_db() as conn:
        conn.execute("DELETE FROM lexemes WHERE sentence_id = ?", (sentence_id,))
        for lex in normalize_lexemes_japanese(lexemes):
            new_id = str(uuid4())
            conn.execute(
                """
                INSERT INTO lexemes (
                    id, sentence_id, text_de, meaning_ja, gender, etymology,
                    preposition_pattern, verb_forms, created_at
                ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)
                """,
                (
                    new_id,
                    sentence_id,
                    lex.get("textDe", ""),
                    lex.get("meaningJa", ""),
                    lex.get("gender", ""),
                    lex.get("etymology", ""),
                    lex.get("prepositionPattern"),
                    lex.get("verbForms"),
                    iso(datetime.now(timezone.utc)),
                ),
            )
        conn.commit()


def seed_cards_if_empty() -> None:
    with get_db() as conn:
        row = conn.execute("SELECT COUNT(*) as c FROM cards").fetchone()
        if row and row["c"] > 0:
            return
        for c in cards:
            lex_id = str(uuid4())
            conn.execute(
                """
                INSERT INTO lexemes (id, sentence_id, text_de, meaning_ja, gender, etymology, created_at)
                VALUES (?, ?, ?, ?, ?, ?, ?)
                """,
                (
                    lex_id,
                    sentences[0]["id"],
                    c["front"],
                    "",
                    "",
                    "",
                    iso(datetime.now(timezone.utc)),
                ),
            )
            conn.execute(
                """
                INSERT INTO cards (id, lexeme_id, front, back, status, due_at, created_at)
                VALUES (?, ?, ?, ?, ?, ?, ?)
                """,
                (
                    c["id"],
                    lex_id,
                    c["front"],
                    c["back"],
                    c["status"],
                    c["dueAt"],
                    iso(datetime.now(timezone.utc)),
                ),
            )
        conn.commit()


def seed_sources_if_empty() -> None:
    with get_db() as conn:
        row = conn.execute("SELECT COUNT(*) as c FROM sources").fetchone()
        if row and row["c"] > 0:
            return
        for s in sources:
            conn.execute(
                """
                INSERT INTO sources (id, handle, type, rss_url, enabled, last_sync_at, created_at)
                VALUES (?, ?, ?, ?, ?, ?, ?)
                """,
                (
                    s["id"],
                    s["handle"],
                    s.get("type", "rss"),
                    s.get("rss_url"),
                    1 if s.get("enabled", True) else 0,
                    s.get("lastSyncAt"),
                    iso(datetime.now(timezone.utc)),
                ),
            )
        conn.commit()


def fetch_cards(status: Optional[str]) -> list[dict]:
    with get_db() as conn:
        seed_cards_if_empty()
        if status:
            rows = conn.execute(
                "SELECT id, front, back, status, due_at FROM cards WHERE status = ?",
                (status,),
            ).fetchall()
        else:
            rows = conn.execute("SELECT id, front, back, status, due_at FROM cards").fetchall()
    return [
        {
            "id": r["id"],
            "front": r["front"],
            "back": r["back"],
            "status": r["status"],
            "dueAt": r["due_at"],
        }
        for r in rows
    ]


def backfill_translations(limit: int = 20) -> int:
    with get_db() as conn:
        rows = conn.execute(
            """
            SELECT id, text_de FROM sentences
            WHERE text_ja IN ('(未翻訳)', '(自動生成予定)')
            ORDER BY created_at DESC
            LIMIT ?
            """,
            (limit,),
        ).fetchall()
        if not rows:
            return 0
        for row in rows:
            translated = translate_ollama(row["text_de"])
            conn.execute(
                "UPDATE sentences SET text_ja = ? WHERE id = ?",
                (translated, row["id"]),
            )
        conn.commit()
        return len(rows)


init_db()


def x_headers() -> dict[str, str]:
    if not X_BEARER_TOKEN:
        raise HTTPException(status_code=501, detail="X_BEARER_TOKEN is not set")
    return {"Authorization": f"Bearer {X_BEARER_TOKEN}"}


def fetch_user_id(username: str) -> str:
    if username in user_id_cache:
        return user_id_cache[username]
    url = f"{X_BASE_URL}/users/by/username/{username}"
    with httpx.Client(timeout=10) as client:
        res = client.get(url, headers=x_headers())
        res.raise_for_status()
        data = res.json().get("data")
        if not data or "id" not in data:
            raise HTTPException(status_code=404, detail=f"User {username} not found")
        user_id_cache[username] = data["id"]
        return data["id"]


def fetch_user_posts(user_id: str) -> list[dict]:
    url = f"{X_BASE_URL}/users/{user_id}/tweets"
    params = {
        "max_results": 5,
        "tweet.fields": "lang,created_at",
        "exclude": "retweets,replies",
    }
    with httpx.Client(timeout=10) as client:
        res = client.get(url, headers=x_headers(), params=params)
        res.raise_for_status()
        return res.json().get("data", [])


def strip_html(text: str) -> str:
    text = re.sub(r"<[^>]+>", "", text or "")
    return re.sub(r"\s+", " ", text).strip()


ABBREVIATIONS_BASE = {
    "z.B.",
    "u.a.",
    "bzw.",
    "ggf.",
    "ca.",
    "Nr.",
    "Dr.",
    "Prof.",
    "d.h.",
    "u.U.",
    "S.",
    "St.",
}


def load_abbreviations() -> set[str]:
    extra = {abbr.strip() for abbr in abbreviations_extra if abbr.strip()}
    return ABBREVIATIONS_BASE | extra


def protect_abbrev(text: str) -> str:
    protected = text
    for abbr in load_abbreviations():
        protected = protected.replace(abbr, abbr.replace(".", "§"))
    return protected


def unprotect_abbrev(text: str) -> str:
    return text.replace("§", ".")


def clamp_sentences(text: str, max_sentences: int = 2) -> str:
    if not text:
        return ""
    protected = protect_abbrev(text)
    parts = re.split(r"(?<=[.!?])\s+", protected)
    parts = [unprotect_abbrev(p.strip()) for p in parts if p.strip()]
    return " ".join(parts[:max_sentences])


def fetch_rss_posts(rss_url: str) -> list[dict]:
    try:
        with httpx.Client(timeout=10) as client:
            res = client.get(rss_url, follow_redirects=True)
            res.raise_for_status()
            feed = feedparser.parse(res.content)
    except Exception:
        return []
    items = []
    for entry in feed.entries[:5]:
        title = strip_html(getattr(entry, "title", ""))
        summary = strip_html(getattr(entry, "summary", ""))
        raw = title if not summary else f"{title}. {summary}"
        text = clamp_sentences(raw, max_sentences=2)
        if DEBUG_RSS:
            print("RAW:", raw)
            print("CLAMPED:", text)
        if text:
            items.append({"text": text})
    return items


def preview_rss(rss_url: str) -> SourcePreviewDTO:
    if not rss_url.startswith("http"):
        raise HTTPException(status_code=400, detail="Invalid rssUrl")
    feed = feedparser.parse(rss_url)
    title = getattr(feed.feed, "title", None)
    items = []
    for entry in feed.entries[:5]:
        title_raw = strip_html(getattr(entry, "title", ""))
        summary_raw = strip_html(getattr(entry, "summary", ""))
        raw = title_raw if not summary_raw else f"{title_raw}. {summary_raw}"
        text = clamp_sentences(raw, max_sentences=2)
        if text:
            items.append(text)
    return SourcePreviewDTO(ok=bool(items), title=title, items=items)


def list_sources() -> list[dict]:
    with get_db() as conn:
        rows = conn.execute(
            "SELECT id, handle, type, rss_url, enabled, last_sync_at FROM sources ORDER BY created_at DESC"
        ).fetchall()
    return [
        {
            "id": r["id"],
            "handle": r["handle"],
            "type": r["type"],
            "rss_url": r["rss_url"],
            "enabled": bool(r["enabled"]),
            "lastSyncAt": r["last_sync_at"],
        }
        for r in rows
    ]


# ------------------------
# Routes
# ------------------------

@app.get("/sentences", response_model=List[SentenceDTO])
def get_sentences():
    with get_db() as conn:
        rows = conn.execute(
            "SELECT id, text_de, text_ja, tags_json FROM sentences ORDER BY created_at DESC LIMIT 50"
        ).fetchall()
        missing_ids = [
            row["id"]
            for row in rows
            if row["text_ja"] in ("(未翻訳)", "(自動生成予定)")
        ]
        if missing_ids and USE_LLM:
            for row in rows:
                if row["id"] in missing_ids:
                    translated = translate_ollama(row["text_de"])
                    conn.execute(
                        "UPDATE sentences SET text_ja = ? WHERE id = ?",
                        (translated, row["id"]),
                    )
            conn.commit()
            rows = conn.execute(
                "SELECT id, text_de, text_ja, tags_json FROM sentences ORDER BY created_at DESC LIMIT 50"
            ).fetchall()
    if rows:
        return [
            SentenceDTO(
                id=row["id"],
                textDe=row["text_de"],
                textJa=row["text_ja"],
                tags=json.loads(row["tags_json"]),
            )
            for row in rows
        ]
    return [
        SentenceDTO(
            id=s["id"],
            textDe=s["textDe"],
            textJa=s["textJa"],
            tags=s.get("tags", []),
        )
        for s in sentences
    ]


@app.get("/sentences/{sentence_id}", response_model=SentenceDetailDTO)
def get_sentence_detail(sentence_id: str):
    with get_db() as conn:
        row = conn.execute(
            "SELECT id, text_de, text_ja, tags_json FROM sentences WHERE id = ?",
            (sentence_id,),
        ).fetchone()
        if row and row["text_ja"] in ("(未翻訳)", "(自動生成予定)") and USE_LLM:
            translated = translate_ollama(row["text_de"])
            conn.execute(
                "UPDATE sentences SET text_ja = ? WHERE id = ?",
                (translated, row["id"]),
            )
            conn.commit()
            row = conn.execute(
                "SELECT id, text_de, text_ja, tags_json FROM sentences WHERE id = ?",
                (sentence_id,),
            ).fetchone()
    if row:
        try:
            tags = json.loads(row["tags_json"])
        except Exception:
            tags = []
        sentence = SentenceDTO(
            id=row["id"],
            textDe=row["text_de"],
            textJa=row["text_ja"],
            tags=tags,
        )
        try:
            with get_db() as conn:
                lex_rows = conn.execute(
                    """
                    SELECT id, text_de, meaning_ja, gender, etymology, preposition_pattern, verb_forms
                    FROM lexemes WHERE sentence_id = ?
                    """,
                    (row["id"],),
                ).fetchall()
        except Exception:
            lex_rows = []
        lexemes = [
            LexemeDTO(
                id=r["id"],
                textDe=r["text_de"],
                meaningJa=r["meaning_ja"],
                gender=r["gender"],
                etymology=r["etymology"],
                prepositionPattern=r["preposition_pattern"],
                verbForms=r["verb_forms"],
            )
            for r in lex_rows
        ]
        return SentenceDetailDTO(sentence=sentence, lexemes=lexemes)
    match = next((s for s in sentences if s["id"] == sentence_id), None)
    if not match:
        raise HTTPException(status_code=404, detail="Sentence not found")
    sentence = SentenceDTO(
        id=match["id"],
        textDe=match["textDe"],
        textJa=match["textJa"],
        tags=match.get("tags", []),
    )
    lexemes = [LexemeDTO(**lex) for lex in match.get("lexemes", [])]
    return SentenceDetailDTO(sentence=sentence, lexemes=lexemes)


@app.get("/sources", response_model=List[SourceDTO])
def get_sources():
    return [
        SourceDTO(
            id=s["id"],
            handle=s["handle"],
            enabled=s["enabled"],
            lastSyncAt=s.get("lastSyncAt"),
            type=s.get("type"),
            rssUrl=s.get("rss_url"),
        )
        for s in list_sources()
    ]


@app.patch("/sources/{source_id}", response_model=SourceDTO)
def update_source(source_id: str, body: UpdateSourceRequest):
    with get_db() as conn:
        row = conn.execute("SELECT id FROM sources WHERE id = ?", (source_id,)).fetchone()
        if not row:
            raise HTTPException(status_code=404, detail="Source not found")
        updates = []
        params = []
        if body.enabled is not None:
            updates.append("enabled = ?")
            params.append(1 if body.enabled else 0)
        if body.handle is not None:
            updates.append("handle = ?")
            params.append(body.handle.strip() or "rss")
        if body.rssUrl is not None:
            updates.append("rss_url = ?")
            params.append(body.rssUrl.strip())
        updates.append("last_sync_at = ?")
        params.append("今")
        params.append(source_id)
        conn.execute(
            f"UPDATE sources SET {', '.join(updates)} WHERE id = ?",
            tuple(params),
        )
        conn.commit()
        updated = conn.execute(
            "SELECT id, handle, type, rss_url, enabled, last_sync_at FROM sources WHERE id = ?",
            (source_id,),
        ).fetchone()
    return SourceDTO(
        id=updated["id"],
        handle=updated["handle"],
        enabled=bool(updated["enabled"]),
        lastSyncAt=updated["last_sync_at"],
        type=updated["type"],
        rssUrl=updated["rss_url"],
    )


@app.post("/sources", response_model=SourceDTO)
def create_source(body: CreateSourceRequest):
    if body.type != "rss":
        raise HTTPException(status_code=400, detail="Only rss sources are supported")
    new_id = str(uuid4())
    handle = body.handle.strip() or "rss"
    rss_url = body.rssUrl.strip()
    if not rss_url:
        raise HTTPException(status_code=400, detail="rssUrl is required")
    with get_db() as conn:
        conn.execute(
            """
            INSERT INTO sources (id, handle, type, rss_url, enabled, last_sync_at, created_at)
            VALUES (?, ?, ?, ?, ?, ?, ?)
            """,
            (new_id, handle, body.type, rss_url, 1, None, iso(datetime.now(timezone.utc))),
        )
        conn.commit()
    return SourceDTO(
        id=new_id,
        handle=handle,
        enabled=True,
        lastSyncAt=None,
        type=body.type,
        rssUrl=rss_url,
    )


@app.delete("/sources/{source_id}")
def delete_source(source_id: str):
    with get_db() as conn:
        row = conn.execute("SELECT id FROM sources WHERE id = ?", (source_id,)).fetchone()
        if not row:
            raise HTTPException(status_code=404, detail="Source not found")
        conn.execute("DELETE FROM sources WHERE id = ?", (source_id,))
        conn.commit()
    return {"deleted": True}


@app.post("/sources/preview", response_model=SourcePreviewDTO)
def source_preview(body: CreateSourceRequest):
    if body.type != "rss":
        raise HTTPException(status_code=400, detail="Only rss sources are supported")
    return preview_rss(body.rssUrl.strip())


@app.get("/cards", response_model=List[CardDTO])
def get_cards(status: Optional[str] = None):
    try:
        items = fetch_cards(status)
        return [CardDTO(**c) for c in items]
    except Exception:
        return []


@app.post("/cards/{card_id}/review", response_model=CardDTO)
def review_card(card_id: str, body: ReviewCardRequest):
    with get_db() as conn:
        row = conn.execute("SELECT id FROM cards WHERE id = ?", (card_id,)).fetchone()
        if not row:
            raise HTTPException(status_code=404, detail="Card not found")
        conn.execute(
            "UPDATE cards SET status = ? WHERE id = ?",
            (body.rating, card_id),
        )
        conn.commit()
        updated = conn.execute(
            "SELECT id, front, back, status, due_at FROM cards WHERE id = ?",
            (card_id,),
        ).fetchone()
    return CardDTO(
        id=updated["id"],
        front=updated["front"],
        back=updated["back"],
        status=updated["status"],
        dueAt=updated["due_at"],
    )


@app.post("/cards", response_model=CardDTO)
def create_card(body: CreateCardRequest):
    with get_db() as conn:
        lex = conn.execute(
            """
            SELECT id, text_de, meaning_ja, gender, etymology, preposition_pattern, verb_forms
            FROM lexemes WHERE id = ?
            """,
            (body.lexemeId,),
        ).fetchone()
        if not lex:
            raise HTTPException(status_code=404, detail="Lexeme not found")
        existing = conn.execute(
            "SELECT id, front, back, status, due_at FROM cards WHERE lexeme_id = ?",
            (body.lexemeId,),
        ).fetchone()
        if existing:
            return CardDTO(
                id=existing["id"],
                front=existing["front"],
                back=existing["back"],
                status=existing["status"],
                dueAt=existing["due_at"],
            )
        front = lex["text_de"]
        back_parts = [
            f"意味: {lex['meaning_ja']}",
            f"性: {lex['gender']}",
            f"語源: {lex['etymology']}",
        ]
        if lex["preposition_pattern"]:
            back_parts.append(f"前置詞: {lex['preposition_pattern']}")
        if lex["verb_forms"]:
            back_parts.append(f"活用: {lex['verb_forms']}")
        back = " / ".join(back_parts)
        new_id = str(uuid4())
        conn.execute(
            """
            INSERT INTO cards (id, lexeme_id, front, back, status, due_at, created_at)
            VALUES (?, ?, ?, ?, ?, ?, ?)
            """,
            (new_id, body.lexemeId, front, back, "new", None, iso(datetime.now(timezone.utc))),
        )
        conn.commit()
        created = conn.execute(
            "SELECT id, front, back, status, due_at FROM cards WHERE id = ?",
            (new_id,),
        ).fetchone()
    return CardDTO(
        id=created["id"],
        front=created["front"],
        back=created["back"],
        status=created["status"],
        dueAt=created["due_at"],
    )


@app.get("/notifications/schedule", response_model=NotificationScheduleDTO)
def get_schedule():
    return NotificationScheduleDTO(**schedule)


@app.patch("/notifications/schedule", response_model=NotificationScheduleDTO)
def update_schedule(body: NotificationScheduleDTO):
    schedule.update(body.model_dump())
    return NotificationScheduleDTO(**schedule)


@app.get("/settings/abbreviations", response_model=AbbreviationsDTO)
def get_abbreviations():
    return AbbreviationsDTO(abbreviations=sorted(abbreviations_extra))


@app.put("/settings/abbreviations", response_model=AbbreviationsDTO)
def update_abbreviations(body: AbbreviationsDTO):
    global abbreviations_extra
    abbreviations_extra = [abbr.strip() for abbr in body.abbreviations if abbr.strip()]
    return AbbreviationsDTO(abbreviations=sorted(abbreviations_extra))


@app.post("/admin/backfill-translations")
def admin_backfill_translations(limit: int = 20):
    updated = backfill_translations(limit=limit)
    return {"updated": updated}


@app.post("/admin/backfill-lexemes")
def admin_backfill_lexemes(limit: int = 20):
    if not USE_LLM:
        return {"updated": 0}
    updated = 0
    with get_db() as conn:
        rows = conn.execute(
            "SELECT id, text_de FROM sentences ORDER BY created_at DESC LIMIT ?",
            (limit,),
        ).fetchall()
        lex_rows = conn.execute(
            """
            SELECT sentence_id, meaning_ja, etymology
            FROM lexemes
            WHERE sentence_id IN (
                SELECT id FROM sentences ORDER BY created_at DESC LIMIT ?
            )
            """,
            (limit,),
        ).fetchall()
        verb_rows = conn.execute(
            """
            SELECT sentence_id, text_de, verb_forms
            FROM lexemes
            WHERE sentence_id IN (
                SELECT id FROM sentences ORDER BY created_at DESC LIMIT ?
            )
            """,
            (limit,),
        ).fetchall()
    english_like = set()
    for r in lex_rows:
        if needs_japanese(r["meaning_ja"]) or needs_japanese(r["etymology"]):
            english_like.add(r["sentence_id"])
    missing_verbs = set()
    for r in verb_rows:
        if looks_like_verb(r["text_de"]) and not (r["verb_forms"] or "").strip():
            missing_verbs.add(r["sentence_id"])
    targets = []
    for row in rows:
        if (
            row["id"] in english_like
            or row["id"] in missing_verbs
            or row["id"] not in {r["sentence_id"] for r in lex_rows}
        ):
            targets.append(row)
    for row in targets:
        lexemes = call_ollama(row["text_de"])
        if lexemes:
            insert_lexemes(row["id"], lexemes)
            updated += 1
    return {"updated": updated}


@app.post("/ingest")
def ingest_text(body: IngestRequest):
    text = body.text.strip()
    if not text:
        raise HTTPException(status_code=400, detail="Text is empty")
    sentence_id, inserted = insert_sentence(
        text_de=text,
        text_ja=translate_ollama(text),
        tags=[body.source or "manual"],
        source_handle=body.source or "manual",
    )
    if inserted:
        lexemes = call_ollama(text)
        if lexemes:
            insert_lexemes(sentence_id, lexemes)
    return {"stored": 1 if inserted else 0, "sentenceId": sentence_id}


@app.post("/ingest/auto")
def ingest_auto():
    enabled_sources = [s for s in list_sources() if s["enabled"]]
    fetched = 0
    stored = 0
    errors: list[str] = []

    for src in enabled_sources:
        last_sync_at = "今"
        try:
            if src.get("type") == "rss":
                posts = fetch_rss_posts(src["rss_url"])
            else:
                handle = src["handle"]
                user_id = fetch_user_id(handle)
                posts = fetch_user_posts(user_id)
            fetched += len(posts)

            for post in posts:
                text = post.get("text", "").strip()
                if not text:
                    continue
                sentence_id, inserted = insert_sentence(
                    text_de=text,
                    text_ja=translate_ollama(text),
                    tags=[src.get("handle", "rss")],
                    source_handle=src.get("handle", "rss"),
                )
                if inserted:
                    lexemes = call_ollama(text)
                    if lexemes:
                        insert_lexemes(sentence_id, lexemes)
                    stored += 1
        except Exception:
            last_sync_at = "失敗"
            errors.append(src.get("handle", "rss"))

        with get_db() as conn:
            conn.execute(
                "UPDATE sources SET last_sync_at = ? WHERE id = ?",
                (last_sync_at, src["id"]),
            )
            conn.commit()

    return {"fetched": fetched, "stored": stored, "errors": errors}
