import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Sumber data yang dapat ditarik dari server saat login dan dibersihkan saat logout.
abstract class CloudSyncable {
  Future<void> pullFromServer();
  void clearLocal();
}

/// Menghubungkan siklus login Supabase dengan penarikan data dari backend.
/// Tidak melakukan apa pun bila Supabase belum diinisialisasi (mis. widget test).
class CloudSync {
  CloudSync._();
  static final instance = CloudSync._();

  final List<CloudSyncable> _targets = [];
  StreamSubscription<AuthState>? _subscription;
  String? _activeUserId;

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
          if (session != null) unawaited(_pull(session.user.id));
        case AuthChangeEvent.signedOut:
          _activeUserId = null;
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
    if (_activeUserId == userId) return; // sudah ditarik untuk user ini
    _activeUserId = userId;
    for (final t in _targets) {
      try {
        await t.pullFromServer();
      } on Object catch (e, s) {
        debugPrint('Sinkron dari server gagal (${t.runtimeType}): $e');
        debugPrintStack(stackTrace: s, maxFrames: 3);
      }
    }
  }

  /// Paksa tarik ulang (mis. tombol refresh).
  Future<void> refresh() async {
    final id = _activeUserId;
    _activeUserId = null;
    if (id != null) await _pull(id);
  }
}
