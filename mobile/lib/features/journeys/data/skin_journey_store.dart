import 'dart:async';
import 'dart:convert';
import 'dart:math' show Random;
import 'dart:ui' show Rect;
import 'package:flutter/foundation.dart';
import '../../../core/api/api_client.dart';
import '../../../core/api/cloud_storage.dart';
import '../../../core/api/cloud_sync.dart';
import '../../../core/api/supabase_direct.dart';
import '../../../core/cache/local_cache.dart';
import'../../scan/data/skin_demo_data.dart';
import'../../scan/models/skin_analysis.dart';
import'../../progress/domain/skin_timeline_engine.dart';

enum JourneyStatus { active, completed, cancelled }

enum CheckinPromptStatus { dueToday, lateThisWeek, resumedAfterMissedWeek }

/// Beberapa journey per pengguna. Setiap journey menyimpan data timeline-nya
/// sendiri; penghapusan bersifat soft-delete dan dapat dipulihkan dari sampah.
class SkinJourneyStore extends ChangeNotifier
    implements CloudSyncable, LocalCacheable {
  SkinJourneyStore._() {
    _createJourney(explicitlyCreated: false);
    addListener(_scheduleSync);
    addListener(_scheduleCacheSave);
  }
  static final SkinJourneyStore instance = SkinJourneyStore._();

  static const visualClasses = <String>[
    'Acne',
    'PIH',
    'Dark Circle',
    'Redness',
    'Wrinkle',
  ];
  static const detectionClasses = <String>[
    'Acne',
    'PIH',
    'Dark Circle',
    'Redness',
    'Wrinkle',
  ];
  static const segmentationClasses = <String>[];
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

  /// Seluruh check-in dari semua perjalanan aktif/selesai (tidak di sampah),
  /// urut dari yang terbaru. Dipakai oleh Riwayat & Aktivitas Terbaru di Home.
  List<JourneyCheckin> get allCheckins {
    final items = <JourneyCheckin>[
      for (final j in _journeys)
        if (j.deletedAt == null) ...j.checkins,
    ]..sort((a, b) => b.date.compareTo(a.date));
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
      id: _uuidV4(),
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

  void deleteJourneyPermanently(String id) {
    final before = _journeys.length;
    _journeys.removeWhere((journey) => journey.id == id);
    if (_journeys.length == before) return;
    _lastSynced.remove(id);
    _remoteIds.remove(id);
    _remoteDeleted.remove(id);
    _syncedCheckinIds.remove(id);
    if (_selectedJourneyId == id) {
      final fallback = _journeys.where(
          (item) => item.deletedAt == null && item.isVisibleInCatalog);
      if (fallback.isNotEmpty) {
        _selectedJourneyId = fallback.first.id;
      } else {
        _createJourney(explicitlyCreated: false);
      }
    }
    notifyListeners();
    if (_canSync) {
      unawaited(_deleteJourneyPermanentlyRemote(id));
    }
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
    Rect? faceRect,
    List<SkinVisualBox> visualBoxes = const [],
    int? imageWidth,
    int? imageHeight,
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
      faceRect: faceRect,
      visualBoxes: List.unmodifiable(visualBoxes),
      imageWidth: imageWidth,
      imageHeight: imageHeight,
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
    Rect? faceRect,
    List<SkinVisualBox> visualBoxes = const [],
    int? imageWidth,
    int? imageHeight,
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
        quality: quality,
        faceRect: faceRect,
        visualBoxes: visualBoxes,
        imageWidth: imageWidth,
        imageHeight: imageHeight);
    photos.insert(0, photo);
    // Scan baru tidak membuat riwayat fiktif maupun memundurkan baseline.
    baselineDate ??= day(photo.date);
    selectedJourney
      ..isDraft = false
      ..explicitlyCreated = true
      ..updatedAt = DateTime.now();
    notifyListeners();
  }

  /// Stores an already analyzed on-device scan in the check-in draft.
  /// Unlike stagePhoto, this method never generates demo detection values.
  void stageAnalysis(SkinAnalysis analysis, {String pose = 'depan'}) {
    final bytes = analysis.selfieBytes;
    if (bytes == null || bytes.isEmpty) {
      throw ArgumentError('Hasil scan tidak memiliki foto sumber.');
    }
    pendingPhotos.add(_makePhoto(
      bytes,
      pose: pose,
      visualFindings: analysis.visualFindings,
      skinType: analysis.skinType,
      skinTypeConfidence: analysis.skinTypeConfidence,
      modelConnected: analysis.modelConnected,
      isDemo: analysis.isDemo,
      detectionCounts: analysis.detectionCounts,
      segmentationAreas: analysis.segmentationAreas,
      confidences: analysis.classConfidences,
      modelVersion: analysis.modelVersion,
      quality: analysis.modelConnected ? 'pass' : 'unchecked',
      faceRect: analysis.faceRect,
      visualBoxes: analysis.visualBoxes,
      imageWidth: analysis.imageWidth,
      imageHeight: analysis.imageHeight,
    ));
    notifyListeners();
  }

  /// Legacy demo-only entry point. Production scan UI calls stageAnalysis.
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
      id: _uuidV4(),
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

  bool completeSelectedJourneyForDemo() {
    if (!isSelectedJourneyActive) return false;
    for (final trackName in timeline.tracks.keys) {
      closedConditions[trackName] = today;
    }
    selectedJourney.status = JourneyStatus.completed;
    selectedJourney.updatedAt = DateTime.now();
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
  // ------------------------------------------------------------------
  // Sinkronisasi dengan backend (tabel skin_journeys & journey_checkins).
  // Foto disimpan di Supabase Storage; struktur lengkap journey disimpan di
  // kolom `meta` agar timeline/grafik dapat dipulihkan persis di perangkat lain.
  // ------------------------------------------------------------------
  final Map<String, String> _lastSynced = {};
  final Set<String> _remoteIds = {};
  final Set<String> _remoteDeleted = {};
  final Map<String, Set<String>> _syncedCheckinIds = {};
  final Map<String, String> _photoPaths = {};
  Timer? _syncTimer;
  Future<void>? _activeSync;
  Future<void>? _activePull;
  bool _syncing = false;
  bool _pulling = false;
  bool _hasLoadedFromServer = false;
  bool _syncAgain = false;
  bool _applyingRemote = false;

  ApiClient get _api => ApiClient.instance;

  bool get _canSync => _api.isAvailable || SupabaseDirect.isSignedIn;
  bool get isSyncing => _pulling;
  bool get hasLoadedFromServer => _hasLoadedFromServer;

  void _scheduleSync() {
    if (_applyingRemote || !_canSync) return;
    _syncTimer?.cancel();
    _syncTimer =
        Timer(const Duration(milliseconds: 350), () => unawaited(_syncDirty()));
  }

  /// Segera sinkronkan semua perjalanan kotor ke backend/Supabase (tanpa menunggu debounce).
  Future<void> syncNow() => flushPending();

  @override
  Future<void> flushPending() async {
    _syncTimer?.cancel();
    _syncTimer = null;
    if (!_canSync) return;
    if (_activeSync != null) {
      await _activeSync;
    }
    await _syncDirty();
  }

  Future<void> _deleteJourneyPermanentlyRemote(String id) async {
    if (_api.shouldAttemptBackend) {
      try {
        await _api.delete('/journeys/$id', query: {'permanent': 'true'});
        return;
      } on Object catch (e) {
        debugPrint(
            'Hapus permanen journey via backend gagal, fallback ke Supabase: $e');
      }
    }
    try {
      await SupabaseDirect.deleteJourneyPermanently(id);
    } on Object catch (e) {
      debugPrint('Hapus permanen journey di Supabase gagal: $e');
    }
  }

  static String _uuidV4() {
    final rnd = Random.secure();
    final b = List<int>.generate(16, (_) => rnd.nextInt(256));
    b[6] = (b[6] & 0x0f) | 0x40;
    b[8] = (b[8] & 0x3f) | 0x80;
    String h(int i) => b[i].toRadixString(16).padLeft(2, '0');
    return '${h(0)}${h(1)}${h(2)}${h(3)}-${h(4)}${h(5)}-${h(6)}${h(7)}-'
        '${h(8)}${h(9)}-${h(10)}${h(11)}${h(12)}${h(13)}${h(14)}${h(15)}';
  }

  Map<String, dynamic> _photoMeta(JourneyPhoto p) => {
        'id': p.id,
        'date': p.date.toIso8601String(),
        'visual_findings': p.visualFindings,
        'skin_type': p.skinType,
        'skin_type_confidence': p.skinTypeConfidence,
        'model_connected': p.modelConnected,
        'is_demo': p.isDemo,
        'detection_counts': p.detectionCounts,
        'segmentation_areas': p.segmentationAreas,
        'confidences': p.confidences,
        'pose': p.pose,
        'model_version': p.modelVersion,
        'quality': p.quality,
        'image_width': p.imageWidth,
        'image_height': p.imageHeight,
        if (p.faceRect != null)
          'face_rect': [
            p.faceRect!.left,
            p.faceRect!.top,
            p.faceRect!.right,
            p.faceRect!.bottom,
          ],
        'visual_boxes': [for (final b in p.visualBoxes) b.toJson()],
        'image_path': _photoPaths[p.id],
      };

  Map<String, dynamic> _journeyMeta(SkinJourneyRecord j) => {
        'answers': j.answers,
        'consent': j.consent,
        'baseline_date': j.baselineDate?.toIso8601String(),
        'closed_conditions': {
          for (final e in j.closedConditions.entries)
            e.key: e.value.toIso8601String(),
        },
        'feedback_rating': j.feedbackRating,
        'feedback_comment': j.feedbackComment,
        'feedback_submitted_at': j.feedbackSubmittedAt?.toIso8601String(),
        'explicitly_created': j.explicitlyCreated,
        'created_at': j.createdAt.toIso8601String(),
        'updated_at': j.updatedAt.toIso8601String(),
        'photos': [for (final p in j.photos) _photoMeta(p)],
      };

  Map<String, dynamic> _journeyBody(SkinJourneyRecord j) => {
        'title': j.name,
        'target_concern': j.findings.isEmpty ? 'Umum' : j.findings.first,
        'status': j.status.name,
        'start_date':
            (j.baselineDate ?? j.createdAt).toIso8601String().substring(0, 10),
        'is_pinned': j.isPinned,
        'meta': _journeyMeta(j),
      };

  Map<String, dynamic> _checkinMeta(JourneyCheckin c) => {
        'date': c.date.toIso8601String(),
        'due_date': c.dueDate.toIso8601String(),
        'per_class': c.perClass,
        'treatment': c.treatment,
        'irritation': c.irritation,
        'photo_ids': c.photoIds,
        'followup': c.followup,
        'care_date': c.careDate?.toIso8601String(),
        'care_note': c.careNote,
      };

  Future<void> _syncDirty() async {
    if (!_canSync) return;
    if (_syncing) {
      _syncAgain = true;
      return;
    }
    _syncing = true;
    final completer = Completer<void>();
    _activeSync = completer.future;
    try {
      for (final journey in List.of(_journeys)) {
        if (!journey.isVisibleInCatalog) continue;
        try {
          await _syncJourney(journey);
        } on Object catch (e) {
          debugPrint('Sinkron journey ${journey.id} gagal: $e');
        }
      }
    } finally {
      _syncing = false;
      if (!completer.isCompleted) completer.complete();
      if (_syncAgain) {
        _syncAgain = false;
        _scheduleSync();
      }
    }
  }

  Future<void> _syncJourney(SkinJourneyRecord j) async {
    for (final photo in j.photos) {
      if (_photoPaths.containsKey(photo.id) || photo.bytes.isEmpty) continue;
      final path =
          await CloudStorage.upload('journeys/${photo.id}.jpg', photo.bytes);
      if (path != null) _photoPaths[photo.id] = path;
    }

    final body = _journeyBody(j);
    final fingerprint = jsonEncode(body);
    if (_lastSynced[j.id] != fingerprint) {
      var savedViaBackend = false;
      if (_api.shouldAttemptBackend) {
        try {
          if (_remoteIds.contains(j.id)) {
            await _api.put('/journeys/${j.id}', body: body);
          } else {
            try {
              await _api.post('/journeys', body: {'id': j.id, ...body});
            } on ApiException catch (e) {
              if (e.statusCode != 409) rethrow;
              await _api.put('/journeys/${j.id}', body: body);
            }
          }
          savedViaBackend = true;
        } on Object catch (e) {
          debugPrint(
              'Simpan journey via backend gagal, fallback ke Supabase: $e');
        }
      }
      if (!savedViaBackend) {
        await SupabaseDirect.upsertJourney(j.id, body);
      }
      _remoteIds.add(j.id);
      _lastSynced[j.id] = fingerprint;
    }

    final deleted = j.deletedAt != null;
    if (deleted && !_remoteDeleted.contains(j.id)) {
      var done = false;
      if (_api.shouldAttemptBackend) {
        try {
          await _api.delete('/journeys/${j.id}');
          done = true;
        } on Object catch (e) {
          debugPrint('Soft-delete journey via backend gagal, fallback: $e');
        }
      }
      if (!done) {
        await SupabaseDirect.setJourneyDeletedAt(j.id, j.deletedAt);
      }
      _remoteDeleted.add(j.id);
    } else if (!deleted && _remoteDeleted.contains(j.id)) {
      var done = false;
      if (_api.shouldAttemptBackend) {
        try {
          await _api.post('/journeys/${j.id}/restore');
          done = true;
        } on Object catch (e) {
          debugPrint('Restore journey via backend gagal, fallback: $e');
        }
      }
      if (!done) {
        await SupabaseDirect.setJourneyDeletedAt(j.id, null);
      }
      _remoteDeleted.remove(j.id);
    }

    final syncedIds = _syncedCheckinIds.putIfAbsent(j.id, () => <String>{});
    for (final c in j.checkins) {
      final cid = c.id ?? _uuidV4();
      if (syncedIds.contains(cid)) continue;
      final checkinBody = {
        'id': cid,
        'journey_id': j.id,
        'checkin_date': c.date.toIso8601String().substring(0, 10),
        'notes':
            [c.treatment, c.irritation].where((s) => s.isNotEmpty).join(' | '),
        'meta': _checkinMeta(c),
      };
      var saved = false;
      if (_api.shouldAttemptBackend) {
        try {
          await _api.post('/journeys/checkin', body: checkinBody);
          saved = true;
        } on ApiException catch (e) {
          if (e.statusCode == 409) {
            saved = true;
          } else {
            debugPrint(
                'Simpan check-in via backend gagal, fallback ke Supabase: $e');
          }
        } on Object catch (e) {
          debugPrint(
              'Simpan check-in via backend gagal, fallback ke Supabase: $e');
        }
      }
      if (!saved) {
        await SupabaseDirect.upsertCheckin(checkinBody);
      }
      syncedIds.add(cid);
    }
  }

  /// PNG transparan 1x1, dipakai bila foto di Storage tidak dapat diunduh.
  static final Uint8List _placeholderPhoto = base64Decode(
    'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR4nGP4//8/AwAI/AL+p5sFhAAAAABJRU5ErkJggg==',
  );

  DateTime? _dt(Object? v) => v is String ? DateTime.tryParse(v) : null;

  /// [loadPhoto] menentukan sumber foto: default unduh dari Storage; saat
  /// memulihkan dari cache, foto dibaca dari penyimpanan HP.
  Future<SkinJourneyRecord> _recordFromServer(
    Map<String, dynamic> json, {
    Future<Uint8List?> Function(Map<String, dynamic> photo)? loadPhoto,
  }) async {
    final load = loadPhoto ??
        (Map<String, dynamic> p) => (p['image_path'] as String?) == null
            ? Future<Uint8List?>.value(null)
            : CloudStorage.download(p['image_path'] as String);
    final meta = (json['meta'] as Map?)?.cast<String, dynamic>() ?? const {};
    final createdAt = _dt(meta['created_at']) ??
        DateTime.parse(json['created_at'] as String).toLocal();
    final record = SkinJourneyRecord(
      id: json['id'] as String,
      name: json['title'] as String,
      createdAt: createdAt,
      updatedAt: _dt(meta['updated_at']) ?? createdAt,
      status: JourneyStatus.values.firstWhere(
        (s) => s.name == json['status'],
        orElse: () => JourneyStatus.active,
      ),
      isPinned: json['is_pinned'] as bool? ?? false,
      explicitlyCreated: meta['explicitly_created'] as bool? ?? true,
    )
      ..deletedAt = _dt(json['deleted_at'])?.toLocal()
      ..baselineDate = _dt(meta['baseline_date'])
      ..consent = meta['consent'] as bool?
      ..feedbackRating = (meta['feedback_rating'] as num?)?.toInt()
      ..feedbackComment = meta['feedback_comment'] as String? ?? ''
      ..feedbackSubmittedAt = _dt(meta['feedback_submitted_at']);
    record.answers.addAll({
      for (final e in ((meta['answers'] as Map?) ?? const {}).entries)
        e.key as String: '${e.value}',
    });
    // Jika kuesioner M01-M07 sudah lengkap tapi flag consent belum tercatat di meta lama,
    // pulihkan consent = true karena submit kuesioner mewajibkan persetujuan foto.
    if (record.consent == null &&
        List.generate(7, (i) => 'M0${i + 1}').every(record.answers.containsKey)) {
      record.consent = true;
    }
    for (final e in ((meta['closed_conditions'] as Map?) ?? const {}).entries) {
      final d = _dt(e.value);
      if (d != null) record.closedConditions[e.key as String] = d;
    }

    final photoJson = ((meta['photos'] as List?) ?? const [])
        .cast<Map<String, dynamic>>()
        .toList();
    for (var i = 0; i < photoJson.length; i += 3) {
      final batch = photoJson.skip(i).take(3).toList();
      final images = await Future.wait([for (final p in batch) load(p)]);
      for (var k = 0; k < batch.length; k++) {
        final p = batch[k];
        final path = p['image_path'] as String?;
        if (path != null) _photoPaths[p['id'] as String] = path;
        record.photos.add(_photoFromMeta(p, images[k] ?? _placeholderPhoto));
      }
    }
    return record;
  }

  JourneyPhoto _photoFromMeta(Map<String, dynamic> p, Uint8List bytes) {
    final face = (p['face_rect'] as List?)?.cast<num>();
    return JourneyPhoto(
      id: p['id'] as String,
      date: _dt(p['date']) ?? DateTime.now(),
      bytes: bytes,
      visualFindings:
          ((p['visual_findings'] as List?) ?? const []).cast<String>(),
      skinType: p['skin_type'] as String?,
      skinTypeConfidence: (p['skin_type_confidence'] as num?)?.toDouble(),
      modelConnected: p['model_connected'] as bool? ?? false,
      isDemo: p['is_demo'] as bool? ?? false,
      detectionCounts: {
        for (final e in ((p['detection_counts'] as Map?) ?? const {}).entries)
          e.key as String: (e.value as num).toInt(),
      },
      segmentationAreas: {
        for (final e in ((p['segmentation_areas'] as Map?) ?? const {}).entries)
          e.key as String: (e.value as num).toDouble(),
      },
      confidences: {
        for (final e in ((p['confidences'] as Map?) ?? const {}).entries)
          e.key as String: (e.value as num).toDouble(),
      },
      pose: p['pose'] as String? ?? 'depan',
      modelVersion: p['model_version'] as String?,
      quality: p['quality'] as String? ?? 'unchecked',
      faceRect: face == null || face.length < 4
          ? null
          : Rect.fromLTRB(face[0].toDouble(), face[1].toDouble(),
              face[2].toDouble(), face[3].toDouble()),
      visualBoxes: [
        for (final b in (p['visual_boxes'] as List?) ?? const [])
          SkinVisualBox.fromJson((b as Map).cast<String, dynamic>()),
      ],
      imageWidth: (p['image_width'] as num?)?.toInt(),
      imageHeight: (p['image_height'] as num?)?.toInt(),
    );
  }

  JourneyCheckin _checkinFromServer(Map<String, dynamic> json) {
    final m = (json['meta'] as Map?)?.cast<String, dynamic>() ?? const {};
    final date =
        _dt(m['date']) ?? DateTime.parse(json['checkin_date'] as String);
    return JourneyCheckin(
      id: json['id'] as String?,
      date: date,
      dueDate: _dt(m['due_date']) ?? date,
      perClass: {
        for (final e in ((m['per_class'] as Map?) ?? const {}).entries)
          e.key as String: '${e.value}',
      },
      treatment: m['treatment'] as String? ?? '',
      irritation: m['irritation'] as String? ?? '',
      photoIds: ((m['photo_ids'] as List?) ?? const []).cast<String>(),
      followup: {
        for (final e in ((m['followup'] as Map?) ?? const {}).entries)
          e.key as String: {
            for (final f in (e.value as Map).entries)
              f.key as String: '${f.value}',
          },
      },
      careDate: _dt(m['care_date']),
      careNote: m['care_note'] as String? ?? '',
    );
  }

  Future<Map<String, String>> _fetchLatestQuizAnswers() async {
    Map<String, dynamic>? row;
    if (_api.shouldAttemptBackend) {
      try {
        row = await _api.get('/quiz/latest') as Map<String, dynamic>?;
      } on Object {
        row = null;
      }
    }
    row ??= await SupabaseDirect.fetchLatestQuiz();
    final raw = (row?['answers'] as Map?) ?? const {};
    return {for (final e in raw.entries) '${e.key}': '${e.value}'};
  }

  @override
  Future<void> pullFromServer() async {
    if (!_canSync) return;
    if (_activePull != null) return _activePull!;
    final completer = Completer<void>();
    _activePull = completer.future;
    _pulling = true;
    notifyListeners();
    try {
      List<Map<String, dynamic>>? detailedList;

      if (_api.shouldAttemptBackend) {
        try {
          final list = (await _api
                  .get('/journeys', query: {'include_deleted': 'true'}) as List)
              .cast<Map<String, dynamic>>();
          final collected = <Map<String, dynamic>>[];
          for (final item in list) {
            final detail = await _api.get('/journeys/${item['id']}')
                as Map<String, dynamic>;
            collected.add(detail);
          }
          detailedList = collected;
        } on Object catch (e) {
          debugPrint(
              'Tarik journey via backend gagal, fallback ke Supabase: $e');
        }
      }

      if (detailedList == null && SupabaseDirect.isSignedIn) {
        detailedList = await SupabaseDirect.fetchJourneysWithCheckins();
      }
      if (detailedList == null) return;

      final rebuilt = <SkinJourneyRecord>[];
      final checkinIds = <String, Set<String>>{};
      for (final detail in detailedList) {
        final record = await _recordFromServer(detail);
        final checkins = ((detail['checkins'] as List?) ?? const [])
            .cast<Map<String, dynamic>>();
        final parsed = checkins.map(_checkinFromServer).toList();
        record.checkins.addAll(parsed);
        rebuilt.add(record);
        checkinIds[record.id] = {
          for (final c in parsed)
            if (c.id != null) c.id!,
        };
      }

      Map<String, String> latestQuizAnswers = const {};
      final anyAnswers = rebuilt.any((r) => r.answers.isNotEmpty);
      if (!anyAnswers) {
        try {
          latestQuizAnswers = await _fetchLatestQuizAnswers();
        } on Object {
          latestQuizAnswers = const {};
        }
      }

      var hadDirty = false;
      _applyingRemote = true;
      try {
        final remoteIds = rebuilt.map((r) => r.id).toSet();
        final previouslyRemote = Set<String>.of(_remoteIds);
        // Pertahankan journey yang belum pernah tersimpan di server (dibuat
        // offline). Yang dulu ada di server tetapi kini hilang berarti sudah
        // dihapus permanen di perangkat lain, jadi tidak dihidupkan lagi.
        final localOnly = _journeys
            .where((j) =>
                !remoteIds.contains(j.id) &&
                !previouslyRemote.contains(j.id) &&
                j.isVisibleInCatalog)
            .toList();
        // Perubahan lokal yang belum terkirim (mis. dibuat saat offline lalu
        // dipulihkan dari cache) tidak boleh tertimpa versi server.
        final dirty = <String, SkinJourneyRecord>{
          for (final j in _journeys)
            if (remoteIds.contains(j.id) && _hasUnsyncedChanges(j)) j.id: j,
        };
        hadDirty = dirty.isNotEmpty;
        final oldLastSynced = Map<String, String>.of(_lastSynced);
        final selected = _selectedJourneyId;
        _journeys
          ..clear()
          ..addAll([for (final r in rebuilt) dirty[r.id] ?? r])
          ..addAll(localOnly);
        _remoteIds
          ..clear()
          ..addAll(remoteIds);
        _remoteDeleted
          ..clear()
          ..addAll(rebuilt.where((r) => r.deletedAt != null).map((r) => r.id));
        _syncedCheckinIds
          ..clear()
          ..addAll(checkinIds);
        _lastSynced
          ..clear()
          ..addEntries(
            rebuilt
                .where((r) => !dirty.containsKey(r.id))
                .map((r) => MapEntry(r.id, jsonEncode(_journeyBody(r)))),
          );
        for (final id in dirty.keys) {
          final old = oldLastSynced[id];
          if (old != null) _lastSynced[id] = old;
        }

        final stillValid =
            _journeys.any((j) => j.id == selected && j.deletedAt == null);
        if (!stillValid) {
          final visible = _journeys
              .where((j) => j.deletedAt == null && j.isVisibleInCatalog)
              .toList();
          // Prioritaskan perjalanan yang sudah punya foto/baseline agar tidak
          // tertutupi oleh perjalanan kosong.
          final withPhotos = visible.where((j) => j.photos.isNotEmpty);
          if (withPhotos.isNotEmpty) {
            _selectedJourneyId = withPhotos.first.id;
          } else if (visible.isNotEmpty) {
            _selectedJourneyId = visible.first.id;
          } else {
            final created = _createJourney(explicitlyCreated: false);
            if (latestQuizAnswers.isNotEmpty) {
              created.answers.addAll(latestQuizAnswers);
              created.consent = true;
            }
          }
        } else if (latestQuizAnswers.isNotEmpty &&
            selectedJourney.answers.isEmpty) {
          selectedJourney.answers.addAll(latestQuizAnswers);
          selectedJourney.consent ??= true;
        }
        _hasLoadedFromServer = true;
        notifyListeners();
      } finally {
        _applyingRemote = false;
      }
      if (hadDirty ||
          _journeys
              .any((j) => !_remoteIds.contains(j.id) && j.isVisibleInCatalog)) {
        _scheduleSync();
      }
    } finally {
      _pulling = false;
      _activePull = null;
      if (!completer.isCompleted) completer.complete();
      notifyListeners();
    }
  }

  /// True bila journey punya perubahan lokal yang belum terkirim ke server.
  bool _hasUnsyncedChanges(SkinJourneyRecord j) {
    if (_lastSynced[j.id] != jsonEncode(_journeyBody(j))) return true;
    final synced = _syncedCheckinIds[j.id] ?? const <String>{};
    return j.checkins.any((c) => c.id != null && !synced.contains(c.id));
  }

  // ------------------------------------------------------------------
  // Cache lokal di HP: journey, check-in, foto, dan status sinkronnya, agar
  // perjalanan kulit tetap tampil saat offline dan langsung saat dibuka.
  // ------------------------------------------------------------------
  static const _cacheName = 'journeys';
  Timer? _cacheTimer;
  bool _restoringCache = false;
  final Set<String> _cachedPhotoIds = {};

  void _scheduleCacheSave() {
    if (_restoringCache || !LocalCache.instance.isActive) return;
    _cacheTimer?.cancel();
    _cacheTimer = Timer(
        const Duration(milliseconds: 600), () => unawaited(_saveCache()));
  }

  Future<void> _saveCache() async {
    final cache = LocalCache.instance;
    if (!cache.isActive) return;
    final visible = _journeys.where((j) => j.isVisibleInCatalog).toList();
    final data = <String, dynamic>{
      'selected': _selectedJourneyId,
      'remote_ids': _remoteIds.toList(),
      'remote_deleted': _remoteDeleted.toList(),
      'last_synced': _lastSynced,
      'synced_checkins': {
        for (final e in _syncedCheckinIds.entries) e.key: e.value.toList(),
      },
      'photo_paths': _photoPaths,
      'journeys': [
        for (final j in visible)
          {
            'id': j.id,
            'title': j.name,
            'status': j.status.name,
            'is_pinned': j.isPinned,
            'deleted_at': j.deletedAt?.toUtc().toIso8601String(),
            'created_at': j.createdAt.toUtc().toIso8601String(),
            'meta': _journeyMeta(j),
            'checkins': [
              for (final c in j.checkins)
                {
                  'id': c.id,
                  'checkin_date': c.date.toIso8601String().substring(0, 10),
                  'meta': _checkinMeta(c),
                },
            ],
          },
      ],
    };
    await cache.writeJson(_cacheName, data);

    // Foto hanya ditulis sekali; placeholder (foto gagal unduh) tidak disimpan.
    final current = <String>{};
    for (final j in visible) {
      for (final p in j.photos) {
        current.add(p.id);
        if (_cachedPhotoIds.contains(p.id) ||
            identical(p.bytes, _placeholderPhoto) ||
            p.bytes.isEmpty) {
          continue;
        }
        await cache.writeBytes('journeys/${p.id}.jpg', p.bytes);
        _cachedPhotoIds.add(p.id);
      }
    }
    for (final id in _cachedPhotoIds.difference(current).toList()) {
      await cache.deleteFile('journeys/$id.jpg');
      _cachedPhotoIds.remove(id);
    }
  }

  @override
  Future<void> loadFromCache() async {
    final cache = LocalCache.instance;
    final data = await cache.readJson(_cacheName);
    if (data == null) return;
    final details = ((data['journeys'] as List?) ?? const [])
        .cast<Map<String, dynamic>>();
    if (details.isEmpty) return;

    final restored = <SkinJourneyRecord>[];
    for (final detail in details) {
      try {
        final record = await _recordFromServer(detail, loadPhoto: (p) async {
          final id = p['id'] as String;
          final bytes = await cache.readBytes('journeys/$id.jpg');
          if (bytes != null) _cachedPhotoIds.add(id);
          return bytes;
        });
        record.checkins.addAll(((detail['checkins'] as List?) ?? const [])
            .cast<Map<String, dynamic>>()
            .map(_checkinFromServer));
        restored.add(record);
      } on Object catch (e) {
        debugPrint('Lewati journey cache yang rusak: $e');
      }
    }
    if (restored.isEmpty) return;

    _restoringCache = true;
    _applyingRemote = true;
    try {
      // Journey yang sudah ada di memori (lebih baru) tidak ditimpa cache.
      final inMemory = {
        for (final j in _journeys)
          if (j.isVisibleInCatalog) j.id: j,
      };
      _journeys
        ..clear()
        ..addAll([for (final r in restored) inMemory.remove(r.id) ?? r])
        ..addAll(inMemory.values);
      _remoteIds.addAll(
          ((data['remote_ids'] as List?) ?? const []).cast<String>());
      _remoteDeleted.addAll(
          ((data['remote_deleted'] as List?) ?? const []).cast<String>());
      for (final e in ((data['last_synced'] as Map?) ?? const {}).entries) {
        _lastSynced.putIfAbsent(e.key as String, () => e.value as String);
      }
      for (final e
          in ((data['synced_checkins'] as Map?) ?? const {}).entries) {
        _syncedCheckinIds
            .putIfAbsent(e.key as String, () => <String>{})
            .addAll((e.value as List).cast<String>());
      }
      for (final e in ((data['photo_paths'] as Map?) ?? const {}).entries) {
        _photoPaths.putIfAbsent(e.key as String, () => e.value as String);
      }

      final cachedSelected = data['selected'] as String?;
      final selectable =
          _journeys.where((j) => j.deletedAt == null && j.isVisibleInCatalog);
      if (selectable.any((j) => j.id == cachedSelected)) {
        _selectedJourneyId = cachedSelected;
      } else if (selectable.isNotEmpty) {
        _selectedJourneyId = selectable.first.id;
      } else {
        _createJourney(explicitlyCreated: false);
      }
      notifyListeners();
    } finally {
      _applyingRemote = false;
      _restoringCache = false;
    }
  }

  @override
  void clearLocal() {
    _syncTimer?.cancel();
    _cacheTimer?.cancel();
    _cachedPhotoIds.clear();
    _applyingRemote = true;
    try {
      _journeys.clear();
      _selectedJourneyId = null;
      _lastSynced.clear();
      _remoteIds.clear();
      _remoteDeleted.clear();
      _syncedCheckinIds.clear();
      _photoPaths.clear();
      _hasLoadedFromServer = false;
      _pulling = false;
      _createJourney(explicitlyCreated: false);
      notifyListeners();
    } finally {
      _applyingRemote = false;
    }
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
  final Rect? faceRect;
  final List<SkinVisualBox> visualBoxes;
  final int? imageWidth;
  final int? imageHeight;

  const JourneyPhoto({
    required this.id,
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
    required this.quality,
    this.faceRect,
    this.visualBoxes = const [],
    this.imageWidth,
    this.imageHeight,
  });
}

class JourneyCheckin {
  final String? id;
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
      {this.id,
      required this.date,
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
