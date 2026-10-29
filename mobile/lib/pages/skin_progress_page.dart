import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter/material.dart';
import '../core/app_assets.dart';
import '../data/skin_journey_store.dart';
import '../data/skin_timeline_engine.dart';
import '../models/skin_analysis.dart';
import '../theme/skin_theme.dart';
import '../widgets/asset_images.dart';
import '../widgets/skin_bottom_nav.dart';
import '../widgets/skin_checkin_shortcut.dart';
import '../widgets/skin_page_header.dart';
import '../widgets/skin_page_background.dart';
import '../widgets/skin_3d.dart';
import '../widgets/skin_ui.dart';
import 'skin_checkin_page.dart';
import 'skin_quiz_page.dart';
import 'skin_result_page.dart';

/// Satu halaman Skin Journey: jumlah temuan per waktu + timeline check-in.
/// Tidak mengubah jumlah deteksi menjadi tingkat kesembuhan.
class SkinProgressPage extends StatefulWidget {
  const SkinProgressPage({super.key});
  @override
  State<SkinProgressPage> createState() => _SkinProgressPageState();
}

class _SkinProgressPageState extends State<SkinProgressPage> {
  String _selected = 'Acne';

  String _date(DateTime d) => SkinFormat.dayMonth(d);
  String _value(String name, double v) =>
      SkinJourneyStore.detectionClasses.contains(name)
          ? '${v.toInt()}'
          : '${(v * 100).toStringAsFixed(0)}%';
  String _unit(String name) => SkinJourneyStore.detectionClasses.contains(name)
      ? 'area terdeteksi'
      : 'luas mask wajah';

  String _statusSubtitle(SkinJourneyStore store) {
    if (!store.hasBaseline) return 'Belum ada scan awal';
    return switch (store.selectedJourneyStatus) {
      JourneyStatus.active =>
        'Perjalanan aktif · minggu ke-${store.currentWeek}',
      JourneyStatus.completed => 'Perjalanan selesai',
      JourneyStatus.cancelled => 'Perjalanan dibatalkan',
    };
  }

