/// Edukasi per temuan scan, diringkas dari artikel Halodoc (halodoc.com).
/// Setiap entri menautkan artikel aslinya; isi ringkas, bukan salinan utuh.
class HalodocEducation {
  const HalodocEducation({
    required this.title,
    required this.summary,
    required this.sections,
    required this.articleTitle,
    required this.url,
    required this.reviewedBy,
  });

  final String title;
  final String summary;
  final List<HalodocSection> sections;
  final String articleTitle;
  final String url;
  final String reviewedBy;
}

class HalodocSection {
  const HalodocSection(this.heading, this.points);

  final String heading;
  final List<String> points;
}

/// Kunci sama dengan nama kelas deteksi (`SkinJourneyStore.visualClasses`).
const halodocEducation = <String, HalodocEducation>{
  'Acne': HalodocEducation(
    title: 'Edukasi Jerawat',
    summary:
        'Jerawat terjadi saat folikel rambut tersumbat oleh sebum dan sel kulit mati, lalu meradang. Paling sering muncul di wajah, leher, dada bagian atas, dan punggung.',
    sections: [
      HalodocSection('Penyebab', [
        'Produksi minyak (sebum) berlebih.',
        'Pori tersumbat oleh sel kulit mati dan sebum.',
        'Bakteri Propionibacterium acnes yang memicu peradangan.',
        'Perubahan hormon, misalnya menjelang menstruasi atau saat pubertas.',
        'Kosmetik yang tidak cocok, stres, dan faktor keturunan.',
      ]),
      HalodocSection('Cara merawat', [
        'Bersihkan wajah dua kali sehari.',
        'Pilih kosmetik dan pelembap non-comedogenic (tidak menyumbat pori).',
        'Jangan memencet atau sering memegang jerawat.',
        'Bersihkan peralatan kosmetik secara rutin.',
        'Jangan menggosok wajah dengan kain kasar, dan segera mandi setelah berkeringat.',
        'Obat seperti asam salisilat, sulfur, antibiotik, atau isotretinoin sebaiknya dipakai dengan arahan dokter. Isotretinoin tidak boleh dipakai saat hamil.',
      ]),
      HalodocSection('Pencegahan', [
        'Gunakan pembersih yang lembut dan bebas pewangi.',
        'Batasi riasan wajah saat sedang berjerawat.',
        'Hindari menyentuh wajah dengan tangan kotor.',
        'Cukupi minum air putih dan perbanyak buah serta sayur.',
      ]),
      HalodocSection('Kapan ke dokter', [
        'Jerawat tidak kunjung hilang, makin parah, atau sangat mengganggu.',
      ]),
    ],
    articleTitle: 'Jerawat: Gejala, Penyebab & Pengobatan',
    url: 'https://www.halodoc.com/kesehatan/jerawat',
    reviewedBy: 'Ditinjau oleh dr. Erlian Dimas SpDVE',
  ),
  'PIH': HalodocEducation(
    title: 'Edukasi Noda Bekas Jerawat (PIH)',
    summary:
        'Hiperpigmentasi pasca inflamasi (PIH) adalah noda cokelat hingga kehitaman yang tertinggal setelah jerawat atau luka sembuh. Noda ini bukan bekas luka, melainkan melanin berlebih akibat peradangan.',
    sections: [
      HalodocSection('Penyebab', [
        'Jerawat yang meradang (penyebab paling umum).',
        'Eksim atau dermatitis.',
        'Luka, gesekan, atau prosedur kosmetik yang terlalu agresif.',
        'Paparan sinar matahari memperparah dan memperlama noda.',
      ]),
      HalodocSection('Cara merawat', [
        'Pakai tabir surya broad-spectrum SPF minimal 30 setiap hari, termasuk di dalam ruangan.',
        'Bahan pencerah yang umum dipakai: vitamin C, niacinamide, dan asam kojat.',
        'Eksfoliasi kimia ringan dengan AHA, seperti asam glikolat atau asam laktat.',
        'Hidrokuinon dan retinoid yang lebih kuat sebaiknya dengan pengawasan dokter.',
      ]),
      HalodocSection('Yang perlu dihindari', [
        'Memencet atau memegang jerawat yang meradang.',
        'Beraktivitas di luar tanpa tabir surya.',
        'Produk yang terlalu keras sehingga memicu iritasi baru.',
      ]),
      HalodocSection('Kapan ke dokter', [
        'Noda tidak memudar setelah berbulan-bulan perawatan mandiri.',
        'Noda terasa gatal atau berubah bentuk.',
        'PIH bisa memudar sendiri, tetapi dapat memakan waktu 3 hingga 24 bulan.',
      ]),
    ],
    articleTitle: 'Bekas Jerawat Hitam? Atasi Hiperpigmentasi Pasca Inflamasi',
    url:
        'https://www.halodoc.com/artikel/bekas-jerawat-hitam-atasi-hiperpigmentasi-pasca-inflamasi',
    reviewedBy: 'Ditinjau oleh Redaksi Halodoc',
  ),
  'Dark Circle': HalodocEducation(
    title: 'Edukasi Mata Panda',
    summary:
        'Mata panda adalah lingkaran gelap di bawah mata yang membuat wajah tampak lelah. Kondisi ini umum dan bisa dialami siapa saja.',
    sections: [
      HalodocSection('Penyebab', [
        'Kurang tidur atau kualitas tidur buruk.',
        'Bertambahnya usia, sehingga kulit di sekitar mata menipis.',
        'Dehidrasi dan alergi di sekitar mata.',
        'Paparan sinar matahari yang menambah pigmen.',
        'Faktor keturunan.',
      ]),
      HalodocSection('Cara merawat', [
        'Kompres dingin, misalnya es batu yang dibungkus kain bersih.',
        'Tidur 7–8 jam dengan bantal sedikit lebih tinggi.',
        'Kompres kantong teh yang sudah didinginkan selama 10–20 menit.',
        'Batasi alkohol dan kafein sebelum tidur, serta cukupi minum air putih.',
        'Krim mata dengan vitamin K, E, atau C; hasilnya baru terlihat setelah beberapa minggu.',
        'Pijat lembut area mata dan lindungi dari matahari dengan tabir surya serta kacamata hitam.',
      ]),
      HalodocSection('Kapan ke dokter', [
        'Lingkaran gelap muncul tiba-tiba atau makin parah.',
        'Disertai gatal, kemerahan, atau bengkak.',
        'Tidak membaik meski sudah mencoba berbagai cara.',
      ]),
    ],
    articleTitle: 'Cara Menghilangkan Mata Panda untuk Tampil Lebih Segar',
    url:
        'https://www.halodoc.com/artikel/7-cara-menghilangkan-mata-panda-untuk-tampil-lebih-segar',
    reviewedBy: 'Ditinjau oleh dr. Erlian Dimas SpDVE',
  ),
  'Redness': HalodocEducation(
    title: 'Edukasi Kemerahan',
    summary:
        'Kemerahan di wajah bisa berasal dari iritasi, peradangan, atau rosacea. Rosacea membuat hidung, pipi, dagu, dan dahi memerah, kadang disertai bintil dan pembuluh darah yang tampak. Kemerahan pada foto tidak otomatis berarti rosacea.',
    sections: [
      HalodocSection('Penyebab rosacea', [
        'Diduga terkait faktor keturunan, gangguan sistem imun, serta tungau atau bakteri.',
        'Cuaca panas dan makanan tertentu dapat memperburuk kemerahan.',
        'Umumnya dialami orang berusia di atas 30 tahun.',
      ]),
      HalodocSection('Cara merawat', [
        'Bersihkan wajah dengan lembut setiap hari, tanpa menggosok.',
        'Pakai tabir surya, sebaiknya yang mengandung seng oksida atau titanium dioksida.',
        'Kompres dengan handuk yang dibasahi air dingin untuk meredakan kemerahan.',
        'Kurangi makanan olahan dan gula; perbanyak sayur hijau, ikan, dan buah beri.',
        'Rosacea tidak bisa disembuhkan permanen, tetapi bisa dikendalikan.',
      ]),
      HalodocSection('Kapan ke dokter', [
        'Kemerahan terasa perih, panas, bengkak, atau terus kambuh. Konsultasikan ke dokter kulit untuk memastikan penyebabnya.',
      ]),
    ],
    articleTitle: 'Ketahui Jenis dan Cara Mengatasi Rosacea',
    url:
        'https://www.halodoc.com/artikel/ketahui-jenis-dan-cara-mengatasi-rosacea',
    reviewedBy: 'Ditinjau oleh Redaksi Halodoc',
  ),
  'Wrinkle': HalodocEducation(
    title: 'Edukasi Keriput & Garis Halus',
    summary:
        'Keriput adalah bagian dari penuaan kulit, gabungan proses alami dan faktor dari luar. Paling sering muncul di area yang terpapar matahari seperti wajah dan leher.',
    sections: [
      HalodocSection('Penyebab', [
        'Penuaan alami: kolagen dan elastisitas kulit menurun.',
        'Sinar UV yang merusak kolagen dan elastin.',
        'Merokok, alkohol berlebih, dan kurang tidur.',
        'Polusi udara dan ekspresi wajah berulang, seperti mengerutkan dahi.',
      ]),
      HalodocSection('Cara merawat', [
        'Retinoid oles dapat mengurangi kerutan halus; hasil butuh berminggu-minggu dan wajib dibarengi tabir surya.',
        'Krim dengan retinol, antioksidan, atau peptida.',
        'Produk dengan AHA untuk mengangkat sel kulit mati.',
        'Prosedur seperti laser, chemical peel, filler, atau botox dilakukan oleh dokter.',
      ]),
      HalodocSection('Pencegahan', [
        'Jaga kulit tetap bersih dan pakai pelembap sesuai jenis kulit.',
        'Lindungi kulit dari sinar matahari dengan tabir surya.',
        'Makan bergizi seimbang dan tidur cukup.',
      ]),
      HalodocSection('Kapan ke dokter', [
        'Kerutan mengganggu dan ingin ditangani dengan perawatan dokter kulit.',
      ]),
    ],
    articleTitle: 'Keriput: Gejala, Penyebab, dan Perawatan',
    url: 'https://www.halodoc.com/kesehatan/keriput',
    reviewedBy: 'Ditinjau oleh dr. Erlian Dimas SpDVE',
  ),
};
