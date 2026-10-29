import 'package:flutter/material.dart';

import'../../../core/app_assets.dart';
import'../../../core/theme/skin_theme.dart';
import'../../../shared/widgets/navigation/skin_bottom_nav.dart';
import'../../../shared/widgets/skin_page_background.dart';
import'../../../shared/widgets/skin_3d.dart';
import'../../../shared/widgets/design_system/skin_ui.dart';

class SkinAboutPage extends StatelessWidget {
  const SkinAboutPage({super.key, this.embedded = false});

  final bool embedded;

  @override
  Widget build(BuildContext context) {
    final content = Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: SkinTokens.maxWidth),
        child: SingleChildScrollView(
          key: const Key('about-page-scroll'),
          physics: const ClampingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 38),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _AboutBrandBar(showBack: !embedded),
              const SizedBox(height: 16),
              const _AboutLegalNav(),
              const SizedBox(height: 18),
              const SkinReveal(child: _AboutHero()),
              const SizedBox(height: 28),
              const Text(
                'TENTANG KAMI',
                key: Key('about-page-title'),
                style: SkinTokens.eyebrow,
              ),
              const SizedBox(height: 9),
              const Text(
                'Membantu mencatat, bukan mendiagnosis.',
                style: TextStyle(
                  color: SkinTokens.ink,
                  fontSize: 28,
                  height: 1.14,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -.7,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'SkinSight adalah aplikasi pemantauan mandiri yang menggabungkan foto, jawaban kuis, check-in, dan materi edukasi. Informasi yang ditampilkan membantu pengguna meninjau catatan dari waktu ke waktu, bukan memastikan kondisi medis.',
                style: TextStyle(
                  color: SkinTokens.muted,
                  fontSize: 15,
                  height: 1.6,
                ),
              ),
              const SizedBox(height: 26),
              const _PurposeSection(),
              const SizedBox(height: 28),
              const SkinSectionTitle(
                title: 'Prinsip kami',
                subtitle: 'Cara SkinSight menyajikan informasi kepadamu.',
              ),
              const SizedBox(height: 14),
              const _Principles(),
              const SizedBox(height: 28),
              const _TeamSection(),
              const SizedBox(height: 24),
              const SkinNotice(
                tone: SkinTone.warning,
                icon: Icons.medical_information_outlined,
                title: 'Catatan medis',
                message:
                    'Fitur analisis SkinSight masih berupa prototipe dan belum divalidasi sebagai alat medis. Keluhan yang menetap, memburuk, nyeri, atau mengkhawatirkan perlu diperiksa oleh tenaga kesehatan.',
              ),
              const SizedBox(height: 22),
              const Center(
                child: Text(
                  'SkinSight · Prototipe versi 1.1.0',
                  style: TextStyle(
                    color: SkinTokens.primary,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );

    if (embedded) {
      return SkinPageBackground(child: content);
    }

    return Scaffold(
      backgroundColor: SkinTokens.background,
      body: SkinPageBackground(
        child: SafeArea(bottom: false, child: content),
      ),
      bottomNavigationBar: const SkinBottomNav(currentIndex: -1),
    );
  }
}

class _AboutLegalNav extends StatelessWidget {
  const _AboutLegalNav();

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        const _AboutBubble(
          label: 'Profil Kami',
          icon: Icons.favorite_outline_rounded,
          selected: true,
        ),
        _AboutBubble(
          key: const Key('about-open-privacy'),
          label: 'Kebijakan Privasi',
          icon: Icons.privacy_tip_outlined,
          onTap: () => Navigator.of(context).pushNamed('/privacy'),
        ),
        _AboutBubble(
          key: const Key('about-open-terms'),
          label: 'Syarat & Ketentuan',
          icon: Icons.gavel_rounded,
          onTap: () => Navigator.of(context).pushNamed('/terms'),
        ),
      ],
    );
  }
}

