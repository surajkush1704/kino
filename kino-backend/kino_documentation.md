# 🎬 KINO — Complete Project Documentation

> **Last Updated:** March 17, 2026 | Version: 1.0.0+1

---

## 1. Project Overview

**Kino** is a mood-driven movie discovery app built with Flutter (mobile) on the front end and FastAPI (Python) on the back end. It goes beyond standard search — users describe how they *feel*, and Kino uses **Gemini AI** to translate that into curated movie recommendations pulled live from **The Movie Database (TMDB)**.

### Core Philosophy
- **Vibe-first discovery** — Feel something → get movies
- **Indian + Global mix** — Regional language cinema is a first-class citizen
- **Premium dark aesthetic** — Cinema-grade UI (deep blacks, Kintsugi gold logo, glassmorphism)

---

## 2. Tech Stack

| Layer | Technology | Version |
|-------|-----------|---------|
| Mobile Frontend | Flutter + Dart | SDK ^3.10.8 |
| Backend API | FastAPI | Latest |
| ASGI Server | Uvicorn | Latest (standard extras) |
| HTTP Client (backend) | httpx | Latest (async) |
| Configuration | Pydantic Settings + python-dotenv | Latest |
| AI Engine | Google Gemini 2.0 Flash | via `google-generativeai` |
| Movie Data Source | TMDB API v3 | REST |
| State / Persistence | SharedPreferences | ^2.2.2 |
| Fonts | Google Fonts (Cinzel Decorative) | ^8.0.2 |
| YouTube Integration | youtube_player_flutter | ^9.0.1 |
| Link Launcher | url_launcher | ^6.3.1 |
| Card Swiper | flutter_card_swiper | ^7.0.0 |
| HTTP (Flutter) | http | ^1.6.0 |

---

## 3. Repository Structure

```
d:\kino\
├── kino-backend\                  ← FastAPI Backend
│   ├── requirements.txt           ← Python dependencies
│   ├── .env                       ← TMDB_API_KEY, GEMINI_API_KEY (gitignored)
│   └── app\
│       ├── main.py                ← FastAPI app creation, router mounting
│       ├── core\
│       │   └── config.py          ← Pydantic Settings (loads .env)
│       ├── api\
│       │   └── routes.py          ← All API route definitions
│       ├── services\
│       │   ├── tmdb.py            ← TMDB API calls & normalization
│       │   └── ai.py              ← Gemini AI vibe analysis
│       └── models\                ← (placeholder for Pydantic models)
│
└── kino_mobile\                   ← Flutter App
    ├── pubspec.yaml               ← Flutter dependencies
    ├── assets\images\             ← Local image assets
    └── lib\
        ├── main.dart              ← Entry point → SplashScreen
        ├── movie_detail_screen.dart  ← Full movie detail page
        ├── screens\
        │   ├── splash_screen.dart
        │   ├── main_screen.dart
        │   ├── main_wrapper_screen.dart  ← Bottom nav shell
        │   ├── home_screen.dart          ← Trending + Regional + Vibe shortcut
        │   ├── search_screen.dart        ← Keyword search with card swiper
        │   ├── vibe_check_screen.dart    ← AI mood-based discovery
        │   ├── anime_screen.dart         ← Anime movies + genre filter
        │   └── library_screen.dart       ← (STUB — Coming Soon)
        ├── services\
        │   └── api_service.dart    ← Flutter HTTP wrapper → backend
        └── widgets\
            └── kino_logo.dart      ← Animated Kintsugi gold KINO logo
```

---

## 4. Backend API — Full Reference

> **Base URL (local):** `http://127.0.0.1:8000`
> **API Prefix:** `/api/v1`
> **Full base:** `http://127.0.0.1:8000/api/v1`

---

### `GET /api/v1/movies/trending`

Returns this week's globally trending movies.

**Source:** `TMDB /trending/movie/week`

**Response:** `Array<Movie>`

```json
[
  {
    "id": 12345,
    "title": "Interstellar",
    "overview": "...",
    "vote_average": 8.7,
    "release_date": "2014-11-07",
    "poster_path": "/gEU2QniE6E77NI6lCU6MxlNBvIx.jpg",
    "tags": ["Trending"]
  }
]
```

---

### `GET /api/v1/movies/regional`

Returns a mixed list of Indian regional language films — Tamil, Telugu, Malayalam, Kannada, Hindi — interleaved in a round-robin pattern.

