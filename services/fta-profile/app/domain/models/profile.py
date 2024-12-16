# Path: fta_profile/app/domain/models/profile.py

from enum import Enum
from datetime import date, datetime
from pydantic import EmailStr
from sqlmodel import SQLModel, Field, UniqueConstraint
from uuid import uuid4

class Gender(str, Enum):
    male = "male"
    female = "female"

class Image(SQLModel, table=False):
    name: str | None = None
    url: str | None = None

class Address(SQLModel, table=False):
    type: str | None = None
    address: str | None = None
    subdistrict: str | None = None
    district: str | None = None
    city: str | None = None
    province: str | None = None
    country: str | None = None
    postalCode: int | None = None

class ProfileBase(SQLModel):
    email: EmailStr
    firstname: str | None = None
    lastname: str | None = None
    birthdate: date | None = None
    gender: Gender | None = None
    addresses: list[Address] | None = None
    image: Image | None = None

class Profile(ProfileBase, table=True):
    __tablename__ = 'profiles'
    __table_args__ = (
        UniqueConstraint('email', name='uq_profiles_email'),
        {'mysql_charset': 'utf8mb4'},
    )

    __mapper_args__ = {
        "eager_defaults": True,
    }
    uuid: str = Field(default_factory=lambda: str(uuid4()), primary_key=True)
    createdAt: datetime = Field(default_factory=datetime.now().isoformat())
    updatedAt: datetime = Field(default_factory=datetime.now().isoformat())

class ProfileCreate(ProfileBase):
    pass

class ProfileUpdate(SQLModel):
    email: EmailStr | None = None
    firstname: str | None = None
    lastname: str | None = None
    birthdate: date | None = None
    gender: Gender | None = None
    addresses: list[Address] | None = None
    image: Image | None = None