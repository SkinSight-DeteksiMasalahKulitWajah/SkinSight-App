import 'package:flutter/foundation.dart';
import 'skin_demo_data.dart';
import 'skin_timeline_engine.dart';

enum JourneyStatus { active, completed, cancelled }

enum CheckinPromptStatus { dueToday, lateThisWeek, resumedAfterMissedWeek }

/// Beberapa journey per pengguna. Setiap journey menyimpan data timeline-nya
/// sendiri; penghapusan bersifat soft-delete dan dapat dipulihkan dari sampah.
class SkinJourneyStore extends ChangeNotifier {
  SkinJourneyStore._() {
    _createJourney(explicitlyCreated: false);
  }
  static final SkinJourneyStore instance = SkinJourneyStore._();

  static const visualClasses = <String>[
    'Acne',
    'PIH',
    'Dark Circle',
    'Redness',
    'Wrinkle',
  ];
  static const detectionClasses = <String>['Acne', 'PIH', 'Dark Circle'];
  static const segmentationClasses = <String>['Redness', 'Wrinkle'];
  static const skinTypes = <String>['Oily', 'Dry', 'Normal', 'Combination'];

  final List<SkinJourneyRecord> _journeys = [];
  String? _selectedJourneyId;

  SkinJourneyRecord get selectedJourney => _journeys.firstWhere(
        (journey) => journey.id == _selectedJourneyId,
      );
  Map<String, String> get answers => selectedJourney.answers;
  List<JourneyPhoto> get photos => selectedJourney.photos;
  List<JourneyPhoto> get pendingPhotos => selectedJourney.pendingPhotos;
  List<JourneyCheckin> get checkins => selectedJourney.checkins;
  Map<String, DateTime> get closedConditions =>
      selectedJourney.closedConditions;
  DateTime? get baselineDate => selectedJourney.baselineDate;
  set baselineDate(DateTime? value) => selectedJourney.baselineDate = value;
  bool? get consent => selectedJourney.consent;
  set consent(bool? value) => selectedJourney.consent = value;

  List<SkinJourneyRecord> get journeys {
    final items = _journeys
        .where((journey) =>
            journey.deletedAt == null && journey.isVisibleInCatalog)
        .toList();
    items.sort((a, b) {
      if (a.isPinned != b.isPinned) return a.isPinned ? -1 : 1;
      return b.updatedAt.compareTo(a.updatedAt);
    });
    return List.unmodifiable(items);
  }

  List<SkinJourneyRecord> get trashedJourneys {
    final items = _journeys
        .where((journey) => journey.deletedAt != null)
        .toList()
      ..sort((a, b) => b.deletedAt!.compareTo(a.deletedAt!));
    return List.unmodifiable(items);
  }

  bool get isSelectedJourneyActive =>
      selectedJourney.status == JourneyStatus.active &&
      selectedJourney.deletedAt == null;
  String get selectedJourneyName => selectedJourney.name;
  JourneyStatus get selectedJourneyStatus => selectedJourney.status;
  int? get feedbackRating => selectedJourney.feedbackRating;
  String get feedbackComment => selectedJourney.feedbackComment;
  DateTime? get feedbackSubmittedAt => selectedJourney.feedbackSubmittedAt;

  bool get allTimelinesCompleted {
    if (!hasBaseline) return false;
    final tracks = timeline.tracks.values;
    return tracks.isNotEmpty &&
        tracks.every((track) => track.reviewState == 'end');
  }

  bool get shouldShowJourneyCompletion =>
      hasBaseline &&
      (selectedJourneyStatus == JourneyStatus.completed ||
          allTimelinesCompleted);

  DateTime? _testingDate;
  int _photoSequence = 0;
  DateTime get today => _testingDate ?? DateTime.now();
  // Pengujian logika dapat memakai tanggal virtual tanpa mengganti jam perangkat.
  void setTestingDate(DateTime? date) {
    _testingDate = date;
    notifyListeners();
  }

