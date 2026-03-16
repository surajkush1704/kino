# SPEC.md — Project Specification

> **Status**: `FINALIZED`
> **Updated**: 2026-03-17
> **Milestone**: v1.0 — May 2026 (Play Store + MCA Final Project)

---

## Vision

Kino is a mood-driven movie discovery app for Android. Users describe how they feel in natural language, and an AI engine translates that into curated film recommendations drawn live from TMDB. By May 2026, Kino must ship on the Google Play Store as a complete, polished product — featuring a persistent library, full user authentication, and a cloud-deployed backend — meeting both public launch standards and MCA final-year project academic requirements.

---

## Goals

1. **Library & Watchlist persistence** — Users can save movies to a watchlist and mark films as watched, persisted locally via SQLite (Phase 1), then synced to the cloud (Phase 2).
2. **User auth & profiles** — Secure JWT-based auth (custom FastAPI backend) with sign-up, login, and a personal profile screen showing watch history and top genres. Demonstrates full-stack backend skills for MCA submission.
3. **Cloud deployment** — Backend deployed to a public hosting provider (Railway / Render / Fly.io), replacing the local `127.0.0.1` hardcoded URL, making the app fully independent of the dev machine.
4. **Play Store readiness** — App icons, splash screen, production build, Play Store listing assets.

---

## Non-Goals (Out of Scope for May 2026)

- TV show discovery (movies only)
- Social features (sharing, following other users)
- Push notifications
- Streaming availability / JustWatch integration
- Director / actor person search
- Reviews or ratings system
- iOS App Store submission (Android Play Store only for May)
- Phase 3–5 features (decade filter, AI explanation card, recommendation engine)

---

## Users

**Primary:** Mobile movie enthusiasts who want discovery beyond generic search — people who know how they *feel* but not what to watch. Indian + global cinema audience.

**Academic evaluator:** MCA final-year project professor who will assess full-stack architecture, code quality, and demonstrated competency in FastAPI, Flutter, JWT auth, and cloud deployment.

---

## Constraints

- **Timeline:** ~6–7 weeks to May 2026 submission/submission date
- **Tech:** Must use existing FastAPI backend (Python) and Flutter frontend — no rebuilds
- **Auth:** Custom JWT (FastAPI) — not Firebase — for academic demonstration value
- **Watchlist storage:** Local-first (SQLite on device) in Phase 1; cloud-synced in Phase 2 after auth is working
- **Backend URL:** Must be configurable (env-based), not hardcoded `127.0.0.1`
- **Solo developer:** One person building everything

---

## Success Criteria

### Phase 1 — Library (Complete by ~Week 2)
- [ ] User can add/remove movies to a persistent watchlist (survives app restart)
- [ ] User can mark movies as "watched"
- [ ] Library screen shows Watchlist and Watched tabs with movie cards
- [ ] Heart/like state on HomeScreen persists across sessions

### Phase 2 — Auth & Profile (Complete by ~Week 4)
- [ ] User can register with email + password (FastAPI + JWT)
- [ ] User can log in and receive a JWT stored securely on device
- [ ] Profile screen shows username, join date, watch count, top genres
- [ ] Watchlist and watched state migrated to be user-specific (backend)
- [ ] Kino API protected routes require valid JWT

### Phase 3 — Polish & Deployment (Complete by ~Week 6)
- [ ] Backend deployed to cloud (Railway / Render / Fly.io)
- [ ] Flutter `baseUrl` configurable via build config (not hardcoded)
- [ ] App icons, splash screen assets finalized
- [ ] Gemini API key moved fully to `.env` (no hardcoded fallback)
- [ ] Play Store listing created with screenshots, description, privacy policy
- [ ] Production APK / AAB built and submitted
