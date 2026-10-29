import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../data/skin_education_content.dart';
import '../theme/skin_theme.dart';
import 'skin_ui.dart';

/// Ilustrasi artikel: lingkaran kaca berisi ikon topik, daun aloe di
/// belakang, dan percikan tetes air — pengganti foto produk di referensi.
class SkinArticleArt extends StatelessWidget {
  const SkinArticleArt({super.key, required this.article, this.size = 150});

  final SkinArticle article;
  final double size;

  @override
  Widget build(BuildContext context) {
    final s = size;
    return SizedBox(
      width: s,
      height: s,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            left: s * .06,
            top: s * .1,
            width: s * .86,
            height: s * .86,
            child: DecoratedBox(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    article.gradient.first,
                    article.gradient.last.withValues(alpha: 0),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            right: -s * .04,
            bottom: s * .12,
            width: s * .5,
            height: s * .78,
            child: Transform.rotate(
              angle: .22,
              child: const SkinAloe(leaves: 4),
            ),
          ),
          Positioned(
            left: s * .14,
            bottom: s * .12,
            width: s * .56,
            height: s * .56,
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Colors.white, Color(0xFFE7F0EC)],
                ),
                border: Border.all(color: Colors.white, width: 2),
                boxShadow: SkinTokens.shadows,
              ),
              child: Icon(
                article.icon,
                size: s * .24,
                color: SkinTokens.ink.withValues(alpha: .78),
              ),
            ),
          ),
          Positioned.fill(
            child: IgnorePointer(
              child: CustomPaint(painter: _DropletsPainter(article.slug)),
            ),
          ),
        ],
      ),
    );
  }
}

class _DropletsPainter extends CustomPainter {
  const _DropletsPainter(this.seed);

  final String seed;

  @override
  void paint(Canvas canvas, Size size) {
    final random = math.Random(seed.hashCode);
    for (var i = 0; i < 9; i++) {
      final angle = -math.pi * (.15 + random.nextDouble() * .8);
      final distance = size.width * (.34 + random.nextDouble() * .2);
      final center = Offset(size.width * .42, size.height * .62) +
          Offset(math.cos(angle), math.sin(angle)) * distance;
      final r = 2.0 + random.nextDouble() * 4.5;
      canvas.drawCircle(
        center,
        r,
        Paint()
          ..shader = RadialGradient(
            center: const Alignment(-.4, -.4),
            colors: [Colors.white, SkinTokens.aqua.withValues(alpha: .9)],
          ).createShader(Rect.fromCircle(center: center, radius: r)),
      );
      canvas.drawCircle(
        center,
        r,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = .8
          ..color = SkinTokens.aquaDeep.withValues(alpha: .5),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _DropletsPainter old) => old.seed != seed;
}

/// Tombol hati untuk menyimpan artikel.
class SkinSaveArticleButton extends StatelessWidget {
  const SkinSaveArticleButton({super.key, required this.slug, this.size = 40});

  final String slug;
  final double size;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Set<String>>(
      valueListenable: skinSavedArticles,
      builder: (context, saved, _) {
        final on = saved.contains(slug);
        return SkinCircleButton(
          size: size,
          tooltip: on ? 'Hapus dari simpanan' : 'Simpan artikel',
          icon: on ? Icons.favorite_rounded : Icons.favorite_border_rounded,
          background: Colors.white,
          onPressed: () => toggleSavedArticle(slug),
        );
      },
    );
  }
}

/// Kartu "Untuk Kamu": judul artikel, waktu baca tebal, tombol hati,
/// ilustrasi, dan CTA "Baca sekarang".
class SkinForYouCard extends StatelessWidget {
  const SkinForYouCard({super.key, required this.article, this.onTap});

