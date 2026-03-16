import asyncio
from app.services.ai import AIService
from app.services.tmdb import TMDBService

async def main():
    try:
        ai_data = await AIService.analyze_vibe('feel good movies')
        print("AI Data:", ai_data)
        
        res = await TMDBService.search_with_vibe(ai_data)
        print("Search Results:", len(res))
    except Exception as e:
        import traceback
        traceback.print_exc()

if __name__ == "__main__":
    asyncio.run(main())