  SkinTimelineEngine get timeline => SkinTimelineEngine(this);
  Map<String, List<JourneyMetric>> get _demoHistory =>
      selectedJourney.demoHistory;
  bool get hasDemoHistory => _demoHistory.isNotEmpty;
  // Sumber snapshot DEMO yang sama dengan grafik: hanya data contoh, bukan
  // sesi foto pasien nyata. Ditampilkan sebagai peristiwa demo di timeline.
  List<JourneyDemoSnapshot> get demoSnapshots {
    final byDay = <DateTime, Map<String, double>>{};
    for (final entry in _demoHistory.entries) {
      for (final metric in entry.value) {
        final date = day(metric.date);
        byDay.putIfAbsent(date, () => <String, double>{})[entry.key] =
            metric.value;
      }
    }
    return [
      for (final entry in byDay.entries)
        JourneyDemoSnapshot(entry.key, Map.unmodifiable(entry.value))
    ]..sort((a, b) => a.date.compareTo(b.date));
  }

  bool get _checkinQuizDone => selectedJourney.checkinQuizDone;
  set _checkinQuizDone(bool value) => selectedJourney.checkinQuizDone = value;
  Map<String, String> get _draftReports => selectedJourney.draftReports;
  String get _draftCare => selectedJourney.draftCare;
  set _draftCare(String value) => selectedJourney.draftCare = value;
  String get _draftIrritation => selectedJourney.draftIrritation;
  set _draftIrritation(String value) => selectedJourney.draftIrritation = value;
  Map<String, Map<String, String>> get _draftFollowups =>
      selectedJourney.draftFollowups;
  DateTime? get _draftCareDate => selectedJourney.draftCareDate;
  set _draftCareDate(DateTime? value) => selectedJourney.draftCareDate = value;
  String get _draftCareNote => selectedJourney.draftCareNote;
  set _draftCareNote(String value) => selectedJourney.draftCareNote = value;
  Map<String, Map<String, String>> get draftFollowups => {
        for (final e in _draftFollowups.entries)
          e.key: Map.unmodifiable(e.value)
      };
  DateTime? get draftCareDate => _draftCareDate;
  String get draftCareNote => _draftCareNote;

  bool get questionnaireDone =>
      List.generate(7, (i) => 'M0${i + 1}').every(answers.containsKey);
  bool get hasBaseline => baselineDate != null;
  bool get baselineFinalized => hasBaseline; // manual save = baseline final
  bool get checkinQuizDone => _checkinQuizDone;
  Map<String, String> get draftReports => Map.unmodifiable(_draftReports);
  String get draftCare => _draftCare;
  String get draftIrritation => _draftIrritation;

  SkinJourneyRecord _createJourney({
    bool explicitlyCreated = true,
    bool isDraft = false,
    String? name,
  }) {
    final created = DateTime.now();
    final record = SkinJourneyRecord(
      id: 'journey-${created.microsecondsSinceEpoch}-${_journeys.length + 1}',
      name: name ?? _defaultJourneyName(created),
      createdAt: created,
      updatedAt: created,
      explicitlyCreated: explicitlyCreated,
      isDraft: isDraft,
    );
    _journeys.add(record);
    _selectedJourneyId = record.id;
    return record;
  }

  String _defaultJourneyName(DateTime date) {
    const months = [
      'Januari',
      'Februari',
      'Maret',
      'April',
      'Mei',
      'Juni',
      'Juli',
      'Agustus',
      'September',
      'Oktober',
      'November',
      'Desember',
    ];
    final base = 'Perjalanan Kulit · ${months[date.month - 1]} ${date.year}';
    final sameName = _journeys
        .where((journey) =>
            journey.isVisibleInCatalog &&
            (journey.name == base || journey.name.startsWith('$base (')))
        .length;
    return sameName == 0 ? base : '$base (${sameName + 1})';
  }

  SkinJourneyRecord beginNewJourney({String? name}) {
    final current = selectedJourney;
    if (!current.isVisibleInCatalog && current.isEmpty) {
      current.explicitlyCreated = true;
      current.isDraft = true;
      current.name = name?.trim().isNotEmpty == true
          ? name!.trim()
          : _defaultJourneyName(DateTime.now());
      current.updatedAt = DateTime.now();
      notifyListeners();
      return current;
    }
    _journeys.removeWhere((journey) => journey.isDraft);
    final journey = _createJourney(name: name, isDraft: true);
    notifyListeners();
    return journey;
  }

