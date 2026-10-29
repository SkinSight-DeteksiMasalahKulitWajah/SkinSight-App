import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import'../../../core/app_assets.dart';
import'../../../core/theme/skin_theme.dart';
import'../../../shared/widgets/navigation/skin_bottom_nav.dart';
import'../../../shared/widgets/skin_page_background.dart';
import'../../../shared/widgets/skin_page_header.dart';
import'../../../shared/widgets/skin_3d.dart';
import'../../../shared/widgets/design_system/skin_ui.dart';

class SkinHelpPage extends StatelessWidget {
  final bool embedded;

  const SkinHelpPage({super.key, this.embedded = false});

  @override
  Widget build(BuildContext context) {
    final content = SkinPageBackground(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: SkinTokens.maxWidth),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final compact = constraints.maxWidth < 350;
              return Column(
                children: [
                  if (embedded)
                    const _EmbeddedHelpHeader()
                  else
                    const SkinPageHeader(
                      title: 'Pusat Bantuan',
                      backKey: Key('help-back'),
                    ),
                  Expanded(
                    child: SingleChildScrollView(
                      key: const Key('help-scroll'),
                      physics: const ClampingScrollPhysics(),
                      padding: EdgeInsets.fromLTRB(
                        compact ? 16 : 20,
                        4,
                        compact ? 16 : 20,
                        32,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          SkinReveal(child: _WelcomeCard(compact: compact)),
                          const SizedBox(height: 22),
                          const SkinSectionTitle(
                            title: 'Topik bantuan',
                            subtitle:
                                'Ketuk topik untuk membuka penjelasannya.',
                          ),
                          const SizedBox(height: 12),
                          const _HelpTopicsPanel(),
                          const SizedBox(height: 18),
                          const SkinNotice(
                            icon: Icons.health_and_safety_outlined,
                            tone: SkinTone.neutral,
                            dense: true,
                            message:
                                'SkinSight hanya untuk skrining awal dan edukasi. Untuk keluhan kulit yang berlanjut, konsultasikan ke dokter kulit.',
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );

    if (embedded) return content;

    return Scaffold(
      backgroundColor: SkinTokens.background,
      body: SafeArea(bottom: false, child: content),
      bottomNavigationBar: const SkinBottomNav(currentIndex: -1),
    );
  }
}

// ───────────────────────── Header ─────────────────────────

class _EmbeddedHelpHeader extends StatelessWidget {
  const _EmbeddedHelpHeader();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.fromLTRB(20, 18, 20, 8),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text('Pusat Bantuan', style: SkinTokens.title),
      ),
    );
  }
}

// ───────────────────────── Welcome ─────────────────────────

class _WelcomeCard extends StatelessWidget {
  final bool compact;

  const _WelcomeCard({required this.compact});

  @override
  Widget build(BuildContext context) {
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        gradient: SkinTokens.brandGradient,
        borderRadius: BorderRadius.circular(SkinTokens.radiusXl),
        boxShadow: SkinTokens.glow(SkinTokens.primary, opacity: .24),
      ),
      child: Stack(
        children: [
          Positioned(
            right: -36,
            top: -46,
            child: Container(
              width: 160,
              height: 160,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: .09),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Positioned(
            right: compact ? -12 : -2,
            bottom: -10,
            width: compact ? 104 : 124,
            height: compact ? 104 : 124,
            child: const Skin3D(AppAssets.help3d, float: true),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(20, 20, compact ? 96 : 120, 22),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: .18),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(
                    Icons.support_agent_rounded,
                    color: Colors.white,
                    size: 23,
                    semanticLabel: 'Bantuan',
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  'Ada yang bisa kami bantu?',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: compact ? 19 : 21,
                    height: 1.2,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -.3,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Panduan penggunaan, privasi, dan jawaban untuk pertanyaanmu.',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: .86),
                    fontSize: 13.5,
                    height: 1.45,
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

// ───────────────────────── Topics panel ─────────────────────────

class _HelpTopicsPanel extends StatelessWidget {
  const _HelpTopicsPanel();

  @override
  Widget build(BuildContext context) {
    const topics = <Widget>[
      _HelpTopic(
        key: Key('help-how-to'),
        icon: Icons.auto_awesome_rounded,
        tone: SkinTone.primary,
        title: 'Cara menggunakan SkinSight',
        subtitle: 'Panduan scan kulit dari awal sampai hasil.',
        initiallyExpanded: true,
        child: _HowToContent(),
      ),
      _HelpTopic(
        key: Key('help-faq'),
        icon: Icons.question_answer_outlined,
        tone: SkinTone.info,
        title: 'FAQ',
        subtitle: 'Jawaban untuk pertanyaan yang sering muncul.',
        child: _FaqContent(),
      ),
      _HelpTopic(
        key: Key('help-contact'),
        icon: Icons.mail_outline_rounded,
        tone: SkinTone.peach,
        title: 'Hubungi kami',
        subtitle: 'Butuh bantuan lebih lanjut? Tim kami siap.',
        child: _ContactContent(),
      ),
      _HelpTopic(
        key: Key('help-privacy'),
        icon: Icons.privacy_tip_outlined,
        tone: SkinTone.lavender,
        title: 'Kebijakan privasi',
        subtitle: 'Cara kami memperlakukan foto dan datamu.',
        child: _PrivacyContent(),
      ),
      _HelpTopic(
        key: Key('help-about'),
        icon: Icons.info_outline_rounded,
        tone: SkinTone.warning,
        title: 'Tentang SkinSight',
        subtitle: 'Kenali tujuan dan batasan aplikasi.',
        child: _AboutContent(),
      ),
    ];
    return Column(
      children: [
        for (var i = 0; i < topics.length; i++) ...[
          SkinReveal.staggered(index: i + 1, child: topics[i]),
          if (i < topics.length - 1) const SizedBox(height: 12),
        ],
      ],
    );
  }
}

class _HelpTopic extends StatelessWidget {
  final IconData icon;
  final SkinTone tone;
  final String title;
  final String subtitle;
  final Widget child;
  final bool initiallyExpanded;

  const _HelpTopic({
    super.key,
    required this.icon,
    required this.tone,
    required this.title,
    required this.subtitle,
    required this.child,
    this.initiallyExpanded = false,
  });

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(SkinTokens.radiusLg);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: radius,
        border: Border.all(color: SkinTokens.border),
        boxShadow: SkinTokens.shadows,
      ),
      child: Material(
        type: MaterialType.transparency,
        borderRadius: radius,
        clipBehavior: Clip.antiAlias,
        child: Theme(
          data: Theme.of(context).copyWith(
            dividerColor: Colors.transparent,
            splashColor: tone.foreground.withValues(alpha: .06),
            highlightColor: tone.foreground.withValues(alpha: .04),
          ),
          child: ExpansionTile(
            initiallyExpanded: initiallyExpanded,
            shape: const Border(),
            collapsedShape: const Border(),
            tilePadding: const EdgeInsets.fromLTRB(14, 8, 14, 8),
            childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 18),
            expandedCrossAxisAlignment: CrossAxisAlignment.start,
            expandedAlignment: Alignment.centerLeft,
            leading: SkinIconTile(icon: icon, tone: tone, size: 44),
            title: Text(
              title,
              style: const TextStyle(
                color: SkinTokens.ink,
                fontSize: 15.5,
                fontWeight: FontWeight.w800,
              ),
            ),
            subtitle: Padding(
              padding: const EdgeInsets.only(top: 3),
              child: Text(
                subtitle,
                style: const TextStyle(
                  color: SkinTokens.muted,
                  fontSize: 13,
                  height: 1.3,
                ),
              ),
            ),
            iconColor: SkinTokens.primaryDark,
            collapsedIconColor: SkinTokens.subtle,
            children: [
              const Divider(height: 1),
              const SizedBox(height: 16),
              child,
            ],
          ),
        ),
      ),
    );
  }
}

// ───────────────────────── How to (timeline) ─────────────────────────

class _HowToContent extends StatelessWidget {
  const _HowToContent();

  @override
  Widget build(BuildContext context) {
    return const Column(
      children: [
        _StepRow(
          1,
          'Isi kuis kondisi kulit',
          'Jawab tujuh pertanyaan singkat sesuai kondisi wajahmu.',
        ),
        _StepRow(
          2,
          'Ambil selfie',
          'Posisikan wajah di dalam frame dengan cahaya yang cukup.',
        ),
        _StepRow(
          3,
          'Lihat hasil',
          'Baca ringkasan temuan visual dan edukasi perawatannya.',
        ),
        _StepRow(
          4,
          'Pantau lewat check-in',
          'Simpan ke Skin Journey lalu isi check-in mingguan.',
          isLast: true,
        ),
      ],
    );
  }
}

class _StepRow extends StatelessWidget {
  final int number;
  final String title;
  final String body;
  final bool isLast;

  const _StepRow(this.number, this.title, this.body, {this.isLast = false});

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 32,
            child: Column(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  alignment: Alignment.center,
                  decoration: const BoxDecoration(
                    gradient: SkinTokens.brandGradient,
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    '$number',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 2,
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      decoration: BoxDecoration(
                        color: SkinTokens.mintStrong,
                        borderRadius: BorderRadius.circular(1),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : 16, top: 5),
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
                  const SizedBox(height: 3),
                  Text(body, style: SkinTokens.caption),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ───────────────────────── FAQ ─────────────────────────

class _FaqContent extends StatelessWidget {
  const _FaqContent();

  @override
  Widget build(BuildContext context) {
    return const Column(
      children: [
        _FaqItem(
          'Apakah hasil SkinSight merupakan diagnosis medis?',
          'Tidak. Hasil bersifat skrining awal dan edukasi, bukan pengganti pemeriksaan dokter kulit.',
        ),
        SizedBox(height: 8),
        _FaqItem(
          'Bagaimana agar hasil foto lebih baik?',
          'Gunakan cahaya dari depan, bersihkan lensa, dan hindari filter atau riasan tebal.',
        ),
        SizedBox(height: 8),
        _FaqItem(
          'Apakah saya bisa mengulang scan?',
          'Bisa. Buka Home lalu ketuk Mulai Scan, atau tambahkan foto baru saat mengisi check-in.',
        ),
        SizedBox(height: 8),
        _FaqItem(
          'Kapan check-in perlu diisi?',
          'Pengingat muncul di Home sesuai jadwal pemantauan Skin Journey-mu.',
        ),
      ],
    );
  }
}

class _FaqItem extends StatelessWidget {
  final String question;
  final String answer;

  const _FaqItem(this.question, this.answer);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: SkinTokens.blueSoft,
        borderRadius: BorderRadius.circular(16),
      ),
      clipBehavior: Clip.antiAlias,
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          shape: const Border(),
          collapsedShape: const Border(),
          tilePadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
          childrenPadding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
          expandedAlignment: Alignment.centerLeft,
          expandedCrossAxisAlignment: CrossAxisAlignment.start,
          iconColor: SkinTokens.blue,
          collapsedIconColor: SkinTokens.blue,
          title: Text(
            question,
            style: const TextStyle(
              color: SkinTokens.ink,
              fontSize: 14,
              fontWeight: FontWeight.w700,
              height: 1.3,
            ),
          ),
          children: [
            Text(
              answer,
              style: const TextStyle(
                color: SkinTokens.muted,
                fontSize: 13.5,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ───────────────────────── Contact ─────────────────────────

class _ContactContent extends StatelessWidget {
  const _ContactContent();

  @override
  Widget build(BuildContext context) {
    const email = 'support@skinsight.app';
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 10, 12),
      decoration: BoxDecoration(
        color: SkinTokens.peachSoft,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.alternate_email_rounded,
              color: SkinTone.peach.foreground,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Email dukungan',
                  style: TextStyle(color: SkinTokens.muted, fontSize: 12.5),
                ),
                SizedBox(height: 2),
                Text(
                  email,
                  style: TextStyle(
                    color: SkinTokens.ink,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
          IconButton.filledTonal(
            key: const Key('copy-support-email'),
            tooltip: 'Salin email',
            style: IconButton.styleFrom(backgroundColor: Colors.white),
            onPressed: () async {
              await Clipboard.setData(const ClipboardData(text: email));
              if (!context.mounted) return;
              ScaffoldMessenger.of(context)
                ..hideCurrentSnackBar()
                ..showSnackBar(
                  const SnackBar(
                    content: Text('Email dukungan berhasil disalin.'),
                  ),
                );
            },
            icon: const Icon(Icons.copy_rounded, size: 19),
          ),
        ],
      ),
    );
  }
}

// ───────────────────────── Privacy ─────────────────────────

class _PrivacyContent extends StatelessWidget {
  const _PrivacyContent();

  @override
  Widget build(BuildContext context) {
    return const Column(
      children: [
        _PrivacyPoint(
          Icons.phone_android_rounded,
          'Foto digunakan untuk menampilkan hasil analisis pada perangkatmu.',
        ),
        _PrivacyPoint(
          Icons.save_outlined,
          'Hasil hanya disimpan ketika kamu memilih tombol Simpan.',
        ),
        _PrivacyPoint(
          Icons.share_outlined,
          'Jangan membagikan hasil yang memuat informasi pribadi kepada pihak yang tidak dipercaya.',
          isLast: true,
        ),
      ],
    );
  }
}

class _PrivacyPoint extends StatelessWidget {
  final IconData icon;
  final String text;
  final bool isLast;

  const _PrivacyPoint(this.icon, this.text, {this.isLast = false});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SkinIconTile(
            icon: icon,
            tone: SkinTone.lavender,
            size: 32,
            radius: 10,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: 5),
              child: Text(text, style: SkinTokens.caption),
            ),
          ),
        ],
      ),
    );
  }
}

// ───────────────────────── About ─────────────────────────

class _AboutContent extends StatelessWidget {
  const _AboutContent();

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'SkinSight membantu pengguna mengenali kondisi kulit melalui kuis dan foto wajah dengan pengalaman yang ringan dan mudah dipahami.',
          style: SkinTokens.caption,
        ),
        SizedBox(height: 12),
        SkinPill(
          label: 'Versi 1.1.0',
          tone: SkinTone.warning,
          icon: Icons.new_releases_outlined,
        ),
      ],
    );
  }
}
