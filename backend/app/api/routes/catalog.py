import uuid
from typing import List, Optional, Sequence

from fastapi import APIRouter, Depends, HTTPException, Query, status
from sqlalchemy import func, select
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.orm import selectinload

from app.api.deps import get_current_profile, get_db, require_admin
from app.models.catalog import Ingredient, Product
from app.models.profile import Profile
from app.models.scan import ScanRecord
from app.schemas.catalog import (
    IngredientCreate,
    IngredientOut,
    IngredientUpdate,
    ProductCreate,
    ProductOut,
    ProductUpdate,
)
from app.schemas.common import MessageResponse, Page
from app.services.recommendation import (
    concerns_for_skin_type,
    find_recommended_products,
    product_query,
    recommend_ingredients,
)

router = APIRouter()
BUDGET_PATTERN = "^(low|mid|high)$"


def _product_out(product: Product, reason: Optional[str] = None) -> ProductOut:
    return ProductOut(
        id=product.id,
        name=product.name,
        brand=product.brand,
        category=product.category,
        price=product.price,
        image_url=product.image_url,
        purchase_url=product.purchase_url,
        description=product.description,
        ingredients=[i.name for i in product.ingredients],
        match_reason=reason,
    )


async def _ingredients_by_names(db: AsyncSession, names: Sequence[str]) -> List[Ingredient]:
    cleaned = [n.strip() for n in names if n and n.strip()]
    if not cleaned:
        return []
    rows = (await db.execute(select(Ingredient).where(func.lower(Ingredient.name).in_([n.lower() for n in cleaned])))).scalars().all()
    found = {i.name.lower() for i in rows}
    missing = [n for n in cleaned if n.lower() not in found]
    if missing:
        raise HTTPException(status_code=422, detail=f"Bahan aktif belum ada di database: {', '.join(missing)}.")
    return list(rows)


async def _load_product(db: AsyncSession, product_id: uuid.UUID) -> Product:
    stmt = select(Product).where(Product.id == product_id).options(selectinload(Product.ingredients))
    product = (await db.execute(stmt)).scalar_one_or_none()
    if product is None:
        raise HTTPException(status_code=404, detail="Produk tidak ditemukan.")
    return product


# ---------------------------------------------------------------- Produk
@router.get("/products", response_model=Page[ProductOut], summary="Filter produk: tipe kulit, bahan aktif, budget")
async def list_products(
    q: Optional[str] = Query(default=None, description="Cari nama / brand"),
    category: Optional[str] = None,
    skin_type: Optional[str] = Query(default=None, description="Oily, Dry, Combination, Sensitive, Normal"),
    concern: Optional[str] = Query(default=None, description="Masalah kulit, mis. Jerawat"),
    ingredient: Optional[List[str]] = Query(default=None, description="Nama bahan aktif (boleh berulang)"),
    budget: Optional[str] = Query(default=None, pattern=BUDGET_PATTERN, description="low <50rb | mid 50-150rb | high >150rb"),
    min_price: Optional[int] = Query(default=None, ge=0),
    max_price: Optional[int] = Query(default=None, ge=0),
    limit: int = Query(default=20, ge=1, le=100),
    offset: int = Query(default=0, ge=0),
    db: AsyncSession = Depends(get_db),
) -> Page[ProductOut]:
    concerns = ([concern] if concern else []) + concerns_for_skin_type(skin_type)
    base = product_query(
        q=q,
        category=category,
        ingredient_names=ingredient,
        concerns=concerns or None,
        min_price=min_price,
        max_price=max_price,
        budget=budget,
    )
    total = (await db.execute(select(func.count()).select_from(base.order_by(None).options().subquery()))).scalar_one()
    rows = (await db.execute(base.order_by(Product.price.asc(), Product.name.asc()).limit(limit).offset(offset))).scalars().unique().all()
    return Page[ProductOut](items=[_product_out(p) for p in rows], total=total, limit=limit, offset=offset)


@router.get("/products/{product_id}", response_model=ProductOut, summary="Detail produk")
async def get_product(product_id: uuid.UUID, db: AsyncSession = Depends(get_db)) -> ProductOut:
    return _product_out(await _load_product(db, product_id))


@router.post("/products", response_model=ProductOut, status_code=status.HTTP_201_CREATED, summary="[Admin] Tambah produk")
async def create_product(
    payload: ProductCreate,
    _: object = Depends(require_admin),
    db: AsyncSession = Depends(get_db),
) -> ProductOut:
    ingredients = await _ingredients_by_names(db, payload.ingredient_names)
    product = Product(**payload.model_dump(exclude={"ingredient_names"}))
    product.ingredients = ingredients
    db.add(product)
    await db.flush()
    return _product_out(await _load_product(db, product.id))


@router.put("/products/{product_id}", response_model=ProductOut, summary="[Admin] Update produk")
async def update_product(
    product_id: uuid.UUID,
    payload: ProductUpdate,
    _: object = Depends(require_admin),
    db: AsyncSession = Depends(get_db),
) -> ProductOut:
    product = await _load_product(db, product_id)
    data = payload.model_dump(exclude_unset=True)
    names = data.pop("ingredient_names", None)
    for field, value in data.items():
        setattr(product, field, value)
    if names is not None:
        product.ingredients = await _ingredients_by_names(db, names)
    await db.flush()
    return _product_out(await _load_product(db, product_id))