  final SkinArticle article;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final open = onTap ?? () => showSkinArticleSheet(context, article);
    return SkinCard(
      inkKey: Key('for-you-${article.slug}'),
      onTap: open,
      padding: EdgeInsets.zero,
      radius: 28,
      child: SizedBox(
        height: 206,
        child: LayoutBuilder(builder: (context, constraints) {
          final art = math.min(150.0, constraints.maxWidth * .44);
          return Stack(
            children: [
              Positioned(
                right: 4,
                bottom: 6,
                child: SkinArticleArt(article: article, size: art),
              ),
              Positioned(
                top: 14,
                right: 14,
                child: SkinSaveArticleButton(slug: article.slug),
              ),
              Padding(
                padding: EdgeInsets.fromLTRB(20, 18, art * .9, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Judul mengisi sisa ruang dan terpotong rapi bila sempit.
                    Expanded(
                      child: Align(
                        alignment: Alignment.topLeft,
                        child: Text(
                          article.title,
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 17.5,
                            height: 1.3,
                            fontWeight: FontWeight.w600,
                            color: SkinTokens.ink,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      skinTopicLabels[article.topic] ?? article.topic,
                      style: const TextStyle(
                        fontSize: 12,
                        color: SkinTokens.muted,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      article.readTime,
                      style: SkinTokens.number.copyWith(fontSize: 20),
                    ),
                    const SizedBox(height: 10),
                    Material(
                      color: Colors.white,
                      shape: const StadiumBorder(),
                      child: InkWell(
                        onTap: open,
                        customBorder: const StadiumBorder(),
                        child: const Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 9,
                          ),
                          child: Text(
                            'Baca sekarang',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: SkinTokens.ink,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        }),
      ),
    );
  }
}

/// Lembar artikel lengkap dari bawah layar.
void showSkinArticleSheet(BuildContext context, SkinArticle article) {
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (context) => DraggableScrollableSheet(
      expand: false,
      initialChildSize: .82,
      minChildSize: .55,
      maxChildSize: .94,
      builder: (context, scrollController) => ListView(
        controller: scrollController,
        padding: const EdgeInsets.fromLTRB(24, 4, 24, 36),
        children: [
          Container(
            height: 176,
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: article.gradient,
              ),
              borderRadius: BorderRadius.circular(SkinTokens.radiusXl),
              border: Border.all(color: Colors.white, width: 1.5),
            ),
            child: Stack(
              children: [
                Positioned(
                  right: 12,
                  bottom: 0,
                  child: SkinArticleArt(article: article, size: 170),
                ),
                Positioned(
                  top: 16,
                  left: 16,
                  child: SkinSaveArticleButton(slug: article.slug),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              SkinPill(label: skinTopicLabels[article.topic] ?? article.topic),
              SkinPill(
                label: '${article.readTime} baca',
                tone: SkinTone.neutral,
                icon: Icons.schedule_rounded,
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            article.title,
            style: SkinTokens.title.copyWith(fontSize: 30),
          ),
          const SizedBox(height: 10),
          Text(
            article.summary,
            style: const TextStyle(
              color: SkinTokens.muted,
              fontSize: 16,
              height: 1.5,
            ),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 20),
            child: Divider(height: 1),
          ),
          Text(
            article.body,
            style: const TextStyle(
              color: SkinTokens.ink,
              fontSize: 16,
              height: 1.7,
            ),
          ),
          const SizedBox(height: 24),
          SkinCard(
            color: SkinTokens.mint.withValues(alpha: .7),
            shadow: false,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    SkinIconTile(
                      icon: Icons.lightbulb_outline_rounded,
                      size: 32,
                      tone: SkinTone.neutral,
                    ),
                    SizedBox(width: 10),
                    Text('Yang perlu diingat', style: SkinTokens.cardTitle),
                  ],
                ),
                const SizedBox(height: 14),
                for (final point in article.keyPoints)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Padding(
                          padding: EdgeInsets.only(top: 3),
                          child: Icon(Icons.check_circle_rounded,
                              size: 17, color: SkinTokens.aloe),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            point,
                            style: const TextStyle(
                              color: SkinTokens.ink,
                              fontSize: 14.5,
                              height: 1.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.menu_book_outlined,
                  size: 16, color: SkinTokens.muted),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Sumber bacaan: ${article.source}',
                  style: const TextStyle(
                    color: SkinTokens.muted,
                    fontSize: 12.5,
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    ),
  );
}