class _AboutBubble extends StatelessWidget {
  const _AboutBubble({
    super.key,
    required this.label,
    required this.icon,
    this.selected = false,
    this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final foreground = selected ? Colors.white : SkinTokens.primaryDark;
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: selected ? SkinTokens.brandGradient : null,
        color: selected ? null : Colors.white,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: selected ? Colors.transparent : SkinTokens.border,
        ),
      ),
      child: Material(
        type: MaterialType.transparency,
        shape: const StadiumBorder(),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(11, 8, 14, 8),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 15, color: foreground),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: foreground,
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AboutBrandBar extends StatelessWidget {
  final bool showBack;
  const _AboutBrandBar({required this.showBack});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) => Row(
        children: [
          if (showBack) ...[
            SkinCircleButton(
              key: const Key('about-back'),
              tooltip: 'Kembali',
              icon: Icons.arrow_back_rounded,
              iconColor: SkinTokens.primaryDark,
              onPressed: () => Navigator.of(context).maybePop(),
            ),
            const SizedBox(width: 12),
          ],
          const SkinBrandMark(size: 34),
          const SizedBox(width: 9),
          const Expanded(
            child: Align(
              alignment: Alignment.centerLeft,
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: SkinWordmark(fontSize: 20),
              ),
            ),
          ),
          if (constraints.maxWidth >= 350)
            const SkinPill(label: 'Tentang produk', tone: SkinTone.neutral),
        ],
      ),
    );
  }
}

