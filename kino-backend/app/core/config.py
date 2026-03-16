from pydantic_settings import BaseSettings

class Settings(BaseSettings):
    PROJECT_NAME: str = "Kino Backend"
    API_V1_STR: str = "/api/v1"
    
    # Existing Keys
    TMDB_API_KEY: str
    OPENAI_API_KEY: str = ""
    
    # --- ADD THIS LINE ---
    # This tells Python to load the key from your .env file
    GEMINI_API_KEY: str 
    # ---------------------

    class Config:
        env_file = ".env"

settings = Settings()