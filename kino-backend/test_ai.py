import asyncio
import sys
import os

# Ensure we can import app modules
sys.path.insert(0, os.path.abspath(os.path.dirname(__file__)))

from app.services.ai import AIService

async def main():
    print("Testing AI Vibe...")
    res = await AIService.analyze_vibe("feel good movies")
    print(res)

if __name__ == "__main__":
    asyncio.run(main())
