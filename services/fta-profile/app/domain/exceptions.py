# Path: fta_profile/app/domain/exceptions.py

class ProfileNotFoundException(Exception):
    """Exception raised when a profile is not found."""
    pass

class ProfileConflictException(Exception):
    """Exception raised when there is a conflict, such as duplicate email."""
    pass

class DataAccessException(Exception):
    """General exception for data access errors."""
    pass