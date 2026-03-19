import httpx
import asyncio
from typing import Optional, List, Dict, Any
from app.core.config import settings

# Errors that are worth retrying (network hiccups, transient server errors)
_RETRIABLE = (httpx.ConnectError, httpx.TimeoutException, httpx.RemoteProtocolError)

class TMDBService:
    # ---------------------------------------------------------
    # MAKE SURE THIS LINE IS EXACTLY AS SHOWN BELOW:
    BASE_URL = "https://api.themoviedb.org/3"
    # ---------------------------------------------------------
    
    @staticmethod
    async def _fetch(endpoint: str, params: Optional[dict] = None, _retries: int = 3):
        """Fetch from TMDB with exponential backoff retry for network errors and 5xx/429."""
        if params is None: params = {}
        params["api_key"] = settings.TMDB_API_KEY
        full_url = f"{TMDBService.BASE_URL}{endpoint}"

        last_exc: Exception = RuntimeError("Unknown error")
        for attempt in range(_retries):
            try:
                async with httpx.AsyncClient(timeout=10.0) as client:
                    response = await client.get(full_url, params=params)

                    # Retry on 429 (TMDB rate limit) and 5xx server errors
                    if response.status_code == 429 or response.status_code >= 500:
                        wait = 2 ** attempt  # 1s, 2s, 4s
                        print(f"[TMDB RETRY] HTTP {response.status_code} on {endpoint} — retrying in {wait}s (attempt {attempt + 1}/{_retries})")
                        await asyncio.sleep(wait)
                        last_exc = httpx.HTTPStatusError(
                            f"HTTP {response.status_code}", request=response.request, response=response
                        )
                        continue

                    response.raise_for_status()
                    return response.json()

            except _RETRIABLE as e:
                wait = 2 ** attempt  # 1s, 2s, 4s
                print(f"[TMDB RETRY] {type(e).__name__} on {endpoint} — retrying in {wait}s (attempt {attempt + 1}/{_retries})")
                last_exc = e
                await asyncio.sleep(wait)

        # All retries exhausted
        print(f"[TMDB FAILED] {endpoint} gave up after {_retries} attempts: {last_exc}")
        raise last_exc

    @staticmethod
    def _normalize(item: dict, custom_tag: str = "Trending") -> Dict[str, Any]:
        return {
            "id": item.get("id"),
            "title": item.get("title", "Unknown"),
            "overview": item.get("overview", "No description available."),
            "vote_average": item.get("vote_average", 0.0),
            "release_date": item.get("release_date", "Unknown"),
            "poster_path": item.get("poster_path"), 
            "tags": [custom_tag]
        }

    @staticmethod
    async def get_trending_movies():
        data = await TMDBService._fetch("/trending/movie/week")
        return [TMDBService._normalize(item) for item in data.get("results", [])]

    @staticmethod
    async def get_regional_mix():
        languages = ["ta", "te", "ml", "kn", "hi"]
        tasks = [TMDBService._fetch("/discover/movie", {"with_original_language": l, "sort_by": "popularity.desc", "region": "IN"}) for l in languages]
        results = await asyncio.gather(*tasks)
        final_mix = []
        for i in range(5):
            for res in results:
                movies = res.get("results", [])
                if len(movies) > i: final_mix.append(TMDBService._normalize(movies[i], "Regional"))
        return final_mix

    @staticmethod
    async def _enhance_results(results: List[Dict[str, Any]]):
        """Fetches runtime, certification, and trailer for the top 30 results in parallel."""
        enhanced_results = []
        
        # Limit to top 30 as requested by user
        subset = results[:30]
        
        tasks = [TMDBService.get_movie_details(m["id"]) for m in subset]
        details_list = await asyncio.gather(*tasks)
        
        for i, details in enumerate(details_list):
            if details:
                # Merge enriched data into the normalized result
                item = subset[i]
                item.update({
                    "runtime": details.get("runtime"),
                    "rating": details.get("rating"),
                    "trailer_key": details.get("trailer_key"),
                    "genres": details.get("genres")
                })
                enhanced_results.append(item)
            else:
                enhanced_results.append(subset[i])
        
        return enhanced_results

    GENRE_MAP = {
        "Action": 28, "Adventure": 12, "Animation": 16, "Comedy": 35, 
        "Crime": 80, "Documentary": 99, "Drama": 18, "Family": 10751, 
        "Fantasy": 14, "History": 36, "Horror": 27, "Music": 10402, 
        "Mystery": 9648, "Romance": 10749, "Sci-Fi": 878, "Science Fiction": 878,
        "Thriller": 53, "War": 10752, "Western": 37, "Biography": 36, "Sports": 10770 # Approximate mappings
    }

    @staticmethod
    async def search_with_vibe(ai_data: dict, sort_preference: str = "popularity"):
        print(f"DEBUG: Vibe Data -> {ai_data}")
        
        # 1. Map Genre Names to IDs
        genre_ids = []
        for g_name in ai_data.get("genres", []):
            clean_name = str(g_name).strip().title()
            if clean_name == "Sci-Fi": clean_name = "Science Fiction"
            if clean_name in TMDBService.GENRE_MAP:
                genre_ids.append(TMDBService.GENRE_MAP[clean_name])
        
        # 2. Determine Sorting & Page (Keeping Variety)
        ai_sort = ai_data.get("recommended_sorting", "popular")
        tmdb_sort = "popularity.desc"
        if ai_sort == "top_rated": tmdb_sort = "vote_average.desc"
        
        # 3. Rating / Certification Mapping
        import random
        rating_val = str(ai_data.get("rating", "")).upper()
        cert_params = {}
        if rating_val:
            # Simple mapping for common ratings
            if "R" in rating_val or "18+" in rating_val:
                cert_params = {"certification_country": "US", "certification": "R"}
            elif "PG-13" in rating_val:
                cert_params = {"certification_country": "US", "certification": "PG-13"}
            elif "PG" in rating_val:
                cert_params = {"certification_country": "US", "certification": "PG"}
            elif "G" in rating_val:
                cert_params = {"certification_country": "US", "certification": "G"}

        # 4. Release Date - ONLY RELEASED MOVIES
        import datetime
        today_str = datetime.date.today().isoformat()
        
        min_vote_count = 50
        
        async def fetch_for_lang(lang_code: str):
            random_page = random.randint(1, 4) if tmdb_sort == "popularity.desc" else 1
            
            p = {
                "include_adult": "false",
                "page": random_page,
                "vote_count.gte": min_vote_count,
                "sort_by": tmdb_sort,
                "with_original_language": lang_code,
                "primary_release_date.lte": today_str,
                "region": "IN" if lang_code == "hi" else None
            }
            p.update(cert_params)
            
            if genre_ids:
                p["with_genres"] = "|".join(map(str, genre_ids))
            
            ai_keywords = ai_data.get("keywords", [])
            if ai_keywords:
                keyword_ids = []
                for kw in ai_keywords[:3]:
                    try:
                        kw_search = await TMDBService._fetch("/search/keyword", {"query": kw})
                        kw_results = kw_search.get("results", [])
                        if kw_results:
                            keyword_ids.append(str(kw_results[0]["id"]))
                    except: continue
                if keyword_ids:
                    p["with_keywords"] = ",".join(keyword_ids)
            
            print(f"DEBUG: Vibe Params ({lang_code}) -> {p}")
            data = await TMDBService._fetch("/discover/movie", p)
            return [TMDBService._normalize(item, f"{lang_code.upper()} Vibe") for item in data.get("results", [])]

        results_tasks = [fetch_for_lang(l) for l in ["en", "hi"]]
        lang_results = await asyncio.gather(*results_tasks)
        
        combined = []
        max_len = max(len(r) for r in lang_results) if lang_results else 0
        for i in range(max_len):
            for r in lang_results:
                if i < len(r): combined.append(r[i])
        
        random.shuffle(combined)
        return await TMDBService._enhance_results(combined)

    @staticmethod
    async def search_movies(query: str):
        """Perform a standard keyword search on TMDB."""
        data = await TMDBService._fetch("/search/movie", {"query": query, "include_adult": "false"})
        results = data.get("results", [])
        normalized = [TMDBService._normalize(item, "Search Result") for item in results]
        return await TMDBService._enhance_results(normalized)

    @staticmethod
    async def get_anime_movies():
        """Fetches popular anime movies from TMDB using Japanese-language + Animation genre."""

        async def fetch_ja_page(page: int):
            """Japanese language animation movies."""
            return await TMDBService._fetch("/discover/movie", {
                "with_original_language": "ja",
                "with_genres": "16",           # Animation
                "sort_by": "popularity.desc",
                "vote_count.gte": 30,
                "page": page,
            })

        async def fetch_en_anime_page(page: int):
            """English-dubbed / international animation with anime keyword."""
            return await TMDBService._fetch("/discover/movie", {
                "with_genres": "16",           # Animation
                "with_keywords": "210024",     # TMDB keyword: anime
                "sort_by": "popularity.desc",
                "vote_count.gte": 30,
                "page": page,
            })

        # Run both passes concurrently across 2 pages each
        tasks = [
            fetch_ja_page(1),
            fetch_ja_page(2),
            fetch_en_anime_page(1),
            fetch_en_anime_page(2),
        ]
        all_pages = await asyncio.gather(*tasks)

        seen_ids = set()
        combined = []
        for page_data in all_pages:
            for item in page_data.get("results", []):
                if item["id"] not in seen_ids:
                    seen_ids.add(item["id"])
                    combined.append(TMDBService._normalize(item, "Anime"))

        return combined[:40]

    @staticmethod
    async def get_movie_details(movie_id: int):
        try:
            # 1. Fetch Basic Info + Videos + Credits + Release Dates + Similar + Images
            data = await TMDBService._fetch(
                f"/movie/{movie_id}", 
                params={"append_to_response": "credits,videos,release_dates,similar,images"}
            )
            
            # 2. Extract Genres
            genres = [g['name'] for g in data.get('genres', [])]

            # 3. Extract Trailer & Screenshots
            videos = [v for v in data.get('videos', {}).get('results', []) if v['site'] == 'YouTube']
            # CHANGED: Using 'trailer_key' to match Flutter code
            trailer = next((v['key'] for v in videos if v['type'] == 'Trailer'), None)
            
            # Get up to 5 backdrop images
            backdrop_images = [img['file_path'] for img in data.get('images', {}).get('backdrops', [])][:5]

            # 4. Extract Cast (Top 10)
            cast = []
            for actor in data.get('credits', {}).get('cast', [])[:10]:
                cast.append({
                    "name": actor['name'],
                    "role": actor['character'],
                    "image": actor['profile_path']
                })

            # 5. Extract Age Rating (Certification)
            rating = "Not Rated"
            for country in data.get('release_dates', {}).get('results', []):
                if country['iso_3166_1'] in ['US', 'IN']:
                    for release in country['release_dates']:
                        if release.get('certification'):
                            rating = release['certification']
                            break
                    if rating != "Not Rated": break
            
            # 6. Extract Similar Movies
            similar = [TMDBService._normalize(m, "Similar") for m in data.get('similar', {}).get('results', [])[:6]]

            return {
                "id": data.get("id"),
                "title": data.get("title"),
                "overview": data.get("overview"),
                "poster_path": data.get("poster_path"),
                "backdrop_path": data.get("backdrop_path"),
                "release_date": data.get("release_date"),
                "runtime": data.get("runtime"),
                "vote_average": data.get("vote_average"),
                "genres": genres,
                "spoken_languages": data.get("spoken_languages", []), # ADDED for Flutter Chips
                "trailer_key": trailer, # RENAMED from trailer_id to trailer_key
                "screenshots": backdrop_images,
                "cast": cast,
                "rating": rating, 
                "similar_movies": similar
            }
        except Exception as e:
            print(f"Error fetching details: {e}")
            return None