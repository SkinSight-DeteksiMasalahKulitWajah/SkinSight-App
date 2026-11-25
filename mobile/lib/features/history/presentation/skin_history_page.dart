import 'package:flutter/material.dart';
import '../../../core/api/cloud_sync.dart';
import '../../../core/api/supabase_direct.dart';
import '../data/skin_history_repository.dart';
import '../../journeys/data/skin_journey_store.dart';
import '../../scan/models/skin_analysis.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/skin_theme.dart';
import '../../../shared/widgets/asset_images.dart';
import '../../../shared/widgets/shimmer_skeleton.dart';
import '../../../shared/widgets/navigation/skin_bottom_nav.dart';
import '../../../shared/widgets/skin_page_header.dart';
import '../../../shared/widgets/skin_page_background.dart';
import '../../../shared/widgets/design_system/skin_ui.dart';
import '../../scan/presentation/skin_result_page.dart';
import '../../progress/presentation/skin_progress_page.dart';

class SkinHistoryPage extends StatefulWidget {
  const SkinHistoryPage({super.key});
  @override
  State<SkinHistoryPage> createState() => _SkinHistoryPageState();
}

class _SkinHistoryPageState extends State<SkinHistoryPage> {
  DateTime? _filter;
  bool _latestFirst = true;
  bool _loading = true;
  bool _refreshing = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final history = SkinHistoryRepository.instance;
    final journey = SkinJourneyStore.instance;
    await history.fetchHistory();

    // Pada mode offline/widget test tanpa sesi Supabase, langsung tampilkan cache lokal.
    if (!SupabaseDirect.isSignedIn) {
      if (mounted) setState(() => _loading = false);
      return;
    }

    // Jika sudah punya cache lokal, tampilkan segera sambil menyegarkan di latar;
    // jika masih kosong, tahan indikator loading sampai data dari Supabase tiba.
    final hasLocalData =
        history.records.isNotEmpty || journey.allCheckins.isNotEmpty;
    if (mounted) {
      setState(() {
        _loading = !hasLocalData;
        _refreshing = hasLocalData;
      });
    }

