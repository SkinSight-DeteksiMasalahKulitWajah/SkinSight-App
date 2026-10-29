import 'package:flutter/material.dart';

import'../data/skin_education_content.dart';
import'../../../core/theme/skin_theme.dart';
import'./widgets/skin_article_widgets.dart';
import'../../../shared/widgets/navigation/skin_bottom_nav.dart';
import'../../../shared/widgets/skin_page_background.dart';
import'../../../shared/widgets/design_system/skin_ui.dart';

class SkinEducationPage extends StatefulWidget {
  final bool embedded;

  const SkinEducationPage({super.key, this.embedded = false});

  @override
  State<SkinEducationPage> createState() => _SkinEducationPageState();
}

class _SkinEducationPageState extends State<SkinEducationPage> {
  static const _topics = <(String, IconData)>[
    ('Semua', Icons.apps_rounded),
    ('Acne', Icons.bubble_chart_outlined),
    ('PIH', Icons.wb_sunny_outlined),
    ('Dark Circle', Icons.remove_red_eye_outlined),
    ('Redness', Icons.local_fire_department_outlined),
    ('Wrinkle', Icons.face_retouching_natural_outlined),
  ];

  final _searchController = TextEditingController();
  String _selectedTopic = 'Semua';
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<SkinArticle> get _filteredArticles {
    final normalizedQuery = _query.trim().toLowerCase();
    return skinArticles.where((article) {
      final topicMatches =
          _selectedTopic == 'Semua' || article.topic == _selectedTopic;
      final queryMatches = normalizedQuery.isEmpty ||
          article.title.toLowerCase().contains(normalizedQuery) ||
          article.summary.toLowerCase().contains(normalizedQuery) ||
          article.topic.toLowerCase().contains(normalizedQuery);
      return topicMatches && queryMatches;
    }).toList(growable: false);
  }

  void _reset() {
    _searchController.clear();
    setState(() {
      _query = '';
      _selectedTopic = 'Semua';
    });
  }

  @override
  Widget build(BuildContext context) {
    final articles = _filteredArticles;
    final showFeatured = articles.contains(skinFeaturedArticle);
    final readingList = articles
        .where((article) => article != skinFeaturedArticle)
        .toList(growable: false);
    const inset = SkinTokens.pageInset;

    final content = Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: SkinTokens.maxWidth),
        child: CustomScrollView(
          key: const Key('education-scroll'),
          physics: const ClampingScrollPhysics(),
          slivers: [
            const SliverPadding(
              padding: EdgeInsets.fromLTRB(inset, 20, inset, 0),
              sliver: SliverToBoxAdapter(
                child: SkinReveal(child: _EducationIntro()),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(inset, 20, inset, 0),
              sliver: SliverToBoxAdapter(
                child: _SearchField(
                  controller: _searchController,
                  onChanged: (value) => setState(() => _query = value),
                  onClear: () {
                    _searchController.clear();
                    setState(() => _query = '');
                  },
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(inset, 16, inset, 0),
              // Semua topik terlihat sekaligus (bukan digeser) di halaman ini.
              sliver: SliverToBoxAdapter(
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final topic in _topics)
                      SkinFilterChip(
                        key: Key(
                          'education-topic-${topic.$1.toLowerCase().replaceAll(' ', '-')}',
                        ),
                        label: skinTopicLabels[topic.$1] ?? topic.$1,
                        icon: topic.$2,
                        selected: topic.$1 == _selectedTopic,
                        onTap: () => setState(() => _selectedTopic = topic.$1),
                      ),
                  ],
                ),
              ),
            ),
            if (showFeatured) ...[
              const SliverPadding(
                padding: EdgeInsets.fromLTRB(inset, 28, inset, 12),
                sliver: SliverToBoxAdapter(
                  child: SkinSectionTitle(title: 'Artikel rekomendasi'),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: inset),
                sliver: SliverToBoxAdapter(
                  child: SkinReveal(
                    delay: const Duration(milliseconds: 80),
                    child: _FeaturedArticle(
                      article: skinFeaturedArticle,
                      onTap: () =>
                          showSkinArticleSheet(context, skinFeaturedArticle),
                    ),
                  ),
                ),
              ),
            ],
            if (readingList.isNotEmpty) ...[
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(inset, 28, inset, 12),
                sliver: SliverToBoxAdapter(
                  child: SkinSectionTitle(
                    title: 'Jelajahi topik kulit',
                    trailing: SkinPill(
                      label: '${readingList.length} artikel',
                      tone: SkinTone.neutral,
                    ),
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: inset),
                sliver: SliverList.separated(
                  itemCount: readingList.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final article = readingList[index];
                    return SkinReveal.staggered(
                      index: index + 2,
                      child: _ArticleRow(
                        article: article,
                        onTap: () => showSkinArticleSheet(context, article),
                      ),
                    );
                  },
                ),
              ),
            ],
            if (articles.isEmpty)
              SliverFillRemaining(
                hasScrollBody: false,
                child: _EmptyEducationState(onReset: _reset),
              ),
            if (articles.isNotEmpty)
              SliverPadding(
                padding: EdgeInsets.fromLTRB(
                  inset,
                  24,
                  inset,
                  widget.embedded ? SkinBottomNav.overlap : 32,
                ),
                sliver: const SliverToBoxAdapter(child: _EducationNote()),
              ),
          ],
        ),
      ),
    );

    if (widget.embedded) return content;

    return Scaffold(
      backgroundColor: SkinTokens.background,
      extendBody: true,
      body: SkinPageBackground(
        child: SafeArea(bottom: false, child: content),
      ),
      bottomNavigationBar: const SkinBottomNav(currentIndex: 1),
    );
  }
}

