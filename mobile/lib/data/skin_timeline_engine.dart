import 'dart:math' as math;
import 'skin_journey_store.dart';
import 'skin_timeline_policy.dart';

/// Hasil kebijakan UI terstruktur yang mengacu pada Rule Lab v1.3.
/// Tidak membuat keputusan pengobatan ataupun prediksi lama pemulihan.
class TimelineTrack {
  final String name;
  final DateTime firstDate;
  final int firstWeek;
  final double firstValue;
  double latestValue;
  Map<String, dynamic> band;
  int horizon;
  String? reviewState;
  final List<String> changes = [];
  final Map<int, List<String>> notices = {};
  TimelineTrack(this.name, this.firstDate, this.firstWeek, this.firstValue,
      this.latestValue, this.band, this.horizon);
  void note(DateTime when, DateTime baseline, String message) {
    final week = math.max(0, when.difference(baseline).inDays ~/ 7);
    notices.putIfAbsent(week, () => []).add(message);
  }
}

class TimelineClassContent {
  final String name;
  final String message;
  final String focus;
  final List<String> notes;
  final String source;
  const TimelineClassContent(
      this.name, this.message, this.focus, this.notes, this.source);
}

class SkinTimelineEngine {
  final SkinJourneyStore store;
  final DateTime now;
  late final Map<String, TimelineTrack> tracks = _buildTracks();
  SkinTimelineEngine(this.store, {DateTime? asOf})
      : now = SkinJourneyStore.day(asOf ?? store.today);

  static const names = SkinJourneyStore.visualClasses;
  static const sourceNames = <String, String>{
    'NICE_ACNE': 'NICE NG198',
    'AAD_ACNE': 'AAD Acne 2024',
    'AAD_PIH': 'American Academy of Dermatology',
    'AAD_RED': 'American Academy of Dermatology',
    'DOC_V04': 'Dokumentasi SkinSight',
  };

  DateTime get baseline => SkinJourneyStore.day(store.baselineDate!);
  int get currentWeek => store.baselineDate == null
      ? 0
      : math.max(0, now.difference(baseline).inDays ~/ 7);
  DateTime onWeek(int week) => baseline.add(Duration(days: 7 * week));
  int get maxHorizon => tracks.values.fold(0, (n, t) => math.max(n, t.horizon));
  bool get hasActiveTracks => tracks.values.any((t) =>
      t.reviewState != 'end' &&
      currentWeek >= t.firstWeek &&
      currentWeek <= t.horizon);
  List<String> classesAt(int week) {
    final active = tracks.values
        .where((t) =>
            week >= t.firstWeek && week <= t.horizon && t.reviewState != 'end')
        .map((t) => t.name)
        .toList();
    final priority = store.userConcerns;
    active.sort((a, b) {
      final aIndex = priority.indexOf(a), bIndex = priority.indexOf(b);
      final av = aIndex < 0 ? 999 : aIndex;
      final bv = bIndex < 0 ? 999 : bIndex;
      return av != bv
          ? av.compareTo(bv)
          : names.indexOf(a).compareTo(names.indexOf(b));
    });
    return active;
  }

  double? _value(JourneyPhoto p, String name) =>
      SkinJourneyStore.detectionClasses.contains(name)
          ? p.detectionCounts[name]?.toDouble()
          : p.segmentationAreas[name] == null
              ? null
              : p.segmentationAreas[name]! * 100;

  Map<String, dynamic>? _band(String name, double v) {
    if (v <= 0) return null;
    final key = _key(name);
    final c = (SkinTimelinePolicy.data['classes'] as Map<String, dynamic>)[key]
        as Map<String, dynamic>;
    for (final raw in (c['bands'] as List<dynamic>)) {
      final b = raw as Map<String, dynamic>;
      if (v >= (b['min'] as num).toDouble() &&
          (b['max'] == null || v <= (b['max'] as num).toDouble()) &&
          (b['max_exclusive'] == null ||
              v < (b['max_exclusive'] as num).toDouble())) {
        return b;
      }
    }
    return null;
  }

