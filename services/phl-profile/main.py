import lru_cache
from fastapi import FastAPI, APIRouter, status, Depends, HTTPException
from sqlmodel import SQLModel, Field, select
from sqlmodel.ext.asyncio.session import AsyncSession
from sqlalchemy.ext.asyncio import create_async_engine
from sqlalchemy.orm import sessionmaker
from pydantic_settings import BaseSettings
from pydantic import BaseModel, EmailStr, ConfigDict, Field as PydanticField
from typing import Optional, List, AsyncGenerator
from datetime import datetime
from contextlib import asynccontextmanager


# Settings
class Settings(BaseSettings):
    db_user: str = PydanticField(json_schema_extra={"env": "DB_USER"})
    db_password: str = PydanticField(json_schema_extra={"env": "DB_PASSWORD"})
    db_host: str = PydanticField(json_schema_extra={"env": "DB_HOST"})
    db_port: int = PydanticField(json_schema_extra={"env": "DB_PORT"})
    db_name: str = PydanticField(json_schema_extra={"env": "DB_NAME"})

    @property
    def database_url(self):
        return f"mysql+aiomysql://{self.db_user}:{self.db_password}@{self.db_host}:{self.db_port}/{self.db_name}"

    model_config = ConfigDict(env_file=".env", env_file_encoding="utf-8")

@lrucache()
def get_settings():
    return Settings()

settings = get_settings()

# Async Engine and Session
engine = create_async_engine(settings.database_url, echo=True)
async_session_maker = sessionmaker(engine, class_=AsyncSession, expire_on_commit=False)


# Models
class ProfileBase(SQLModel):
    email: EmailStr
    name: str
    age: int


class Profile(ProfileBase, table=True):
    userid: Optional[int] = Field(default=None, primary_key=True)
    created_at: datetime = Field(default_factory=datetime.utcnow)
    updated_at: datetime = Field(default_factory=datetime.utcnow)


class ProfileCreateModel(BaseModel):
    email: EmailStr
    name: str
    age: Optional[int] = None


class ProfileUpdateModel(BaseModel):
    email: Optional[EmailStr] = None
    name: Optional[str] = None
    age: Optional[int] = None


class ProfileResponseModel(ProfileBase):
    userid: int
    created_at: datetime
    updated_at: datetime


# Dependency
async def get_session() -> AsyncGenerator[AsyncSession, None]:
    async with async_session_maker() as session:
        yield session


# Service
class ProfileService:
    def __init__(self, session: AsyncSession):
        self.session = session

    async def get_profiles(self) -> List[Profile]:
        result = await self.session.exec(select(Profile))
        return result.all()

    async def create_profile(self, profile_create: ProfileCreateModel) -> Profile:
        new_profile = Profile(
            email=profile_create.email,
            name=profile_create.name,
            age=profile_create.age,
            created_at=datetime.utcnow(),
            updated_at=datetime.utcnow(),
        )
        self.session.add(new_profile)
        await self.session.commit()
        await self.session.refresh(new_profile)
        return new_profile

    async def get_profile(self, userid: int) -> Profile:
        profile = await self.session.get(Profile, userid)
        if not profile:
            raise HTTPException(status_code=404, detail="Profile not found")
        return profile

    async def update_profile(
        self, userid: int, profile_data: ProfileUpdateModel
    ) -> Profile:
        profile = await self.session.get(Profile, userid)
        if not profile:
            raise HTTPException(status_code=404, detail="Profile not found")

        if profile_data.email is not None:
            profile.email = profile_data.email
        if profile_data.name is not None:
            profile.name = profile_data.name
        if profile_data.age is not None:
            profile.age = profile_data.age

        profile.updated_at = datetime.utcnow()
        self.session.add(profile)
        await self.session.commit()
        await self.session.refresh(profile)
        return profile

    async def delete_profile(self, userid: int) -> dict:
        profile = await self.session.get(Profile, userid)
        if not profile:
            raise HTTPException(status_code=404, detail="Profile not found")
        await self.session.delete(profile)
        await self.session.commit()


# Event Startup and Shutdown
@asynccontextmanager
async def lifespan(app: FastAPI):
    # Startup code: create tables
    async with engine.begin() as conn:
        await conn.run_sync(SQLModel.metadata.create_all)
    yield
    # Shutdown code (if any)


# FastAPI App
app = FastAPI(lifespan=lifespan)

# Router
profile_router = APIRouter(prefix="/profiles")


# Routes
@profile_router.get(
    "/", response_model=List[ProfileResponseModel], status_code=status.HTTP_200_OK
)
async def list_profiles(session: AsyncSession = Depends(get_session)):
    service = ProfileService(session)
    profiles = await service.get_profiles()
    return profiles


@profile_router.post(
    "/", response_model=ProfileResponseModel, status_code=status.HTTP_201_CREATED
)
async def create_profile(
    profile: ProfileCreateModel, session: AsyncSession = Depends(get_session)
):
    service = ProfileService(session)
    new_profile = await service.create_profile(profile)
    return new_profile


@profile_router.get(
    "/{userid}", response_model=ProfileResponseModel, status_code=status.HTTP_200_OK
)
async def get_profile(userid: int, session: AsyncSession = Depends(get_session)):
    service = ProfileService(session)
    profile = await service.get_profile(userid)
    return profile


@profile_router.put(
    "/{userid}", response_model=ProfileResponseModel, status_code=status.HTTP_200_OK
)
async def update_profile(
    userid: int,
    profile_data: ProfileUpdateModel,
    session: AsyncSession = Depends(get_session),
):
    service = ProfileService(session)
    updated_profile = await service.update_profile(userid, profile_data)
    return updated_profile


@profile_router.delete("/{userid}", status_code=status.HTTP_204_NO_CONTENT)
async def delete_profile(userid: int, session: AsyncSession = Depends(get_session)):
    service = ProfileService(session)
    await service.delete_profile(userid)


app.include_router(profile_router, tags=["profiles"])
