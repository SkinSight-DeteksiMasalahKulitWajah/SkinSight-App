from typing import Any, AsyncGenerator, Dict, Tuple
from urllib.parse import parse_qsl, urlencode, urlsplit, urlunsplit

from sqlalchemy.ext.asyncio import (
    AsyncSession,
    async_sessionmaker,
    create_async_engine,
)
from sqlalchemy.orm import DeclarativeBase
from app.core.config import settings


class Base(DeclarativeBase):
    """Base class for all SQLAlchemy ORM models."""
    pass


def prepare_asyncpg_connection(raw_url: str) -> Tuple[str, Dict[str, Any]]:
    """Normalisasi URL PostgreSQL agar kompatibel dengan driver asyncpg.

    - Mengubah scheme `postgresql://` atau `postgres://` -> `postgresql+asyncpg://`.
    - Memindahkan parameter `sslmode` (yang tidak dikenali asyncpg) ke `connect_args['ssl']`.
    - Mematikan statement cache secara otomatis untuk PgBouncer / Supabase transaction pooler (port 6543).
    """
    url = raw_url.strip()
    if url.startswith("postgres://"):
        url = url.replace("postgres://", "postgresql+asyncpg://", 1)
    elif url.startswith("postgresql://"):
        url = url.replace("postgresql://", "postgresql+asyncpg://", 1)

    parsed = urlsplit(url)
    connect_args: Dict[str, Any] = {}
    filtered_query = []

    for key, value in parse_qsl(parsed.query, keep_blank_values=True):
        lowered = key.lower()
        if lowered == "sslmode":
            mode = value.lower()
            if mode in {"require", "verify-ca", "verify-full", "prefer", "allow"}:
                connect_args["ssl"] = "require"
            elif mode == "disable":
                connect_args["ssl"] = False
            continue
        if lowered == "ssl":
            connect_args["ssl"] = False if value.lower() in {"false", "0", "disable"} else value
            continue
        filtered_query.append((key, value))

    if parsed.port == 6543:
        connect_args["statement_cache_size"] = 0

    clean_url = urlunsplit(
        (parsed.scheme, parsed.netloc, parsed.path, urlencode(filtered_query), parsed.fragment)
    )
    return clean_url, connect_args


database_url, database_connect_args = prepare_asyncpg_connection(settings.DATABASE_URL)

engine = create_async_engine(
    database_url,
    connect_args=database_connect_args,
    echo=settings.ENVIRONMENT == "development",
    future=True,
    pool_size=10,
    max_overflow=20,
    pool_recycle=300,
    pool_pre_ping=True,
)

AsyncSessionLocal = async_sessionmaker(
    bind=engine,
    class_=AsyncSession,
    autocommit=False,
    autoflush=False,
    expire_on_commit=False,
)


async def get_db() -> AsyncGenerator[AsyncSession, None]:
    """Dependency injection to provide database session per request."""
    async with AsyncSessionLocal() as session:
        try:
            yield session
            await session.commit()
        except Exception:
            await session.rollback()
            raise
        finally:
            await session.close()
