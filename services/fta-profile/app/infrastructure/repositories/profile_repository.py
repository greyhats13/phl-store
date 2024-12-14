# Path: fta_profile/app/infrastructure/repositories/profile_repository.py

from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.future import select
from sqlalchemy.exc import SQLAlchemyError, IntegrityError
from fastapi import HTTPException, status
from ...domain.interfaces.profile_interface import ProfileInterface
from ...domain.models.profile import Profile, ProfileCreate, ProfileUpdate
from datetime import datetime

class ProfileRepository(ProfileInterface):
    def __init__(self, session: AsyncSession):
        self.session = session

    async def health(self) -> dict:
        try:
            self.session.execute("SELECT 1")
            return {"status": "ok"}
        except Exception as e:
            raise HTTPException(
                status_code=503, detail={"status": "error", "message": str(e)}
            )

    async def isExist(self, uuid: str) -> bool:
        try:
            result = await self.session.execute(
                select(Profile).where(Profile.uuid == uuid)
            )
            return result.scalars().first() is not None
        except SQLAlchemyError as e:
            raise HTTPException(
                status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
                detail={"msg": "Cannot list profiles", "reason": str(e)},
            )

    async def isConflict(self, email: str, exclude_uuid: str = None) -> bool:
        try:
            stmt = select(Profile).where(Profile.email == email)
            if exclude_uuid:
                stmt = stmt.where(Profile.uuid != exclude_uuid)
            result = await self.session.execute(stmt)
            return result.scalars().first() is not None
        except SQLAlchemyError as e:
            # Log or handle error as needed
            raise e

    async def list(
        self, order_by: str = "uuid", offset: int = 0, limit: int = 10
    ) -> list[Profile]:
        try:
            stmt = (
                select(Profile)
                .order_by(getattr(Profile, order_by))
                .offset(offset)
                .limit(limit)
            )
            result = await self.session.execute(stmt)
            return result.scalars().all()
        except SQLAlchemyError as e:
            raise HTTPException(
                status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
                detail={"msg": "Cannot list profiles", "reason": str(e)},
            )

    async def get(self, uuid: str) -> Profile:
        try:
            result = await self.session.execute(
                select(Profile).where(Profile.uuid == uuid)
            )
            profile = result.scalars().first()
            return profile
        except SQLAlchemyError as e:
            raise HTTPException(
                status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
                detail={"msg": "Cannot get profile", "reason": str(e)},
            )

    async def create(self, profile_data: ProfileCreate) -> Profile:
        try:
            profile = Profile.from_orm(profile_data)
            self.session.add(profile)
            await self.session.commit()
            await self.session.refresh(profile)
            return profile
        except IntegrityError as e:
            await self.session.rollback()
            raise HTTPException(
                status_code=status.HTTP_409_CONFLICT,
                detail={"msg": "Email already in use", "reason": str(e)},
            )
        except SQLAlchemyError as e:
            await self.session.rollback()
            raise HTTPException(
                status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
                detail={"msg": "Cannot create profile", "reason": str(e)},
            )

    async def update(self, uuid: str, profile_data: ProfileUpdate) -> Profile:
        try:
            profile = await self.get(uuid)
            for key, value in profile_data.dict(exclude_unset=True).items():
                setattr(profile, key, value)
            profile.updatedAt = datetime.now().isoformat()()
            await self.session.commit()
            await self.session.refresh(profile)
            return profile
        except IntegrityError as e:
            await self.session.rollback()
            raise HTTPException(
                status_code=status.HTTP_409_CONFLICT,
                detail={"msg": "Email already in use", "reason": str(e)},
            )
        except SQLAlchemyError as e:
            await self.session.rollback()
            raise HTTPException(
                status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
                detail={"msg": "Cannot update profile", "reason": str(e)},
            )

    async def delete(self, uuid: str):
        try:
            profile = await self.get(uuid)
            await self.session.delete(profile)
            await self.session.commit()
        except SQLAlchemyError as e:
            await self.session.rollback()
            raise HTTPException(
                status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
                detail={"msg": "Cannot delete profile", "reason": str(e)},
            )