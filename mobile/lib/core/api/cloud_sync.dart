import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'api_client.dart';

/// Sumber data yang dapat ditarik dari server saat login, di-flush sebelum logout,
/// dan dibersihkan saat logout.
abstract class CloudSyncable {
  Future<void> pullFromServer();
  Future<void> flushPending() async {}
  void clearLocal();
}

/// Menghubungkan siklus login Supabase dengan penarikan data dari backend/Supabase.
/// Mengekspos [isSyncing] dan [hasCompletedInitialSync] sebagai [ChangeNotifier]
/// agar UI (Home, Riwayat, Journey) dapat menampilkan indikator loading yang rapi.
class CloudSync extends ChangeNotifier {
  CloudSync._();
  static final instance = CloudSync._();

  final List<CloudSyncable> _targets = [];
  StreamSubscription<AuthState>? _subscription;
  String? _activeUserId;
  Future<void>? _activePull;
  bool _isSyncing = false;
  bool _hasCompletedInitialSync = false;

  bool get isSyncing => _isSyncing;
  bool get hasCompletedInitialSync => _hasCompletedInitialSync;

  void attach(Iterable<CloudSyncable> targets) {
    _targets
      ..clear()
      ..addAll(targets);
  }

  void start() {
    if (_subscription != null) return;
    final SupabaseClient client;
    try {
      client = Supabase.instance.client;
    } on Object {
      return;
    }
    _subscription = client.auth.onAuthStateChange.listen((state) {
      final session = state.session;
      switch (state.event) {
        case AuthChangeEvent.initialSession:
        case AuthChangeEvent.signedIn:
        case AuthChangeEvent.userUpdated:
          if (session != null) unawaited(_pull(session.user.id));
        case AuthChangeEvent.signedOut:
          _activeUserId = null;
          _activePull = null;
          _isSyncing = false;
          _hasCompletedInitialSync = false;
          for (final t in _targets) {
            t.clearLocal();
          }
          notifyListeners();
        default:
          break;
      }
    });
    final existing = client.auth.currentSession;
    if (existing != null) unawaited(_pull(existing.user.id));
  }

  Future<void> _pull(String userId) async {
    if (_activeUserId == userId && _activePull != null) {
      return _activePull!;
    }
    _activeUserId = userId;
    final completer = Completer<void>();
    _activePull = completer.future;
    _isSyncing = true;
    notifyListeners();
    try {
      // Tarik seluruh target secara paralel agar loading setelah login cepat.
      await Future.wait([
        for (final t in List<CloudSyncable>.of(_targets))
          t.pullFromServer().catchError((Object e, StackTrace s) {
            debugPrint('Sinkron dari server gagal (${t.runtimeType}): $e');
            debugPrintStack(stackTrace: s, maxFrames: 3);
          }),
      ]);
      _hasCompletedInitialSync = true;
    } finally {
      _isSyncing = false;
      if (!completer.isCompleted) completer.complete();
      notifyListeners();
    }
  }

  /// Paksa kirim semua perubahan lokal yang masih tertunda sebelum logout.
  Future<void> flushPending() async {
    await Future.wait([
      for (final t in List<CloudSyncable>.of(_targets))
        t
            .flushPending()
            .timeout(const Duration(seconds: 12))
            .catchError((Object e) {
          debugPrint('Flush sinkron sebelum keluar gagal (${t.runtimeType}): $e');
        }),
    ]);
  }

  /// Paksa tarik ulang (mis. setelah login atau pull-to-refresh).
  Future<void> refresh({bool retryBackend = false}) async {
    if (retryBackend) ApiClient.instance.resetCircuitBreaker();
    String? id = _activeUserId;
    if (id == null) {
      try {
        id = Supabase.instance.client.auth.currentUser?.id;
      } on Object {
        id = null;
      }
    }
    _activeUserId = null;
    _activePull = null;
    if (id != null) await _pull(id);
  }
}
