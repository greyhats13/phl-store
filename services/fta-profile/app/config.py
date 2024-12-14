# Path: fta_profile/app/config.py

from pydantic_settings import BaseSettings
from pydantic import Field, ConfigDict

class Settings(BaseSettings):
    # Application Settings
    app_host: str = "0.0.0.0"
    app_port: int = 8000
    app_log_level: str = "debug"
    app_env: str = "dev"
    app_name: str = "fta_profile"
    app_workers: int = 2

    # Database Settings
    db_user: str = Field(..., env="DB_USER")
    db_password: str = Field(..., env="DB_PASSWORD")
    db_host: str = Field(..., env="DB_HOST")
    db_port: int = Field(3306, env="DB_PORT")
    db_name: str = Field(..., env="DB_NAME")

    @property
    def database_url(self) -> str:
        return f"mysql+aiomysql://{self.db_user}:{self.db_password}@{self.db_host}:{self.db_port}/{self.db_name}"

    # Middleware
    cors_allow_origins: str = "*"
    cors_allow_methods: str = "*"
    cors_allow_headers: str = "*"
    cors_allow_credentials: bool = False
    cors_max_age: int = 86400

    trusted_hosts: str = "*"
    gzip_min_length: int = 512
    use_aiologger: bool = False

    # OpenTelemetry
    otel_exporter_otlp_endpoint: str = "otel-collector:4317"
    otel_exporter_otlp_insecure: bool = True
    otel_exporter_otlp_headers_str: str = ""
    otel_sampling_rate: float = 1.0

    @property
    def otel_exporter_otlp_headers(self) -> dict[str, str]:
        headers_str = self.otel_exporter_otlp_headers_str
        headers = {}
        if headers_str:
            for header in headers_str.split(","):
                key, value = header.strip().split("=")
                headers[key.strip()] = value.strip()
        return headers

    model_config = ConfigDict(env_file=".env", env_file_encoding="utf-8")