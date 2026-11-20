"""Isi data awal (bahan aktif, produk contoh, artikel edukasi). Aman dijalankan berulang.

Jalankan dari folder backend:  python -m scripts.seed
"""
import asyncio
import json
from pathlib import Path

from sqlalchemy import func, select

from app.core.database import AsyncSessionLocal, engine
from app.models.catalog import Ingredient, Product
from app.models.education import Article

DATA = Path(__file__).resolve().parent.parent / "app" / "seed_data"


async def seed() -> None:
    catalog = json.loads((DATA / "catalog.json").read_text(encoding="utf-8"))
    articles = json.loads((DATA / "articles.json").read_text(encoding="utf-8"))
    added = {"ingredients": 0, "products": 0, "articles": 0}

    async with AsyncSessionLocal() as db:
        by_name = {}
        for item in catalog["ingredients"]:
            row = (
                await db.execute(select(Ingredient).where(func.lower(Ingredient.name) == item["name"].lower()))
            ).scalar_one_or_none()
            if row is None:
                row = Ingredient(**item)
                db.add(row)
                added["ingredients"] += 1
            by_name[item["name"]] = row
        await db.flush()

        for item in catalog["products"]:
            exists = (
                await db.execute(
                    select(Product.id).where(Product.name == item["name"], Product.brand == item["brand"])
                )
            ).first()
            if exists:
                continue
            product = Product(**{k: v for k, v in item.items() if k != "ingredients"})
            product.ingredients = [by_name[n] for n in item["ingredients"]]
            db.add(product)
            added["products"] += 1

        for item in articles:
            exists = (await db.execute(select(Article.id).where(Article.slug == item["slug"]))).first()
            if not exists:
                db.add(Article(**item))
                added["articles"] += 1

        await db.commit()
    await engine.dispose()
    print("Seed selesai:", added)


if __name__ == "__main__":
    asyncio.run(seed())
