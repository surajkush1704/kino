# REQUIREMENTS.md

> Auto-generated from SPEC.md — 2026-03-17

| ID | Requirement | Phase | Status |
|----|-------------|-------|--------|
| REQ-01 | User can add a movie to a watchlist that persists across app restarts | Phase 1 | Pending |
| REQ-02 | User can remove a movie from the watchlist | Phase 1 | Pending |
| REQ-03 | User can mark a movie as "watched" (persisted across restarts) | Phase 1 | Pending |
| REQ-04 | Library screen displays Watchlist tab and Watched tab with movie cards | Phase 1 | Pending |
| REQ-05 | Empty-state UI shown when watchlist or watched list is empty | Phase 1 | Pending |
| REQ-06 | Heart/like state on HomeScreen persists across sessions | Phase 1 | Pending |
| REQ-07 | User can register with email + password via FastAPI backend | Phase 2 | Pending |
| REQ-08 | User can log in and receive a JWT stored securely on device | Phase 2 | Pending |
| REQ-09 | JWT is sent as Bearer token on all authenticated API requests | Phase 2 | Pending |
| REQ-10 | Profile screen shows username, join date, watchlist count, watched count | Phase 2 | Pending |
| REQ-11 | Profile screen shows user's top genres (derived from watched history) | Phase 2 | Pending |
| REQ-12 | Watchlist sync: local SQLite migrated to cloud API on login | Phase 2 | Pending |
| REQ-13 | FastAPI `/auth/register` and `/auth/login` routes implemented | Phase 2 | Pending |
| REQ-14 | FastAPI `/users/watchlist` and `/users/watched` routes (JWT-protected) | Phase 2 | Pending |
| REQ-15 | App shows login screen when no valid JWT is found on device | Phase 2 | Pending |
| REQ-16 | Backend deployed to cloud; app uses configurable non-hardcoded base URL | Phase 3 | Pending |
| REQ-17 | Gemini API key fully loaded from `.env` (no hardcoded fallback) | Phase 3 | Pending |
| REQ-18 | Unused `openai` dependency removed from `requirements.txt` | Phase 3 | Pending |
| REQ-19 | App icon set for all Android densities | Phase 3 | Pending |
| REQ-20 | Play Store listing created with description, screenshots, privacy policy | Phase 3 | Pending |
| REQ-21 | Production release AAB built and signed with keystore | Phase 3 | Pending |
| REQ-22 | `print()` statements replaced with proper `logging` in backend | Phase 3 | Pending |