    try {
      await Future.wait([
        history.pullFromServer(),
        journey.pullFromServer(),
      ]);
    } on Object catch (e) {
      debugPrint('Muat riwayat dari server gagal: $e');
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
          _refreshing = false;
        });
      }
    }
  }

  Future<void> _onRefresh() async {
    if (!SupabaseDirect.isSignedIn) return;
    await CloudSync.instance.refresh(retryBackend: true);
  }

  String _date(DateTime d) =>
      '${SkinFormat.shortDate(d)} · ${SkinFormat.time(d)}';

  bool _matches(DateTime date) =>
      _filter == null ||
      (date.year == _filter!.year &&
          date.month == _filter!.month &&
          date.day == _filter!.day);

  Future<void> _confirmDelete(SkinAnalysis analysis) async {
    final displayTitle = _localizedTitle(analysis);
    final ok = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        icon: const SkinIconTile(
          icon: Icons.delete_outline_rounded,
          tone: SkinTone.danger,
          size: 46,
        ),
        title: const Text('Hapus riwayat scan?'),
        content: Text(
          '“$displayTitle” beserta fotonya akan dihapus dari riwayat & Supabase.',
          textAlign: TextAlign.center,
        ),
        actionsPadding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Batal'),
          ),
          FilledButton(
            key: const Key('confirm-delete-scan'),
            style: FilledButton.styleFrom(
              backgroundColor: SkinTokens.coral,
              minimumSize: const Size(92, 44),
            ),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    await SkinHistoryRepository.instance.delete(analysis.id);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Riwayat scan berhasil dihapus.')),
    );
  }

  Future<void> _pickDate() async {
    final date = await showDatePicker(
      context: context,
      helpText: 'Pilih tanggal scan',
      confirmText: 'Pilih',
      cancelText: 'Batal',
      firstDate: DateTime(2024),
      lastDate: DateTime(2035),
      initialDate: _filter ?? DateTime.now(),
    );
    if (mounted && date != null) setState(() => _filter = date);
  }

  @override
  Widget build(BuildContext context) {
    final history = SkinHistoryRepository.instance;
    final journey = SkinJourneyStore.instance;
    final cloud = CloudSync.instance;
    return Scaffold(
      backgroundColor: SkinTokens.background,
      body: SkinPageBackground(
          child: SafeArea(
              bottom: false,
              child: Center(
                  child: ConstrainedBox(
                constraints:
                    const BoxConstraints(maxWidth: SkinTokens.maxWidth),
                child: Column(children: [
                  SkinPageHeader(
                    title: 'Riwayat Kulit',
                    subtitle: 'Scan dan check-in yang tersimpan',
                    backKey: const Key('history-back'),
                    trailing: SkinCircleButton(
                      key: const Key('history-filter-date'),
                      tooltip: 'Filter tanggal',
                      icon: Icons.calendar_month_outlined,
                      iconColor: SkinTokens.primaryDark,
                      onPressed: _pickDate,
                    ),
                  ),
                  Expanded(
                      child: AnimatedBuilder(
                    animation: Listenable.merge([history, journey, cloud]),
                    builder: (context, _) {
                      final scans = history.records
                          .where((r) => _matches(r.analyzedAt))
                          .toList();
                      scans.sort((a, b) => _latestFirst
                          ? b.analyzedAt.compareTo(a.analyzedAt)
                          : a.analyzedAt.compareTo(b.analyzedAt));
                      final checkins = journey.allCheckins
                          .where((c) => _matches(c.date))
                          .toList();
                      final isSyncingNow =
                          cloud.isSyncing || history.isSyncing || _refreshing;
                      final showSkeleton = scans.isEmpty &&
                          checkins.isEmpty &&
                          (_loading || isSyncingNow);

                      return RefreshIndicator(
                        onRefresh: _onRefresh,
                        color: SkinTokens.primary,
                        child: ListView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
                          children: [
                            Row(children: [
                              const Expanded(
                                child: Text(
                                  'Aktivitas yang tercatat',
                                  style: SkinTokens.section,
                                ),
                              ),
                              TextButton.icon(
                                key: const Key('history-sort-toggle'),
                                onPressed: () => setState(
                                    () => _latestFirst = !_latestFirst),
                                style: TextButton.styleFrom(
                                  backgroundColor: Colors.white,
                                  shape: const StadiumBorder(
                                    side: BorderSide(color: SkinTokens.border),
                                  ),
                                ),
                                icon: Icon(
                                  _latestFirst
                                      ? Icons.arrow_downward_rounded
                                      : Icons.arrow_upward_rounded,
                                  size: 16,
                                ),
                                label:
                                    Text(_latestFirst ? 'Terbaru' : 'Terlama'),
                              ),
                            ]),
                            if (_filter != null) ...[
                              const SizedBox(height: 8),
                              Align(
                                alignment: Alignment.centerLeft,
                                child: InputChip(
                                  key: const Key('clear-history-filter'),
                                  avatar: const Icon(Icons.event_rounded,
                                      size: 16, color: SkinTokens.primaryDark),
                                  label: Text(SkinFormat.date(_filter!)),
                                  selected: true,
                                  showCheckmark: false,
                                  deleteIcon:
                                      const Icon(Icons.close_rounded, size: 16),
                                  onDeleted: () =>
                                      setState(() => _filter = null),
                                  onPressed: () =>
                                      setState(() => _filter = null),
                                ),
                              ),
                            ],
                            if (isSyncingNow && !showSkeleton) ...[
                              const SizedBox(height: 10),
                              const ClipRRect(
                                borderRadius:
                                    BorderRadius.all(Radius.circular(999)),
                                child: LinearProgressIndicator(
                                  minHeight: 3,
                                  color: SkinTokens.primary,
                                  backgroundColor: SkinTokens.mint,
                                ),
                              ),
                            ],
                            const SizedBox(height: 14),
                            if (showSkeleton)
                              Column(
                                key: const Key('history-loading-state'),
                                children: [
                                  ShimmerLoading(
                                    child: Column(
                                      children: [
                                        for (var i = 0; i < 4; i++) ...[
                                          const SkeletonBox(
                                            height: 82,
                                            borderRadius: BorderRadius.all(
                                              Radius.circular(20),
                                            ),
                                          ),
                                          const SizedBox(height: 10),
                                        ],
                                      ],
                                    ),
                                  ),
                                ],
                              )
                            else if (scans.isEmpty && checkins.isEmpty)
                              Padding(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 36),
                                child: SkinEmptyState(
                                  icon: Icons.history_rounded,
                                  title: _filter == null
                                      ? 'Belum ada aktivitas'
                                      : 'Tidak ada aktivitas',
                                  message: _filter == null
                                      ? 'Simpan hasil scan untuk mulai membangun riwayat kulitmu.'
                                      : 'Tidak ada scan atau check-in pada tanggal ini.',
                                ),
                              )
                            else ...[
                              for (var i = 0; i < scans.length; i++) ...[
                                _ScanRow(
                                  analysis: scans[i],
                                  date: _date(scans[i].analyzedAt),
                                  onDelete: () => _confirmDelete(scans[i]),
                                ),
                                const SizedBox(height: 10),
                              ],
                              for (final c in checkins) ...[
                                SkinCard(
                                  onTap: () => Navigator.of(context).push(
                                      MaterialPageRoute<void>(
                                          builder: (_) =>
                                              const SkinProgressPage())),
                                  padding: const EdgeInsets.all(12),
                                  child: Row(children: [
                                    const SkinIconTile(
                                      icon: Icons.event_note_rounded,
                                      tone: SkinTone.peach,
                                      size: 56,
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          const Text('Check-in Kulit',
                                              style: SkinTokens.cardTitle),
                                          const SizedBox(height: 3),
                                          Text(
                                            '${_date(c.date)} · Dikonfirmasi pengguna',
                                            style: SkinTokens.caption,
                                          ),
                                        ],
                                      ),
                                    ),
                                    const Icon(Icons.chevron_right_rounded,
                                        color: SkinTokens.subtle),
                                  ]),
                                ),
                                const SizedBox(height: 12),
                              ],
                            ],
                          ],
                        ),
                      );
                    },
                  )),
                ]),
              )))),
      bottomNavigationBar: const SkinBottomNav(currentIndex: -1),
    );
  }
}

