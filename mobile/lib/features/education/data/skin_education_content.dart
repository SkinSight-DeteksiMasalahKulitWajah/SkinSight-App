import 'package:flutter/material.dart';

/// Artikel edukasi bersama. Dipakai halaman Edukasi dan seksi "Untuk Kamu"
/// di Home sehingga isi keduanya selalu sama.
class SkinArticle {
  final String slug;
  final String topic;
  final String title;
  final String summary;
  final String body;
  final String readTime;
  final String source;
  final IconData icon;
  final List<Color> gradient;
  final List<String> keyPoints;

  const SkinArticle({
    required this.slug,
    required this.topic,
    required this.title,
    required this.summary,
    required this.body,
    required this.readTime,
    required this.source,
    required this.icon,
    required this.gradient,
    required this.keyPoints,
  });
}

/// Label topik dalam Bahasa Indonesia untuk chip filter.
const skinTopicLabels = <String, String>{
  'Semua': 'Semua',
  'Acne': 'Jerawat',
  'PIH': 'Noda',
  'Dark Circle': 'Area mata',
  'Redness': 'Kemerahan',
  'Wrinkle': 'Garis halus',
};

/// Artikel yang disimpan pengguna (ikon hati). Hanya di memori.
final skinSavedArticles = ValueNotifier<Set<String>>(<String>{});

void toggleSavedArticle(String slug) {
  final next = {...skinSavedArticles.value};
  if (!next.remove(slug)) next.add(slug);
  skinSavedArticles.value = next;
}

const skinFeaturedArticle = SkinArticle(
  slug: 'sunscreen-setiap-hari',
  topic: 'PIH',
  title: 'Sunscreen dan noda gelap: hubungan yang perlu kamu tahu',
  summary:
      'Perlindungan UV membantu mencegah noda tampak makin gelap dan mendukung perawatan yang konsisten.',
  body:
      'Paparan sinar matahari dapat membuat hiperpigmentasi pascainflamasi tampak lebih gelap. Karena itu, perlindungan UV menjadi bagian penting dari rutinitas harian. Pilih sunscreen yang nyaman digunakan, aplikasikan dengan merata saat akan terpapar matahari, dan padukan dengan kebiasaan mencari teduh atau memakai pelindung fisik bila diperlukan.',
  readTime: '4 menit',
  source: 'American Academy of Dermatology (AAD)',
  icon: Icons.wb_sunny_outlined,
  gradient: [Color(0xFFDCEBE4), Color(0xFFF4EEDF)],
  keyPoints: [
    'Konsistensi penggunaan lebih penting daripada mengejar rutinitas yang terlalu rumit.',
    'Noda tidak memiliki satu waktu pudar yang sama untuk semua orang.',
    'Jika produk menimbulkan perih atau iritasi, catat reaksinya dan evaluasi penggunaannya.',
  ],
);

