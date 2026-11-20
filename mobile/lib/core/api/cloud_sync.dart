import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Sumber data yang dapat ditarik dari server saat login, di-flush sebelum logout,
/// dan dibersihkan saat logout.
abstract class CloudSyncable {
  Future<void> pullFromServer();
  Future<void> flushPending() async {}
  void clearLocal();
}

/// Menghubungkan siklus login Supabase dengan penarikan data dari backend/Supabase.
/// Tidak melakukan apa pun bila Supabase belum diinisialisasi (mis. widget test).
class CloudSync {
  CloudSync._();
  static final instance = CloudSync._();

  final List<CloudSyncable> _targets = [];
  StreamSubscription<AuthState>? _subscription;
  String? _activeUserId;
  Future<void>? _activePull;

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
          for (final t in _targets) {
            t.clearLocal();
          }
        default:
          break;
      }
    });
    final existing = client.auth.currentSession;
    if (existing != null) unawaited(_pull(existing.user.id));
  }

  Future<void> _pull(String userId) async {
    if (_activeUserId == userId && _activePull != null) return;
    _activeUserId = userId;
    final completer = Completer<void>();
    _activePull = completer.future;
    try {
      for (final t in _targets) {
        try {
          await t.pullFromServer();
        } on Object catch (e, s) {
          debugPrint('Sinkron dari server gagal (${t.runtimeType}): $e');
          debugPrintStack(stackTrace: s, maxFrames: 3);
        }
      }
    } finally {
      if (!completer.isCompleted) completer.complete();
    }
  }

  /// Paksa kirim semua perubahan lokal yang masih tertunda sebelum logout.
  Future<void> flushPending() async {
    for (final t in _targets) {
      try {
        await t.flushPending().timeout(const Duration(seconds: 10));
      } on Object catch (e) {
        debugPrint('Flush sinkron sebelum keluar gagal (${t.runtimeType}): $e');
      }
    }
  }

  /// Paksa tarik ulang (mis. setelah login atau tombol refresh).
  Future<void> refresh() async {
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