**Source:** `TMDB /discover/movie` × 5 language calls (concurrent via `asyncio.gather`)

**Response:** `Array<Movie>` (tag: `"Regional"`)

---

### `GET /api/v1/search/movie?query=<string>`

Standard keyword search against TMDB. Results are **enhanced** — each movie in the top 30 gets full details (runtime, rating, trailer key, genres) fetched concurrently.

**Query Params:**
| Param | Type | Required | Description |
|-------|------|----------|-------------|
| `query` | string | ✅ | Search keyword(s) |

**Response:** `Array<EnhancedMovie>` — same as Movie but with `runtime`, `rating`, `trailer_key`, `genres` added.

---

### `GET /api/v1/search/vibe?query=<string>&sort=<string>`

**The core AI feature.** A 3-step pipeline:

1. **Gemini AI** analyzes the natural-language query → returns structured JSON (mood, genres, tone, rating, keywords)
2. **TMDB Discover** uses those filters to fetch English + Hindi film lists concurrently (2 languages × random page 1–4)
3. **Enhancement pass** — top 30 results enriched with full details (runtime, trailer, certification)

**Query Params:**
| Param | Type | Required | Default | Description |
|-------|------|----------|---------|-------------|
| `query` | string | ✅ | — | Natural language mood/vibe |
| `sort` | string | ❌ | `"popularity"` | `"popularity"` or `"top_rated"` |

**AI JSON Schema (returned from Gemini):**
```json
{
  "mood": "emotional",
  "genres": ["Drama", "Romance"],
  "tone": "Emotional",
  "rating": "PG-13",
  "keywords": ["heartbreak", "tragedy", "loss"]
}
```

**Full Response:**
```json
{
  "movies": [ /* Array<EnhancedMovie> */ ],
  "metadata": {
    "mood": "emotional",
    "genres": ["Drama", "Romance"],
    "tone": "Emotional",
    "rating": "PG-13",
    "keywords": ["heartbreak", "tragedy", "loss"]
  }
}
```

