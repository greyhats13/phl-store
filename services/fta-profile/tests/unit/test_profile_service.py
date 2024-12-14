# Path: fta_profile/tests/test_profile_service.py

import pytest
from unittest.mock import AsyncMock
from app.application.http.profile_service import ProfileService
from app.domain.models.profile import ProfileCreate, ProfileUpdate
from fastapi import HTTPException, status

@pytest.mark.asyncio
async def test_get_profile_success():
    # Arrange
    mock_repo = AsyncMock()
    mock_repo.get.return_value = ProfileCreate(uuid='123', email='test@example.com')
    service = ProfileService(profile_repo=mock_repo)

    # Act
    profile = await service.get('123')

    # Assert
    assert profile.uuid == '123'
    assert profile.email == 'test@example.com'

@pytest.mark.asyncio
async def test_get_profile_not_found():
    # Arrange
    mock_repo = AsyncMock()
    mock_repo.get.return_value = None
    service = ProfileService(profile_repo=mock_repo)

    # Act & Assert
    with pytest.raises(HTTPException) as exc_info:
        await service.get('nonexistent')

    assert exc_info.value.status_code == status.HTTP_404_NOT_FOUND
    assert exc_info.value.detail == 'Profile not found'

@pytest.mark.asyncio
async def test_create_profile_success():
    # Arrange
    mock_repo = AsyncMock()
    mock_repo.isConflict.return_value = False
    mock_repo.create.return_value = ProfileCreate(uuid='generated_uuid', email='test@example.com')
    service = ProfileService(profile_repo=mock_repo)
    profile_data = ProfileCreate(email='test@example.com')

    # Act
    profile = await service.post(profile_data)

    # Assert
    assert profile.email == 'test@example.com'
    mock_repo.create.assert_called_once()
    mock_repo.isConflict.assert_called_once()

@pytest.mark.asyncio
async def test_create_profile_conflict():
    # Arrange
    mock_repo = AsyncMock()
    mock_repo.isConflict.return_value = True
    service = ProfileService(profile_repo=mock_repo)
    profile_data = ProfileCreate(email='test@example.com')

    # Act & Assert
    with pytest.raises(HTTPException) as exc_info:
        await service.post(profile_data)

    assert exc_info.value.status_code == status.HTTP_409_CONFLICT
    assert exc_info.value.detail == 'Profile email already exist'

@pytest.mark.asyncio
async def test_update_profile_success():
    # Arrange
    mock_repo = AsyncMock()
    mock_repo.isExist.return_value = True
    mock_repo.get.return_value = ProfileCreate(uuid='123', email='updated@example.com')
    service = ProfileService(profile_repo=mock_repo)
    profile_update = ProfileUpdate(email='updated@example.com')

    # Act
    profile = await service.put('123', profile_update)

    # Assert
    assert profile.email == 'updated@example.com'
    mock_repo.update.assert_called_once_with('123', profile_update)

@pytest.mark.asyncio
async def test_update_profile_not_found():
    # Arrange
    mock_repo = AsyncMock()
    mock_repo.isExist.return_value = False
    service = ProfileService(profile_repo=mock_repo)
    profile_update = ProfileUpdate(email='updated@example.com')

    # Act & Assert
    with pytest.raises(HTTPException) as exc_info:
        await service.put('nonexistent', profile_update)

    assert exc_info.value.status_code == status.HTTP_404_NOT_FOUND
    assert exc_info.value.detail == 'Profile not found'

@pytest.mark.asyncio
async def test_delete_profile_success():
    # Arrange
    mock_repo = AsyncMock()
    mock_repo.isExist.return_value = True
    service = ProfileService(profile_repo=mock_repo)

    # Act
    await service.delete('123')

    # Assert
    mock_repo.delete.assert_called_once_with('123')

@pytest.mark.asyncio
async def test_delete_profile_not_found():
    # Arrange
    mock_repo = AsyncMock()
    mock_repo.isExist.return_value = False
    service = ProfileService(profile_repo=mock_repo)

    # Act & Assert
    with pytest.raises(HTTPException) as exc_info:
        await service.delete('nonexistent')

    assert exc_info.value.status_code == status.HTTP_404_NOT_FOUND
    assert exc_info.value.detail == 'Profile not found'