class _AboutHero extends StatelessWidget {
  const _AboutHero();

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 340;
        final height = compact ? 210.0 : 240.0;
        return Container(
          key: const Key('about-hero'),
          height: height,
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(SkinTokens.radiusXl),
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFFDCEAE5), Color(0xFFBFD8D2)],
            ),
            boxShadow: SkinTokens.shadows,
          ),
          child: Stack(
            children: [
              Positioned(
                left: -34,
                top: -42,
                child: Container(
                  width: 150,
                  height: 150,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: .5),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
              Positioned(
                right: -18,
                bottom: -54,
                child: Container(
                  width: 190,
                  height: 190,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF6EAE3).withValues(alpha: .85),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
              Positioned(
                right: compact ? -16 : 6,
                bottom: -2,
                width: compact ? 180 : 210,
                height: compact ? 185 : 222,
                child: const Skin3D(
                  AppAssets.serum3d,
                  alignment: Alignment.bottomCenter,
                  float: true,
                ),
              ),
              Positioned(
                left: 20,
                top: 22,
                width: compact ? 132 : 162,
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Amati. Catat.\nPahami perubahannya.',
                      style: TextStyle(
                        color: SkinTokens.ink,
                        fontSize: 20,
                        height: 1.18,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -.4,
                      ),
                    ),
                    SizedBox(height: 12),
                    SizedBox(
                      width: 36,
                      child: Divider(
                        thickness: 3.5,
                        color: SkinTokens.primary,
                      ),
                    ),
                  ],
                ),
              ),
              Positioned(
                left: 18,
                bottom: 18,
                child: Container(
                  width: compact ? 52 : 60,
                  height: compact ? 52 : 60,
                  padding: const EdgeInsets.all(5),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: .92),
                    shape: BoxShape.circle,
                    boxShadow: SkinTokens.shadows,
                  ),
                  child: const Skin3D(AppAssets.aloe3d),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _PurposeSection extends StatelessWidget {
  const _PurposeSection();

  @override
  Widget build(BuildContext context) {
    return const SkinCard(
      gradient: SkinTokens.warmGradient,
      borderColor: Color(0xFFFFFFFF),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SkinIconTile(icon: Icons.flag_outlined, tone: SkinTone.peach),
          SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Tujuan pengembangan', style: SkinTokens.cardTitle),
                SizedBox(height: 6),
                Text(
                  'Menyediakan satu tempat untuk menyimpan catatan kondisi kulit secara berkala. Foto dan check-in dapat membantu pengguna membandingkan catatannya sendiri, tetapi hasilnya tetap dipengaruhi pencahayaan, posisi kamera, dan kualitas gambar.',
                  style: TextStyle(
                    color: SkinTokens.muted,
                    fontSize: 13.5,
                    height: 1.55,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Principles extends StatelessWidget {
  const _Principles();

  @override
  Widget build(BuildContext context) {
    return const SkinCard(
      padding: EdgeInsets.fromLTRB(16, 18, 16, 18),
      child: Column(
        children: [
          _Principle(
            icon: Icons.fact_check_outlined,
            tone: SkinTone.primary,
            title: 'Berdasarkan data yang diberikan',
            body:
                'Ringkasan dibuat dari foto dan jawaban yang dimasukkan pengguna, sehingga hasil dapat berbeda ketika kondisi pengambilan data berubah.',
          ),
          Divider(height: 28),
          _Principle(
            icon: Icons.timeline_rounded,
            tone: SkinTone.info,
            title: 'Berfokus pada pencatatan berkala',
            body:
                'Journey mengelompokkan baseline, foto, kuis, dan check-in agar setiap perjalanan dapat ditinjau secara terpisah.',
          ),
          Divider(height: 28),
          _Principle(
            icon: Icons.menu_book_outlined,
            tone: SkinTone.lavender,
            title: 'Edukasi dengan rujukan',
            body:
                'Materi edukasi menyertakan sumber yang dapat diperiksa dan disajikan sebagai informasi umum, bukan rekomendasi terapi pribadi.',
          ),
          Divider(height: 28),
          _Principle(
            icon: Icons.health_and_safety_outlined,
            tone: SkinTone.peach,
            title: 'Batas penggunaan yang jelas',
            body:
                'Hasil visual merupakan observasi awal dan tidak digunakan untuk menetapkan diagnosis atau menggantikan pemeriksaan tenaga kesehatan.',
          ),
        ],
      ),
    );
  }
}

class _Principle extends StatelessWidget {
  const _Principle({
    required this.icon,
    required this.tone,
    required this.title,
    required this.body,
  });

  final IconData icon;
  final SkinTone tone;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SkinIconTile(icon: icon, tone: tone, size: 42),
        const SizedBox(width: 13),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: SkinTokens.ink,
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                body,
                style: const TextStyle(
                  color: SkinTokens.muted,
                  fontSize: 13,
                  height: 1.45,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _TeamSection extends StatelessWidget {
  const _TeamSection();

  static const _members = <(String, String, SkinTone)>[
    ('Moch. Adam Arsyad F.', 'Project Manager', SkinTone.primary),
    ('Bintang Pancahaya P.', 'Mobile Developer', SkinTone.info),
    ('Rafazl Radana D.', 'ML Engineer', SkinTone.lavender),
    ('Muchammad Ibrahim A. A', 'UI/UX Designer', SkinTone.peach),
    ('Anthea Amodia Syaffah A.', 'QA / Dokumentasi', SkinTone.warning),
  ];

  String _initials(String name) {
    final parts = name
        .replaceAll('.', ' ')
        .split(RegExp(r'\s+'))
        .where((part) => part.length > 1)
        .toList();
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts.first[0].toUpperCase();
    return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SkinSectionTitle(
          title: 'Tim di balik SkinSight',
          subtitle:
              'Kelompok 2 · PBL Semester 5 Teknik Informatika, Politeknik Negeri Malang.',
        ),
        const SizedBox(height: 14),
        SkinCard(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Column(
            children: [
              for (var i = 0; i < _members.length; i++) ...[
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: _members[i].$3.background,
                          shape: BoxShape.circle,
                        ),
                        child: Text(
                          _initials(_members[i].$1),
                          style: TextStyle(
                            color: _members[i].$3.foreground,
                            fontSize: 13.5,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _members[i].$1,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: SkinTokens.ink,
                                fontSize: 14.5,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 1),
                            Text(
                              _members[i].$2,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: SkinTokens.muted,
                                fontSize: 12.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                if (i < _members.length - 1)
                  const Divider(height: 1, indent: 68, endIndent: 16),
              ],
            ],
          ),
        ),
      ],
    );
  }
}
