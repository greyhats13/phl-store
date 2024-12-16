import pytest
from httpx import AsyncClient
from sqlalchemy.ext.asyncio import create_async_engine, AsyncSession
from sqlalchemy.orm import sessionmaker
from sqlmodel import SQLModel

from main import app, get_session, ProfileCreateModel, ProfileUpdateModel

# In-memory SQLite database URL for testing
DATABASE_URL = "sqlite+aiosqlite:///:memory:"

# Create an asynchronous engine for the test database
test_engine = create_async_engine(DATABASE_URL, echo=False)

# Create a sessionmaker bound to the test engine
TestSessionLocal = sessionmaker(
    bind=test_engine,
    class_=AsyncSession,
    expire_on_commit=False
)

# Override the get_session dependency to use the test session
async def override_get_session() -> AsyncSession:
    async with TestSessionLocal() as session:
        yield session

# Apply the dependency override to the FastAPI app
app.dependency_overrides[get_session] = override_get_session

# Fixture to prepare and clean up the database before and after tests
@pytest.fixture(scope="session", autouse=True)
async def prepare_database():
    # Create all tables in the test database
    async with test_engine.begin() as conn:
        await conn.run_sync(SQLModel.metadata.create_all)
    yield
    # Drop all tables after tests are done
    async with test_engine.begin() as conn:
        await conn.run_sync(SQLModel.metadata.drop_all)

# Fixture to provide an AsyncClient for making HTTP requests to the FastAPI app
@pytest.fixture
async def client():
    async with AsyncClient(app=app, base_url="http://test") as ac:
        yield ac

# Test creating a new profile
@pytest.mark.asyncio
async def test_create_profile(client: AsyncClient):
    payload = {
        "email": "test@example.com",
        "name": "Test User",
        "age": 30
    }
    response = await client.post("/profiles/", json=payload)
    assert response.status_code == 201
    data = response.json()
    assert data["email"] == "test@example.com"
    assert data["name"] == "Test User"
    assert data["age"] == 30
    assert "userid" in data
    assert "created_at" in data
    assert "updated_at" in data

# Test retrieving a list of profiles
@pytest.mark.asyncio
async def test_list_profiles(client: AsyncClient):
    # First, create a profile to ensure there is at least one in the database
    payload = {
        "email": "listtest@example.com",
        "name": "List Test",
        "age": 25
    }
    await client.post("/profiles/", json=payload)
    
    # Retrieve the list of profiles
    response = await client.get("/profiles/")
    assert response.status_code == 200
    data = response.json()
    assert isinstance(data, list)
    assert len(data) >= 1  # Ensure at least one profile exists
    # Verify the attributes of the first profile
    profile = data[0]
    assert "userid" in profile
    assert "email" in profile
    assert "name" in profile
    assert "age" in profile

# Test retrieving a profile by userid
@pytest.mark.asyncio
async def test_get_profile(client: AsyncClient):
    # Create a profile first
    payload = {
        "email": "gettest@example.com",
        "name": "Get Test",
        "age": 40
    }
    create_response = await client.post("/profiles/", json=payload)
    userid = create_response.json()["userid"]
    
    # Retrieve the created profile
    response = await client.get(f"/profiles/{userid}")
    assert response.status_code == 200
    data = response.json()
    assert data["userid"] == userid
    assert data["email"] == "gettest@example.com"
    assert data["name"] == "Get Test"
    assert data["age"] == 40

    # Attempt to retrieve a non-existent profile
    response = await client.get("/profiles/9999")
    assert response.status_code == 404
    assert response.json()["detail"] == "Profile not found"

# Test updating a profile
@pytest.mark.asyncio
async def test_update_profile(client: AsyncClient):
    # Create a profile first
    payload = {
        "email": "updatetest@example.com",
        "name": "Update Test",
        "age": 50
    }
    create_response = await client.post("/profiles/", json=payload)
    userid = create_response.json()["userid"]
    
    # Update the profile's name and age
    update_payload = {
        "name": "Updated Name",
        "age": 55
    }
    response = await client.put(f"/profiles/{userid}", json=update_payload)
    assert response.status_code == 200
    data = response.json()
    assert data["userid"] == userid
    assert data["name"] == "Updated Name"
    assert data["age"] == 55
    assert data["email"] == "updatetest@example.com"

    # Attempt to update a non-existent profile
    response = await client.put("/profiles/9999", json=update_payload)
    assert response.status_code == 404
    assert response.json()["detail"] == "Profile not found"

# Test deleting a profile
@pytest.mark.asyncio
async def test_delete_profile(client: AsyncClient):
    # Create a profile first
    payload = {
        "email": "deletetest@example.com",
        "name": "Delete Test",
        "age": 60
    }
    create_response = await client.post("/profiles/", json=payload)
    userid = create_response.json()["userid"]
    
    # Delete the created profile
    response = await client.delete(f"/profiles/{userid}")
    assert response.status_code == 204

    # Verify that the profile has been deleted
    response = await client.get(f"/profiles/{userid}")
    assert response.status_code == 404
    assert response.json()["detail"] == "Profile not found"

    # Attempt to delete a non-existent profile
    response = await client.delete("/profiles/9999")
    assert response.status_code == 404
    assert response.json()["detail"] == "Profile not found"