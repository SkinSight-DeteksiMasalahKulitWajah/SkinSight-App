-- Jalankan di Supabase SQL Editor: bucket privat foto scan + policy per-user.
-- (Trigger on_auth_user_created -> profiles sudah ada di project ini, jadi tidak diulang di sini.)

-- Bucket privat untuk foto scan (file disimpan di <user_id>/<nama-file>)
INSERT INTO storage.buckets (id, name, public)
VALUES ('skin-scans', 'skin-scans', false)
ON CONFLICT (id) DO NOTHING;

DROP POLICY IF EXISTS "skin_scans_select_own" ON storage.objects;
DROP POLICY IF EXISTS "skin_scans_insert_own" ON storage.objects;
DROP POLICY IF EXISTS "skin_scans_update_own" ON storage.objects;
DROP POLICY IF EXISTS "skin_scans_delete_own" ON storage.objects;

CREATE POLICY "skin_scans_select_own" ON storage.objects FOR SELECT TO authenticated
  USING (bucket_id = 'skin-scans' AND (storage.foldername(name))[1] = auth.uid()::text);
CREATE POLICY "skin_scans_insert_own" ON storage.objects FOR INSERT TO authenticated
  WITH CHECK (bucket_id = 'skin-scans' AND (storage.foldername(name))[1] = auth.uid()::text);
CREATE POLICY "skin_scans_update_own" ON storage.objects FOR UPDATE TO authenticated
  USING (bucket_id = 'skin-scans' AND (storage.foldername(name))[1] = auth.uid()::text);
CREATE POLICY "skin_scans_delete_own" ON storage.objects FOR DELETE TO authenticated
  USING (bucket_id = 'skin-scans' AND (storage.foldername(name))[1] = auth.uid()::text);
