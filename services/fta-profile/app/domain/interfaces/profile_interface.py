# Path: fta_profile/app/domain/interfaces/profile_interface.py

from abc import ABC, abstractmethod
from fastapi import HTTPException
from ..models.profile import Profile, ProfileCreate, ProfileUpdate

class ProfileInterface(ABC):
    @abstractmethod
    async def list(self, order_by: str = "uuid", offset: int = 0, limit: int = 10) -> list[Profile]:
        raise HTTPException(status_code=501, detail="Not Implemented")

    @abstractmethod
    async def get(self, uuid: str) -> Profile:
        raise HTTPException(status_code=501, detail="Not Implemented")

    @abstractmethod
    async def create(self, profile_data: ProfileCreate) -> Profile:
        raise HTTPException(status_code=501, detail="Not Implemented")

    @abstractmethod
    async def update(self, uuid: str, profile_data: ProfileUpdate) -> Profile:
        raise HTTPException(status_code=501, detail="Not Implemented")

    @abstractmethod
    async def delete(self, uuid: str):
        raise HTTPException(status_code=501, detail="Not Implemented")