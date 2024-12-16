# Path: fta_profile/app/adapter/transport/http/profile_router.py

from typing import Annotated
from fastapi import APIRouter, status, Depends, Response
from ....domain.models.profile import Profile, ProfileCreate, ProfileUpdate
from ....application.http.profile_service import ProfileService
from ....dependencies import get_profile_service

profile_http_router = APIRouter(prefix="/v1")

@profile_http_router.get("/profiles", response_model=list[Profile])
async def list_profiles(
    profile_service: Annotated[ProfileService, Depends(get_profile_service)],
    order_by: str = "uuid",
    offset: int = 0,
    limit: int = 10
):
    return await profile_service.list(order_by=order_by, offset=offset, limit=limit)

@profile_http_router.get("/profiles/{uuid}", response_model=Profile)
async def get_profile(
    uuid: str,
    profile_service: Annotated[ProfileService, Depends(get_profile_service)]
):
    return await profile_service.get(uuid)

@profile_http_router.post("/profiles", response_model=Profile, status_code=status.HTTP_201_CREATED)
async def create_profile(
    profile: ProfileCreate,
    profile_service: Annotated[ProfileService, Depends(get_profile_service)]
):
    return await profile_service.post(profile)

@profile_http_router.put("/profiles/{uuid}", response_model=Profile)
async def update_profile(
    uuid: str,
    profile: ProfileUpdate,
    profile_service: Annotated[ProfileService, Depends(get_profile_service)]
):
    return await profile_service.put(uuid, profile)

@profile_http_router.delete("/profiles/{uuid}", status_code=status.HTTP_204_NO_CONTENT)
async def delete_profile(
    uuid: str,
    profile_service: Annotated[ProfileService, Depends(get_profile_service)]
):
    await profile_service.delete(uuid)
    return Response(status_code=status.HTTP_204_NO_CONTENT)

@profile_http_router.get("/healthcheck", status_code=status.HTTP_200_OK)
async def healthcheck(
    profile_service: Annotated[ProfileService, Depends(get_profile_service)]
):
    return await profile_service.health()