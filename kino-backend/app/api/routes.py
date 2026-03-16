from fastapi import APIRouter
from app.services.tmdb import TMDBService
from app.services.ai import AIService

router = APIRouter()

@router.get("/movies/trending")
async def trending_movies():
    return await TMDBService.get_trending_movies()

@router.get("/movies/regional")
async def regional_mix():
    return await TMDBService.get_regional_mix()

@router.get("/search/vibe")
async def vibe_search(query: str, sort: str = "popularity"): 
    # 1. Ask AI to analyze the query
    ai_instructions = await AIService.analyze_vibe(query)
    
    # 2. Search using AI instructions AND Sort preference
    movies = await TMDBService.search_with_vibe(ai_instructions, sort_preference=sort)
    
    return {
        "movies": movies,
        "metadata": ai_instructions
    }

@router.get("/search/movie")
async def search_movie(query: str):
    """Perform a standard keyword search on TMDB."""
    return await TMDBService.search_movies(query)

# --- NEW ROUTE ADDED BELOW ---
@router.get("/movie/{movie_id}/details")
async def movie_details(movie_id: int):
    """
    Fetches full movie details including cast, trailers, and similar movies.
    """
    return await TMDBService.get_movie_details(movie_id)

@router.get("/anime")
async def anime_movies():
    """Returns a curated list of popular anime movies."""
    return await TMDBService.get_anime_movies()