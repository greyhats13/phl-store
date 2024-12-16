# Path: fta_profile/tests/test_profile_repository.py

import pytest
from unittest.mock import AsyncMock, Mock
from app.infrastructure.repositories.profile_repository import ProfileRepository
from app.domain.models.profile import ProfileCreate, ProfileUpdate

# Async generator function
async def async_gen(items):
    for item in items:
        yield item

@pytest.mark.asyncio
async def test_get_existing_profile():
    # Arrange
    mock_collection = Mock()
    mock_document = Mock()
    mock_get = AsyncMock()
    mock_get.return_value.exists = True
    mock_get.return_value.to_dict = Mock(return_value={
        'uuid': '123',
        'email': 'test@example.com',
        'firstname': 'John',
        'lastname': 'Doe',
    })
    mock_document.get = mock_get
    mock_collection.document.return_value = mock_document

    repo = ProfileRepository(collection=mock_collection, transport='http')

    # Act
    profile = await repo.get('123')

    # Assert
    assert profile.uuid == '123'
    assert profile.email == 'test@example.com'

@pytest.mark.asyncio
async def test_get_nonexistent_profile():
    # Arrange
    mock_collection = Mock()
    mock_document = Mock()
    mock_get = AsyncMock()
    mock_get.return_value.exists = False
    mock_document.get = mock_get
    mock_collection.document.return_value = mock_document

    repo = ProfileRepository(collection=mock_collection, transport='http')

    # Act
    profile = await repo.get('nonexistent')

    # Assert
    assert profile is None

@pytest.mark.asyncio
async def test_create_profile():
    # Arrange
    mock_collection = Mock()
    mock_document = Mock()
    mock_set = AsyncMock()
    mock_document.set = mock_set
    mock_collection.document.return_value = mock_document

    repo = ProfileRepository(collection=mock_collection, transport='http')
    profile_data = ProfileCreate(uuid='123', email='test@example.com')

    # Act
    result = await repo.create(profile_data)

    # Assert
    mock_document.set.assert_called_once_with(profile_data.model_dump())
    assert result == profile_data

@pytest.mark.asyncio
async def test_update_profile():
    # Arrange
    mock_collection = Mock()
    mock_document = Mock()
    mock_update = AsyncMock()
    mock_document.update = mock_update
    mock_collection.document.return_value = mock_document

    repo = ProfileRepository(collection=mock_collection, transport='http')
    profile_update = ProfileUpdate(email='new@example.com')

    # Act
    await repo.update('123', profile_update)

    # Assert
    mock_document.update.assert_called_once_with(profile_update.model_dump(exclude_unset=True))

@pytest.mark.asyncio
async def test_delete_profile():
    # Arrange
    mock_collection = Mock()
    mock_document = Mock()
    mock_delete = AsyncMock()
    mock_document.delete = mock_delete
    mock_collection.document.return_value = mock_document

    repo = ProfileRepository(collection=mock_collection, transport='http')

    # Act
    await repo.delete('123')

    # Assert
    mock_document.delete.assert_called_once()

@pytest.mark.asyncio
async def test_is_exist_true():
    # Arrange
    mock_collection = Mock()
    mock_document = Mock()
    mock_get = AsyncMock()
    mock_get.return_value.exists = True
    mock_document.get = mock_get
    mock_collection.document.return_value = mock_document

    repo = ProfileRepository(collection=mock_collection, transport='http')

    # Act
    exists = await repo.isExist('123')

    # Assert
    assert exists is True

@pytest.mark.asyncio
async def test_is_exist_false():
    # Arrange
    mock_collection = Mock()
    mock_document = Mock()
    mock_get = AsyncMock()
    mock_get.return_value.exists = False
    mock_document.get = mock_get
    mock_collection.document.return_value = mock_document

    repo = ProfileRepository(collection=mock_collection, transport='http')

    # Act
    exists = await repo.isExist('nonexistent')

    # Assert
    assert exists is False

@pytest.mark.asyncio
async def test_is_conflict_true():
    # Arrange
    mock_collection = Mock()
    mock_query = Mock()
    existing_docs = [Mock()]  # Simulate existing documents

    # Use the async generator to mock query.stream()
    mock_query.stream.return_value = async_gen(existing_docs)
    mock_collection.where.return_value = mock_query

    repo = ProfileRepository(collection=mock_collection, transport='http')
    profile_data = ProfileCreate(email='test@example.com')

    # Act
    conflict = await repo.isConflict(profile_data)

    # Assert
    assert conflict is True

@pytest.mark.asyncio
async def test_is_conflict_false():
    # Arrange
    mock_collection = Mock()
    mock_query = Mock()
    existing_docs = []  # No documents found

    # Use the async generator to mock query.stream()
    mock_query.stream.return_value = async_gen(existing_docs)
    mock_collection.where.return_value = mock_query

    repo = ProfileRepository(collection=mock_collection, transport='http')
    profile_data = ProfileCreate(email='unique@example.com')

    # Act
    conflict = await repo.isConflict(profile_data)

    # Assert
    assert conflict is False