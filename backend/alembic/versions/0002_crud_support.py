"""0002_crud_support

Revision ID: 0002_crud_support
Revises: 0001_initial_schema
"""
from typing import Sequence, Union
from alembic import op

revision: str = '0002_crud_support'
down_revision: Union[str, None] = '0001_initial_schema'
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None

STATEMENTS = [
    "ALTER TABLE public.profiles ADD COLUMN IF NOT EXISTS phone VARCHAR(30)",
    "ALTER TABLE public.profiles ADD COLUMN IF NOT EXISTS avatar_url VARCHAR(1024)",
    "ALTER TABLE public.scan_records ADD COLUMN IF NOT EXISTS meta JSONB NOT NULL DEFAULT '{}'::jsonb",
    "ALTER TABLE public.skin_journeys ADD COLUMN IF NOT EXISTS is_pinned BOOLEAN NOT NULL DEFAULT false",
    "ALTER TABLE public.skin_journeys ADD COLUMN IF NOT EXISTS deleted_at TIMESTAMPTZ",
    "ALTER TABLE public.skin_journeys ADD COLUMN IF NOT EXISTS meta JSONB NOT NULL DEFAULT '{}'::jsonb",
    "ALTER TABLE public.journey_checkins ADD COLUMN IF NOT EXISTS meta JSONB NOT NULL DEFAULT '{}'::jsonb",
    """CREATE TABLE IF NOT EXISTS public.articles (
        id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
        slug VARCHAR(150) UNIQUE NOT NULL,
        topic VARCHAR(50) NOT NULL,
        title VARCHAR(255) NOT NULL,
        summary TEXT NOT NULL DEFAULT '',
        body TEXT NOT NULL DEFAULT '',
        key_points JSONB NOT NULL DEFAULT '[]'::jsonb,
        read_time VARCHAR(30),
        source VARCHAR(255),
        image_url VARCHAR(1024),
        is_published BOOLEAN NOT NULL DEFAULT true,
        created_at TIMESTAMPTZ NOT NULL DEFAULT now()
    )""",
    "CREATE INDEX IF NOT EXISTS ix_articles_slug ON public.articles(slug)",
    "CREATE INDEX IF NOT EXISTS ix_articles_topic ON public.articles(topic)",
]


def upgrade() -> None:
    for stmt in STATEMENTS:
        op.execute(stmt)


def downgrade() -> None:
    op.execute("DROP TABLE IF EXISTS public.articles")