  String _key(String name) => name.toLowerCase().replaceAll(' ', '_');
  bool _good(JourneyPhoto p) =>
      p.quality == 'pass' && (p.modelConnected || p.isDemo);
  bool _comparable(JourneyPhoto a, JourneyPhoto b) =>
      _good(a) &&
      _good(b) &&
      a.pose == b.pose &&
      a.modelVersion == b.modelVersion &&
      (a.modelVersion ?? '').isNotEmpty;

  Map<String, TimelineTrack> _buildTracks() {
    final output = <String, TimelineTrack>{};
    if (!store.hasBaseline) return output;
    final scans = store.photos
        .where((p) => !SkinJourneyStore.day(p.date).isAfter(now) && _good(p))
        .toList()
      ..sort((a, b) => a.date.compareTo(b.date));
    final refs = <String, JourneyPhoto>{};
    // Hanya foto aktual yang disimpan. Tidak mengarang snapshot historis.
    for (final photo in scans) {
      for (final name in names) {
        final v = _value(photo, name);
        if (v == null || v < 0) continue;
        final t = output[name];
        if (t == null) {
          if (v <= 0) continue;
          final band = _band(name, v);
          if (band == null) continue;
          final week =
              math.max(0, (photo.date.difference(baseline).inDays / 7).ceil());
          output[name] = TimelineTrack(name, SkinJourneyStore.day(photo.date),
              week, v, v, band, week + (band['weeks'] as int));
          refs[name] = photo;
          continue;
        }
        if (!_comparable(refs[name]!, photo)) continue;
        t.latestValue = v;
        if (v > 0) {
          final next = _band(name, v);
          if (next == null) continue;
          if (next['code'] != t.band['code']) {
            t.changes.add('${t.band['code']} → ${next['code']}');
            t.note(photo.date, baseline,
                'Jumlah/luas temuan pada foto sebanding berpindah rentang pemantauan.');
            t.band = next;
          }
          // Band naik memperpanjang horizon; band turun tidak memotong sepihak.
          t.horizon = math.max(t.horizon, t.firstWeek + (next['weeks'] as int));
        }
      }
    }
    // Review otomatis: bila horizon sudah tiba dan ada observasi/laporan aktual
    // di jendela review, lanjutkan; tanpa data, tandai perlu review (tidak auto-loop).
    for (final t in output.values) {
      if (store.closedConditions.containsKey(t.name)) {
        final closedAt = store.closedConditions[t.name]!;
        final restarted = scans
            .where((p) =>
                SkinJourneyStore.day(p.date)
                    .isAfter(SkinJourneyStore.day(closedAt)) &&
                (_value(p, t.name) ?? 0) > 0)
            .toList();
        if (restarted.isNotEmpty) {
          storeClosedNote(t, restarted.first.date);
          final startWeek = math.max(
              0, (restarted.first.date.difference(baseline).inDays / 7).ceil());
          t.horizon = math.max(t.horizon, startWeek + (t.band['weeks'] as int));
        } else {
          t.reviewState = 'end';
          continue;
        }
      }
      var pass = 0;
      while (onWeek(t.horizon).isBefore(now.add(const Duration(days: 1))) &&
          pass++ < 12) {
        final reviewDate = onWeek(t.horizon);
        final windowStart = reviewDate
            .subtract(Duration(days: 7 * (t.band['extension_weeks'] as int)));
        final recentScans = scans
            .where((p) =>
                !p.date.isBefore(windowStart) &&
                !SkinJourneyStore.day(p.date).isAfter(now) &&
                _value(p, t.name) != null)
            .toList();
        final recentReports = store.checkins
            .where((c) =>
                !SkinJourneyStore.day(c.date).isAfter(now) &&
                !c.date.isBefore(windowStart) &&
                c.perClass.containsKey(t.name))
            .toList();
        if (recentScans.isEmpty && recentReports.isEmpty) {
          t.reviewState = 'pending';
          break;
        }
        if (canClose(t.name, asOf: now)) {
          t.reviewState = 'review';
          break;
        }
        final worse = recentReports.any((c) =>
            c.perClass[t.name] == 'Memburuk' || c.irritation == 'Sedang-berat');
        t.note(
            reviewDate,
            baseline,
            worse
                ? 'Keluhan dilaporkan memburuk; observasi diteruskan dan keluhan perlu ditinjau.'
                : 'Pemantauan dilanjutkan karena data belum memenuhi syarat penutupan.');
        t.horizon += t.band['extension_weeks'] as int;
      }
    }
    return output;
  }