  void finalizeCurrentJourney(String name) {
    final journey = selectedJourney;
    final trimmed = name.trim();
    journey
      ..name =
          trimmed.isEmpty ? _defaultJourneyName(journey.createdAt) : trimmed
      ..explicitlyCreated = true
      ..isDraft = false
      ..updatedAt = DateTime.now();
    notifyListeners();
  }

  bool selectJourney(String id) {
    final exists = _journeys.any(
      (journey) => journey.id == id && journey.deletedAt == null,
    );
    if (!exists) return false;
    _selectedJourneyId = id;
    notifyListeners();
    return true;
  }

  void renameJourney(String id, String name) {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return;
    final journey = _findJourney(id);
    if (journey == null || journey.deletedAt != null) return;
    journey
      ..name = trimmed
      ..updatedAt = DateTime.now();
    notifyListeners();
  }

  void togglePin(String id) {
    final journey = _findJourney(id);
    if (journey == null || journey.deletedAt != null) return;
    journey
      ..isPinned = !journey.isPinned
      ..updatedAt = DateTime.now();
    notifyListeners();
  }

  void setJourneyStatus(String id, JourneyStatus status) {
    final journey = _findJourney(id);
    if (journey == null || journey.deletedAt != null) return;
    journey
      ..status = status
      ..updatedAt = DateTime.now();
    notifyListeners();
  }

  void moveJourneyToTrash(String id) {
    final journey = _findJourney(id);
    if (journey == null || journey.deletedAt != null) return;
    journey
      ..deletedAt = DateTime.now()
      ..isPinned = false
      ..updatedAt = DateTime.now();
    if (_selectedJourneyId == id) {
      final fallback = _journeys.where((item) =>
          item.id != id && item.deletedAt == null && item.isVisibleInCatalog);
      if (fallback.isNotEmpty) {
        _selectedJourneyId = fallback.first.id;
      } else {
        _createJourney(explicitlyCreated: false);
      }
    }
    notifyListeners();
  }

  void restoreJourney(String id) {
    final journey = _findJourney(id);
    if (journey == null || journey.deletedAt == null) return;
    journey
      ..deletedAt = null
      ..updatedAt = DateTime.now();
    notifyListeners();
  }

  SkinJourneyRecord? _findJourney(String id) {
    for (final journey in _journeys) {
      if (journey.id == id) return journey;
    }
    return null;
  }

  @visibleForTesting
  void resetForTesting() {
    _journeys.clear();
    _selectedJourneyId = null;
    _testingDate = null;
    _photoSequence = 0;
    _createJourney(explicitlyCreated: false);
    notifyListeners();
  }

  static DateTime day([DateTime? date]) {
    final d = date ?? DateTime.now();
    return DateTime(d.year, d.month, d.day);
  }

  static bool sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  int get currentWeek {
    if (baselineDate == null) return 0;
    final days = day(today).difference(day(baselineDate)).inDays;
    return days < 0 ? 0 : days ~/ 7;
  }

  bool get hasCheckinDue {
    if (!isSelectedJourneyActive || !hasBaseline || currentWeek < 1) {
      return false;
    }
    final engine = timeline;
    if (!engine.hasActiveTracks) return false;
    final due = day(baselineDate).add(Duration(days: currentWeek * 7));
    return !checkins.any((c) => sameDay(c.dueDate, due));
  }

  DateTime? get activeDueDate {
    if (!hasCheckinDue) return null;
    return day(baselineDate).add(Duration(days: currentWeek * 7));
  }

  CheckinPromptStatus? get checkinPromptStatus {
    final due = activeDueDate;
    if (due == null) return null;

    final engine = timeline;
    for (var week = 1; week < currentWeek; week++) {
      if (engine.classesAt(week).isEmpty) continue;
      final previousDue = day(baselineDate).add(Duration(days: week * 7));
      final wasCompleted =
          checkins.any((checkin) => sameDay(checkin.dueDate, previousDue));
      if (!wasCompleted) {
        return CheckinPromptStatus.resumedAfterMissedWeek;
      }
    }

    return sameDay(today, due)
        ? CheckinPromptStatus.dueToday
        : CheckinPromptStatus.lateThisWeek;
  }

