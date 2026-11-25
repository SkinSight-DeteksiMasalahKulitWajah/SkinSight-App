"""Rule engine rekomendasi bahan aktif & filter katalog produk berdasarkan budget."""
from typing import Iterable, List, Optional, Sequence, Tuple

from sqlalchemy import Select, and_, func, or_, select
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.orm import selectinload

from app.models.catalog import Ingredient, Product, product_ingredients

# Batas harga (Rupiah) untuk filter budget.
BUDGET_RANGES = {
    "low": (None, 49_999),         # < Rp 50.000
    "mid": (50_000, 150_000),      # Rp 50.000 - Rp 150.000
    "high": (150_001, None),       # > Rp 150.000
}

SKIN_TYPE_CONCERNS = {
    "oily": ["Minyak Berlebih", "Jerawat", "Pori-pori"],
    "berminyak": ["Minyak Berlebih", "Jerawat", "Pori-pori"],
    "dry": ["Kulit Kering", "Skin Barrier"],
    "kering": ["Kulit Kering", "Skin Barrier"],
    "combination": ["Minyak Berlebih", "Kelembapan"],
    "kombinasi": ["Minyak Berlebih", "Kelembapan"],
    "sensitive": ["Kemerahan", "Skin Barrier"],
    "sensitif": ["Kemerahan", "Skin Barrier"],
    "normal": ["Kelembapan"],
}


def recommend_ingredients(
    acne: int = 0, oil: int = 0, redness: int = 0, pores: int = 0, skin_type: str = ""
) -> Tuple[List[str], List[str]]:
    """Baseline rule engine: (bahan disarankan, bahan dihindari) dari metrik scan."""
    recommended: List[str] = []
    avoid: List[str] = []

    def add(target: List[str], *names: str) -> None:
        for n in names:
            if n not in target:
                target.append(n)

    if acne >= 30 or oil >= 50:
        add(recommended, "Niacinamide", "Salicylic Acid", "Tea Tree")
        add(avoid, "Scrub kasar", "Minyak berat (heavy oil)")
    if redness >= 30:
        add(recommended, "Centella Asiatica", "Ceramide", "Hyaluronic Acid")
        add(avoid, "Alcohol Denat konsentrasi tinggi", "Pewangi sintetis")
    if pores >= 40:
        add(recommended, "Niacinamide", "Salicylic Acid")
    if skin_type.lower() in ("dry", "kering"):
        add(recommended, "Hyaluronic Acid", "Ceramide")
    if not recommended:
        add(recommended, "Hyaluronic Acid", "Ceramide", "Niacinamide")
    return recommended, avoid


def budget_bounds(budget: Optional[str]) -> Tuple[Optional[int], Optional[int]]:
    if not budget:
        return None, None
    return BUDGET_RANGES.get(budget.lower(), (None, None))


def concerns_for_skin_type(skin_type: Optional[str]) -> List[str]:
    return SKIN_TYPE_CONCERNS.get((skin_type or "").strip().lower(), [])


def product_query(
    *,
    q: Optional[str] = None,
    category: Optional[str] = None,
    ingredient_names: Optional[Sequence[str]] = None,
    concerns: Optional[Sequence[str]] = None,
    min_price: Optional[int] = None,
    max_price: Optional[int] = None,
    budget: Optional[str] = None,
) -> Select:
    stmt = select(Product).options(selectinload(Product.ingredients))
    conds = []
    if q:
        like = f"%{q.strip()}%"
        conds.append(or_(Product.name.ilike(like), Product.brand.ilike(like)))
    if category:
        conds.append(func.lower(Product.category) == category.strip().lower())

    b_min, b_max = budget_bounds(budget)
    lo = min_price if min_price is not None else b_min
    hi = max_price if max_price is not None else b_max
    if lo is not None:
        conds.append(Product.price >= lo)
    if hi is not None:
        conds.append(Product.price <= hi)

    ing_filters = []
    if ingredient_names:
        lowered = [n.lower() for n in ingredient_names]
        ing_filters.append(func.lower(Ingredient.name).in_(lowered))
    if concerns:
        ing_filters.append(or_(*[Ingredient.good_for.contains([c]) for c in concerns]))
    if ing_filters:
        sub = (
            select(product_ingredients.c.product_id)
            .join(Ingredient, Ingredient.id == product_ingredients.c.ingredient_id)
            .where(or_(*ing_filters))
        )
        conds.append(Product.id.in_(sub))

    if conds:
        stmt = stmt.where(and_(*conds))
    return stmt


def match_reason(product: Product, wanted: Iterable[str]) -> Optional[str]:
    wanted_l = {w.lower() for w in wanted}
    hits = [i.name for i in product.ingredients if i.name.lower() in wanted_l]
    if hits:
        return "Mengandung " + ", ".join(hits) + " yang sesuai dengan kondisi kulitmu."
    return None


async def find_recommended_products(
    db: AsyncSession,
    ingredient_names: Sequence[str],
    budget: Optional[str] = None,
    limit: int = 10,
) -> List[Tuple[Product, Optional[str]]]:
    if not ingredient_names:
        return []
    stmt = product_query(ingredient_names=ingredient_names, budget=budget).order_by(Product.price).limit(limit)
    products = (await db.execute(stmt)).scalars().unique().all()
    return [(p, match_reason(p, ingredient_names)) for p in products]