const skinArticles = <SkinArticle>[
  skinFeaturedArticle,
  SkinArticle(
    slug: 'jerawat-tidak-hilang-semalam',
    topic: 'Acne',
    title: 'Mengapa jerawat tidak hilang dalam semalam?',
    summary:
        'Perawatan membutuhkan waktu, sementara memencet lesi dapat menambah risiko iritasi dan bekas.',
    body:
        'Jerawat terbentuk melalui proses yang tidak berhenti hanya dalam satu malam. Perubahan yang terlihat dari hari ke hari juga dapat dipengaruhi cahaya, sudut foto, dan kondisi kulit saat itu. Gunakan rutinitas yang lembut, hindari memencet lesi, dan nilai perubahan secara berkala dengan foto yang konsisten.',
    readTime: '3 menit',
    source: 'AAD dan NICE Acne Guideline NG198',
    icon: Icons.bubble_chart_outlined,
    gradient: [Color(0xFFF3E3DD), Color(0xFFF6F0EC)],
    keyPoints: [
      'Jangan menyimpulkan keberhasilan atau kegagalan dari satu hari atau satu foto.',
      'Jerawat yang dalam, sangat nyeri, atau berisiko meninggalkan parut perlu perhatian profesional.',
      'Tambahkan produk baru secara bertahap agar respons kulit lebih mudah diamati.',
    ],
  ),
  SkinArticle(
    slug: 'foto-dark-circle-konsisten',
    topic: 'Dark Circle',
    title: 'Cahaya foto bisa mengubah tampilan area bawah mata',
    summary:
        'Bayangan, posisi wajah, dan pencahayaan perlu serupa sebelum dua foto dibandingkan.',
    body:
        'Tampilan lingkaran gelap dapat dipengaruhi pigmentasi, pembuluh darah, struktur wajah, atau gabungan beberapa faktor. Foto saja tidak dapat menentukan penyebabnya. Untuk dokumentasi, gunakan cahaya dari depan, ekspresi netral, dan jarak kamera yang sama.',
    readTime: '4 menit',
    source: 'Periorbital Hyperpigmentation Comprehensive Review',
    icon: Icons.remove_red_eye_outlined,
    gradient: [Color(0xFFE3E4EF), Color(0xFFF0F1F5)],
    keyPoints: [
      'Bayangan yang berbeda dapat terlihat seperti perubahan kondisi.',
      'Hindari memilih bahan aktif dekat mata hanya berdasarkan satu foto.',
      'Catat juga keluhan yang kamu rasakan, bukan hanya tampilan visual.',
    ],
  ),
  SkinArticle(
    slug: 'redness-dan-iritasi',
    topic: 'Redness',
    title: 'Saat kemerahan disertai rasa perih atau panas',
    summary:
        'Keluhan yang dirasakan sama pentingnya dengan area kemerahan yang terlihat pada foto.',
    body:
        'Kemerahan tidak selalu memiliki penyebab yang sama. Jika muncul setelah produk baru, hentikan eksperimen tambahan dan catat waktu serta produk yang digunakan. Perawatan lembut, pelembap yang nyaman, dan perlindungan UV dapat membantu menjaga skin barrier tanpa mengklaim diagnosis tertentu.',
    readTime: '3 menit',
    source: 'American Academy of Dermatology (AAD)',
    icon: Icons.health_and_safety_outlined,
    gradient: [Color(0xFFF2E1DF), Color(0xFFF7EFEC)],
    keyPoints: [
      'Perih, panas, bengkak, atau perubahan cepat tidak boleh diabaikan.',
      'Jangan menambah banyak bahan aktif saat kulit sedang teriritasi.',
      'Pertimbangkan bantuan profesional untuk keluhan sedang hingga berat.',
    ],
  ),
  SkinArticle(
    slug: 'wrinkle-pose-netral',
    topic: 'Wrinkle',
    title: 'Mengamati garis halus tanpa terkecoh ekspresi',
    summary:
        'Pose netral dan perlindungan UV membuat dokumentasi garis halus lebih bermakna.',
    body:
        'Ekspresi wajah dapat mengubah garis yang terlihat pada foto. Bila ingin memantau perubahan, gunakan pose netral, pencahayaan, jarak, dan area wajah yang serupa. Hasil foto merupakan observasi teknis, bukan ukuran kedalaman kerutan secara klinis.',
    readTime: '4 menit',
    source: 'Systematic Review Tretinoin for Photoaging dan WSRS',
    icon: Icons.face_retouching_natural_outlined,
    gradient: [Color(0xFFDDEBE5), Color(0xFFEEF3E6)],
    keyPoints: [
      'Bandingkan foto hanya saat pose dan ekspresi benar-benar serupa.',
      'Perlindungan UV relevan untuk perawatan kulit jangka panjang.',
      'Riset perawatan berlangsung berbulan-bulan dan bukan janji hasil individual.',
    ],
  ),
  SkinArticle(
    slug: 'rutinitas-lembut',
    topic: 'Acne',
    title: 'Rutinitas sederhana yang lebih mudah dipertahankan',
    summary:
        'Pembersih lembut, pelembap, dan perlindungan matahari adalah fondasi yang realistis.',
    body:
        'Rutinitas yang konsisten tidak harus panjang. Mulailah dari langkah dasar yang terasa nyaman, lalu ubah satu hal dalam satu waktu. Cara ini membantu kamu mengenali produk yang bekerja baik dan produk yang mungkin memicu iritasi.',
    readTime: '3 menit',
    source: 'AAD dan NICE Acne Guideline NG198',
    icon: Icons.spa_outlined,
    gradient: [Color(0xFFD9EAE3), Color(0xFFEDF5EF)],
    keyPoints: [
      'Mulai dari langkah dasar sebelum menambah banyak produk.',
      'Perubahan bertahap membuat respons kulit lebih mudah ditelusuri.',
      'Ikuti arahan dokter bila kamu sedang berada dalam perawatan profesional.',
    ],
  ),
];