String _localizeCondition(String raw) => switch (raw.trim().toLowerCase()) {
      'acne' => 'Jerawat',
      'pih' || 'hyperpigmentation' || 'dark spots' => 'Noda Gelap (PIH)',
      'dark circle' || 'dark circles' => 'Lingkar Mata',
      'redness' || 'erythema' => 'Kemerahan',
      'wrinkle' || 'wrinkles' || 'fine lines' => 'Garis Halus',
      'pores' || 'enlarged pores' => 'Pori Besar',
      _ => raw,
    };

String _localizeSkinType(String raw) => switch (raw.trim().toLowerCase()) {
      'dry' => 'Kering',
      'oily' => 'Berminyak',
      'normal' => 'Normal',
      'combination' => 'Kombinasi',
      _ => raw,
    };

String _localizedTitle(SkinAnalysis analysis) {
  if (analysis.visualFindings.isNotEmpty) {
    final labels =
        analysis.visualFindings.map(_localizeCondition).toList(growable: false);
    if (labels.length <= 2) return labels.join(' & ');
    return '${labels.take(2).join(' & ')} +${labels.length - 2}';
  }
  return analysis.title;
}

class _ScanRow extends StatelessWidget {
  const _ScanRow({
    required this.analysis,
    required this.date,
    required this.onDelete,
  });

  final SkinAnalysis analysis;
  final String date;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final photo = analysis.selfieBytes;
    final title = _localizedTitle(analysis);
    final findingCount = analysis.visualFindings.length;
    final skinType = _localizeSkinType(analysis.skinType);
    final showSkinType = skinType.isNotEmpty &&
        !skinType.toLowerCase().contains('belum');

    return SkinCard(
      inkKey: Key('history-detail-${analysis.id}'),
      onTap: () => Navigator.of(context).push(MaterialPageRoute<void>(
          builder: (_) => SkinResultPage(analysis: analysis, archived: true))),
      color: Colors.white,
      borderColor: SkinTokens.border,
      radius: 20,
      padding: const EdgeInsets.all(12),
      child: Row(children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: photo == null || photo.isEmpty
              ? const SkinIconTile(
                  icon: Icons.face_retouching_natural,
                  size: 54,
                  radius: 14,
                )
              : Image.memory(
                  photo,
                  width: 54,
                  height: 54,
                  fit: BoxFit.cover,
                  cacheWidth: thumbnailCacheWidth(context, 54),
                ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 14.5,
                  height: 1.3,
                  fontWeight: FontWeight.w700,
                  color: SkinTokens.ink,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                date,
                style: const TextStyle(
                  fontSize: 12,
                  color: SkinTokens.muted,
                  fontFeatures: [FontFeature.tabularFigures()],
                ),
              ),
              const SizedBox(height: 6),
              Wrap(
                spacing: 6,
                runSpacing: 4,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: findingCount > 0
                          ? SkinTokens.peachSoft
                          : AppColors.mintTint,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      findingCount > 0
                          ? '$findingCount temuan'
                          : 'Foto tersimpan',
                      style: TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w700,
                        color: findingCount > 0
                            ? const Color(0xFFA35035)
                            : SkinTokens.primary,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                  ),
                  if (showSkinType)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceTint,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        skinType,
                        style: const TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w700,
                          color: SkinTokens.muted,
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(width: 6),
        IconButton(
          key: Key('history-delete-${analysis.id}'),
          tooltip: 'Hapus riwayat scan',
          onPressed: onDelete,
          style: IconButton.styleFrom(
            backgroundColor: SkinTokens.coralSoft,
            foregroundColor: SkinTokens.coral,
            minimumSize: const Size(38, 38),
          ),
          icon: const Icon(Icons.delete_outline_rounded, size: 18),
        ),
      ]),
    );
  }
}
