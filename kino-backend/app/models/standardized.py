from pydantic import BaseModel
from typing import List, Optional
from enum import Enum

class SourceType(str, Enum):
    TMDB = "tmdb"
    JIKAN = "jikan"

# This is the Master Object. 
# Everything Kino sends to the phone will look like this.
class KinoMediaItem(BaseModel):
    remote_id: int              # The ID from TMDB or Jikan
    source: SourceType          # Where did it come from?
    title: str
    poster_url: Optional[str]   # Full URL to the image
    release_year: Optional[str] 
    rating: Optional[float]     # 1-10 scale
    overview: Optional[str]     # Short description
    
    # Smart Tags (e.g., "South Indian", "Anime", "Korean")
    tags: List[str] = []

    class Config:
        from_attributes = True