  DateTime? get nextCheckin {
    if (!hasBaseline) return null;
    final days = day(today).difference(day(baselineDate)).inDays;
    final nextWeek = days < 0 ? 1 : days ~/ 7 + 1;
    return day(baselineDate).add(Duration(days: nextWeek * 7));
  }

  List<String> get userConcerns {
    final selected = (answers['M07'] ?? '').split('|');
    return visualClasses.where(selected.contains).toList();
  }

  List<String> get trackedConditions {
    final observed = photos.expand((p) => p.visualFindings).toSet();
    final existing = <String>{
      ...observed
    }; // M07 hanya memprioritaskan urutan, bukan menambah diagnosis.
    for (final checkin in checkins) {
      existing.addAll(checkin.perClass.keys);
    }
    return visualClasses.where(existing.contains).toList();
  }

  void saveQuestionnaire(Map<String, String> response,
      {bool photoConsent = false}) {
    answers
      ..clear()
      ..addAll(response);
    consent = photoConsent;
    selectedJourney
      ..explicitlyCreated = true
      ..updatedAt = DateTime.now();
    notifyListeners();
  }

  JourneyPhoto _makePhoto(
    Uint8List bytes, {
    List<String> visualFindings = const [],
    String? skinType,
    bool isDemo = false,
    double? skinTypeConfidence,
    bool modelConnected = false,
    Map<String, int> detectionCounts = const {},
    Map<String, double> segmentationAreas = const {},
    Map<String, double> confidences = const {},
    String pose = 'depan',
    String? modelVersion,
    String quality = 'unchecked',
  }) {
    final sequence = ++_photoSequence;
    final now = _testingDate == null
        ? DateTime.now()
        : day(_testingDate).add(Duration(hours: 12, seconds: sequence));
    return JourneyPhoto(
      id: 'photo-${DateTime.now().microsecondsSinceEpoch}-$sequence',
      date: now,
      bytes: bytes,
      visualFindings: List.unmodifiable(visualFindings),
      skinType: skinType,
      skinTypeConfidence: skinTypeConfidence,
      modelConnected: modelConnected,
      isDemo: isDemo,
      detectionCounts: Map.unmodifiable(detectionCounts),
      segmentationAreas: Map.unmodifiable(segmentationAreas),
      confidences: Map.unmodifiable(confidences),
      pose: pose,
      modelVersion: modelVersion,
      quality: quality,
    );
  }

  /// Hanya dipanggil sesudah pengguna memilih Simpan Hasil (baseline/scan bebas).
  void addPhoto(
    Uint8List bytes, {
    List<String> visualFindings = const [],
    String? skinType,
    bool isDemo = false,
    double? skinTypeConfidence,
    bool modelConnected = false,
    Map<String, int> detectionCounts = const {},
    Map<String, double> segmentationAreas = const {},
    Map<String, double> confidences = const {},
    String pose = 'depan',
    String? modelVersion,
    String quality = 'unchecked',
  }) {
    final photo = _makePhoto(bytes,
        visualFindings: visualFindings,
        skinType: skinType,
        skinTypeConfidence: skinTypeConfidence,
        modelConnected: modelConnected,
        isDemo: isDemo,
        detectionCounts: detectionCounts,
        segmentationAreas: segmentationAreas,
        confidences: confidences,
        pose: pose,
        modelVersion: modelVersion,
        quality: quality);
    photos.insert(0, photo);
    // Scan baru tidak membuat riwayat fiktif maupun memundurkan baseline.
    baselineDate ??= day(photo.date);
    selectedJourney
      ..explicitlyCreated = true
      ..updatedAt = DateTime.now();
    notifyListeners();
  }

  /// Halaman kiri menyimpan sesi ke draft, bukan otomatis mengonfirmasi check-in.
  void stagePhoto(Uint8List bytes, {String pose = 'depan'}) {
    final analysis = SkinDemoData.forPhoto(bytes,
        sessionIndex: photos.length + pendingPhotos.length);
    pendingPhotos.add(_makePhoto(bytes,
        pose: pose,
        visualFindings: analysis.visualFindings,
        skinType: analysis.skinType,
        skinTypeConfidence: analysis.skinTypeConfidence,
        isDemo: true,
        detectionCounts: analysis.detectionCounts,
        segmentationAreas: analysis.segmentationAreas,
        confidences: analysis.classConfidences,
        modelVersion: analysis.modelVersion,
        quality: 'pass'));
    notifyListeners();
  }