@router.delete("/products/{product_id}", response_model=MessageResponse, summary="[Admin] Hapus produk")
async def delete_product(
    product_id: uuid.UUID,
    _: object = Depends(require_admin),
    db: AsyncSession = Depends(get_db),
) -> MessageResponse:
    product = await _load_product(db, product_id)
    await db.delete(product)
    return MessageResponse(message="Produk dihapus.")


# ----------------------------------------------------------- Rekomendasi
@router.get("/recommendations", response_model=List[ProductOut], summary="Produk terkurasi dari hasil scan")
async def recommendations(
    scan_id: Optional[str] = Query(default=None, description="Default: scan terbaru milik user"),
    budget: Optional[str] = Query(default=None, pattern=BUDGET_PATTERN),
    limit: int = Query(default=10, ge=1, le=50),
    profile: Profile = Depends(get_current_profile),
    db: AsyncSession = Depends(get_db),
) -> List[ProductOut]:
    if scan_id:
        scan = await db.get(ScanRecord, scan_id)
        if scan is None or scan.user_id != profile.id:
            raise HTTPException(status_code=404, detail="Data scan tidak ditemukan.")
    else:
        scan = (
            await db.execute(
                select(ScanRecord).where(ScanRecord.user_id == profile.id).order_by(ScanRecord.analyzed_at.desc()).limit(1)
            )
        ).scalar_one_or_none()
        if scan is None:
            raise HTTPException(status_code=404, detail="Belum ada hasil scan.")

    wanted = list(scan.recommended_ingredients or [])
    if not wanted:
        wanted, _avoid = recommend_ingredients(
            acne=scan.acne, oil=scan.oil, redness=scan.redness, pores=scan.pores, skin_type=scan.skin_type
        )
    matches = await find_recommended_products(db, wanted, budget=budget, limit=limit)
    return [_product_out(p, reason) for p, reason in matches]


# -------------------------------------------------------------- Bahan aktif
@router.get("/ingredients", response_model=List[IngredientOut], summary="Daftar bahan aktif")
async def list_ingredients(
    q: Optional[str] = None,
    concern: Optional[str] = None,
    db: AsyncSession = Depends(get_db),
) -> List[Ingredient]:
    stmt = select(Ingredient).order_by(Ingredient.name)
    if q:
        stmt = stmt.where(Ingredient.name.ilike(f"%{q.strip()}%"))
    if concern:
        stmt = stmt.where(Ingredient.good_for.contains([concern]))
    return list((await db.execute(stmt)).scalars().all())


@router.get("/ingredients/{ingredient_id}", response_model=IngredientOut, summary="Detail bahan aktif")
async def get_ingredient(ingredient_id: uuid.UUID, db: AsyncSession = Depends(get_db)) -> Ingredient:
    ingredient = await db.get(Ingredient, ingredient_id)
    if ingredient is None:
        raise HTTPException(status_code=404, detail="Bahan aktif tidak ditemukan.")
    return ingredient


@router.post("/ingredients", response_model=IngredientOut, status_code=status.HTTP_201_CREATED, summary="[Admin] Tambah bahan aktif")
async def create_ingredient(
    payload: IngredientCreate,
    _: object = Depends(require_admin),
    db: AsyncSession = Depends(get_db),
) -> Ingredient:
    exists = (await db.execute(select(Ingredient).where(func.lower(Ingredient.name) == payload.name.lower()))).scalar_one_or_none()
    if exists is not None:
        raise HTTPException(status_code=409, detail="Bahan aktif sudah ada.")
    ingredient = Ingredient(**payload.model_dump())
    db.add(ingredient)
    await db.flush()
    await db.refresh(ingredient)
    return ingredient


@router.put("/ingredients/{ingredient_id}", response_model=IngredientOut, summary="[Admin] Update bahan aktif")
async def update_ingredient(
    ingredient_id: uuid.UUID,
    payload: IngredientUpdate,
    _: object = Depends(require_admin),
    db: AsyncSession = Depends(get_db),
) -> Ingredient:
    ingredient = await db.get(Ingredient, ingredient_id)
    if ingredient is None:
        raise HTTPException(status_code=404, detail="Bahan aktif tidak ditemukan.")
    for field, value in payload.model_dump(exclude_unset=True).items():
        setattr(ingredient, field, value)
    await db.flush()
    await db.refresh(ingredient)
    return ingredient


@router.delete("/ingredients/{ingredient_id}", response_model=MessageResponse, summary="[Admin] Hapus bahan aktif")
async def delete_ingredient(
    ingredient_id: uuid.UUID,
    _: object = Depends(require_admin),
    db: AsyncSession = Depends(get_db),
) -> MessageResponse:
    ingredient = await db.get(Ingredient, ingredient_id)
    if ingredient is None:
        raise HTTPException(status_code=404, detail="Bahan aktif tidak ditemukan.")
    await db.delete(ingredient)
    return MessageResponse(message="Bahan aktif dihapus.")