class _EducationIntro extends StatelessWidget {
  const _EducationIntro();

  @override
  Widget build(BuildContext context) {
    return const Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Edukasi', style: SkinTokens.title),
              SizedBox(height: 6),
              Text(
                'Bacaan singkat berbasis rujukan untuk memahami kulitmu.',
                style: SkinTokens.caption,
              ),
            ],
          ),
        ),
        SizedBox(width: 12),
        SkinIconTile(icon: Icons.auto_stories_rounded, size: 48),
      ],
    );
  }
}

class _SearchField extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;

  const _SearchField({
    required this.controller,
    required this.onChanged,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(999);
    return SkinGlass(
      radius: 999,
      color: SkinTokens.glassStrong,
      blur: 0,
      child: ValueListenableBuilder<TextEditingValue>(
        valueListenable: controller,
        builder: (context, value, _) => TextField(
          key: const Key('education-search'),
          controller: controller,
          onChanged: onChanged,
          textInputAction: TextInputAction.search,
          decoration: InputDecoration(
            hintText: 'Cari topik atau kebutuhan kulit',
            prefixIcon: const Padding(
              padding: EdgeInsets.only(left: 16, right: 8),
              child: Icon(Icons.search_rounded, color: SkinTokens.muted),
            ),
            prefixIconConstraints: const BoxConstraints(minWidth: 44),
            suffixIcon: value.text.isEmpty
                ? null
                : IconButton(
                    tooltip: 'Hapus pencarian',
                    onPressed: onClear,
                    icon: const Icon(Icons.close_rounded),
                  ),
            fillColor: Colors.transparent,
            contentPadding: const EdgeInsets.symmetric(vertical: 16),
            enabledBorder: OutlineInputBorder(
              borderRadius: radius,
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: radius,
              borderSide: const BorderSide(color: SkinTokens.primary),
            ),
          ),
        ),
      ),
    );
  }
}

class _FeaturedArticle extends StatelessWidget {
  final SkinArticle article;
  final VoidCallback onTap;

