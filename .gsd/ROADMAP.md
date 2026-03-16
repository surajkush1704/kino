# ROADMAP.md

> **Current Phase**: Phase 1 — Library & Watchlist
> **Milestone**: v1.0 — May 2026 (Play Store + MCA Submission)
> **Updated**: 2026-03-17

---

## Must-Haves for May 2026

- [ ] Persistent watchlist (SQLite, local-first)
- [ ] "Watched" state tracking
- [ ] Library screen with Watchlist + Watched tabs
- [ ] User registration + login (FastAPI JWT)
- [ ] Profile screen (username, stats, top genres)
- [ ] Watchlist synced to backend (post-auth)
- [ ] Backend deployed to cloud (Railway / Render / Fly.io)
- [ ] Hardcoded `127.0.0.1` URL replaced with configurable base URL
- [ ] Gemini API key fully in `.env`
- [ ] Play Store APK / AAB submitted

---

## Phase 1 — Library & Watchlist Persistence
**Status**: ⬜ Not Started
**Target**: ~Week 1–2 (by ~March 31)
**Objective**: Give users a persistent library — movies they want to watch and movies they've watched — surviving app restarts. No auth required; local SQLite.

### Tasks
- [ ] Add `sqflite` + `path` Flutter dependency
- [ ] Create `DatabaseHelper` service (local SQLite with `watchlist` + `watched` tables)
- [ ] Wire "Add to Watchlist" / "Mark Watched" buttons in `MovieDetailScreen` to DB
- [ ] Persist heart/like state on `HomeScreen` (SQLite or SharedPreferences)
- [ ] Build out `LibraryScreen` — Watchlist tab + Watched tab, movie cards, remove action
- [ ] Empty-state UI for both tabs
- [ ] Fix `_selectedIndex` dead nav bar in `MovieDetailScreen`

**Requirements:** REQ-01 through REQ-06

---

## Phase 2 — User Auth & Profile
**Status**: ⬜ Not Started
**Target**: ~Week 3–4 (by ~April 14)
**Objective**: Full custom JWT auth via the existing FastAPI backend. Users get persistent identities. Watchlist migrates to the cloud and becomes user-specific.

### Backend Tasks
- [ ] Add `users` table design (Postgres or SQLite on server)
- [ ] Add `python-jose` + `passlib[bcrypt]` dependencies
- [ ] `POST /api/v1/auth/register` — create user, hash password, return JWT
- [ ] `POST /api/v1/auth/login` — verify credentials, return JWT
- [ ] `GET /api/v1/auth/me` — return current user (JWT-protected)
- [ ] `POST /api/v1/users/watchlist` — add movie (JWT-protected)
- [ ] `DELETE /api/v1/users/watchlist/{id}` — remove movie (JWT-protected)
- [ ] `GET /api/v1/users/watchlist` — fetch user's watchlist (JWT-protected)
- [ ] `POST /api/v1/users/watched` — mark movie watched (JWT-protected)
- [ ] `GET /api/v1/users/watched` — fetch watched history (JWT-protected)
- [ ] JWT middleware / dependency injection for protected routes

### Flutter Tasks
- [ ] Add `flutter_secure_storage` dependency
- [ ] `LoginScreen` — email + password + "Register" link
- [ ] `RegisterScreen` — name + email + password + confirm
- [ ] `AuthService` — register / login, store JWT in secure storage
- [ ] Auth gate in `main.dart` — show login or main app based on token
- [ ] `ProfileScreen` — avatar, username, joined date, watchlist count, watched count, top genres
- [ ] Migrate local SQLite watchlist to API calls post-login
- [ ] Add JWT Bearer header to all `ApiService` calls

**Requirements:** REQ-07 through REQ-15

---

## Phase 3 — Polish, Security & Play Store Launch
**Status**: ⬜ Not Started
**Target**: ~Week 5–6 (by ~May 2)
**Objective**: Production-ready. Backend live on cloud. App ships on Play Store. MCA submission materials ready.

### Backend Tasks
- [ ] Deploy FastAPI backend to Railway / Render / Fly.io
- [ ] Move `GEMINI_API_KEY` fully to `.env` (remove hardcoded fallback in `ai.py`)
- [ ] Configure CORS for production domain
- [ ] Add basic rate limiting (fastapi-limiter or SlowAPI)
- [ ] Remove unused `openai` dependency from `requirements.txt`
- [ ] Replace `print()` statements with proper Python `logging`
- [ ] Choose and configure production database (SQLite → Postgres recommended)

### Flutter Tasks
- [ ] Replace hardcoded `baseUrl` with build-time config (`--dart-define` or `.env`)
- [ ] App icon (all Android densities via `flutter_launcher_icons`)
- [ ] Splash screen polish (finalize animated logo timing)
- [ ] Play Store listing: description, screenshots (6), feature graphic, privacy policy
- [ ] Sign release AAB with keystore
- [ ] Submit to Google Play — Internal Testing → Closed Testing → Production

### Academic Materials
- [ ] Architecture diagram (from ARCHITECTURE.md)
- [ ] API documentation (routes, auth flow, AI pipeline)
- [ ] README.md with setup instructions, tech stack, and feature list

**Requirements:** REQ-16 through REQ-22

---

## Phase 4 — Discovery Enhancements (Post-May)
**Status**: ⬜ Backlog
**Objective**: Richer discovery — decade filters, AI explanation cards, similar movies from watchlist patterns.

- [ ] Decade filter in Vibe Check / Search
- [ ] AI explanation card ("Why we picked this for you")
- [ ] "More like your watchlist" recommendation mode
- [ ] Certified Fresh / Rotten Tomatoes badge integration

---

## Phase 5 — Engagement & Social (Post-May)
**Status**: ⬜ Backlog
**Objective**: Retention features and lightweight social layer.

- [ ] Friends / follow system
- [ ] Shared lists
- [ ] Push notifications (new releases matching saved vibes)
- [ ] Ratings and personal reviews

---

## Phase 6 — Cloud Infrastructure Upgrade (Post-May)
**Status**: ⬜ Backlog
**Objective**: Scale backend for real traffic. Redis caching, CDN, monitoring.

- [ ] Redis caching layer for TMDB responses (TTL: 1 hour)
- [ ] Sentry error monitoring
- [ ] PostgreSQL fully managed (Supabase / Neon)
- [ ] iOS App Store submission