The [metadata](file:///d:/kino/kino_mobile/.metadata) object (AI insights) is displayed as tags/chips in the Flutter UI (VibeCheckScreen).

---

### `GET /api/v1/movie/{movie_id}/details`

Fetches a rich, fully detailed movie object using TMDB's `append_to_response` feature in a single HTTP call.

**Path Params:**
| Param | Type | Required |
|-------|------|----------|
| `movie_id` | int | ✅ |

**Response:**
```json
{
  "id": 12345,
  "title": "Interstellar",
  "overview": "...",
  "poster_path": "/...",
  "backdrop_path": "/...",
  "release_date": "2014-11-07",
  "runtime": 169,
  "vote_average": 8.7,
  "genres": ["Science Fiction", "Adventure", "Drama"],
  "spoken_languages": [{"english_name": "English"}],
  "trailer_key": "zSWdZVtXT7E",
  "screenshots": ["/backdrop1.jpg", "/backdrop2.jpg"],
  "cast": [
    { "name": "Matthew McConaughey", "role": "Cooper", "image": "/actor.jpg" }
  ],
  "rating": "PG-13",
  "similar_movies": [ /* Array<Movie> — 6 items */ ]
}
```

**TMDB `append_to_response`:** `credits,videos,release_dates,similar,images`

---

### `GET /api/v1/anime`

Returns up to **40 unique** anime movies by merging 4 concurrent TMDB queries (Japanese-language animation × 2 pages + anime-keyworded animation × 2 pages). Deduplication is done via `seen_ids` set.

**Response:** `Array<Movie>` (tag: `"Anime"`)

---

### `GET /`

**Health check.**

```json
{ "status": "Kino Backend Running" }
```

---

## 5. AI Engine — Gemini Vibe Analyzer

**File:** [kino-backend/app/services/ai.py](file:///d:/kino/kino-backend/app/services/ai.py)

**Model:** `gemini-2.0-flash`

**Prompt Strategy:** Few-shot example-driven mapping. 14 user intent categories are hard-coded as reference examples in the system prompt:

| Category | Genres | Tone | Rating |
|----------|--------|------|--------|
| Sad / Emotional | Drama, Romance | Emotional | PG-13+ |
| Feel Good | Comedy, Family | Uplifting | PG-13 |
| Comedy | Comedy | Light/Funny | PG-13 |
| Adult Comedy | Comedy, Dark Comedy | Raunchy | R/18+ |
| Romantic | Romance, Drama | Romantic | PG-13+ |
| Dark / Gore | Horror, Thriller | Dark/Intense | R/18+ |
| Action | Action, Adventure | Intense | PG-13/R |
| Adventure | Adventure, Fantasy | Exciting | PG-13 |
| Sci-Fi | Sci-Fi | Futuristic | PG-13/R |
| Psychological | Thriller, Mystery, Sci-Fi | Psychological | PG-13/R |
| Anime | Animation, Fantasy, Adventure | Stylized | PG-13+ |
| Cult Classics | Drama, Crime | — | PG-13/R |
| Motivational | Biography, Drama, Sports | Inspirational | PG-13 |
| Family | Family, Animation, Comedy | Wholesome | PG |

**Fallback:** If Gemini crashes, returns a generic fallback dict that still lets the discovery pipeline run.

---

## 6. TMDB Service — Normalization Schema

All TMDB results are passed through [_normalize()](file:///d:/kino/kino-backend/app/services/tmdb.py#23-34) before being returned:

```python
{
  "id": int,
  "title": str,
  "overview": str,
  "vote_average": float,
  "release_date": str,
  "poster_path": str | None,
  "tags": [str]     # e.g. "Trending", "Regional", "Anime", "EN Vibe"
}
```

Genre name → TMDB ID mapping is handled via `TMDBService.GENRE_MAP` (20 genres supported).

---

## 7. Flutter App — Screen Inventory

### 🎬 SplashScreen ([splash_screen.dart](file:///d:/kino/kino_mobile/lib/screens/splash_screen.dart))
- Animated logo entry with sweep light effect
- Auto-navigates to [MainWrapperScreen](file:///d:/kino/kino_mobile/lib/screens/main_wrapper_screen.dart#8-14) after delay

### 🏠 HomeScreen ([home_screen.dart](file:///d:/kino/kino_mobile/lib/screens/home_screen.dart))
- **PageView carousel** — top 7 trending movies, auto-slides every 4s with smooth `fastOutSlowIn` curve
- **Bento Grid section** — regional language movies in masonry layout
- **"Vibe Check" shortcut card** — quick access to AI discovery
- Heart/like toggle per movie card (in-session state)
- Floating [KinoLogo](file:///d:/kino/kino_mobile/lib/widgets/kino_logo.dart#8-82) with animated light sweep
- Navigation via bottom nav bar ([MainWrapperScreen](file:///d:/kino/kino_mobile/lib/screens/main_wrapper_screen.dart#8-14))

### 🔍 SearchScreen ([search_screen.dart](file:///d:/kino/kino_mobile/lib/screens/search_screen.dart))
- Text input → calls `/api/v1/search/movie`
- Results rendered as **flutter_card_swiper** stack (swipe left/right)
- Each card shows: poster, title, rating, genre chips
- Tap card → [MovieDetailScreen](file:///d:/kino/kino_mobile/lib/movie_detail_screen.dart#9-17)

### ✨ VibeCheckScreen ([vibe_check_screen.dart](file:///d:/kino/kino_mobile/lib/screens/vibe_check_screen.dart))
- Natural language input field (e.g. "I want to cry tonight")
- **Suggestion chips** (8 pre-set vibey prompts, shuffled on screen load)
- **Recent Searches** — persisted via `SharedPreferences`, last 6, shown as chips
- Sort toggle: Popularity vs. Top Rated
- On submit → calls `/api/v1/search/vibe`
- Results as swipeable card stack + metadata chips (mood, genres, tone from AI)
- Shows `_vibeMetadata` as colored tag row below the cards

### 🎌 AnimeScreen ([anime_screen.dart](file:///d:/kino/kino_mobile/lib/screens/anime_screen.dart))
- Calls `/api/v1/anime` on load
- **Genre filter chips** (client-side by `genre_ids`): All, Action, Adventure, Fantasy, Sci-Fi, Romance, Thriller, Drama, Comedy, Mystery
- Pull-to-refresh
- Grid layout → tap → [MovieDetailScreen](file:///d:/kino/kino_mobile/lib/movie_detail_screen.dart#9-17)

### 📚 LibraryScreen ([library_screen.dart](file:///d:/kino/kino_mobile/lib/screens/library_screen.dart))
- **STUB** — placeholder "Library Coming Soon" text
- Pure black scaffold

### 🎬 MovieDetailScreen ([movie_detail_screen.dart](file:///d:/kino/kino_mobile/lib/movie_detail_screen.dart))
- Called from any screen by pushing with a movie object
- Calls `/api/v1/movie/{id}/details` on init
- **Sections:**
  - Hero backdrop image with blur overlay
  - Title, year, runtime (formatted as Xh Ym), rating badge
  - Genre + language chips
  - "Play Trailer" button → full-screen YouTube dialog (youtube_player_flutter)
  - Overview text
  - Screenshot gallery (horizontal scroll, backdrop images)
  - Cast row (avatar + name + character)
  - "Similar Movies" horizontal list
  - Watchlist / Watched toggle buttons (UI only — no persistence yet)

---

## 8. Flutter Data Flow

```
User Action
    │
    ▼
Screen Widget
    │  calls
    ▼
ApiService.dart (http package)
    │  HTTP GET → localhost:8000/api/v1/...
    ▼
FastAPI Backend (routes.py)
    │
    ├── TMDBService.py
    │       └── httpx async → api.themoviedb.org
    │
    └── AIService.py (vibe only)
            └── google-generativeai → Gemini 2.0 Flash
                    └── returns structured JSON
    │
    ▼
JSON response → Dart `json.decode` → `setState` → Widget rebuild
```

---

## 9. Configuration & Environment Variables

**Backend [.env](file:///d:/kino/kino_mobile/.env) file** (must exist at [kino-backend/.env](file:///d:/kino/kino-backend/.env)):

```env
TMDB_API_KEY=your_tmdb_v3_api_key
GEMINI_API_KEY=your_gemini_api_key
OPENAI_API_KEY=          # currently unused (placeholder)
```

**Flutter [api_service.dart](file:///d:/kino/kino_mobile/lib/services/api_service.dart):**
The `baseUrl` is hardcoded as `http://127.0.0.1:8000`. For device testing, this must be changed to the machine's LAN IP (e.g., `http://192.168.x.x:8000`).

> ⚠️ **Known Issue:** The Gemini API key is currently also hardcoded directly in [ai.py](file:///d:/kino/kino-backend/test_ai.py) as a fallback. It should be moved to [.env](file:///d:/kino/kino_mobile/.env) / `settings.GEMINI_API_KEY` for production.

---

## 10. Running the Project

### Backend
```powershell
cd d:\kino\kino-backend
pip install -r requirements.txt
uvicorn app.main:app --reload
# Server → http://127.0.0.1:8000
# Docs   → http://127.0.0.1:8000/docs
```

### Flutter
```powershell
cd d:\kino\kino_mobile
flutter pub get
flutter run
```

---

## 11. Current State of the App ✅

| Feature | Status |
|---------|--------|
| Splash screen with animated logo | ✅ Done |
| Home: Trending carousel (auto-slide) | ✅ Done |
| Home: Regional language bento grid | ✅ Done |
| Search: Keyword search + card swiper | ✅ Done |
| Vibe Check: AI mood search | ✅ Done |
| Vibe Check: Recent searches (persisted) | ✅ Done |
| Vibe Check: Sort toggle | ✅ Done |
| Anime: Full list + genre filter | ✅ Done |
| Movie Detail: Full info page | ✅ Done |
| Movie Detail: YouTube trailer player | ✅ Done |
| Movie Detail: Screenshots gallery | ✅ Done |
| Movie Detail: Cast row | ✅ Done |
| Movie Detail: Similar movies | ✅ Done |
| Watchlist / Watched buttons (UI only) | ⚠️ UI exists, no persistence |
| Library screen | ❌ Stub only |
| User auth / profiles | ❌ Not started |

---

## 12. Known Issues & Technical Debt

| # | Issue | Severity | File |
|---|-------|----------|------|
| 1 | Gemini API key hardcoded in [ai.py](file:///d:/kino/kino-backend/test_ai.py) instead of reading from `settings` | 🔴 High | `services/ai.py:22` |
| 2 | `baseUrl` in Flutter is hardcoded `127.0.0.1` — breaks on physical devices | 🟡 Medium | [services/api_service.dart](file:///d:/kino/kino_mobile/lib/services/api_service.dart) |
| 3 | `_isInWatchlist` / `_isWatched` state in MovieDetailScreen is not persisted | 🟡 Medium | [movie_detail_screen.dart](file:///d:/kino/kino_mobile/lib/movie_detail_screen.dart) |
| 4 | `_selectedIndex` in MovieDetailScreen is always 0 (dead nav bar) | 🟢 Low | `movie_detail_screen.dart:21` |
| 5 | Like/heart button in HomeScreen is in-memory only (lost on navigate) | 🟢 Low | [home_screen.dart](file:///d:/kino/kino_mobile/lib/screens/home_screen.dart) |
| 6 | `openai` in requirements.txt but not used | 🟢 Low | [requirements.txt](file:///d:/kino/kino-backend/requirements.txt) |
| 7 | No loading retry on API failure | 🟢 Low | Multiple screens |
| 8 | `print()` debug statements in production backend | 🟢 Low | [tmdb.py](file:///d:/kino/kino-backend/app/services/tmdb.py), [ai.py](file:///d:/kino/kino-backend/test_ai.py) |

---

## 13. Future Roadmap 🚀

### Phase 1 — Library & Persistence (Next)
- [ ] **Watchlist** — Save movies to a local SQLite or SharedPreferences watchlist (reuse existing UI buttons in MovieDetailScreen)
- [ ] **Library Screen** — Display Watched + Watchlist tabs with movie cards
- [ ] **Persist likes/hearts** from HomeScreen across sessions

### Phase 2 — Social & Profiles
- [ ] **User Profile** — Name, avatar, stats (movies watched, genres loved)
- [ ] **Top Genres** — Derived from watch history
- [ ] **Streak / Activity** — Films watched per week

### Phase 3 — Discovery Enhancements
- [ ] **Director/Actor Search** — Search by people, not just titles
- [ ] **Decade Filter** — "Show me 90s thrillers"
- [ ] **Streaming Availability** — Where to watch (JustWatch API integration via TMDB)
- [ ] **More Languages** — Add South Indian languages to VibeCheck (currently en + hi only)
- [ ] **AI Explanation Card** — Show Gemini's reasoning ("We picked these because you said you're feeling X")

### Phase 4 — Engagement
- [ ] **Reviews / Notes** — Users can write a personal review after watching
- [ ] **Ratings** — User can rate movies 1–5 stars (stored locally)
- [ ] **Recommendations engine** — Based on watch history and liked genres
- [ ] **Push Notifications** — "New release in your favorite genre"

### Phase 5 — Platform & Infra
- [ ] **Move backend to cloud** — Railway / Render / Fly.io hosting
- [ ] **Replace 127.0.0.1** with env-based configurable URL
- [ ] **Move API keys to [.env](file:///d:/kino/kino_mobile/.env) fully** — no hardcoded keys
- [ ] **Add caching** — Redis / in-memory TTL cache for trending + anime (they hardly change minute-to-minute)
- [ ] **Error handling & retry logic** — Exponential backoff on TMDB failures
- [ ] **TMDB Rate Limit handling** — Respect `X-RateLimit-*` headers
- [ ] **TV Shows** — Extend discovery to series not just movies

---

## 14. Image URL Construction

TMDB image paths are relative. To construct full URLs:

```
Poster  (w500) : https://image.tmdb.org/t/p/w500{poster_path}
Backdrop(w1280): https://image.tmdb.org/t/p/w1280{backdrop_path}
Profile (w185) : https://image.tmdb.org/t/p/w185{profile_path}
Original       : https://image.tmdb.org/t/p/original{file_path}
```

---

## 15. Design System

| Element | Value |
|---------|-------|
| Background | `#121212` (near-black) |
| Primary Accent | `Colors.purpleAccent` |
| Secondary Accent | `Colors.redAccent` |
| Logo Font | Cinzel Decorative (Google Fonts) |
| Logo Colors | Antique Bronze `#B8860B` → Champagne `#F7E7CE` → Metallic Gold `#D4AF37` |
| Glass Effect | `BackdropFilter(ImageFilter.blur(...))` |
| Card corners | Rounded (8–16px) |
| Text | White / White54 / White38 hierarchy |

The [KinoLogo](file:///d:/kino/kino_mobile/lib/widgets/kino_logo.dart#8-82) widget accepts a `sweepValue` (0.0–1.0) that animates the gold light sweep across the letters — used in the splash screen animation.
