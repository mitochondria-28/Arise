<div align="center">

# ⚔️ Arise

### Level up your real life.

**Arise** is an AI-powered personal development RPG platform that transforms your daily goals, habits, and reflections into a rich progression system. Real actions earn XP. Real reflection drives AI analysis. Real growth is tracked, visualised, and celebrated.

[![FastAPI](https://img.shields.io/badge/Backend-FastAPI-009688?style=flat-square&logo=fastapi)](https://fastapi.tiangolo.com)
[![React](https://img.shields.io/badge/Web-React%2019-61DAFB?style=flat-square&logo=react)](https://react.dev)
[![Flutter](https://img.shields.io/badge/Mobile-Flutter-02569B?style=flat-square&logo=flutter)](https://flutter.dev)
[![PostgreSQL](https://img.shields.io/badge/DB-PostgreSQL%2016-4169E1?style=flat-square&logo=postgresql)](https://postgresql.org)
[![Gemini](https://img.shields.io/badge/AI-Gemini-8E75B2?style=flat-square&logo=google)](https://ai.google.dev)

</div>

---

## ✨ Features

### 🧬 Character System
- Create your **Hunter character** with a rank system (E → S)
- Six core stats: **Vitality, Strength, Intelligence, Wisdom, Charisma, Discipline**
- XP-based levelling with deterministic level thresholds
- Rank progression tied to character level

### 🎯 Goal System
- Create goals with category, difficulty, and optional target date
- Complete goals with **evidence text + reflection + effort rating** — XP is never free
- **Goal Templates** — 30 pre-built goal templates organised by category
- **Goal Milestones** — break goals into checkable sub-tasks
- AI analysis generated automatically on every completion

### ⚔️ Mission System (Daily Habits)
- Daily/weekly/monthly recurring missions for habit tracking
- Check in with evidence + streak tracking
- **Mission Templates** — curated habit blueprints
- Streak counter, longest streak, and completion history
- AI coaching note after each check-in

### 📖 Journal
- Free-form journal entries with optional mood rating (1–5)
- AI-generated reflection on each entry
- Full history with mood trend visibility

### ⚡ Skill Tree
- **30-skill catalog** across all 6 stat categories (5 per category)
- Unlock skills, then practice them with notes and duration
- Skills level up 1–10 based on session count with XP bonuses
- Duration bonus: up to 2× XP for 30+ minute sessions

### 🏆 Achievements
- Automatic achievement unlocks for milestones (first goal, streaks, levels, etc.)
- Achievement gallery with unlock dates

### 📊 Progress Dashboard
- XP history bar chart (7 / 30 / 90 day windows)
- **Stat trend line chart** — track how each stat grew over time
- Goals breakdown by difficulty and category
- Top missions by streak

### 🤖 AI Coach
- **Chat interface** — multi-turn conversation with context-aware coaching
- Conversation history saved and resumable
- **Weekly Reviews** — AI-generated weekly summary (idempotent per week)
- **Growth Reports** — holistic analysis of character progress

---

## 🏗️ Tech Stack

| Layer | Technology |
|---|---|
| **Backend** | FastAPI 0.115+, Python 3.12, SQLAlchemy 2 (async), Alembic |
| **Database** | PostgreSQL 16 |
| **AI** | Google Gemini 2.0 Flash (`google-genai` SDK) |
| **Web** | React 19, TypeScript, Vite, TailwindCSS v4, TanStack Query v5, Recharts, Framer Motion |
| **Mobile** | Flutter 3.x, Riverpod, GoRouter, Dio |
| **Auth** | JWT (access + refresh tokens) |

---

## 📁 Project Structure

```
arise/
├── backend/                 FastAPI application
│   ├── alembic/             Database migrations (001 → 019)
│   │   └── versions/
│   ├── app/
│   │   ├── api/v1/routes/   REST endpoints
│   │   ├── core/            Config, auth, Gemini client, XP engine
│   │   ├── models/          SQLAlchemy ORM models
│   │   ├── repositories/    Database access layer
│   │   ├── schemas/         Pydantic request/response schemas
│   │   └── services/        Business logic
│   ├── pyproject.toml
│   └── requirements.txt
│
├── web/                     React web app
│   └── src/
│       ├── app/             Router + providers
│       ├── features/        Page-level feature modules
│       └── shared/          UI components, API client, types
│
├── mobile/                  Flutter app
│   └── lib/
│       ├── core/            Auth, models, network, theme
│       ├── features/        Screen-level feature modules
│       └── shared/          Shared widgets
│
├── docs/                    Architecture documentation
├── scripts/                 Dev helper scripts
└── docker-compose.yml
```

---

## 🚀 Quick Start

### Prerequisites

- Python 3.12+
- Node.js 20+
- Flutter 3.x (stable channel)
- PostgreSQL 16 (via Docker or local install)

### 1. Clone

```bash
git clone https://github.com/mitochondria-28/Arise.git
cd Arise
```

### 2. Start PostgreSQL

```bash
docker compose up postgres -d
```

Or install locally:
```bash
brew install postgresql@16
brew services start postgresql@16
psql postgres -c "CREATE USER arise WITH PASSWORD 'arise_dev_password';"
psql postgres -c "CREATE DATABASE arise_db OWNER arise;"
```

### 3. Backend Setup

```bash
cd backend
python3 -m venv .venv
source .venv/bin/activate          # Windows: .venv\Scripts\activate
pip install -r requirements.txt

# Configure environment (copy defaults, add your Gemini key)
cp ../.env.example .env
# Edit .env → set GEMINI_API_KEY=your_key_here

# Run all database migrations
alembic upgrade head

# Start the API server
uvicorn app.main:app --reload --port 8000
# → http://localhost:8000
# → http://localhost:8000/docs  (Swagger UI)
```

### 4. Web Setup

```bash
cd web
npm install
npm run dev
# → http://localhost:5173
```

### 5. Mobile Setup

```bash
cd mobile
flutter pub get
flutter run
```

---

## ⚙️ Environment Variables

Create `backend/.env` (all have defaults for local dev except `GEMINI_API_KEY`):

```env
# Database
DATABASE_URL=postgresql+asyncpg://arise:arise_dev_password@127.0.0.1:5432/arise_db

# Auth — generate with: python3 -c "import secrets; print(secrets.token_hex(32))"
JWT_SECRET_KEY=change_me_in_production

# AI (get from https://aistudio.google.com)
GEMINI_API_KEY=your_gemini_api_key_here
GEMINI_MODEL=gemini-2.0-flash

# CORS (JSON array)
CORS_ORIGINS=["http://localhost:5173","http://localhost:3000"]
```

---

## 🗃️ Database Migrations

```bash
cd backend

# Apply all migrations
alembic upgrade head

# Create a new migration
alembic revision --autogenerate -m "describe the change"

# Check current state
alembic current

# Rollback one step
alembic downgrade -1
```

Migrations are numbered `001` → `019` covering the full schema:

| Migration | Description |
|-----------|-------------|
| 001–002 | Users + profiles |
| 003–005 | Characters, stats, XP transactions |
| 006–007 | Goals + completions |
| 008–009 | Missions + logs |
| 010 | AI analyses |
| 011 | Achievements |
| 012 | Journal entries |
| 013–014 | Goal + Mission templates |
| 015 | Skill tree (30 seeded skills) |
| 016 | Goal milestones |
| 017 | Stat snapshots (daily trend data) |
| 018 | AI conversations + messages |
| 019 | Weekly reviews |

---

## 🧠 Core Philosophy

> **Real action → Evidence → Reflection → Deterministic XP → AI Analysis → Growth**

XP is **never** awarded for clicking a button. Every point of progress must represent a real-world action backed by written evidence and reflection. The AI then analyses that evidence to provide genuinely useful coaching — not generic motivation.

---

## 📜 License

MIT — see [LICENSE](LICENSE) for details.