  void storeClosedNote(TimelineTrack t, DateTime at) {
    t.note(at, baseline,
        'Temuan kembali tercatat setelah pemantauan sebelumnya berakhir. Pemantauan aktif kembali.');
    t.reviewState = 'reopened';
  }

  bool canClose(String name, {DateTime? asOf}) {
    final cutoff = asOf ?? now;
    final valid = store.photos
        .where((p) =>
            !SkinJourneyStore.day(p.date).isAfter(cutoff) &&
            _good(p) &&
            _value(p, name) != null)
        .toList()
      ..sort((a, b) => a.date.compareTo(b.date));
    if (valid.length < 2) return false;
    final last = valid.last, previous = valid[valid.length - 2];
    if (!_comparable(previous, last) ||
        SkinJourneyStore.sameDay(previous.date, last.date) ||
        _value(previous, name) != 0 ||
        _value(last, name) != 0) return false;
    final reports = store.checkins.where((c) =>
        !SkinJourneyStore.day(c.date).isAfter(cutoff) &&
        !c.date.isBefore(last.date) &&
        (c.perClass[name] == 'Sama' || c.perClass[name] == 'Membaik') &&
        c.irritation != 'Sedang-berat');
    return reports.isNotEmpty;
  }

  TimelineClassContent content(String name, int week) {
    final t = tracks[name]!;
    final relative = week - t.firstWeek;
    final c = (SkinTimelinePolicy.data['classes']
        as Map<String, dynamic>)[_key(name)] as Map<String, dynamic>;
    final weekly = (c['weekly'] as List<dynamic>);
    final extra = (c['additional_weeks'] as Map<String, dynamic>);
    var message = relative < weekly.length
        ? weekly[relative] as String
        : (extra['$relative'] as String?) ??
            'Catat laporan pengguna, perubahan perawatan, dan foto yang sebanding.';
    final initialWeeks = t.band['weeks'] as int;
    final phase = relative == 0
        ? 'start'
        : relative == 1
            ? 'first_checkin'
            : week == t.horizon
                ? 'review'
                : relative > initialWeeks
                    ? 'extension'
                    : relative <= initialWeeks / 2
                        ? 'early'
                        : 'middle';
    final stage = t.band['stage_messages'] as Map<String, dynamic>;
    final details = <String>[];
    if (name == 'Acne' && relative == 2 && store.answers['M01'] != 'Ya') {
      message =
          'Belum ada perawatan yang dilaporkan. Catat bila memulai perawatan, tanpa mengasumsikan respons terapi.';
    }
    if (name == 'Redness' && relative == 2 && store.answers['M04'] == 'Tidak') {
      message =
          'Catat bila muncul iritasi atau pemicu baru; jangan mengarang penyebab kemerahan.';
    }
    final date = onWeek(week);
    if (relative <= 1) {
      if (store.answers['M03'] == 'Sedang-berat')
        details.add(
            'Keluhan iritasi sedang–berat perlu ditinjau tenaga kesehatan.');
      if (store.answers['M06'] == 'Ya')
        details.add(
            'Sedang dalam perawatan dokter; jangan mengubah terapi sendiri.');
      if (store.answers['M01'] == 'Tidak' && name == 'Acne')
        details.add('Belum ada perawatan yang dilaporkan.');
      if (store.answers['M04'] == 'Ya')
        details.add('Perhatikan riwayat reaksi terhadap produk.');
      if (store.photos.isNotEmpty) {
        final type = store.photos.last.skinType;
        final message = switch (type) {
          'Dry' =>
            'Kulit cenderung kering: perhatikan kenyamanan dan kelembapan.',
          'Oily' =>
            'Pilih perawatan ringan yang tidak menyumbat pori bila diperlukan.',
          'Combination' => 'Kebutuhan area T-zone dan pipi bisa berbeda.',
          'Normal' =>
            'Tetap sesuaikan perawatan dengan keluhan yang dirasakan.',
          _ => null,
        };
        if (message != null) details.add(message);
      }
    }
    final past = _latestReport(name, date.subtract(const Duration(days: 1)));
    if (past != null) {
      final status = past.perClass[name];
      if (status == 'Memburuk')
        details.add(
            'Pada laporan sebelumnya kondisi dirasakan memburuk. Pantau keluhan dan pemicunya.');
      if (status == 'Tidak yakin')
        details.add('Perubahan sebelumnya belum dapat dipastikan.');
      if (past.irritation == 'Sedang-berat')
        details.add(
            'Iritasi sedang–berat pernah dilaporkan; utamakan keselamatan.');
      if (past.treatment == 'Berubah')
        details.add(
            'Perawatan berubah. Jadwal evaluasi lama tidak otomatis berlaku.');
      final answers = past.followup[name] ?? const <String, String>{};
      if (name == 'Acne' && answers['pain_scars'] == 'ya')
        details.add(
            'Keluhan jerawat dalam/nyeri atau bekas parut perlu evaluasi profesional.');
      if (name == 'PIH' &&
          (answers['uv'] == 'tidak' || answers['uv'] == 'kadang'))
        details.add('Tinjau lagi kebiasaan perlindungan UV yang dilaporkan.');
      if (name == 'Redness' && answers['burning'] == 'ya')
        details.add('Tanyakan apakah perih atau panas masih berlangsung.');
      if (name == 'Dark Circle' && answers['lighting'] == 'tidak')
        details.add(
            'Foto sebelumnya tidak sebanding; jangan menyimpulkan tren dari jumlah objek.');
      if (name == 'Wrinkle' && answers['expression'] == 'tidak')
        details.add(
            'Ekspresi foto sebelumnya berbeda; perbandingan perlu hati-hati.');
    }
    if ((name == 'PIH' || name == 'Wrinkle')) {
      final uv = _latestUv(name, date);
      if (uv == 'Tidak' || uv == 'Kadang')
        details.add(
            'Perlindungan UV dilaporkan belum rutin; tinjau penggunaan sunscreen.');
      if (uv == 'Rutin' &&
          (store.answers['M05'] == 'Tidak' || store.answers['M05'] == 'Kadang'))
        details.add('Penggunaan sunscreen kini dilaporkan rutin.');
    }
    final start = DateTime.tryParse(store.answers['regimen_start'] ?? '');
    final regimenClass = store.answers['regimen_class'];
    final applicable = store.answers['M01'] == 'Ya' &&
        start != null &&
        (regimenClass == name ||
            regimenClass == null && store.trackedConditions.length == 1) &&
        (past == null ||
            (past.treatment != 'Berubah' && past.treatment != 'Tidak'));
    if (applicable && !date.isBefore(start)) {
      final treatmentWeek = date.difference(start).inDays ~/ 7;
      if (name == 'Acne' && [6, 7, 8].contains(treatmentWeek))
        details.add(
            'Sebagian terapi Acne mulai menunjukkan manfaat pada 6–8 minggu sejak dimulai (NICE).');
      if (name == 'Acne' && treatmentWeek == 12)
        details.add(
            'Pedoman NICE membahas evaluasi terapi sekitar minggu ke-12 sejak dimulai.');
      if (name == 'PIH' && [4, 8, 12].contains(treatmentWeek))
        details.add(
            'Penelitian PIH tertentu melakukan evaluasi pada minggu 4, 8, dan 12 sejak terapi.');
      if (name == 'Wrinkle' && [12, 16, 24].contains(treatmentWeek))
        details.add(
            'Sejumlah penelitian photoaging menilai hasil setelah beberapa bulan terapi.');
    }
    final current = _reportAtWeek(name, week);
    if (current != null) {
      details.add('Menurut pengguna: ${current.perClass[name]}.');
      final conflict = _conflict(name, current);
      if (conflict)
        details.add(
            'Laporan pengguna dan temuan foto berbeda arah. Keduanya perlu dibaca terpisah.');
      final f = current.followup[name] ?? const <String, String>{};
      if (name == 'Acne' && f['new_lesions'] == 'ya')
        details.add('Pengguna melaporkan jerawat baru.');
      if (name == 'Acne' && f['pain_scars'] == 'ya')
        details.add(
            'Ada keluhan jerawat nyeri/dalam atau bekas parut; pertimbangkan pemeriksaan profesional.');
      if (name == 'PIH' && f['new_spots'] == 'ya')
        details.add('Pengguna melaporkan noda baru.');
      if (name == 'Redness' && f['burning'] == 'ya')
        details.add('Pengguna melaporkan perih atau panas.');
      if (name == 'Redness' && f['new_product_reaction'] == 'ya')
        details.add('Ada reaksi terhadap produk baru yang dilaporkan.');
    }
    final notices = t.notices[week];
    if (notices != null) details.addAll(notices);
    final sourceIndex = relative < weekly.length ? relative : weekly.length - 1;
    String source = 'Dokumentasi SkinSight';
    if (c['weekly_evidence_ids'] is List) {
      final refs = (c['weekly_evidence_ids'] as List<dynamic>);
      if (sourceIndex < refs.length) {
        final ref = refs[sourceIndex];
        final ids = ref is List ? ref : [ref];
        source = ids
            .map((x) => sourceNames[x.toString()] ?? 'Literatur referensi')
            .toSet()
            .join(' · ');
      }
    }
    String cleaner(String value) => value
        .replaceAll('ROI', 'area wajah')
        .replaceAll('(M01, M02)', 'yang dilaporkan')
        .replaceAll('pada foto contoh', 'pada foto')
        .replaceAll('hasil teknis', 'hasil pengamatan')
        .replaceAll('kategori klinis NICE', 'diagnosis tingkat keparahan')
        .replaceAll('UX', 'pemantauan');
    return TimelineClassContent(
        name,
        cleaner(message),
        cleaner(stage[phase] as String? ?? ''),
        details.map(cleaner).toList(),
        source);
  }

