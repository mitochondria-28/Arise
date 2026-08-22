# Arise — System Architecture

## Overview

```
                    GEMINI AI ENGINE
                          │
                          ▼
             ┌────────────────────────┐
             │    FASTAPI BACKEND     │
             │                        │
             │  XP Engine             │
             │  Mission Engine        │
             │  Goal Engine           │
             │  Skill Engine          │
             │  Achievement Engine    │
             │  AI Services           │
             │  Auth (JWT)            │
             └────────┬───────────────┘
                      │  REST API /api/v1
              ┌───────┴────────┐
              ▼                ▼
        React Web          Flutter
        (Vite/TS)      (iOS + Android)
              │                │
              └───────┬────────┘
                      ▼
                 PostgreSQL 16
```

## Principles

1. **Backend is the single source of truth** — XP, levels, stats, and achievements are always calculated server-side.
2. **Clients are display layers** — React and Flutter receive data and render it; they hold no business logic.
3. **AI advises, backend decides** — All LLM output passes through Pydantic validation and business rule layers before touching the database.
4. **XP is deterministic** — A mission's XP reward is calculated from a transparent formula, not arbitrarily assigned.

## XP Formula

```
mission_xp =
  BASE_DIFFICULTY_XP[difficulty]
  × EFFORT_MULTIPLIER[duration_bucket]
  × evidence_quality_factor
  × streak_bonus (capped at 1.3×)
  × diminishing_returns_factor (prevents farming)
```

All factors are table-driven in `backend/app/rules/`.

## Request Flow

```
Flutter/React → Dio/Axios → FastAPI Route → Service Layer → Repository → PostgreSQL
                                  ↓
                            AI Service (when needed)
                                  ↓
                         Pydantic Validation
                                  ↓
                          Business Rules
                                  ↓
                             Repository
```

## Database Schema (abbreviated)

```
users                    account + auth
user_profiles            display info, preferences
user_stats               current stat values (8 stats)
stat_snapshots           daily snapshots for trend charts
goals                    user goals
goal_milestones          milestones within goals
skills                   global skill catalog
user_skills              user's progress per skill
missions                 mission instances
mission_completions      completion records
mission_evidence         reflection / evidence text
xp_transactions          IMMUTABLE XP ledger (append-only)
levels                   XP threshold table
user_levels              current level state
achievements             achievement definitions
user_achievements        earned achievements
journal_entries          reflection journal
ai_conversations         Coach conversation sessions
ai_messages              individual messages
weekly_reviews           AI-generated weekly summaries
```

## Security Model

- JWT: 15-minute access token + 30-day refresh token
- Web: access token in memory, refresh token in httpOnly cookie
- Mobile: both tokens in Flutter Secure Storage (Keychain/Keystore)
- AI API keys: server-side only, never exposed to clients
- Database credentials: server-side only

## Folder Structure

```
backend/app/
  api/v1/routes/   — thin HTTP layer, no business logic
  services/        — all business logic
  repositories/    — all database queries
  rules/           — XP tables, difficulty configs, caps
  ai/agents/       — one file per AI agent
  ai/prompts/      — versioned prompt templates
  models/          — SQLAlchemy ORM
  schemas/         — Pydantic request/response

web/src/
  features/        — co-located feature slices
  shared/          — design system, API client, utilities

mobile/lib/
  features/        — data/domain/presentation per feature
  core/            — network, theme, routing, storage
  shared/          — shared widgets and models
```
