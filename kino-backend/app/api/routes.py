from typing import Optional

from fastapi import APIRouter

from app.services.ai import AIService
from app.services.tmdb import TMDBService

router = APIRouter()


@router.get("/movies/trending")
async def trending_movies():
    try:
        return await TMDBService.get_trending_movies()
    except Exception as e:
        print(f"[API TRENDING ERROR] {e}")
        return []


@router.get("/movies/classics")
async def classic_movies():
    return await TMDBService.get_classic_movies()


@router.get("/movies/foryou")
async def for_you_movies():
    return await TMDBService.get_for_you_movies()


@router.get("/movies/regional")
async def regional_mix():
    try:
        return await TMDBService.get_regional_mix()
    except Exception as e:
        print(f"[API REGIONAL ERROR] {e}")
        return []


@router.get("/search/vibe")
async def vibe_search(query: str, sort: str = "popularity"):
    fallback_metadata = {
        "mood": "Mixed",
        "genres": [],
        "tone": "Balanced",
        "rating": "PG-13",
        "keywords": [],
    }
    try:
        ai_instructions = await AIService.analyze_vibe(query)
        movies = await TMDBService.search_with_vibe(
            ai_instructions,
            sort_preference=sort,
        )
        return {
            "movies": movies,
            "metadata": {
                **fallback_metadata,
                **(ai_instructions or {}),
            },
        }
    except Exception as e:
        print(f"[API VIBE ERROR] {e}")
        return {
            "movies": [],
            "metadata": fallback_metadata,
        }


@router.get("/search/movie")
async def search_movie(query: str):
    try:
        return await TMDBService.search_movies(query)
    except Exception as e:
        print(f"[API SEARCH ERROR] {e}")
        return []


@router.get("/search/advanced")
async def advanced_search(
    content_type: str = "movie",
    min_rating: float = 0.0,
    genres: Optional[str] = None,
    decade: Optional[str] = None,
    keywords: Optional[str] = None,
    languages: Optional[str] = None,
    page: int = 1,
):
    return await TMDBService.search_advanced(
        content_type=content_type,
        min_rating=min_rating,
        genres=genres,
        decade=decade,
        keywords=keywords,
        languages=languages,
        page=page,
    )


@router.get("/movie/{movie_id}/details")
async def movie_details(movie_id: int):
    try:
        details = await TMDBService.get_movie_details(movie_id)
        return details or {}
    except Exception as e:
        print(f"[API DETAILS ERROR] {e}")
        return {}


@router.get("/anime")
async def anime_movies():
    try:
        return await TMDBService.get_anime_movies()
    except Exception as e:
        print(f"[API ANIME ERROR] {e}")
        return []