  JourneyCheckin? _latestReport(String name, DateTime before) {
    final reports = store.checkins
        .where((c) =>
            !SkinJourneyStore.day(c.date).isAfter(before) &&
            c.perClass.containsKey(name))
        .toList()
      ..sort((a, b) => a.date.compareTo(b.date));
    return reports.isEmpty ? null : reports.last;
  }

  JourneyCheckin? _reportAtWeek(String name, int week) {
    for (final c in store.checkins.reversed) {
      if (SkinJourneyStore.sameDay(c.dueDate, onWeek(week)) &&
          !SkinJourneyStore.day(c.date).isAfter(now) &&
          c.perClass.containsKey(name)) return c;
    }
    return null;
  }

  String _latestUv(String name, DateTime when) {
    final reports = store.checkins
        .where((c) =>
            !SkinJourneyStore.day(c.date).isAfter(when) &&
            c.followup[name]?.containsKey('uv') == true)
        .toList()
      ..sort((a, b) => a.date.compareTo(b.date));
    if (reports.isNotEmpty) {
      return switch (reports.last.followup[name]!['uv']) {
        'rutin' => 'Rutin',
        'kadang' => 'Kadang',
        'tidak' => 'Tidak',
        _ => 'Tidak tahu'
      };
    }
    return store.answers['M05'] ?? 'Tidak tahu';
  }

  bool _conflict(String name, JourneyCheckin c) {
    final relevant = store.photos
        .where((p) =>
            _good(p) &&
            !SkinJourneyStore.day(p.date)
                .isAfter(SkinJourneyStore.day(c.date)) &&
            _value(p, name) != null)
        .toList()
      ..sort((a, b) => a.date.compareTo(b.date));
    if (relevant.length < 2) return false;
    final a = relevant[relevant.length - 2], b = relevant.last;
    if (!_comparable(a, b) || !SkinJourneyStore.sameDay(b.date, c.date))
      return false;
    final diff = _value(b, name)! - _value(a, name)!;
    final status = c.perClass[name];
    return (status == 'Membaik' && diff > 0) ||
        (status == 'Memburuk' && diff < 0) ||
        (status == 'Sama' && diff != 0);
  }
}
