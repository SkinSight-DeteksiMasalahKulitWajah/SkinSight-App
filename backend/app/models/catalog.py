import uuid
from typing import List, Optional
from sqlalchemy import String, Integer, Text, Table, Column, ForeignKey
from sqlalchemy.dialects.postgresql import UUID, JSONB
from sqlalchemy.orm import Mapped, mapped_column, relationship
from app.core.database import Base

# Many-to-Many association table antara Product dan Ingredient
product_ingredients = Table(
    "product_ingredients",
    Base.metadata,
    Column("product_id", UUID(as_uuid=True), ForeignKey("products.id", ondelete="CASCADE"), primary_key=True),
    Column("ingredient_id", UUID(as_uuid=True), ForeignKey("ingredients.id", ondelete="CASCADE"), primary_key=True),
)


class Ingredient(Base):
    """Skincare active ingredients catalog and suitability rules."""
    __tablename__ = "ingredients"

    id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), primary_key=True, default=uuid.uuid4
    )
    name: Mapped[str] = mapped_column(String(100), unique=True, index=True, nullable=False)
    description: Mapped[Optional[str]] = mapped_column(Text, nullable=True)
    
    # Masalah kulit yang cocok diatasi (misal: ["Jerawat", "Minyak Berlebih", "Pori-pori"])
    good_for: Mapped[list] = mapped_column(JSONB, default=list, server_default="[]")
    
    # Kondisi yang harus berhati-hati (misal: ["Kulit Sangat Sensitif", "Eksim"])
    cautions: Mapped[list] = mapped_column(JSONB, default=list, server_default="[]")

    # Relasi produk
    products: Mapped[List["Product"]] = relationship(
        "Product", secondary=product_ingredients, back_populates="ingredients"
    )


class Product(Base):
    """Skincare products catalog for recommendation engine with budget filtering."""
    __tablename__ = "products"

    id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), primary_key=True, default=uuid.uuid4
    )
    name: Mapped[str] = mapped_column(String(255), index=True, nullable=False)
    brand: Mapped[str] = mapped_column(String(100), index=True, nullable=False)
    category: Mapped[str] = mapped_column(String(50), index=True, nullable=False)  # Cleanser, Toner, Serum, Moisturizer, Sunscreen
    
    # Harga riil dalam Rupiah (untuk budget filter: < 50rb, 50-150rb, > 150rb)
    price: Mapped[int] = mapped_column(Integer, nullable=False)
    
    image_url: Mapped[Optional[str]] = mapped_column(String(1024), nullable=True)
    purchase_url: Mapped[Optional[str]] = mapped_column(String(1024), nullable=True)
    description: Mapped[Optional[str]] = mapped_column(Text, nullable=True)
    
    # Relasi ingredients
    ingredients: Mapped[List["Ingredient"]] = relationship(
        "Ingredient", secondary=product_ingredients, back_populates="products"
    )