  void clearPendingPhoto(String id) {
    pendingPhotos.removeWhere((photo) => photo.id == id);
    notifyListeners();
  }

  void saveDraftQuiz(
      Map<String, String> perClass, String care, String irritation,
      {Map<String, Map<String, String>> followups = const {},
      DateTime? careDate,
      String careNote = ''}) {
    _draftReports
      ..clear()
      ..addAll(perClass);
    _draftCare = care;
    _draftIrritation = irritation;
    _draftFollowups
      ..clear()
      ..addAll({for (final e in followups.entries) e.key: Map.of(e.value)});
    _draftCareDate = careDate;
    _draftCareNote = careNote;
    _checkinQuizDone = true;
    notifyListeners();
  }

  /// Konfirmasi MANUAL pada hari yang sama; satu check-in per jadwal.
  bool confirmCheckin() {
    if (!isSelectedJourneyActive || !hasCheckinDue || !_checkinQuizDone) {
      return false;
    }
    final due = activeDueDate!;
    checkins.add(JourneyCheckin(
      date: today,
      dueDate: due,
      perClass: Map.unmodifiable(_draftReports),
      treatment: _draftCare,
      irritation: _draftIrritation,
      photoIds: List.unmodifiable(pendingPhotos.map((p) => p.id)),
      followup: {
        for (final e in _draftFollowups.entries)
          e.key: Map.unmodifiable(e.value)
      },
      careDate: _draftCareDate,
      careNote: _draftCareNote,
    ));
    photos.insertAll(0, pendingPhotos.reversed);
    pendingPhotos.clear();
    _draftReports.clear();
    _draftCare = '';
    _draftIrritation = '';
    _draftFollowups.clear();
    _draftCareDate = null;
    _draftCareNote = '';
    _checkinQuizDone = false;
    selectedJourney.updatedAt = DateTime.now();
    notifyListeners();
    return true;
  }

  bool closeCondition(String name) {
    if (!isSelectedJourneyActive || !timeline.canClose(name)) return false;
    closedConditions[name] = today;
    final trackNames = timeline.tracks.keys;
    if (trackNames.isNotEmpty &&
        trackNames.every(closedConditions.containsKey)) {
      selectedJourney.status = JourneyStatus.completed;
    }
    selectedJourney.updatedAt = DateTime.now();
    notifyListeners();
    return true;
  }

  bool submitJourneyFeedback(int rating, String comment) {
    final trimmed = comment.trim();
    if (!shouldShowJourneyCompletion ||
        rating < 1 ||
        rating > 5 ||
        trimmed.isEmpty) {
      return false;
    }
    selectedJourney
      ..feedbackRating = rating
      ..feedbackComment = trimmed
      ..feedbackSubmittedAt = DateTime.now()
      ..updatedAt = DateTime.now();
    notifyListeners();
    return true;
  }

  void reopenCondition(String name) {
    closedConditions.remove(name);
    notifyListeners();
  }

  bool isFinalized(DateTime date) =>
      checkins.any((c) => sameDay(c.date, date)) ||
      (baselineDate != null && sameDay(baselineDate!, date));

  /// Metrik grafik hanya dari observasi ML yang tersedia dan pose depan yang sebanding.
  /// Tidak menggabungkan beberapa foto pada hari sama. Pilih satu foto terbaru per hari.
  List<JourneyMetric> metricHistory(String condition) {
    final newestFirst = [...photos]..sort((a, b) => b.date.compareTo(a.date));
    final visited = <String>{};
    String? referenceModelVersion;
    final collected = <JourneyMetric>[];
    for (final photo in newestFirst) {
      if (!(photo.modelConnected || photo.isDemo) ||
          photo.pose != 'depan' ||
          photo.quality != 'pass') {
        continue;
      }
      if (photo.modelVersion == null || photo.modelVersion!.isEmpty) continue;
      referenceModelVersion ??= photo.modelVersion;
      if (photo.modelVersion != referenceModelVersion) continue;
      final key = '${photo.date.year}-${photo.date.month}-${photo.date.day}';
      if (visited.contains(key)) continue;
      final number = detectionClasses.contains(condition)
          ? photo.detectionCounts[condition]?.toDouble()
          : photo.segmentationAreas[condition];
      if (number == null) continue;
      visited.add(key);
      collected.add(JourneyMetric(photo.date, number, photo.id));
    }
    final actual = collected.reversed.toList();
    final demos = _demoHistory[condition] ?? const <JourneyMetric>[];
    return [...demos, ...actual]..sort((a, b) => a.date.compareTo(b.date));
  }
}

