-- Initial Schema for SkinSight Backend Database (PostgreSQL / Supabase)
-- Dapat dijalankan langsung di Supabase SQL Editor jika tidak memakai CLI Alembic

-- 1. Profiles (Sinkron dengan auth.users)
CREATE TABLE IF NOT EXISTS public.profiles (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    email VARCHAR(255) UNIQUE NOT NULL,
    full_name VARCHAR(255),
    gender VARCHAR(20),
    birth_date DATE,
    dominant_skin_type VARCHAR(50),
    skin_concerns JSONB NOT NULL DEFAULT '[]'::jsonb,
    allergies JSONB NOT NULL DEFAULT '[]'::jsonb,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS ix_profiles_email ON public.profiles(email);

-- 2. Quiz Submissions (Gaya Hidup & Kuis Awal)
CREATE TABLE IF NOT EXISTS public.quiz_submissions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    answers JSONB NOT NULL DEFAULT '{}'::jsonb,
    lifestyle_score INTEGER,
    submitted_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS ix_quiz_submissions_user_id ON public.quiz_submissions(user_id);

-- 3. Scan Records (Riwayat Deteksi ML Kulit Wajah)
CREATE TABLE IF NOT EXISTS public.scan_records (
    id VARCHAR(64) PRIMARY KEY,
    user_id UUID REFERENCES public.profiles(id) ON DELETE SET NULL,
    image_url VARCHAR(1024),
    score INTEGER NOT NULL DEFAULT 0,
    title VARCHAR(255) NOT NULL,
    skin_type VARCHAR(50) NOT NULL,
    oil INTEGER NOT NULL DEFAULT 0,
    pores INTEGER NOT NULL DEFAULT 0,
    acne INTEGER NOT NULL DEFAULT 0,
    redness INTEGER NOT NULL DEFAULT 0,
    visual_findings JSONB NOT NULL DEFAULT '[]'::jsonb,
    recommended_ingredients JSONB NOT NULL DEFAULT '[]'::jsonb,
    avoid_ingredients JSONB NOT NULL DEFAULT '[]'::jsonb,
    detection_counts JSONB NOT NULL DEFAULT '{}'::jsonb,
    segmentation_areas JSONB NOT NULL DEFAULT '{}'::jsonb,
    class_confidences JSONB NOT NULL DEFAULT '{}'::jsonb,
    model_version VARCHAR(50) DEFAULT 'v1.0.0',
    model_connected BOOLEAN NOT NULL DEFAULT true,
    is_demo BOOLEAN NOT NULL DEFAULT false,
    analyzed_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS ix_scan_records_user_id ON public.scan_records(user_id);

-- 4. Skin Journeys (Pelacakan Perjalanan Skincare)
CREATE TABLE IF NOT EXISTS public.skin_journeys (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    title VARCHAR(255) NOT NULL,
    target_concern VARCHAR(100) NOT NULL,
    status VARCHAR(30) NOT NULL DEFAULT 'active',
    start_date DATE NOT NULL DEFAULT CURRENT_DATE,
    end_date DATE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS ix_skin_journeys_user_id ON public.skin_journeys(user_id);

-- 5. Journey Checkins (Foto & Catatan Harian/Mingguan)
CREATE TABLE IF NOT EXISTS public.journey_checkins (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    journey_id UUID NOT NULL REFERENCES public.skin_journeys(id) ON DELETE CASCADE,
    checkin_date DATE NOT NULL DEFAULT CURRENT_DATE,
    photo_url VARCHAR(1024),
    notes TEXT,
    condition_rating INTEGER,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS ix_journey_checkins_journey_id ON public.journey_checkins(journey_id);

-- 6. Ingredients (Master Data Bahan Aktif)
CREATE TABLE IF NOT EXISTS public.ingredients (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name VARCHAR(100) UNIQUE NOT NULL,
    description TEXT,
    good_for JSONB NOT NULL DEFAULT '[]'::jsonb,
    cautions JSONB NOT NULL DEFAULT '[]'::jsonb
);
CREATE INDEX IF NOT EXISTS ix_ingredients_name ON public.ingredients(name);

-- 7. Products (Katalog Produk Skincare dengan Filter Harga)
CREATE TABLE IF NOT EXISTS public.products (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name VARCHAR(255) NOT NULL,
    brand VARCHAR(100) NOT NULL,
    category VARCHAR(50) NOT NULL,
    price INTEGER NOT NULL,
    image_url VARCHAR(1024),
    purchase_url VARCHAR(1024),
    description TEXT
);
CREATE INDEX IF NOT EXISTS ix_products_brand ON public.products(brand);
CREATE INDEX IF NOT EXISTS ix_products_category ON public.products(category);
CREATE INDEX IF NOT EXISTS ix_products_name ON public.products(name);

-- 8. Product Ingredients (Many-to-Many Pivot Table)
CREATE TABLE IF NOT EXISTS public.product_ingredients (
    product_id UUID NOT NULL REFERENCES public.products(id) ON DELETE CASCADE,
    ingredient_id UUID NOT NULL REFERENCES public.ingredients(id) ON DELETE CASCADE,
    PRIMARY KEY (product_id, ingredient_id)
);
