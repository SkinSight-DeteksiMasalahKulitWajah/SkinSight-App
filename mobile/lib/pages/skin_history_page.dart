import 'package:flutter/material.dart';
import '../data/skin_history_repository.dart';
import '../data/skin_journey_store.dart';
import '../models/skin_analysis.dart';
import '../theme/skin_theme.dart';
import '../widgets/asset_images.dart';
import '../widgets/shimmer_skeleton.dart';
import '../widgets/skin_bottom_nav.dart';
import '../widgets/skin_page_header.dart';
import '../widgets/skin_page_background.dart';
import '../widgets/skin_ui.dart';
import 'skin_result_page.dart';
import 'skin_progress_page.dart';

class SkinHistoryPage extends StatefulWidget {
  const SkinHistoryPage({super.key});
  @override
  State<SkinHistoryPage> createState() => _SkinHistoryPageState();
}

class _SkinHistoryPageState extends State<SkinHistoryPage> {
  DateTime? _filter;
  bool _latestFirst = true;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    SkinHistoryRepository.instance.fetchHistory().then((_) {
      if (mounted) setState(() => _loading = false);
    });
  }

  String _date(DateTime d) =>
      '${SkinFormat.shortDate(d)} · ${SkinFormat.time(d)}';

  bool _matches(DateTime date) =>
      _filter == null ||
      (date.year == _filter!.year &&
          date.month == _filter!.month &&
          date.day == _filter!.day);

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
                    animation: Listenable.merge([history, journey]),
                    builder: (context, _) {
                      final scans = history.records
                          .where((r) => _matches(r.analyzedAt))
                          .toList();
                      scans.sort((a, b) => _latestFirst
                          ? b.analyzedAt.compareTo(a.analyzedAt)
                          : a.analyzedAt.compareTo(b.analyzedAt));
                      final checkins = journey.checkins
                          .where((c) => _matches(c.date))
                          .toList();
                      return ListView(
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
                            const SizedBox(height: 14),
                            if (_loading)
                              ShimmerLoading(
                                child: Column(
                                  children: [
                                    for (var i = 0; i < 3; i++) ...[
                                      const SkeletonBox(
                                        height: 78,
                                        borderRadius: BorderRadius.all(
                                          Radius.circular(SkinTokens.radiusLg),
                                        ),
                                      ),
                                      const SizedBox(height: 12),
                                    ],
                                  ],
                                ),
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
                                SkinReveal.staggered(
                                  index: i,
                                  child: _ScanRow(
                                    analysis: scans[i],
                                    date: _date(scans[i].analyzedAt),
                                  ),
                                ),
                                const SizedBox(height: 12),
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
                          ]);
                    },
                  )),
                ]),
              )))),
      bottomNavigationBar: const SkinBottomNav(currentIndex: -1),
    );
  }
}

class _ScanRow extends StatelessWidget {
  const _ScanRow({required this.analysis, required this.date});

  final SkinAnalysis analysis;
  final String date;

  @override
  Widget build(BuildContext context) {
    final photo = analysis.selfieBytes;
    return SkinCard(
      inkKey: Key('history-detail-${analysis.id}'),
      onTap: () => Navigator.of(context).push(MaterialPageRoute<void>(
          builder: (_) => SkinResultPage(analysis: analysis, archived: true))),
      padding: const EdgeInsets.all(12),
      child: Row(children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: photo == null || photo.isEmpty
              ? const SkinIconTile(
                  icon: Icons.face_retouching_natural,
                  size: 56,
                  radius: 16,
                )
              : Image.memory(
                  photo,
                  width: 56,
                  height: 56,
                  fit: BoxFit.cover,
                  cacheWidth: thumbnailCacheWidth(context, 56),
                ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                analysis.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: SkinTokens.cardTitle,
              ),
              const SizedBox(height: 3),
              Text(
                '$date · Hasil pengamatan kulit',
                style: SkinTokens.caption,
              ),
            ],
          ),
        ),
        const Icon(Icons.chevron_right_rounded, color: SkinTokens.subtle),
      ]),
    );
  }
}
