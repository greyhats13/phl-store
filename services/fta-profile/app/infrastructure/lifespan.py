# Path: fta_profile/app/infrastructure/lifespan.py

from fastapi import FastAPI
from contextlib import asynccontextmanager
from sqlmodel import SQLModel
from sqlalchemy.ext.asyncio import create_async_engine

engine =  {}

@asynccontextmanager
async def lifespan(app: FastAPI):
    engine["connection"] = create_async_engine(app.state.database_url, echo=True)
    async with engine["connection"].begin() as conn:
       engine["create"] = await conn.run_sync(SQLModel.metadata.create_all)
    try:
        yield
    finally:
        await engine["connection"].dispose()