  const _FeaturedArticle({required this.article, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return SkinCard(
      inkKey: const Key('education-featured'),
      onTap: onTap,
      padding: EdgeInsets.zero,
      radius: SkinTokens.radiusXl,
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          ...article.gradient.map((c) => c.withValues(alpha: .9)),
        ],
      ),
      borderColor: Colors.white,
      child: SizedBox(
        height: 232,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final compact = constraints.maxWidth < 355;
            return Stack(
              children: [
                Positioned(
                  right: compact ? -10 : 6,
                  bottom: 4,
                  child: SkinArticleArt(
                    article: article,
                    size: compact ? 150 : 176,
                  ),
                ),
                Positioned(
                  top: 16,
                  right: 16,
                  child: SkinSaveArticleButton(slug: article.slug),
                ),
                Positioned(
                  left: 20,
                  top: 20,
                  bottom: 20,
                  width: compact ? 175 : 210,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SkinPill(
                        label: skinTopicLabels[article.topic] ?? article.topic,
                        icon: Icons.auto_awesome_rounded,
                      ),
                      const Spacer(),
                      Text(
                        article.title,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontFamily: SkinTokens.serif,
                          color: SkinTokens.ink,
                          fontSize: compact ? 23 : 26,
                          height: 1.1,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.fromLTRB(14, 8, 10, 8),
                        decoration: BoxDecoration(
                          color: SkinTokens.primary,
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Flexible(
                              child: Text(
                                'Baca  •  ${article.readTime}',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            const SizedBox(width: 6),
                            const Icon(
                              Icons.play_arrow_rounded,
                              size: 16,
                              color: Colors.white,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _ArticleRow extends StatelessWidget {
  final SkinArticle article;
  final VoidCallback onTap;

  const _ArticleRow({required this.article, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return SkinCard(
      inkKey: Key('education-article-${article.slug}'),
      onTap: onTap,
      padding: const EdgeInsets.all(12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          _TopicMark(article: article),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      (skinTopicLabels[article.topic] ?? article.topic)
                          .toUpperCase(),
                      style: SkinTokens.eyebrow.copyWith(fontSize: 10),
                    ),
                    const SizedBox(width: 8),
                    const Icon(Icons.schedule_rounded,
                        size: 12, color: SkinTokens.muted),
                    const SizedBox(width: 3),
                    Text(
                      article.readTime,
                      style: const TextStyle(
                        color: SkinTokens.muted,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 5),
                Text(
                  article.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: SkinTokens.ink,
                    fontSize: 15.5,
                    height: 1.3,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  article.summary,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: SkinTokens.muted,
                    fontSize: 12.5,
                    height: 1.45,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 6),
          Container(
            width: 32,
            height: 32,
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.play_arrow_rounded,
              size: 18,
              color: SkinTokens.ink,
            ),
          ),
        ],
      ),
    );
  }
}

class _TopicMark extends StatelessWidget {
  final SkinArticle article;

  const _TopicMark({required this.article});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 68,
      height: 80,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: article.gradient,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white),
      ),
      child: Icon(
        article.icon,
        size: 28,
        color: SkinTokens.ink.withValues(alpha: .75),
      ),
    );
  }
}

class _EmptyEducationState extends StatelessWidget {
  final VoidCallback onReset;

  const _EmptyEducationState({required this.onReset});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(36, 36, 36, 110),
      child: Center(
        child: SkinEmptyState(
          icon: Icons.manage_search_rounded,
          title: 'Topik belum ditemukan',
          message: 'Coba kata kunci lain atau tampilkan kembali semua topik.',
          action: OutlinedButton.icon(
            onPressed: onReset,
            icon: const Icon(Icons.refresh_rounded, size: 18),
            label: const Text('Lihat semua topik'),
          ),
        ),
      ),
    );
  }
}

class _EducationNote extends StatelessWidget {
  const _EducationNote();

  @override
  Widget build(BuildContext context) {
    return const SkinNotice(
      icon: Icons.verified_user_outlined,
      tone: SkinTone.neutral,
      dense: true,
      message:
          'Konten ini bersifat edukasi umum. Hasil foto dan artikel tidak menggantikan diagnosis atau saran tenaga kesehatan.',
    );
  }
}
