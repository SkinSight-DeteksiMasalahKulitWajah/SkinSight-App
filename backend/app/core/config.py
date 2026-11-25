import json
from typing import List, Union
from pydantic import field_validator
from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    PROJECT_NAME: str = "SkinSight API"
    VERSION: str = "1.0.0"
    API_V1_STR: str = "/api/v1"
    ENVIRONMENT: str = "development"

    # Host & Port
    HOST: str = "0.0.0.0"
    PORT: int = 8000

    # CORS origins
    CORS_ORIGINS: Union[List[str], str] = ["*"]

    @field_validator("CORS_ORIGINS", mode="before")
    def assemble_cors_origins(cls, v: Union[str, List[str]]) -> List[str]:
        if isinstance(v, str):
            if v.startswith("[") and v.endswith("]"):
                try:
                    return json.loads(v)
                except Exception:
                    pass
            return [i.strip() for i in v.split(",") if i.strip()]
        elif isinstance(v, list):
            return v
        return ["*"]

    # Database
    DATABASE_URL: str = "postgresql+asyncpg://postgres:password@localhost:5432/skinsight"

    # Supabase (Auth / Storage)
    SUPABASE_URL: str = "https://pzszjjjyrwdfehfwczyo.supabase.co"
    SUPABASE_ANON_KEY: str = ""
    SUPABASE_SERVICE_ROLE_KEY: str = ""
    SUPABASE_JWT_SECRET: str = ""

    # Email admin (dipisah koma) yang boleh mengelola katalog & artikel
    ADMIN_EMAILS: str = ""

    # ML Model Configuration
    ML_MODEL_PATH: str = "models/all_conditions_detect_float32.tflite"
    USE_MOCK_ML: bool = False

    # LLM (Gemini API) Configuration (mendukung banyak key dipisah koma untuk rotasi/failover)
    GEMINI_API_KEY: str = ""
    GEMINI_API_KEYS: str = ""
    GEMINI_MODEL: str = "gemini-3.5-flash"

    @property
    def gemini_api_keys(self) -> List[str]:
        """Parse daftar Gemini API key valid dari GEMINI_API_KEY / GEMINI_API_KEYS."""
        keys: List[str] = []
        seen = set()
        for source in (self.GEMINI_API_KEY or "", self.GEMINI_API_KEYS or ""):
            for item in source.replace("\n", ",").split(","):
                key = item.strip()
                if not key or key.startswith("YOUR_") or key in seen:
                    continue
                seen.add(key)
                keys.append(key)
        return keys

    model_config = SettingsConfigDict(
        env_file=".env",
        env_file_encoding="utf-8",
        case_sensitive=True,
        extra="ignore"
    )


settings = Settings()
