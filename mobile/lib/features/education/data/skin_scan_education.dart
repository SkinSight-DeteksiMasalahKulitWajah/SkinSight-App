import 'package:flutter/material.dart';

import '../../../core/theme/skin_theme.dart';

/// Panduan edukasi singkat per temuan visual hasil scan.
/// Nilai: (ringkasan perawatan, catatan waktu/evaluasi).
///
/// Dipakai bersama oleh halaman hasil (`SkinResultPage`) sebagai ringkasan
/// dan halaman detail (`EducationResultScreen`) agar isi selalu konsisten.
const scanEducation = <String, (String, String)>{
  'Acne': (
    'Bersihkan wajah dengan lembut. Benzoyl peroxide, retinoid dan azelaic acid merupakan contoh bahan yang punya dasar bukti, tetapi pilihan bergantung pada toleransi dan kondisi kulit.',
    'Efek sebagian terapi mulai dinilai setelah 6–8 minggu; evaluasi sekitar 12 minggu.'
  ),
  'PIH': (
    'Prioritaskan perlindungan UV dan pencegahan peradangan baru. Azelaic acid termasuk bahan yang diteliti untuk hiperpigmentasi.',
    'Pemudaran noda dapat memerlukan berbulan-bulan; bukan prediksi waktu sembuh.'
  ),
  'Dark Circle': (
    'Lingkar gelap bisa berkaitan dengan pigmen, pembuluh darah atau struktur wajah. Jangan mencoba bahan aktif dekat mata tanpa mempertimbangkan risikonya.',
    'Tidak ada estimasi durasi pemulihan yang universal.'
  ),
  'Redness': (
    'Gunakan perawatan lembut, perhatikan pemicu iritasi dan gunakan perlindungan matahari yang sesuai.',
    'Kemerahan pada foto tidak otomatis berarti rosacea.'
  ),
  'Wrinkle': (
    'Perlindungan UV penting. Retinoid mempunyai penelitian pendukung, tetapi perlu memperhatikan iritasi serta batas keamanannya.',
    'Sebagian penelitian menilai perubahan setelah 3–6 bulan atau lebih.'
  ),
};

/// Label Bahasa Indonesia untuk nama kelas temuan.
const findingLabels = <String, String>{
  'Acne': 'Jerawat',
  'PIH': 'Noda (PIH)',
  'Dark Circle': 'Lingkar mata',
  'Redness': 'Kemerahan',
  'Wrinkle': 'Garis halus',
};

/// Label Bahasa Indonesia untuk jenis kulit.
const skinTypeLabels = <String, String>{
  'Dry': 'Kering',
  'Oily': 'Berminyak',
  'Normal': 'Normal',
  'Combination': 'Kombinasi',
};

IconData findingIcon(String name) => switch (name) {
      'Acne' => Icons.grain_rounded,
      'PIH' => Icons.blur_on_rounded,
      'Dark Circle' => Icons.remove_red_eye_outlined,
      'Redness' => Icons.brightness_5_outlined,
      _ => Icons.spa_outlined,
    };

// Warna temuan diredam agar selaras dengan palet sage.
Color findingColor(String name) => switch (name) {
      'Acne' => const Color(0xFFB8646B),
      'PIH' => const Color(0xFFA9803A),
      'Dark Circle' => const Color(0xFF7078A8),
      'Redness' => const Color(0xFFB0677E),
      _ => SkinTokens.aloe,
    };
