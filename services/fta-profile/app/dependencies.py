# Path: fta_profile/app/dependencies.py

from functools import lru_cache
from typing import Annotated, AsyncGenerator
from fastapi import Depends
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.orm import sessionmaker
from .application.http.profile_service import ProfileService
from .infrastructure.repositories.profile_repository import ProfileRepository
from .config import Settings
from .infrastructure.lifespan import engine

@lru_cache()
def get_settings():
    return Settings()

settings = get_settings()

async_session_maker = sessionmaker(
    engine["connection"], class_=AsyncSession, expire_on_commit=False
)

async def get_session() -> AsyncGenerator[AsyncSession, None]:
    async with async_session_maker() as session:
        yield session

async def get_profile_repository(
    session: Annotated[AsyncSession, Depends(get_session)]
):
    return ProfileRepository(session=session)

async def get_profile_service(
    profile_repo: Annotated[ProfileRepository, Depends(get_profile_repository)]
):
    return ProfileService(profile_repo=profile_repo)