  @override
  Widget build(BuildContext context) {
    final store = SkinJourneyStore.instance;
    return Scaffold(
      extendBody: true,
      backgroundColor: SkinTokens.background,
      body: SkinPageBackground(
          child: SafeArea(
              bottom: false,
              child: Center(
                  child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: SkinTokens.maxWidth),
        child: AnimatedBuilder(
            animation: store,
            builder: (context, _) {
              final engine = store.timeline;
              final classes = engine.tracks.isEmpty
                  ? SkinJourneyStore.visualClasses
                  : engine.tracks.keys.toList();
              final selected =
                  classes.contains(_selected) ? _selected : classes.first;
              final values = store.metricHistory(selected);
              final isDetection =
                  SkinJourneyStore.detectionClasses.contains(selected);
              // Satu event per TANGGAL, bukan per foto atau per laporan.
              // Data beberapa sesi tetap disimpan dan dapat dibuka masing-masing.
              final events = _dailyEvents(store, engine);
              final header = SkinPageHeader(
                title: store.selectedJourneyName,
                subtitle: _statusSubtitle(store),
                backKey: const Key('journey-back'),
              );
              if (store.shouldShowJourneyCompletion) {
                return Column(children: [
                  header,
                  Expanded(
                    child: ListView(
                      key: const Key('completed-journey-detail'),
                      padding: const EdgeInsets.fromLTRB(
                          20, 4, 20, SkinBottomNav.overlap + 16),
                      children: [
                        _JourneyCompletionContent(engine: engine),
                      ],
                    ),
                  ),
                ]);
              }
              return Column(children: [
                header,
                Expanded(
                  child: ListView(
                      padding: const EdgeInsets.fromLTRB(
                          20, 4, 20, SkinBottomNav.overlap + 16),
                      children: [
                        if (!store.isSelectedJourneyActive) ...[
                          _journeyStatusBanner(store.selectedJourneyStatus),
                          const SizedBox(height: 12),
                        ],
                        if (!store.hasBaseline)
                          _emptyJourney(context)
                        else ...[
                          SkinReveal(child: _heroCard(context, store, engine)),
                          if (store.hasCheckinDue) ...[
                            const SizedBox(height: 14),
                            SkinCheckinShortcut(
                              key: const Key('journey-checkin-shortcut'),
                              buttonKey: const Key('journey-start-checkin'),
                              week: store.currentWeek,
                              dueDate: store.activeDueDate!,
                              status: store.checkinPromptStatus!,
                              onPressed: () => Navigator.of(context).push(
                                MaterialPageRoute<void>(
                                  builder: (_) => const SkinCheckinPage(),
                                ),
                              ),
                            ),
                          ],
                          const SizedBox(height: 28),
                          const SkinSectionTitle(
                            title: 'Grafik temuan kulit',
                            subtitle:
                                'Pilih kondisi untuk melihat perbandingan tiap tanggal.',
                          ),
                          const SizedBox(height: 12),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              for (final c in classes)
                                ChoiceChip(
                                  label: Text(c),
                                  selected: selected == c,
                                  onSelected: (_) =>
                                      setState(() => _selected = c),
                                ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          SkinReveal(
                            delay: const Duration(milliseconds: 80),
                            child: _chartPanel(selected, values, isDetection),
                          ),
                          const SizedBox(height: 30),
                          SkinSectionTitle(
                            title: 'Timeline',
                            subtitle:
                                'Riwayat → hari ini → jadwal mendatang, dalam satu garis waktu.',
                            trailing: SkinPill(
                              label: '${events.length} momen',
                              tone: SkinTone.neutral,
                              icon: Icons.calendar_month_rounded,
                            ),
                          ),
                          const SizedBox(height: 16),
                          if (events.isEmpty)
                            const Text('Belum ada peristiwa atau jadwal.',
                                style: SkinTokens.caption),
                          ...List.generate(
                              events.length,
                              (i) => _timelineRow(
                                  context, events[i], i == events.length - 1)),
                        ],
                      ]),
                ),
              ]);
            }),
      )))),
      bottomNavigationBar: SkinBottomNav(
        currentIndex: 3,
        onJourney: () {
          final navigator = Navigator.of(context);
          var foundJourneyList = false;
          navigator.popUntil((route) {
            foundJourneyList = route.settings.name == '/journeys';
            return foundJourneyList || route.isFirst;
          });
          if (!foundJourneyList) navigator.pushNamed('/journeys');
        },
      ),
    );
  }

  Widget _heroCard(
    BuildContext context,
    SkinJourneyStore store,
    SkinTimelineEngine engine,
  ) {
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        gradient: SkinTokens.deepGradient,
        borderRadius: BorderRadius.circular(SkinTokens.radiusXl),
        boxShadow: SkinTokens.glow(SkinTokens.primaryDark, opacity: .3),
      ),
      child: Stack(children: [
        Positioned(
          right: -40,
          top: -46,
          child: Container(
            width: 170,
            height: 170,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: .07),
              shape: BoxShape.circle,
            ),
          ),
        ),
        Positioned(
          right: 14,
          top: 14,
          child: Icon(Icons.spa_rounded,
              color: Colors.white.withValues(alpha: .22), size: 64),
        ),
        Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'PERJALANAN KULITMU',
                style: SkinTokens.eyebrow.copyWith(
                  color: const Color(0xFFBFD8D2),
                ),
              ),
              const SizedBox(height: 10),
              Text('Minggu ke-${store.currentWeek}',
                  style: const TextStyle(
                      fontFamily: SkinTokens.serif,
                      fontSize: 40,
                      height: 1.0,
                      fontWeight: FontWeight.w400,
                      color: Colors.white)),
              const SizedBox(height: 4),
              Text(
                'Dimulai ${SkinFormat.date(store.baselineDate!)}',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: .75),
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 16),
              Row(children: [
                _heroStat('${store.photos.length}', 'Sesi foto'),
                const SizedBox(width: 8),
                _heroStat('${store.checkins.length}', 'Check-in'),
                const SizedBox(width: 8),
                _heroStat('${engine.tracks.length}', 'Dipantau'),
              ]),
            ],
          ),
        ),
      ]),
    );
  }

  Widget _heroStat(String value, String label) => Expanded(
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: .1),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Column(children: [
            Text(value,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 19,
                  fontWeight: FontWeight.w800,
                )),
            const SizedBox(height: 1),
            Text(label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: .72),
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                )),
          ]),
        ),
      );

  Widget _chartPanel(
    String selected,
    List<JourneyMetric> values,
    bool isDetection,
  ) {
    return _panel(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Expanded(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(selected,
              style: const TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.w800,
                  color: SkinTokens.ink)),
          const SizedBox(height: 3),
          Text(isDetection ? 'Jumlah temuan terdeteksi' : 'Luas mask wajah',
              style: SkinTokens.caption),
        ])),
        if (values.isNotEmpty)
          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Text(_value(selected, values.last.value),
                style: const TextStyle(
                    fontSize: 30,
                    height: 1.05,
                    color: SkinTokens.primary,
                    fontWeight: FontWeight.w800)),
            Text(_unit(selected),
                style: const TextStyle(color: SkinTokens.muted, fontSize: 11)),
          ]),
      ]),
      const SizedBox(height: 16),
      if (values.isEmpty)
        const SizedBox(
            height: 150,
            child: SkinEmptyState(
              compact: true,
              icon: Icons.show_chart_rounded,
              title: 'Belum ada data',
              message: 'Belum ada titik pengamatan untuk kelas ini.',
            ))
      else ...[
        SizedBox(
            height: 180,
            width: double.infinity,
            child: CustomPaint(
                painter:
                    _JourneyPlot(values, SkinTokens.primary, isDetection))),
        const SizedBox(height: 6),
        Padding(
          padding: const EdgeInsets.only(left: 35),
          child: Row(
              mainAxisAlignment: values.length == 1
                  ? MainAxisAlignment.center
                  : MainAxisAlignment.spaceBetween,
              children: values
                  .map((v) => Text(_date(v.date),
                      style: const TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w600,
                          color: SkinTokens.muted)))
                  .toList()),
        ),
        const SizedBox(height: 16),
        Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
                color: SkinTokens.mint,
                borderRadius: BorderRadius.circular(14)),
            child: Row(children: [
              const Icon(Icons.compare_arrows_rounded,
                  color: SkinTokens.primaryDark, size: 21),
              const SizedBox(width: 9),
              Expanded(
                  child: Text(
                      values.length == 1
                          ? 'Pengamatan awal: ${_value(selected, values.first.value)} ${_unit(selected)}'
                          : 'Dari ${_value(selected, values.first.value)} ke ${_value(selected, values.last.value)} ${_unit(selected)}',
                      style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: SkinTokens.ink))),
            ])),
      ],
      const SizedBox(height: 12),
      Text(
          isDetection
              ? 'Angka menunjukkan jumlah box terdeteksi pada foto dengan pose dan versi model yang sebanding; bukan tingkat keparahan.'
              : 'Angka menunjukkan proporsi luas mask dari area wajah yang valid; bukan skor kesembuhan.',
          style: const TextStyle(
              color: SkinTokens.muted, fontSize: 11.5, height: 1.45)),
    ]));
  }

  /// Satu baris timeline untuk satu tanggal kalender, bahkan jika pada hari
  /// itu terdapat scan awal, beberapa foto tambahan, check-in dan jadwal.
  List<_Event> _dailyEvents(SkinJourneyStore store, SkinTimelineEngine engine) {
    final byDate = <DateTime, _DayBucket>{};
    _DayBucket getDay(DateTime value) {
      final d = SkinJourneyStore.day(value);
      return byDate.putIfAbsent(d, () => _DayBucket(d));
    }

    if (store.isSelectedJourneyActive) {
      for (final planned in _plannedEvents(store, engine)) {
        getDay(planned.date).planned = planned;
      }
    }
    for (final p in store.photos) {
      getDay(p.date).photos.add(p);
    }
    for (final c in store.checkins) {
      getDay(c.date).checkins.add(c);
    }
    final days = byDate.values.toList()
      ..sort((a, b) => a.date.compareTo(b.date));
    return [for (final day in days) day.toEvent()];
  }

  /// Buka layar HASIL lengkap dari masing-masing foto yang sudah tersimpan.
  /// archived memastikan tidak muncul tombol Simpan ulang di hasil tersebut.
  void _openSavedSession(BuildContext context, JourneyPhoto photo) {
    final result = SkinAnalysis(
      id: photo.id,
      analyzedAt: photo.date,
      selfieBytes: photo.bytes,
      score: 0,
      oil: 0,
      pores: 0,
      acne: 0,
      redness: 0,
      title: 'Hasil sesi foto',
      skinType: photo.skinType ?? 'Belum diketahui',
      skinTypeConfidence: photo.skinTypeConfidence,
      visualFindings: photo.visualFindings,
      modelConnected: photo.modelConnected,
      isDemo: photo.isDemo,
      detectionCounts: photo.detectionCounts,
      segmentationAreas: photo.segmentationAreas,
      classConfidences: photo.confidences,
      modelVersion: photo.modelVersion,
    );
    Navigator.of(context).push(MaterialPageRoute<void>(
        builder: (_) => SkinResultPage(analysis: result, archived: true)));
  }

  /// Beberapa foto = beberapa sesi DALAM satu event tanggal, bukan beberapa
  /// titik timeline. Nilai setiap foto tidak dirata-ratakan.
  Widget _photoSessions(BuildContext context, List<JourneyPhoto> photos) {
    if (photos.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('${photos.length} sesi foto tersimpan',
            style: const TextStyle(
                color: SkinTokens.ink,
                fontSize: 12,
                fontWeight: FontWeight.w800)),
        const SizedBox(height: 8),
        SizedBox(
          height: 102,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: photos.length,
            separatorBuilder: (_, __) => const SizedBox(width: 10),
            itemBuilder: (context, index) {
              final p = photos[index];
              return InkWell(
                key: Key('journey-session-${p.id}'),
                onTap: () => _openSavedSession(context, p),
                borderRadius: BorderRadius.circular(14),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      ClipRRect(
                          borderRadius: BorderRadius.circular(14),
                          child: p.bytes.isNotEmpty
                              ? Image.memory(p.bytes,
                                  width: 70,
                                  height: 76,
                                  fit: BoxFit.cover,
                                  cacheWidth: thumbnailCacheWidth(context, 70))
                              : Container(
                                  width: 70,
                                  height: 76,
                                  color: SkinTokens.mint,
                                  child: const Icon(Icons.image_outlined,
                                      color: SkinTokens.primary))),
                      const SizedBox(height: 5),
                      Text('Sesi ${index + 1}',
                          style: const TextStyle(
                              fontSize: 11,
                              color: SkinTokens.primary,
                              fontWeight: FontWeight.w800)),
                    ]),
              );
            },
          ),
        ),
      ]),
    );
  }

  Widget _emptyJourney(BuildContext context) => SkinCard(
        padding: const EdgeInsets.fromLTRB(22, 26, 22, 22),
        gradient: SkinTokens.softGradient,
        borderColor: Colors.white,
        child: Column(children: [
          SizedBox(
            width: 120,
            height: 120,
            child: const Skin3D(AppAssets.journey3d, float: true),
          ),
          const SizedBox(height: 14),
          const Text('Mulai perjalanan kulitmu',
              textAlign: TextAlign.center, style: SkinTokens.section),
          const SizedBox(height: 8),
          const Text(
              'Simpan hasil scan pertama untuk membuka grafik, catatan kondisi, dan check-in mingguan.',
              textAlign: TextAlign.center,
              style: SkinTokens.caption),
          if (SkinJourneyStore.instance.isSelectedJourneyActive) ...[
            const SizedBox(height: 20),
            SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                    onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute<void>(
                            builder: (_) => const SkinQuizPage())),
                    icon: const Icon(Icons.camera_alt_outlined),
                    label: const Text('Mulai scan pertama'))),
          ],
        ]),
      );

  Widget _journeyStatusBanner(JourneyStatus status) {
    final (label, icon, tone) = switch (status) {
      JourneyStatus.active => (
          'Perjalanan aktif',
          Icons.play_circle_outline_rounded,
          SkinTone.primary,
        ),
      JourneyStatus.completed => (
          'Perjalanan ini telah selesai',
          Icons.task_alt_rounded,
          SkinTone.info,
        ),
      JourneyStatus.cancelled => (
          'Perjalanan ini dibatalkan',
          Icons.cancel_outlined,
          SkinTone.danger,
        ),
    };
    return SkinNotice(message: label, icon: icon, tone: tone, dense: true);
  }

  /// Satu urutan: riwayat, periode yang terlewat, check-in tersedia,
  /// dan jadwal masa depan yang dihitung dari baseline. Tidak memprediksi hasil.
  List<_Event> _plannedEvents(
      SkinJourneyStore store, SkinTimelineEngine engine) {
    if (!store.hasBaseline) return const [];
    final items = <_Event>[];
    for (int w = 0; w <= engine.maxHorizon; w++) {
      final active = engine.classesAt(w);
      if (active.isEmpty) continue;
      final due = engine.onWeek(w);
      final checkin = store.checkins
          .where((c) => SkinJourneyStore.sameDay(c.dueDate, due))
          .toList();
      final complete = checkin.isNotEmpty;
      final isDue =
          w > 0 && !complete && w == engine.currentWeek && store.hasCheckinDue;
      final isMissed = w > 0 && !complete && w < engine.currentWeek;
      final isPlanned = w > engine.currentWeek;
      final lines = <String>[];
      final classContent = <TimelineClassContent>[];
      for (final name in active) {
        final content = engine.content(name, w);
        classContent.add(content);
        final parts = <String>[content.message];
        if (content.focus.isNotEmpty) parts.add(content.focus);
        parts.addAll(content.notes);
        lines.add('$name\n${parts.join(' ')}');
      }
      if (isMissed) {
        lines.add(
            'Belum ada laporan pada minggu ini. Perubahan tidak diasumsikan sama.');
      }
      final review = active
          .where((name) =>
              w == engine.tracks[name]!.horizon &&
              !isPlanned &&
              engine.canClose(name))
          .toList();
      items.add(_Event(
          due,
          w == 0 ? 'Awal Skin Journey' : 'Check-in minggu $w',
          lines.join('\n\n'),
          w == 0
              ? Icons.flag_outlined
              : complete
                  ? Icons.check_circle_outline
                  : isDue
                      ? Icons.edit_calendar_outlined
                      : Icons.event_outlined,
          null,
          dueDate: isDue ? due : null,
          isPlanned: isPlanned,
          isMissed: isMissed,
          reviewNames: review,
          classItems: classContent,
          order: 2));
    }
    return items;
  }

  // Semua event masuk dalam SATU timeline kronologis, termasuk masa depan.
  // Tombol Mulai hanya muncul pada baris due, sesuai wireframe pengguna.
  Widget _timelineRow(BuildContext context, _Event e, bool last) {
    final isCurrentDue = e.dueDate != null;
    final isFuture = e.isPlanned || e.isResearch;
    final foreground = isFuture ? SkinTokens.muted : SkinTokens.ink;
    final String? label = e.isMissed
        ? 'TERLEWAT'
        : isCurrentDue
            ? (SkinJourneyStore.sameDay(e.date,
                    SkinJourneyStore.day(SkinJourneyStore.instance.today))
                ? 'HARI INI'
                : 'BELUM DIISI')
            : e.isResearch
                ? 'ACUAN RISET'
                : e.isPlanned
                    ? 'JADWAL'
                    : null;
    final labelTone = e.isMissed
        ? SkinTone.danger
        : isCurrentDue
            ? SkinTone.peach
            : SkinTone.neutral;
    return IntrinsicHeight(
        child: Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
            width: 40,
            child: Column(children: [
              Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                      gradient: isCurrentDue ? SkinTokens.brandGradient : null,
                      color: isCurrentDue
                          ? null
                          : isFuture
                              ? Colors.white
                              : SkinTokens.mint,
                      border: isFuture
                          ? Border.all(color: SkinTokens.border)
                          : null,
                      boxShadow: isCurrentDue
                          ? SkinTokens.glow(SkinTokens.primary, opacity: .25)
                          : null,
                      shape: BoxShape.circle),
                  child: Icon(e.icon,
                      color: isCurrentDue
                          ? Colors.white
                          : isFuture
                              ? SkinTokens.subtle
                              : SkinTokens.primaryDark,
                      size: 18)),
              if (!last)
                Expanded(
                    child: Container(
                        width: 2,
                        margin: const EdgeInsets.symmetric(vertical: 4),
                        decoration: BoxDecoration(
                          color: isFuture
                              ? SkinTokens.border
                              : SkinTokens.mintStrong,
                          borderRadius: BorderRadius.circular(1),
                        ))),
            ])),
        const SizedBox(width: 12),
        Expanded(
            child: Padding(
          padding: EdgeInsets.only(bottom: last ? 0 : 16),
          child: Container(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
            decoration: BoxDecoration(
              color: isFuture ? SkinTokens.glassSoft : SkinTokens.glassStrong,
              borderRadius: BorderRadius.circular(SkinTokens.radiusLg),
              border: Border.all(
                color: isCurrentDue ? SkinTokens.primary : Colors.white,
                width: isCurrentDue ? 1.4 : 1,
              ),
              boxShadow: isFuture ? null : SkinTokens.shadows,
            ),
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Text(_date(e.date),
                    style: const TextStyle(
                        color: SkinTokens.primary,
                        fontSize: 12,
                        fontWeight: FontWeight.w800)),
                if (label != null) ...[
                  const SizedBox(width: 8),
                  Flexible(
                    child: SkinPill(label: label, tone: labelTone, dense: true),
                  ),
                ],
              ]),
              const SizedBox(height: 6),
              Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Expanded(
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                      Text(e.title,
                          style: TextStyle(
                              color: foreground,
                              fontSize: 15,
                              fontWeight: FontWeight.w800)),
                      if (e.classItems.isEmpty && e.description.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(e.description, style: SkinTokens.caption),
                      ] else ...[
                        for (final item in e.classItems) ...[
                          const SizedBox(height: 10),
                          Row(children: [
                            Container(
                              width: 6,
                              height: 6,
                              decoration: const BoxDecoration(
                                color: SkinTokens.primary,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 7),
                            Expanded(
                              child: Text(item.name,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w800,
                                      color: SkinTokens.ink,
                                      fontSize: 13)),
                            ),
                          ]),
                          const SizedBox(height: 3),
                          Text(item.message, style: SkinTokens.caption),
                          if (item.focus.isNotEmpty) ...[
                            const SizedBox(height: 3),
                            Text(item.focus, style: SkinTokens.caption),
                          ],
                          for (final note in item.notes) ...[
                            const SizedBox(height: 4),
                            Text(note, style: SkinTokens.caption),
                          ],
                          if (item.source != 'Dokumentasi SkinSight')
                            Padding(
                                padding: const EdgeInsets.only(top: 4),
                                child: Text('Referensi: ${item.source}',
                                    style: const TextStyle(
                                        fontSize: 10.5,
                                        color: SkinTokens.subtle))),
                        ],
                        if (e.isMissed) ...[
                          const SizedBox(height: 6),
                          const Text(
                              'Tidak ada laporan check-in pada minggu ini.',
                              style: SkinTokens.caption),
                        ],
                      ],
                    ])),
                if (isCurrentDue) ...[
                  const SizedBox(width: 8),
                  FilledButton(
                    key: const Key('start-timeline-checkin'),
                    onPressed: () => Navigator.of(context).push(
                        MaterialPageRoute<void>(
                            builder: (_) => const SkinCheckinPage())),
                    style: FilledButton.styleFrom(
                        minimumSize: const Size(70, 38),
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                        textStyle: Theme.of(context)
                            .textTheme
                            .labelLarge!
                            .copyWith(
                                fontSize: 13, fontWeight: FontWeight.w800)),
                    child: const Text('Mulai'),
                  ),
                ],
              ]),
              // Check-in yang dilakukan pada hari yang sama tidak menciptakan
              // titik tanggal baru: rangkuman disisipkan ke event harian ini.
              for (final report in e.reports) ...[
                const SizedBox(height: 10),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: SkinTokens.surfaceAlt,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Laporan check-in',
                            style: TextStyle(
                                color: SkinTokens.ink,
                                fontSize: 12,
                                fontWeight: FontWeight.w800)),
                        const SizedBox(height: 4),
                        Text(
                            report.perClass.entries
                                .map((item) => '${item.key}: ${item.value}')
                                .join(' · '),
                            style: SkinTokens.caption),
                        const SizedBox(height: 3),
                        Text(
                            'Perawatan: ${report.treatment} · Iritasi: ${report.irritation}',
                            style: SkinTokens.caption),
                      ]),
                ),
              ],
              _photoSessions(context, e.photos),
              if (e.reviewNames.isNotEmpty) ...[
                const SizedBox(height: 8),
                for (final name in e.reviewNames)
                  TextButton.icon(
                      onPressed: () {
                        if (SkinJourneyStore.instance.closeCondition(name)) {
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                              content: Text(
                                  'Pemantauan $name diakhiri. Riwayat tetap tersimpan.')));
                        }
                      },
                      icon: const Icon(Icons.done_all, size: 16),
                      label: Text('Akhiri pemantauan $name')),
              ],
            ]),
          ),
        )),
      ],
    ));
  }

  Widget _panel({required Widget child}) => SkinCard(
        padding: const EdgeInsets.all(18),
        radius: SkinTokens.radiusXl,
        child: child,
      );
}

