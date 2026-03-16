import google.generativeai as genai
import json
import re
from app.core.config import settings

class AIService:
    
    @staticmethod
    def _extract_json(text):
        try:
            # Matches anything between { and } across multiple lines
            match = re.search(r'\{.*\}', text, re.DOTALL)
            if match: return match.group(0)
            return text
        except:
            return text

    @staticmethod
    async def analyze_vibe(user_query: str) -> dict:
        api_key = settings.GEMINI_API_KEY

        if not api_key:
            print("\n[ERROR] GEMINI_API_KEY is not set in .env!\n")
            return {"is_keyword_search": True, "corrected_query": user_query}

        genai.configure(api_key=api_key)
        
        # Using the latest Gemini 2.0 Flash model
        model = genai.GenerativeModel('gemini-2.0-flash')

        # New Prompt: Multi-Category Example-Driven Algorithm
        prompt = f"""
        You are a movie discovery AI agent.

        Your task is to analyze the user's message and determine the movie genres, tone, and rating filters that match their request.

        Use the following examples as reference mappings between user input and movie search filters.

        Always convert user messages into structured JSON containing:

        {{
        "mood": "string",
        "genres": ["string", "string"],
        "tone": "string",
        "rating": "string (e.g. R, PG-13, G)",
        "keywords": ["tag1", "tag2"]
        }}

        Only return JSON when responding to user messages.

        --- Reference Mappings ---

        Sad / Emotional Movies
        User: "I want to cry tonight", "Suggest heartbreaking movies", "I feel lonely today", "Tragic love stories"
        Mapping → Genres: Drama, Romance | Tone: Emotional | Rating: PG-13+

        Feel Good / Comfort Movies
        User: "I feel low today", "Suggest feel good movies", "I had a bad day cheer me up", "Uplifting", "Wholesome"
        Mapping → Genres: Comedy, Family, Feel-Good | Tone: Uplifting | Rating: PG-13

        Comedy Movies
        User: "I want to laugh", "funny movies", "hilarious", "laugh-out-loud"
        Mapping → Genres: Comedy | Tone: Light / Funny | Rating: PG-13

        Adult Comedy Movies
        User: "Adult comedy", "raunchy comedy", "R rated comedy", "Crude humor", "Explicit"
        Mapping → Genres: Comedy, Dark Comedy | Tone: Raunchy / Adult Humor | Rating: R / 18+

        Romantic Movies
        User: "Suggest romantic movies", "Date night ideas", "Love story", "Relationship movies"
        Mapping → Genres: Romance, Drama | Tone: Emotional / Romantic | Rating: PG-13+

        Dark / Gore / Violent Movies
        User: "Dark and intense", "disturbing movies", "Violent horror", "Gore", "Extreme"
        Mapping → Genres: Horror, Thriller | Tone: Dark / Intense | Rating: R / 18+

        Action Movies
        User: "Action movies", "High energy", "Adrenaline", "Gun fight", "Intense action"
        Mapping → Genres: Action, Adventure | Tone: Intense / Exciting | Rating: PG-13 / R

        Adventure Movies
        User: "Epic adventure", "Treasure hunt", "Journey", "Quest"
        Mapping → Genres: Adventure, Fantasy | Tone: Exciting | Rating: PG-13

        Sci-Fi Movies
        User: "Space movies", "Futuristic", "Alien invasion", "Cyberpunk", "AI movies", "Time travel"
        Mapping → Genres: Sci-Fi | Tone: Futuristic | Rating: PG-13 / R

        Psychological Movies
        User: "Mind bending", "Crazy twists", "mess with your mind", "Twist ending"
        Mapping → Genres: Thriller, Mystery, Sci-Fi | Tone: Psychological | Rating: PG-13 / R

        Anime Movies
        User: "Suggest anime movies", "Japanese animated films", "Anime action"
        Mapping → Genres: Animation, Fantasy, Adventure | Tone: Stylized / Emotional | Rating: PG-13+

        Cult Classic Movies
        User: "Show me cult classics", "Legendary", "Iconic", "Timeless", "Vintage"
        Mapping → Genres: Drama, Crime, Classic | Sorting: Top rated | Rating: PG-13 / R

        Motivational Movies
        User: "I need motivation", "Success story", "Underdog", "Comeback", "inspiring true stories"
        Mapping → Genres: Biography, Drama, Sports | Tone: Inspirational | Rating: PG-13

        Family Movies
        User: "Movies for family night", "Kids friendly", "Disney style", "To watch with children"
        Mapping → Genres: Family, Animation, Comedy | Tone: Light / Wholesome | Rating: PG-13

        Current User Query: "{user_query}"

        Only return JSON responses. Do not include explanations.
        """

        try:
            # Generation call
            response = await model.generate_content_async(prompt)
            
            # Cleaning and parsing
            raw_text = response.text.strip()
            clean_json = AIService._extract_json(raw_text)
            data = json.loads(clean_json)
            
            # Log for terminal debugging
            print(f"\n[AI SUCCESS]: {data}\n") 
            return data

        except Exception as e:
            print(f"\n[AI CRASH]: {e}")
            # Robust Fallback for production stability
            return {
                "is_keyword_search": False, 
                "corrected_query": user_query, 
                "genre_id": None, 
                "year_start": None, 
                "year_end": None,
                "language_filter": "en|hi",
                "vibe_description": "Fallback mixed discovery"
            }