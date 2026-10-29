# Setup Login Google (Skinsight)

Tombol "Masuk dengan Google" memakai OAuth Supabase dengan deep link
`io.supabase.skinsight://login-callback/`. Konfigurasi sisi aplikasi sudah
selesai; langkah dashboard di bawah cukup dilakukan sekali oleh pemilik
project Supabase & Google Cloud.

## Sudah beres di repo
- `lib/data/auth_service.dart` — `signInWithGoogle()` mengirim `redirectTo`
  deep link, menunggu sesi terbentuk dari callback (bukan langsung pindah
  layar), dan memberi pesan jelas jika dibatalkan / tidak ada respons.
- `android/app/src/main/AndroidManifest.xml` — intent-filter `VIEW` untuk
  `io.supabase.skinsight://login-callback` (wajib agar Android membuka
  kembali aplikasi setelah login di browser).
- `ios/Runner/Info.plist` — URL scheme `io.supabase.skinsight` untuk build iOS.
- `lib/pages/skin_login_page.dart` — tombol Google menampilkan status
  "Menghubungkan ke Google..." selama menunggu.

## Langkah sekali saja (dashboard)
1. **Google Cloud Console** → APIs & Services → Credentials → Create
   credentials → OAuth client ID → tipe **Web application**:
   - Authorized JavaScript origins: `https://<PROJECT_REF>.supabase.co`
   - Authorized redirect URI: `https://<PROJECT_REF>.supabase.co/auth/v1/callback`
   - Simpan **Client ID** dan **Client Secret**.
2. **Supabase Dashboard** → Authentication → Sign In / Providers → **Google**:
   aktifkan dan tempel Client ID & Client Secret dari langkah 1.
3. **Supabase Dashboard** → Authentication → URL Configuration → tambahkan ke
   **Redirect URLs** persis (termasuk garis miring di akhir):
   `io.supabase.skinsight://login-callback/`

## Menjalankan dengan backend asli
```bash
flutter run --dart-define=SUPABASE_URL=https://<PROJECT_REF>.supabase.co --dart-define=SUPABASE_ANON_KEY=<publishable/anon key>
```

Tanpa `--dart-define`, aplikasi otomatis memakai `FakeAuthService` (mode
demo): tombol Google langsung pindah ke Home tanpa OAuth sungguhan.

## Uji manual di HP/emulator
1. Jalankan perintah di atas.
2. Login → "Masuk dengan Google" → pilih akun → browser kembali ke aplikasi.
3. Berhasil: aplikasi pindah ke Home tanpa snackbar error.
4. Dibatalkan (kembali dari browser): muncul snackbar
   "Masuk dengan Google dibatalkan."

## Catatan
- Halaman Profil belum menampilkan data akun Google yang sedang login (masih
  data dummy) — kandidat pengerjaan berikutnya.
- Jika muncul "Provider Google belum aktif di dashboard Supabase", ulangi
  langkah 2.
