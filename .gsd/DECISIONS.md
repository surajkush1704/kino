# DECISIONS.md — Architecture Decision Record

> This file logs significant technical decisions made during the project.

---

## ADR-001: Local-first watchlist storage (Phase 1)

**Date:** 2026-03-17
**Status:** Accepted

**Decision:** Use SQLite (`sqflite` package) on-device for watchlist and watched state in Phase 1. Migrate to cloud-synced storage in Phase 2 after auth is working.

**Rationale:** Decouples Phase 1 from backend work. Faster to ship. Works fully offline. Local state doesn't require auth complexity. Migration path is well-defined.

**Consequences:** Phase 2 will need a data migration step from local SQLite → backend API on first login.

---

## ADR-002: Custom FastAPI JWT auth (not Firebase)

**Date:** 2026-03-17
**Status:** Accepted

**Decision:** Implement user authentication using custom FastAPI endpoints with JWT tokens (`python-jose`, `passlib[bcrypt]`). Store JWT securely on device using `flutter_secure_storage`.

**Rationale:** MCA final project requires demonstration of backend development skills. Firebase would obscure the full-stack architecture. Custom JWT shows real understanding of auth systems and integrates naturally with the existing FastAPI backend.

**Consequences:** Phase 2 takes longer than Firebase would. Auth endpoints need careful implementation (hashing, token expiry, refresh strategy). Increased attack surface — must validate inputs properly.

---

## ADR-003: Backend deployment target

**Date:** 2026-03-17
**Status:** Open — to be decided in Phase 3

**Candidates:** Railway, Render, Fly.io
**Decision:** TBD. Evaluate based on free-tier limits and ease of Python/FastAPI deployment.
