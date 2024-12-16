# Path: fta_profile/app/application/http/profile_service.py

from ...infrastructure.repositories.profile_repository import ProfileRepository
from ...domain.models.profile import ProfileCreate, ProfileUpdate, Profile
from fastapi import HTTPException, status
from typing import List

class ProfileService:
    def __init__(self, profile_repo: ProfileRepository):
        self.profile_repo = profile_repo

    # Health check method
    async def health(self):
        try:
            await self.profile_repo.session.execute("SELECT 1")
            return {"status": "ok"}
        except Exception as e:
            raise HTTPException(status_code=503, detail="Database unavailable")

    # List profiles with pagination and ordering
    async def list(
        self, order_by: str = "uuid", offset: int = 0, limit: int = 10
    ) -> List[Profile]:
        if limit <= 0:
            raise HTTPException(status_code=400, detail="Limit must be greater than 0")
        try:
            profiles = await self.profile_repo.list(
                order_by=order_by, offset=offset, limit=limit
            )
            return profiles
        except HTTPException as e:
            # Re-raise HTTP exceptions from repository
            raise e
        except Exception as e:
            # Handle unexpected exceptions
            raise HTTPException(
                status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
                detail="An error occurred while listing profiles",
            )

    # Get a single profile by UUID
    async def get(self, uuid: str) -> Profile:
        profile = await self.profile_repo.get(uuid)
        if profile is None:
            raise HTTPException(status_code=404, detail="Profile not found")
        return profile

    # Create a new profile
    async def post(self, profile_data: ProfileCreate) -> Profile:
        # Check for email conflict
        if await self.profile_repo.isConflict(profile_data.email):
            raise HTTPException(status_code=409, detail="Email already in use")
        try:
            profile = await self.profile_repo.create(profile_data)
            return profile
        except HTTPException as e:
            # Re-raise HTTP exceptions
            raise e
        except Exception as e:
            # Handle unexpected exceptions
            raise HTTPException(
                status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
                detail="An error occurred while creating profile",
            )

    # Update an existing profile
    async def put(self, uuid: str, profile_data: ProfileUpdate) -> Profile:
        # Check if profile exists
        if not await self.profile_repo.isExist(uuid):
            raise HTTPException(status_code=404, detail="Profile not found")
        # Check for email conflict if email is being updated
        if profile_data.email:
            existing_profile = await self.profile_repo.get(uuid)
            if profile_data.email != existing_profile.email:
                if await self.profile_repo.isConflict(
                    profile_data.email, exclude_uuid=uuid
                ):
                    raise HTTPException(status_code=409, detail="Email already in use")
        try:
            profile = await self.profile_repo.update(uuid, profile_data)
            return profile
        except HTTPException as e:
            # Re-raise HTTP exceptions
            raise e
        except Exception as e:
            # Handle unexpected exceptions
            raise HTTPException(
                status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
                detail="An error occurred while updating profile",
            )

    # Delete a profile
    async def delete(self, uuid: str):
        # Check if profile exists
        if not await self.profile_repo.isExist(uuid):
            raise HTTPException(status_code=404, detail="Profile not found")
        try:
            await self.profile_repo.delete(uuid)
        except HTTPException as e:
            # Re-raise HTTP exceptions
            raise e
        except Exception as e:
            # Handle unexpected exceptions
            raise HTTPException(
                status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
                detail="An error occurred while deleting profile",
            )