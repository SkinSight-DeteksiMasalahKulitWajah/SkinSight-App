import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/skin_theme.dart';
import '../../../shared/widgets/design_system/skin_ui.dart';
import '../../../shared/widgets/navigation/skin_bottom_nav.dart';
import '../../../shared/widgets/skin_page_background.dart';
import '../data/skin_education_content.dart';
import './widgets/skin_article_widgets.dart';

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
  bool _savedOnly = false;
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<SkinArticle> _filteredArticles(Set<String> savedSlugs) {
    final normalizedQuery = _query.trim().toLowerCase();
    return skinArticles.where((article) {
      if (_savedOnly && !savedSlugs.contains(article.slug)) return false;
      final topicMatches =
          _selectedTopic == 'Semua' || article.topic == _selectedTopic;
      final topicLabel = (skinTopicLabels[article.topic] ?? article.topic)
          .toLowerCase();
      final queryMatches = normalizedQuery.isEmpty ||
          article.title.toLowerCase().contains(normalizedQuery) ||
          article.summary.toLowerCase().contains(normalizedQuery) ||
          article.topic.toLowerCase().contains(normalizedQuery) ||
          topicLabel.contains(normalizedQuery);
      return topicMatches && queryMatches;
    }).toList(growable: false);
  }

  void _reset() {
    _searchController.clear();
    setState(() {
      _query = '';
      _selectedTopic = 'Semua';
      _savedOnly = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final content = LayoutBuilder(builder: (context, constraints) {
      final compact = constraints.maxWidth < 350;
      final inset = compact ? 16.0 : 20.0;

      return ValueListenableBuilder<Set<String>>(
        valueListenable: skinSavedArticles,
        builder: (context, savedSlugs, _) {
          final articles = _filteredArticles(savedSlugs);
          final showFeatured = !_savedOnly &&
              _query.trim().isEmpty &&
              articles.contains(skinFeaturedArticle);
          final readingList = showFeatured
              ? articles
                  .where((article) => article != skinFeaturedArticle)
                  .toList(growable: false)
              : articles;

          return Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: SkinTokens.maxWidth),
              child: CustomScrollView(
                key: const Key('education-scroll'),
                physics: const ClampingScrollPhysics(),
                slivers: [
                  SliverPadding(
                    padding: EdgeInsets.fromLTRB(inset, 16, inset, 0),
                    sliver: SliverToBoxAdapter(
                      child: _EducationMasthead(
                        savedCount: savedSlugs.length,
                        savedOnly: _savedOnly,
                        onToggleSaved: () =>
                            setState(() => _savedOnly = !_savedOnly),
                      ),
                    ),
                  ),
                  SliverPadding(
                    padding: EdgeInsets.fromLTRB(inset, 16, inset, 0),
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
                    padding: EdgeInsets.fromLTRB(inset, 14, inset, 0),
                    sliver: SliverToBoxAdapter(
                      child: Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          for (final topic in _topics)
                            _TopicFilterChip(
                              key: Key(
                                'education-topic-${topic.$1.toLowerCase().replaceAll(' ', '-')}',
                              ),
                              label: skinTopicLabels[topic.$1] ?? topic.$1,
                              icon: topic.$2,
                              selected:
                                  !_savedOnly && topic.$1 == _selectedTopic,
                              onTap: () => setState(() {
                                _savedOnly = false;
                                _selectedTopic = topic.$1;
                              }),
                            ),
                        ],
                      ),
                    ),
                  ),
                  if (showFeatured) ...[
                    SliverPadding(
                      padding: EdgeInsets.fromLTRB(inset, 24, inset, 10),
                      sliver: const SliverToBoxAdapter(
                        child: SkinSectionTitle(title: 'Artikel rekomendasi'),
                      ),
                    ),
                    SliverPadding(
                      padding: EdgeInsets.symmetric(horizontal: inset),
                      sliver: SliverToBoxAdapter(
                        child: _FeaturedArticle(
                          article: skinFeaturedArticle,
                          compact: compact,
                          onTap: () => showSkinArticleSheet(
                            context,
                            skinFeaturedArticle,
                          ),
                        ),
                      ),
                    ),
                  ],
                  if (readingList.isNotEmpty) ...[
                    SliverPadding(
                      padding: EdgeInsets.fromLTRB(inset, 24, inset, 10),
                      sliver: SliverToBoxAdapter(
                        child: SkinSectionTitle(
                          title: _savedOnly
                              ? 'Artikel tersimpan'
                              : 'Jelajahi topik kulit',
                          trailing: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 5,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.surfaceTint,
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(
                              '${readingList.length} artikel',
                              style: const TextStyle(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w700,
                                color: SkinTokens.muted,
                                fontFeatures: [FontFeature.tabularFigures()],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    SliverPadding(
                      padding: EdgeInsets.symmetric(horizontal: inset),
                      sliver: SliverList.separated(
                        itemCount: readingList.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 10),
                        itemBuilder: (context, index) {
                          final article = readingList[index];
                          return _ArticleRow(
                            article: article,
                            saved: savedSlugs.contains(article.slug),
                            onTap: () => showSkinArticleSheet(context, article),
                          );
                        },
                      ),
                    ),
                  ],
                  if (articles.isEmpty)
                    SliverFillRemaining(
                      hasScrollBody: false,
                      child: _EmptyEducationState(
                        savedOnly: _savedOnly,
                        onReset: _reset,
                      ),
                    ),
                  if (articles.isNotEmpty)
                    SliverPadding(
                      padding: EdgeInsets.fromLTRB(
                        inset,
                        22,
                        inset,
                        widget.embedded ? SkinBottomNav.overlap + 16 : 32,
                      ),
                      sliver: const SliverToBoxAdapter(
                        child: _EducationNote(),
                      ),
                    ),
                ],
              ),
            ),
          );
        },
      );
    });

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

class _EducationMasthead extends StatelessWidget {
  const _EducationMasthead({
    required this.savedCount,
    required this.savedOnly,
    required this.onToggleSaved,
  });

  final int savedCount;
  final bool savedOnly;
  final VoidCallback onToggleSaved;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Edukasi Kulit',
                style: TextStyle(
                  fontSize: 24,
                  height: 1.18,
                  letterSpacing: -.4,
                  fontWeight: FontWeight.w800,
                  color: SkinTokens.ink,
                ),
              ),
              SizedBox(height: 4),
              Text(
                'Panduan singkat berbasis rujukan dermatologi.',
                style: TextStyle(
                  fontSize: 13,
                  height: 1.4,
                  color: SkinTokens.muted,
                ),
              ),
            ],
          ),
        ),
        if (savedCount > 0 || savedOnly) ...[
          const SizedBox(width: 10),
          Material(
            color: savedOnly ? SkinTokens.primary : Colors.white,
            shape: StadiumBorder(
              side: BorderSide(
                color: savedOnly ? SkinTokens.primary : SkinTokens.border,
              ),
            ),
            child: InkWell(
              key: const Key('education-saved-toggle'),
              customBorder: const StadiumBorder(),
              onTap: onToggleSaved,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      savedOnly
                          ? Icons.bookmark_rounded
                          : Icons.bookmark_border_rounded,
                      size: 16,
                      color: savedOnly ? Colors.white : SkinTokens.primary,
                    ),
                    const SizedBox(width: 5),
                    Text(
                      '$savedCount',
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                        color: savedOnly ? Colors.white : SkinTokens.ink,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
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
    final radius = BorderRadius.circular(16);
    return ValueListenableBuilder<TextEditingValue>(
      valueListenable: controller,
      builder: (context, value, _) => TextField(
        key: const Key('education-search'),
        controller: controller,
        onChanged: onChanged,
        textInputAction: TextInputAction.search,
        style: const TextStyle(
          fontSize: 14,
          color: SkinTokens.ink,
          fontWeight: FontWeight.w500,
        ),
        decoration: InputDecoration(
          hintText: 'Cari topik atau keluhan kulit...',
          hintStyle: const TextStyle(
            fontSize: 14,
            color: SkinTokens.muted,
            fontWeight: FontWeight.w400,
          ),
          filled: true,
          fillColor: Colors.white,
          prefixIcon: const Padding(
            padding: EdgeInsets.only(left: 14, right: 8),
            child: Icon(
              Icons.search_rounded,
              size: 20,
              color: SkinTokens.muted,
            ),
          ),
          prefixIconConstraints: const BoxConstraints(minWidth: 42),
          suffixIcon: value.text.isEmpty
              ? null
              : IconButton(
                  tooltip: 'Hapus pencarian',
                  onPressed: onClear,
                  icon: const Icon(
                    Icons.close_rounded,
                    size: 18,
                    color: SkinTokens.muted,
                  ),
                ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 14,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: radius,
            borderSide: const BorderSide(color: SkinTokens.border),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: radius,
            borderSide: const BorderSide(
              color: SkinTokens.primary,
              width: 1.5,
            ),
          ),
        ),
      ),
    );
  }
}

class _TopicFilterChip extends StatelessWidget {
  const _TopicFilterChip({
    super.key,
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? SkinTokens.primary : Colors.white,
      shape: StadiumBorder(
        side: BorderSide(
          color: selected ? SkinTokens.primary : SkinTokens.border,
        ),
      ),
      child: InkWell(
        customBorder: const StadiumBorder(),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 15,
                color: selected ? Colors.white : SkinTokens.muted,
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                  color: selected ? Colors.white : SkinTokens.ink,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FeaturedArticle extends StatelessWidget {
  final SkinArticle article;
  final bool compact;
  final VoidCallback onTap;

  const _FeaturedArticle({
    required this.article,
    required this.compact,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final topicLabel = skinTopicLabels[article.topic] ?? article.topic;

    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: SkinTokens.deepGradient,
        borderRadius: BorderRadius.circular(24),
        boxShadow: SkinTokens.glow(AppColors.forestDeep, opacity: .2),
      ),
      child: Material(
        type: MaterialType.transparency,
        borderRadius: BorderRadius.circular(24),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          key: const Key('education-featured'),
          onTap: onTap,
          child: Padding(
            padding: EdgeInsets.all(compact ? 16 : 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.mintTint,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            article.icon,
                            size: 13,
                            color: AppColors.forestDeep,
                          ),
                          const SizedBox(width: 5),
                          Text(
                            topicLabel,
                            style: const TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w800,
                              color: AppColors.forestDeep,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        '${article.readTime} baca',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFFD4E8E0),
                          fontFeatures: [FontFeature.tabularFigures()],
                        ),
                      ),
                    ),
                    SkinSaveArticleButton(
                      slug: article.slug,
                      size: 36,
                      darkSurface: true,
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Text(
                  article.title,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: compact ? 18 : 20,
                    height: 1.24,
                    letterSpacing: -.3,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  article.summary,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 13,
                    height: 1.45,
                    color: Color(0xFFD4E8E0),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 9,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Baca artikel',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                              color: AppColors.forestDeep,
                            ),
                          ),
                          SizedBox(width: 6),
                          Icon(
                            Icons.arrow_forward_rounded,
                            size: 16,
                            color: AppColors.forestDeep,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        article.source,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.right,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFFB5D2C7),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ArticleRow extends StatelessWidget {
  final SkinArticle article;
  final bool saved;
  final VoidCallback onTap;

  const _ArticleRow({
    required this.article,
    required this.saved,
    required this.onTap,
  });

  static (Color bg, Color fg) _topicColors(String topic) => switch (topic) {
        'Acne' => (SkinTokens.peachSoft, const Color(0xFFA35035)),
        'PIH' => (SkinTokens.amberSoft, SkinTokens.amber),
        'Dark Circle' => (SkinTokens.lavenderSoft, SkinTokens.lavender),
        'Redness' => (SkinTokens.coralSoft, SkinTokens.coral),
        'Wrinkle' => (SkinTokens.blueSoft, SkinTokens.blue),
        _ => (AppColors.mintTint, SkinTokens.primary),
      };

  @override
  Widget build(BuildContext context) {
    final (badgeBg, badgeFg) = _topicColors(article.topic);
    final topicLabel = skinTopicLabels[article.topic] ?? article.topic;

    return SkinCard(
      inkKey: Key('education-article-${article.slug}'),
      onTap: onTap,
      color: Colors.white,
      borderColor: SkinTokens.border,
      radius: 20,
      padding: const EdgeInsets.all(14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: badgeBg,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(article.icon, size: 22, color: badgeFg),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  article.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: SkinTokens.ink,
                    fontSize: 15,
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
                    height: 1.42,
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: badgeBg,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        topicLabel,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: badgeFg,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Icon(
                      Icons.schedule_rounded,
                      size: 13,
                      color: SkinTokens.muted,
                    ),
                    const SizedBox(width: 3),
                    Flexible(
                      child: Text(
                        article.readTime,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: SkinTokens.muted,
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                          fontFeatures: [FontFeature.tabularFigures()],
                        ),
                      ),
                    ),
                    if (saved) ...[
                      const SizedBox(width: 8),
                      const Icon(
                        Icons.bookmark_rounded,
                        size: 14,
                        color: SkinTokens.primary,
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 6),
          const Padding(
            padding: EdgeInsets.only(top: 12),
            child: Icon(
              Icons.chevron_right_rounded,
              size: 20,
              color: SkinTokens.muted,
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyEducationState extends StatelessWidget {
  final bool savedOnly;
  final VoidCallback onReset;

  const _EmptyEducationState({
    required this.savedOnly,
    required this.onReset,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(28, 36, 28, 110),
      child: Center(
        child: SkinEmptyState(
          icon: savedOnly
              ? Icons.bookmark_border_rounded
              : Icons.manage_search_rounded,
          title: savedOnly ? 'Belum ada artikel tersimpan' : 'Topik belum ditemukan',
          message: savedOnly
              ? 'Ketuk ikon simpan pada artikel mana pun untuk membacanya lagi nanti.'
              : 'Coba kata kunci lain atau tampilkan kembali semua topik.',
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
