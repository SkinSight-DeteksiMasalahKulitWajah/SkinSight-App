"""Unit test normalisasi URL PostgreSQL -> asyncpg."""
from app.core.database import prepare_asyncpg_connection


def test_strip_sslmode_require_for_asyncpg():
    url, args = prepare_asyncpg_connection(
        "postgresql+asyncpg://user:pass@aws-0-ap-southeast-2.pooler.supabase.com:5432/postgres?sslmode=require"
    )
    assert "sslmode" not in url
    assert url.startswith("postgresql+asyncpg://")
    assert args.get("ssl") == "require"
    assert "statement_cache_size" not in args


def test_convert_postgres_scheme_and_pooler_port_6543():
    url, args = prepare_asyncpg_connection(
        "postgres://user:pass@aws-0-ap-southeast-2.pooler.supabase.com:6543/postgres?sslmode=verify-full&application_name=skinsight"
    )
    assert url.startswith("postgresql+asyncpg://")
    assert "application_name=skinsight" in url
    assert "sslmode" not in url
    assert args.get("ssl") == "require"
    assert args.get("statement_cache_size") == 0


def test_plain_local_url_unchanged():
    url, args = prepare_asyncpg_connection("postgresql://postgres:pw@localhost:5432/skinsight")
    assert url == "postgresql+asyncpg://postgres:pw@localhost:5432/skinsight"
    assert args == {}
