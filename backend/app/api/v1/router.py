from fastapi import APIRouter

from app.api.v1.routes import achievements, ai, auth, character, coach, goals, journal, missions, skills, stats, users

api_router = APIRouter()
api_router.include_router(auth.router)
api_router.include_router(users.router)
api_router.include_router(character.router)
api_router.include_router(goals.router)
api_router.include_router(missions.router)
api_router.include_router(ai.router)
api_router.include_router(coach.router)
api_router.include_router(stats.router)
api_router.include_router(achievements.router)
api_router.include_router(journal.router)
api_router.include_router(skills.router)