class SkinJourneyRecord {
  SkinJourneyRecord({
    required this.id,
    required this.name,
    required this.createdAt,
    required this.updatedAt,
    this.status = JourneyStatus.active,
    this.isPinned = false,
    this.explicitlyCreated = false,
    this.isDraft = false,
  });

  final String id;
  String name;
  final DateTime createdAt;
  DateTime updatedAt;
  JourneyStatus status;
  bool isPinned;
  bool explicitlyCreated;
  bool isDraft;
  DateTime? deletedAt;

  final Map<String, String> answers = {};
  final List<JourneyPhoto> photos = [];
  final List<JourneyPhoto> pendingPhotos = [];
  final List<JourneyCheckin> checkins = [];
  final Map<String, DateTime> closedConditions = {};
  final Map<String, List<JourneyMetric>> demoHistory = {};
  DateTime? baselineDate;
  bool? consent;
  bool checkinQuizDone = false;
  final Map<String, String> draftReports = {};
  String draftCare = '';
  String draftIrritation = '';
  final Map<String, Map<String, String>> draftFollowups = {};
  DateTime? draftCareDate;
  String draftCareNote = '';
  int? feedbackRating;
  String feedbackComment = '';
  DateTime? feedbackSubmittedAt;

  bool get isEmpty =>
      answers.isEmpty &&
      photos.isEmpty &&
      pendingPhotos.isEmpty &&
      checkins.isEmpty &&
      baselineDate == null;

  bool get isVisibleInCatalog => !isDraft && (explicitlyCreated || !isEmpty);

  List<String> get findings {
    final values = photos.expand((photo) => photo.visualFindings).toSet();
    return SkinJourneyStore.visualClasses.where(values.contains).toList();
  }
}

class JourneyMetric {
  final DateTime date;
  final double value;
  final String photoId;
  const JourneyMetric(this.date, this.value, this.photoId);
}

class JourneyPhoto {
  final String id;
  final DateTime date;
  final Uint8List bytes;
  final List<String> visualFindings;
  final String? skinType;
  final double? skinTypeConfidence;
  final bool modelConnected;
  final bool isDemo;
  final Map<String, int> detectionCounts;

  /// Rasio area segmentasi dari area wajah valid (0..1), bukan skor severity.
  final Map<String, double> segmentationAreas;
  final Map<String, double> confidences;
  final String pose;
  final String? modelVersion;
  final String quality;
  const JourneyPhoto(
      {required this.id,
      required this.date,
      required this.bytes,
      required this.visualFindings,
      required this.skinType,
      required this.skinTypeConfidence,
      required this.modelConnected,
      required this.isDemo,
      required this.detectionCounts,
      required this.segmentationAreas,
      required this.confidences,
      required this.pose,
      required this.modelVersion,
      required this.quality});
}

class JourneyCheckin {
  final DateTime date;
  final DateTime dueDate;
  final Map<String, String> perClass;
  final String treatment;
  final String irritation;
  final List<String> photoIds;
  final Map<String, Map<String, String>> followup;
  final DateTime? careDate;
  final String careNote;
  final bool isDemo;
  const JourneyCheckin(
      {required this.date,
      required this.dueDate,
      required this.perClass,
      required this.treatment,
      required this.irritation,
      required this.photoIds,
      this.isDemo = false,
      this.followup = const {},
      this.careDate,
      this.careNote = ''});
}

/// Snapshot angka fixture (tanpa foto), agar grafik demo dan timeline sejalan.
class JourneyDemoSnapshot {
  final DateTime date;
  final Map<String, double> values;
  const JourneyDemoSnapshot(this.date, this.values);
}