class _JourneyCompletionContent extends StatefulWidget {
  const _JourneyCompletionContent({required this.engine});

  final SkinTimelineEngine engine;

  @override
  State<_JourneyCompletionContent> createState() =>
      _JourneyCompletionContentState();
}

class _JourneyCompletionContentState extends State<_JourneyCompletionContent> {
  late final TextEditingController _feedbackController;
  late int _rating;

  @override
  void initState() {
    super.initState();
    final store = SkinJourneyStore.instance;
    _feedbackController = TextEditingController(text: store.feedbackComment);
    _rating = store.feedbackRating ?? 0;
  }

  @override
  void dispose() {
    _feedbackController.dispose();
    super.dispose();
  }

  String _metricValue(String condition, double value) {
    if (SkinJourneyStore.detectionClasses.contains(condition)) {
      return value.toInt().toString();
    }
    return '${(value * 100).toStringAsFixed(0)}%';
  }

  String _progressLabel(String condition) {
    final values = SkinJourneyStore.instance.metricHistory(condition);
    if (values.length < 2) return 'Belum dapat dibandingkan';
    final suffix = SkinJourneyStore.detectionClasses.contains(condition)
        ? ' temuan'
        : ' luas mask';
    return '${_metricValue(condition, values.first.value)} → '
        '${_metricValue(condition, values.last.value)}$suffix';
  }

