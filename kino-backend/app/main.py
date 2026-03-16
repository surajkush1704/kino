from fastapi import FastAPI
from app.api.routes import router as api_router

app = FastAPI(title="Kino API")

# Include the routes we just created
app.include_router(api_router, prefix="/api/v1")

@app.get("/")
def home():
    return {"status": "Kino Backend Running"}