"""0001_initial_schema

Revision ID: 0001_initial_schema
Revises: 
Create Date: 2026-11-05 10:00:00.000000

"""
from typing import Sequence, Union
from alembic import op
import sqlalchemy as sa
from sqlalchemy.dialects import postgresql

revision: str = '0001_initial_schema'
down_revision: Union[str, None] = None
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    # 1. Tabel profiles
    op.create_table(
        'profiles',
        sa.Column('id', postgresql.UUID(as_uuid=True), primary_key=True),
        sa.Column('email', sa.String(length=255), nullable=False),
        sa.Column('full_name', sa.String(length=255), nullable=True),
        sa.Column('gender', sa.String(length=20), nullable=True),
        sa.Column('birth_date', sa.Date(), nullable=True),
        sa.Column('dominant_skin_type', sa.String(length=50), nullable=True),
        sa.Column('skin_concerns', postgresql.JSONB(astext_type=sa.Text()), server_default='[]', nullable=False),
        sa.Column('allergies', postgresql.JSONB(astext_type=sa.Text()), server_default='[]', nullable=False),
        sa.Column('created_at', sa.DateTime(timezone=True), server_default=sa.text('now()'), nullable=False),
        sa.Column('updated_at', sa.DateTime(timezone=True), server_default=sa.text('now()'), nullable=False),
    )
    op.create_index(op.f('ix_profiles_email'), 'profiles', ['email'], unique=True)

    # 2. Tabel quiz_submissions
    op.create_table(
        'quiz_submissions',
        sa.Column('id', postgresql.UUID(as_uuid=True), primary_key=True),
        sa.Column('user_id', postgresql.UUID(as_uuid=True), sa.ForeignKey('profiles.id', ondelete='CASCADE'), nullable=False),
        sa.Column('answers', postgresql.JSONB(astext_type=sa.Text()), server_default='{}', nullable=False),
        sa.Column('lifestyle_score', sa.Integer(), nullable=True),
        sa.Column('submitted_at', sa.DateTime(timezone=True), server_default=sa.text('now()'), nullable=False),
    )
    op.create_index(op.f('ix_quiz_submissions_user_id'), 'quiz_submissions', ['user_id'], unique=False)

    # 3. Tabel scan_records
    op.create_table(
        'scan_records',
        sa.Column('id', sa.String(length=64), primary_key=True),
        sa.Column('user_id', postgresql.UUID(as_uuid=True), sa.ForeignKey('profiles.id', ondelete='SET NULL'), nullable=True),
        sa.Column('image_url', sa.String(length=1024), nullable=True),
        sa.Column('score', sa.Integer(), nullable=False),
        sa.Column('title', sa.String(length=255), nullable=False),
        sa.Column('skin_type', sa.String(length=50), nullable=False),
        sa.Column('oil', sa.Integer(), nullable=False),
        sa.Column('pores', sa.Integer(), nullable=False),
        sa.Column('acne', sa.Integer(), nullable=False),
        sa.Column('redness', sa.Integer(), nullable=False),
        sa.Column('visual_findings', postgresql.JSONB(astext_type=sa.Text()), server_default='[]', nullable=False),
        sa.Column('recommended_ingredients', postgresql.JSONB(astext_type=sa.Text()), server_default='[]', nullable=False),
        sa.Column('avoid_ingredients', postgresql.JSONB(astext_type=sa.Text()), server_default='[]', nullable=False),
        sa.Column('detection_counts', postgresql.JSONB(astext_type=sa.Text()), server_default='{}', nullable=False),
        sa.Column('segmentation_areas', postgresql.JSONB(astext_type=sa.Text()), server_default='{}', nullable=False),
        sa.Column('class_confidences', postgresql.JSONB(astext_type=sa.Text()), server_default='{}', nullable=False),
        sa.Column('model_version', sa.String(length=50), nullable=True),
        sa.Column('model_connected', sa.Boolean(), nullable=False),
        sa.Column('is_demo', sa.Boolean(), nullable=False),
        sa.Column('analyzed_at', sa.DateTime(timezone=True), server_default=sa.text('now()'), nullable=False),
    )
    op.create_index(op.f('ix_scan_records_user_id'), 'scan_records', ['user_id'], unique=False)

    # 4. Tabel skin_journeys
    op.create_table(
        'skin_journeys',
        sa.Column('id', postgresql.UUID(as_uuid=True), primary_key=True),
        sa.Column('user_id', postgresql.UUID(as_uuid=True), sa.ForeignKey('profiles.id', ondelete='CASCADE'), nullable=False),
        sa.Column('title', sa.String(length=255), nullable=False),
        sa.Column('target_concern', sa.String(length=100), nullable=False),
        sa.Column('status', sa.String(length=30), nullable=False),
        sa.Column('start_date', sa.Date(), nullable=False),
        sa.Column('end_date', sa.Date(), nullable=True),
        sa.Column('created_at', sa.DateTime(timezone=True), server_default=sa.text('now()'), nullable=False),
    )
    op.create_index(op.f('ix_skin_journeys_user_id'), 'skin_journeys', ['user_id'], unique=False)

    # 5. Tabel journey_checkins
    op.create_table(
        'journey_checkins',
        sa.Column('id', postgresql.UUID(as_uuid=True), primary_key=True),
        sa.Column('journey_id', postgresql.UUID(as_uuid=True), sa.ForeignKey('skin_journeys.id', ondelete='CASCADE'), nullable=False),
        sa.Column('checkin_date', sa.Date(), nullable=False),
        sa.Column('photo_url', sa.String(length=1024), nullable=True),
        sa.Column('notes', sa.Text(), nullable=True),
        sa.Column('condition_rating', sa.Integer(), nullable=True),
        sa.Column('created_at', sa.DateTime(timezone=True), server_default=sa.text('now()'), nullable=False),
    )
    op.create_index(op.f('ix_journey_checkins_journey_id'), 'journey_checkins', ['journey_id'], unique=False)

    # 6. Tabel ingredients
    op.create_table(
        'ingredients',
        sa.Column('id', postgresql.UUID(as_uuid=True), primary_key=True),
        sa.Column('name', sa.String(length=100), nullable=False),
        sa.Column('description', sa.Text(), nullable=True),
        sa.Column('good_for', postgresql.JSONB(astext_type=sa.Text()), server_default='[]', nullable=False),
        sa.Column('cautions', postgresql.JSONB(astext_type=sa.Text()), server_default='[]', nullable=False),
    )
    op.create_index(op.f('ix_ingredients_name'), 'ingredients', ['name'], unique=True)

    # 7. Tabel products
    op.create_table(
        'products',
        sa.Column('id', postgresql.UUID(as_uuid=True), primary_key=True),
        sa.Column('name', sa.String(length=255), nullable=False),
        sa.Column('brand', sa.String(length=100), nullable=False),
        sa.Column('category', sa.String(length=50), nullable=False),
        sa.Column('price', sa.Integer(), nullable=False),
        sa.Column('image_url', sa.String(length=1024), nullable=True),
        sa.Column('purchase_url', sa.String(length=1024), nullable=True),
        sa.Column('description', sa.Text(), nullable=True),
    )
    op.create_index(op.f('ix_products_brand'), 'products', ['brand'], unique=False)
    op.create_index(op.f('ix_products_category'), 'products', ['category'], unique=False)
    op.create_index(op.f('ix_products_name'), 'products', ['name'], unique=False)

    # 8. Tabel pivot product_ingredients
    op.create_table(
        'product_ingredients',
        sa.Column('product_id', postgresql.UUID(as_uuid=True), sa.ForeignKey('products.id', ondelete='CASCADE'), primary_key=True),
        sa.Column('ingredient_id', postgresql.UUID(as_uuid=True), sa.ForeignKey('ingredients.id', ondelete='CASCADE'), primary_key=True),
    )


def downgrade() -> None:
    op.drop_table('product_ingredients')
    op.drop_index(op.f('ix_products_name'), table_name='products')
    op.drop_index(op.f('ix_products_category'), table_name='products')
    op.drop_index(op.f('ix_products_brand'), table_name='products')
    op.drop_table('products')
    op.drop_index(op.f('ix_ingredients_name'), table_name='ingredients')
    op.drop_table('ingredients')
    op.drop_index(op.f('ix_journey_checkins_journey_id'), table_name='journey_checkins')
    op.drop_table('journey_checkins')
    op.drop_index(op.f('ix_skin_journeys_user_id'), table_name='skin_journeys')
    op.drop_table('skin_journeys')
    op.drop_index(op.f('ix_scan_records_user_id'), table_name='scan_records')
    op.drop_table('scan_records')
    op.drop_index(op.f('ix_quiz_submissions_user_id'), table_name='quiz_submissions')
    op.drop_table('quiz_submissions')
    op.drop_index(op.f('ix_profiles_email'), table_name='profiles')
    op.drop_table('profiles')
