import uuid
from typing import Optional

from fastapi import APIRouter, Depends, HTTPException, Query, status
from sqlalchemy import func, or_, select
from sqlalchemy.exc import IntegrityError
from sqlalchemy.ext.asyncio import AsyncSession

from app.api.deps import get_db, require_admin
from app.models.education import Article
from app.schemas.common import MessageResponse, Page
from app.schemas.education import ArticleCreate, ArticleOut, ArticleUpdate

router = APIRouter()


async def _get_article(db: AsyncSession, key: str) -> Article:
    """Ambil artikel berdasarkan UUID atau slug."""
    try:
        article = await db.get(Article, uuid.UUID(key))
    except ValueError:
        article = (await db.execute(select(Article).where(Article.slug == key))).scalar_one_or_none()
    if article is None:
        raise HTTPException(status_code=404, detail="Artikel tidak ditemukan.")
    return article


@router.get("/articles", response_model=Page[ArticleOut], summary="Daftar artikel edukasi")
async def list_articles(
    topic: Optional[str] = Query(default=None, description="Acne, PIH, Dark Circle, Redness, Wrinkle"),
    q: Optional[str] = Query(default=None, description="Cari judul / ringkasan"),
    limit: int = Query(default=20, ge=1, le=100),
    offset: int = Query(default=0, ge=0),
    db: AsyncSession = Depends(get_db),
) -> Page[ArticleOut]:
    conds = [Article.is_published.is_(True)]
    if topic:
        conds.append(func.lower(Article.topic) == topic.strip().lower())
    if q:
        like = f"%{q.strip()}%"
        conds.append(or_(Article.title.ilike(like), Article.summary.ilike(like)))
    total = (await db.execute(select(func.count()).select_from(Article).where(*conds))).scalar_one()
    rows = (
        await db.execute(select(Article).where(*conds).order_by(Article.created_at.desc(), Article.title).limit(limit).offset(offset))
    ).scalars().all()
    return Page[ArticleOut](items=[ArticleOut.model_validate(a) for a in rows], total=total, limit=limit, offset=offset)


@router.get("/articles/{article_key}", response_model=ArticleOut, summary="Detail artikel (UUID atau slug)")
async def get_article(article_key: str, db: AsyncSession = Depends(get_db)) -> Article:
    article = await _get_article(db, article_key)
    if not article.is_published:
        raise HTTPException(status_code=404, detail="Artikel tidak ditemukan.")
    return article


@router.post("/articles", response_model=ArticleOut, status_code=status.HTTP_201_CREATED, summary="[Admin] Tambah artikel")
async def create_article(
    payload: ArticleCreate,
    _: object = Depends(require_admin),
    db: AsyncSession = Depends(get_db),
) -> Article:
    if (await db.execute(select(Article.id).where(Article.slug == payload.slug))).first():
        raise HTTPException(status_code=409, detail="Slug sudah dipakai.")
    article = Article(**payload.model_dump())
    db.add(article)
    await db.flush()
    await db.refresh(article)
    return article


@router.put("/articles/{article_key}", response_model=ArticleOut, summary="[Admin] Update artikel")
async def update_article(
    article_key: str,
    payload: ArticleUpdate,
    _: object = Depends(require_admin),
    db: AsyncSession = Depends(get_db),
) -> Article:
    article = await _get_article(db, article_key)
    for field, value in payload.model_dump(exclude_unset=True).items():
        setattr(article, field, value)
    try:
        await db.flush()
    except IntegrityError:
        raise HTTPException(status_code=409, detail="Slug sudah dipakai.")
    await db.refresh(article)
    return article


@router.delete("/articles/{article_key}", response_model=MessageResponse, summary="[Admin] Hapus artikel")
async def delete_article(
    article_key: str,
    _: object = Depends(require_admin),
    db: AsyncSession = Depends(get_db),
) -> MessageResponse:
    article = await _get_article(db, article_key)
    await db.delete(article)
    return MessageResponse(message="Artikel dihapus.")
