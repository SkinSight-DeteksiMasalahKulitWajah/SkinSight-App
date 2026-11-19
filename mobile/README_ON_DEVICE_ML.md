# SkinSight — Flutter On-device ML Integration

SkinSight menggunakan model on-device LiteRT (TensorFlow Lite) terpadu berbasis YOLO11 Object Detection yang langsung memproses citra wajah pengguna secara lokal di perangkat tanpa koneksi server backend.

## Alur Scan On-Device

1. Flutter membaca foto dari kamera atau galeri.
2. Foto dinormalisasi ke orientasi tegak (EXIF), lalu Google ML Kit Face Detection mencari wajah.
3. Jika beberapa wajah ditemukan, aplikasi memilih bounding box wajah yang paling besar.
4. Aplikasi memotong Face ROI dengan padding konteks 12%, mengikuti rasio deteksi wajah. Foto full-frame tidak diberikan langsung ke model.
5. ROI di-letterbox ke 640 x 640 dan dinormalisasi sebagai input FP32 NCHW `[1, 3, 640, 640]`.
6. Model tunggal LiteRT dijalankan:
   - `all_conditions_detect_float32.tflite` (output tensor `[1, 9, 8400]`): mendeteksi seluruh 5 kondisi wajah (Acne, PIH, DarkCircle, Skin-Redness, Wrinkles) secara simultan dengan single inference pass.
   - Menggantikan sequential 3 model sebelumnya, menghemat memori RAM dan mempercepat waktu inferensi ~3x.
7. Post-processing non-maximum suppression (NMS) menghasilkan:
   - `detectionCounts`: jumlah titik terdeteksi per kondisi (`Acne`, `PIH`, `Dark Circle`, `Redness`, `Wrinkle`).
   - `classConfidences`: tingkat keyakinan model.
   - `visualBoxes`: bounding box dan lingkaran penanda pada overlay visual kamera/hasil.
8. Seluruh metrik timeline, progress journey, dan riwayat analisis telah dimigrasikan dari logika luas mask (`segmentationAreas`) menjadi jumlah titik deteksi (`detectionCounts`).

Jika wajah tidak terdeteksi atau terlalu kecil, scan dihentikan dengan pesan panduan yang jelas. Aplikasi tidak membuat temuan visual dummy sebagai fallback.

## Model Assets

- `assets/ml_models/all_conditions_detect_float32.tflite`: Model deteksi terpadu YOLO11 float32 (10.6 MB, input `[1, 3, 640, 640]`, output `[1, 9, 8400]`).
- `assets/ml_models/acne_pih_darkcircle_float32.tflite`: Checkpoint terdahulu (fallback).
- `assets/ml_models/redness_float32.tflite`: Checkpoint terdahulu (fallback).
- `assets/ml_models/wrinkle_float32.tflite`: Checkpoint terdahulu (fallback).
- `assets/ml_models/conversion_manifest.json`: Manifest konversi dan verifikasi integritas model.
