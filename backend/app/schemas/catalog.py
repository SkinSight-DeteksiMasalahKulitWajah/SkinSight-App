import uuid
from typing import List, Optional
from pydantic import BaseModel, ConfigDict, Field


class IngredientBase(BaseModel):
    name: str = Field(..., min_length=1, max_length=100)
    description: Optional[str] = None
    good_for: List[str] = Field(default_factory=list)
    cautions: List[str] = Field(default_factory=list)


class IngredientCreate(IngredientBase):
    pass


class IngredientUpdate(BaseModel):
    name: Optional[str] = Field(default=None, min_length=1, max_length=100)
    description: Optional[str] = None
    good_for: Optional[List[str]] = None
    cautions: Optional[List[str]] = None


class IngredientOut(IngredientBase):
    model_config = ConfigDict(from_attributes=True)
    id: uuid.UUID


class ProductBase(BaseModel):
    name: str = Field(..., min_length=1, max_length=255)
    brand: str = Field(..., min_length=1, max_length=100)
    category: str = Field(..., min_length=1, max_length=50)
    price: int = Field(..., ge=0)
    image_url: Optional[str] = None
    purchase_url: Optional[str] = None
    description: Optional[str] = None


class ProductCreate(ProductBase):
    ingredient_names: List[str] = Field(default_factory=list)


class ProductUpdate(BaseModel):
    name: Optional[str] = Field(default=None, min_length=1, max_length=255)
    brand: Optional[str] = Field(default=None, min_length=1, max_length=100)
    category: Optional[str] = Field(default=None, min_length=1, max_length=50)
    price: Optional[int] = Field(default=None, ge=0)
    image_url: Optional[str] = None
    purchase_url: Optional[str] = None
    description: Optional[str] = None
    ingredient_names: Optional[List[str]] = None


class ProductOut(ProductBase):
    id: uuid.UUID
    ingredients: List[str] = Field(default_factory=list)
    match_reason: Optional[str] = None