  void _submitFeedback() {
    if (_rating == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pilih rating terlebih dahulu.')),
      );
      return;
    }
    if (_feedbackController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tulis feedback terlebih dahulu.')),
      );
      return;
    }
    if (SkinJourneyStore.instance
        .submitJourneyFeedback(_rating, _feedbackController.text)) {
      FocusScope.of(context).unfocus();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Feedback berhasil dikirim.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final store = SkinJourneyStore.instance;
    final submitted = store.feedbackSubmittedAt != null;
    final conditions = widget.engine.tracks.keys.toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SkinReveal(
          child: Container(
            key: const Key('journey-complete-banner'),
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              gradient: SkinTokens.warmGradient,
              borderRadius: BorderRadius.circular(SkinTokens.radiusXl),
              border: Border.all(color: const Color(0xFFFFFFFF)),
              boxShadow: SkinTokens.shadows,
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(18, 18, 12, 18),
              child: Row(
                children: [
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SkinPill(
                          label: 'SELESAI',
                          tone: SkinTone.peach,
                          icon: Icons.emoji_events_outlined,
                          dense: true,
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Perjalanan pemantauanmu selesai!',
                          style: TextStyle(
                            color: SkinTokens.ink,
                            fontSize: 18,
                            height: 1.25,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        SizedBox(height: 5),
                        Text(
                          'Kamu sudah mencapai akhir periode pemantauan yang dijadwalkan. Yuk, lihat kembali perubahan yang tercatat.',
                          style: SkinTokens.caption,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  SizedBox(
                    width: 84,
                    height: 84,
                    child: const Skin3D(AppAssets.celebrate3d, float: true),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 24),
        const SkinSectionTitle(
          title: 'Ringkasan perjalanan',
          subtitle:
              'Ringkasan menggunakan data yang tersimpan pada perjalanan ini.',
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            _SummaryMetric(
              value: '${widget.engine.maxHorizon}',
              label: 'Minggu',
              icon: Icons.date_range_rounded,
            ),
            const SizedBox(width: 10),
            _SummaryMetric(
              value: '${store.checkins.length}',
              label: 'Check-in',
              icon: Icons.task_alt_rounded,
            ),
            const SizedBox(width: 10),
            _SummaryMetric(
              value: '${store.photos.length}',
              label: 'Sesi foto',
              icon: Icons.photo_library_outlined,
            ),
          ],
        ),
        const SizedBox(height: 26),
        const SkinSectionTitle(
          title: 'Perkembangan kulit',
          subtitle:
              'Perbandingan hanya ditampilkan jika hasil foto memenuhi syarat kesebandingan.',
        ),
        const SizedBox(height: 12),
        SkinCard(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          child: conditions.isEmpty
              ? const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: Text(
                    'Belum ada kondisi dengan data yang dapat diringkas.',
                    style: SkinTokens.caption,
                  ),
                )
              : Column(
                  children: [
                    for (var i = 0; i < conditions.length; i++) ...[
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 11),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Text(
                                conditions[i],
                                style: const TextStyle(
                                  color: SkinTokens.ink,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            const SizedBox(width: 14),
                            Flexible(
                              child: Text(
                                _progressLabel(conditions[i]),
                                textAlign: TextAlign.right,
                                style: const TextStyle(
                                  color: SkinTokens.primaryDark,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (i < conditions.length - 1) const Divider(height: 1),
                    ],
                  ],
                ),
        ),
        const SizedBox(height: 26),
        SkinCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Bagaimana pengalamanmu?',
                style: SkinTokens.section,
              ),
              const SizedBox(height: 5),
              const Text(
                'Berikan rating dan ceritakan pengalamanmu selama menggunakan Skin Journey.',
                style: SkinTokens.caption,
              ),
              const SizedBox(height: 12),
              Row(
                key: const Key('journey-feedback-stars'),
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  for (var star = 1; star <= 5; star++)
                    IconButton(
                      key: Key('journey-feedback-star-$star'),
                      tooltip: '$star bintang',
                      padding: const EdgeInsets.all(5),
                      onPressed: submitted
                          ? null
                          : () => setState(() => _rating = star),
                      icon: Icon(
                        star <= _rating
                            ? Icons.star_rounded
                            : Icons.star_border_rounded,
                        color: star <= _rating
                            ? const Color(0xFFE4A72D)
                            : SkinTokens.subtle,
                        size: 32,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 10),
              TextField(
                key: const Key('journey-feedback-text'),
                controller: _feedbackController,
                enabled: !submitted,
                minLines: 3,
                maxLines: 5,
                maxLength: 500,
                decoration: const InputDecoration(
                  labelText: 'Feedback',
                  hintText:
                      'Tulis pengalamanmu selama menjalani pemantauan kulit.',
                  alignLabelWithHint: true,
                ),
              ),
              const SizedBox(height: 10),
              FilledButton(
                key: const Key('journey-feedback-submit'),
                onPressed: submitted ? null : _submitFeedback,
                child: Text(submitted ? 'Feedback terkirim' : 'Kirim'),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _SummaryMetric extends StatelessWidget {
  const _SummaryMetric({
    required this.value,
    required this.label,
    required this.icon,
  });

  final String value;
  final String label;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
        decoration: BoxDecoration(
          color: SkinTokens.glassStrong,
          borderRadius: BorderRadius.circular(SkinTokens.radiusLg),
          border: Border.all(color: Colors.white),
          boxShadow: SkinTokens.shadows,
        ),
        child: Column(
          children: [
            Icon(icon, size: 20, color: SkinTokens.primary),
            const SizedBox(height: 6),
            Text(
              value,
              style: const TextStyle(
                color: SkinTokens.ink,
                fontSize: 22,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: SkinTokens.caption.copyWith(fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}

class _Event {
  final DateTime date;
  final String title;
  final String description;
  final IconData icon;
  final Uint8List? thumbnail;
  final DateTime? dueDate;
  final bool isPlanned;
  final bool isResearch;
  final bool isMissed;
  final int order;
  final List<String> reviewNames;
  final List<TimelineClassContent> classItems;
  final List<JourneyPhoto> photos;
  final List<JourneyCheckin> reports;
  const _Event(this.date, this.title, this.description, this.icon,
      this.thumbnail,
      {this.dueDate,
      this.isPlanned = false,
      this.isResearch = false,
      this.isMissed = false,
      this.order = 0,
      this.reviewNames = const [],
      this.classItems = const [],
      this.photos = const [],
      this.reports = const []});
}

/// Penggabungan ini hanya mengubah PRESENTASI timeline; semua foto asli dan
/// laporan check-in tetap entitas terpisah di SkinJourneyStore.
class _DayBucket {
  final DateTime date;
  _Event? planned;
  final List<JourneyPhoto> photos = [];
  final List<JourneyCheckin> checkins = [];
  _DayBucket(this.date);

  _Event toEvent() {
    photos.sort((a, b) => a.date.compareTo(b.date));
    checkins.sort((a, b) => a.date.compareTo(b.date));
    final plan = planned;
    return _Event(
      date,
      plan?.title ?? (checkins.isNotEmpty ? 'Check-in kulit' : 'Sesi foto'),
      plan?.description ?? '',
      plan?.icon ??
          (checkins.isNotEmpty
              ? Icons.task_alt_rounded
              : Icons.camera_alt_outlined),
      null,
      dueDate: plan?.dueDate,
      isPlanned: plan?.isPlanned ?? false,
      isResearch: plan?.isResearch ?? false,
      isMissed: plan?.isMissed ?? false,
      reviewNames: plan?.reviewNames ?? const [],
      classItems: plan?.classItems ?? const [],
      photos: List.unmodifiable(photos),
      reports: List.unmodifiable(checkins),
    );
  }
}

/// Grafik jumlah temuan berdasarkan observasi sebanding, bukan skor kesehatan.
class _JourneyPlot extends CustomPainter {
  final List<JourneyMetric> points;
  final Color color;
  final bool detection;
  const _JourneyPlot(this.points, this.color, this.detection);

  @override
  void paint(Canvas canvas, Size size) {
    const top = 12.0;
    final bottom = size.height - 10;
    const left = 35.0;
    final right = size.width - 10;
    final ceiling = points.isEmpty
        ? 1.0
        : math.max(detection ? 1.0 : .05,
            points.map((p) => p.value).reduce(math.max) * 1.2);
    const textStyle = TextStyle(color: Color(0xFF9AA8A3), fontSize: 10);
    final grid = Paint()
      ..color = const Color(0xFFDCE5E0)
      ..strokeWidth = 1;
    for (int i = 0; i <= 3; i++) {
      final y = top + (bottom - top) * i / 3;
      for (var x = left; x < right; x += 8) {
        canvas.drawLine(Offset(x, y), Offset(math.min(x + 4, right), y), grid);
      }
      final val = ceiling * (3 - i) / 3;
      final painter = TextPainter(
          text: TextSpan(
              text: detection
                  ? val.round().toString()
                  : '${(val * 100).toStringAsFixed(0)}%',
              style: textStyle),
          textDirection: TextDirection.ltr)
        ..layout();
      painter.paint(canvas, Offset(0, y - painter.height / 2));
    }
    if (points.isEmpty) return;
    Offset point(int i) {
      final x = points.length == 1
          ? (left + right) / 2
          : left + (right - left) * i / (points.length - 1);
      final y = bottom - points[i].value / ceiling * (bottom - top);
      return Offset(x, y);
    }

    // Kurva halus (cubic) di antara titik pengamatan.
    final line = Path()..moveTo(point(0).dx, point(0).dy);
    for (int i = 1; i < points.length; i++) {
      final a = point(i - 1);
      final b = point(i);
      final midX = (a.dx + b.dx) / 2;
      line.cubicTo(midX, a.dy, midX, b.dy, b.dx, b.dy);
    }
    if (points.length > 1) {
      final fill = Path.from(line)
        ..lineTo(point(points.length - 1).dx, bottom)
        ..lineTo(point(0).dx, bottom)
        ..close();
      canvas.drawPath(
        fill,
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [color.withValues(alpha: .24), color.withValues(alpha: 0)],
          ).createShader(Rect.fromLTRB(left, top, right, bottom)),
      );
      canvas.drawPath(
          line,
          Paint()
            ..color = color
            ..strokeWidth = 3.2
            ..strokeCap = StrokeCap.round
            ..strokeJoin = StrokeJoin.round
            ..style = PaintingStyle.stroke);
    }
    for (int i = 0; i < points.length; i++) {
      final isLast = i == points.length - 1;
      if (isLast) {
        canvas.drawCircle(
            point(i), 10, Paint()..color = color.withValues(alpha: .16));
      }
      canvas.drawCircle(point(i), 5.6, Paint()..color = Colors.white);
      canvas.drawCircle(point(i), isLast ? 4.4 : 3.8, Paint()..color = color);
    }
  }

  @override
  bool shouldRepaint(covariant _JourneyPlot old) =>
      old.points != points || old.color != color || old.detection != detection;
}
