# Path: fta_profile/tests/integration/test_integration_profile.py

import json, random, string, pytest
from uuid import uuid4
from httpx import AsyncClient
from fastapi import FastAPI
from main import app  # Pastikan ini adalah path yang benar ke instance FastAPI Anda
from greyprojects.fta.fta_profile.app.infrastructure.lifespan import lifespan
import os

@pytest.fixture(scope="session", autouse=True)
def set_env_vars():
    os.environ['USE_FIRESTORE_EMULATOR'] = '1'
    os.environ['FIRESTORE_EMULATOR_HOST'] = 'localhost:8080'
    yield
    del os.environ['USE_FIRESTORE_EMULATOR']
    del os.environ['FIRESTORE_EMULATOR_HOST']

@pytest.fixture(scope="session")
def anyio_backend():
    return 'asyncio'

@pytest.fixture(scope="session")
async def test_app():
    async with lifespan(app):
        yield app

@pytest.fixture(scope="module")
async def async_client(test_app: FastAPI):
    async with AsyncClient(app=test_app, base_url="http://test") as client:
        yield client

@pytest.fixture
def load_fixture():
    def _load_fixture(fixture_file):
        with open(fixture_file, 'r') as f:
            data = json.load(f)
        # Generate a unique email address
        random_string = ''.join(random.choices(string.ascii_letters + string.digits, k=12))
        data['email'] = f"test_{random_string}@example.com"
        return data
    return _load_fixture

@pytest.mark.anyio
async def test_healthcheck(async_client: AsyncClient):
    response = await async_client.get("/v1/healthcheck")
    assert response.status_code == 200
    assert response.json() == {"status": "ok"}

@pytest.mark.anyio
async def test_create_profile(async_client: AsyncClient, load_fixture):
    profile_data = load_fixture("tests/integration/fixtures/test_basic.json")
    response = await async_client.post("/v1/profiles", json=profile_data)
    assert response.status_code == 201, f"Response content: {response.text}"
    response_data = response.json()
    assert response_data["email"] == profile_data["email"]
    assert "uuid" in response_data

    # Test create profile wih the same email
    new_profile_data = {
        "email": profile_data["email"],
        "firstname": "John",
        "lastname": "Doe",
        "gender": "male"
    }
    response = await async_client.post("/v1/profiles", json=new_profile_data)
    assert response.status_code == 409, f"Response content: {response.text}"

@pytest.mark.anyio
async def test_get_profile(async_client: AsyncClient, load_fixture):
    # Create a profile from test_basic.json
    profile_data = load_fixture("tests/integration/fixtures/test_basic.json")
    create_response = await async_client.post("/v1/profiles", json=profile_data)
    assert create_response.status_code == 201, f"Response content: {create_response.text}"
    created_profile = create_response.json()
    uuid = created_profile["uuid"]

    # Now, retrieve the profile
    get_response = await async_client.get(f"/v1/profiles/{uuid}")
    assert get_response.status_code == 200
    retrieved_profile = get_response.json()
    assert retrieved_profile["email"] == profile_data["email"]

    # Test get profile with non-existent uuid
    uuid = str(uuid4())
    get_response = await async_client.get(f"/v1/profiles/{uuid}")
    assert get_response.status_code == 404 

     # Create a profile from test_complex.json
    profile_data = load_fixture("tests/integration/fixtures/test_complex.json")
    create_response = await async_client.post("/v1/profiles", json=profile_data)
    assert create_response.status_code == 201, f"Response content: {create_response.text}"
    created_profile = create_response.json()
    uuid = created_profile["uuid"]

    # Now, retrieve the profile
    get_response = await async_client.get(f"/v1/profiles/{uuid}")
    assert get_response.status_code == 200
    retrieved_profile = get_response.json()
    assert retrieved_profile["email"] == profile_data["email"]
    assert retrieved_profile["addresses"][0]["city"] == profile_data["addresses"][0]["city"]

@pytest.mark.anyio
async def test_list_profiles(async_client: AsyncClient):
    # Retrieve all profiles
    response = await async_client.get("/v1/profiles?orderby=uuid&offset=1&limit=10")
    assert response.status_code == 200
    assert isinstance(response.json(), list)

    # Retrieve all profiles with limit 0
    response = await async_client.get("/v1/profiles?orderby=uuid&offset=0&limit=10")
    assert response.status_code == 400

@pytest.mark.anyio
async def test_update_profile(async_client: AsyncClient, load_fixture):
    # Create a profile from test_basic.json
    profile_data = load_fixture("tests/integration/fixtures/test_basic.json")
    create_response = await async_client.post("/v1/profiles", json=profile_data)
    assert create_response.status_code == 201, f"Response content: {create_response.text}"
    created_profile = create_response.json()
    uuid = created_profile["uuid"]

    # Prepare the data to update the profile
    update_data = {
        "firstname": "John",
        "email": "john@example.com"
    }

    # Now, update the profile
    update_response = await async_client.put(f"/v1/profiles/{uuid}", json=update_data)
    assert update_response.status_code == 200, f"Response content: {update_response.text}"
    updated_profile = update_response.json()
    assert updated_profile["firstname"] == "John"
    assert updated_profile["email"] == "john@example.com"

    # Test update profile with non-existent uuid
    uuid = str(uuid4())
    update_response = await async_client.put(f"/v1/profiles/{uuid}", json=update_data)
    assert update_response.status_code == 404

    # Test update profile with conflicting email
    conflicting_data = {
        "email": profile_data["email"]
    }

@pytest.mark.anyio
async def test_delete_profile(async_client: AsyncClient, load_fixture):
    # Buat profil terlebih dahulu
    profile_data = load_fixture("tests/integration/fixtures/test_basic.json")
    create_response = await async_client.post("/v1/profiles", json=profile_data)
    assert create_response.status_code == 201, f"Response content: {create_response.text}"
    created_profile = create_response.json()
    uuid = created_profile["uuid"]

    # Lakukan penghapusan
    delete_response = await async_client.delete(f"/v1/profiles/{uuid}")
    assert delete_response.status_code == 204

    # Verifikasi penghapusan
    get_response = await async_client.get(f"/v1/profiles/{uuid}")
    assert get_response.status_code == 404

    # Test delete profile with non-existent uuid
    delete_response = await async_client.delete(f"/v1/profiles/{uuid}")
    assert delete_response.status_code == 404

@pytest.mark.parametrize("fixture_file", [
    "tests/integration/fixtures/test_basic.json",
    "tests/integration/fixtures/test_complex.json"
])
@pytest.mark.anyio
async def test_create_multiple_profiles(async_client: AsyncClient, load_fixture, fixture_file):
    # Create multiple profiles
    profile_data = load_fixture(fixture_file)
    response = await async_client.post("/v1/profiles", json=profile_data)
    assert response.status_code == 201, f"Failed to create profile with {fixture_file}. Response content: {response.text}"
    response_data = response.json()
    assert response_data["email"] == profile_data["email"]
    assert "uuid" in response_data

    # List all profiles
    response = await async_client.get("/v1/profiles?orderby=uuid&offset=1&limit=10")
    assert response.status_code == 200
    assert isinstance(response.json(), list)
    assert len(response.json()) > 0