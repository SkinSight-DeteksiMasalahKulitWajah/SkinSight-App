import 'dart:async';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/widgets.dart' show AppLifecycleListener;
import 'package:supabase_flutter/supabase_flutter.dart';

/// Deep link callback OAuth Google. Harus sama dengan intent-filter di
/// `android/app/src/main/AndroidManifest.xml` (dan Info.plist iOS) serta
/// daftar Redirect URLs di Supabase Dashboard.
const authRedirectTo = 'io.supabase.skinsight://login-callback/';

/// Kontrak auth agar UI bisa diuji tanpa jaringan.
/// Produksi: [SupabaseAuthService]. Tes/widget: [FakeAuthService].
abstract class AuthService {
  Future<void> signUp(
      {required String name, required String email, required String password});
  Future<void> signIn({required String email, required String password});
  Future<void> signInWithGoogle();
  Future<void> signOut();
}

void validateRegister(
    {required String name, required String email, required String password}) {
  if (name.trim().isEmpty) {
    throw ArgumentError('Nama perlu diisi.');
  }
  if (!email.contains('@')) {
    throw ArgumentError('Masukkan alamat email yang valid.');
  }
  if (password.length < 6) {
    throw ArgumentError('Password minimal 6 karakter.');
  }
}

String friendlyAuthError(Object e) {
  final msg = e.toString();
  if (msg.contains('User already registered') ||
      msg.contains('already been registered')) {
    return 'Email sudah terdaftar. Silakan masuk.';
  }
  if (msg.contains('Invalid login credentials')) {
    return 'Email atau password salah.';
  }
  if (msg.contains('Email not confirmed')) {
    return 'Email belum dikonfirmasi. Cek inbox lalu masuk.';
  }
  if (msg.contains('provider is not enabled') ||
      msg.contains('Unsupported provider')) {
    return 'Provider Google belum aktif di dashboard Supabase.';
  }
  return 'Gagal autentikasi. Coba lagi.';
}

/// Implementasi asli Supabase. Trigger SQL `handle_new_user()` membuat `profiles`.
class SupabaseAuthService implements AuthService {
  SupabaseClient get _client => Supabase.instance.client;

  @override
  Future<void> signUp(
      {required String name,
      required String email,
      required String password}) async {
    validateRegister(name: name, email: email, password: password);
    try {
      await _client.auth.signUp(
        email: email.trim(),
        password: password,
        data: {'name': name.trim()},
      );
    } catch (e) {
      throw Exception(friendlyAuthError(e));
    }
  }

  @override
  Future<void> signIn({required String email, required String password}) async {
    try {
      await _client.auth
          .signInWithPassword(email: email.trim(), password: password);
    } catch (e) {
      throw Exception(friendlyAuthError(e));
    }
  }

  @override
  Future<void> signInWithGoogle() async {
    final auth = _client.auth;
    if (auth.currentSession != null) return; // Sesi tersimpan, siap masuk.

    final signedIn = Completer<void>();
    StreamSubscription<AuthState>? sub;
    try {
      // Mulai mendengarkan sebelum membuka browser agar event `signedIn`
      // dari deep-link callback (diproses otomatis oleh SDK) tidak terlewat.
      sub = auth.onAuthStateChange.listen((state) {
        if (state.event == AuthChangeEvent.signedIn && !signedIn.isCompleted) {
          signedIn.complete();
        }
      });
      await auth.signInWithOAuth(
        OAuthProvider.google,
        redirectTo: kIsWeb ? null : authRedirectTo,
        authScreenLaunchMode: LaunchMode.externalApplication,
      );
    } catch (e) {
      await sub?.cancel();
      throw Exception(friendlyAuthError(e));
    }
    try {
      // Di mobile future di atas selesai begitu browser terbuka; tunggu
      // sampai sesi benar-benar terbentuk lewat deep link.
      if (!kIsWeb) await _waitForGoogleSession(signedIn.future);
    } finally {
      await sub.cancel();
    }
  }

  /// Menunggu sesi OAuth muncul dari callback, atau pengguna kembali ke app
  /// tanpa menyelesaikan login (dianggap dibatalkan).
  Future<void> _waitForGoogleSession(Future<void> signedIn) async {
    final auth = _client.auth;
    final returned = Completer<void>();
    final listener = AppLifecycleListener(onResume: () {
      if (!returned.isCompleted) returned.complete();
    });
    try {
      final first = await Future.any<String>([
        signedIn.then((_) => 'signed-in'),
        returned.future.then((_) => 'returned'),
      ]).timeout(
        const Duration(minutes: 2),
        onTimeout: () =>
            throw Exception('Tidak ada respons dari Google. Coba lagi.'),
      );

      if (first == 'returned' && auth.currentSession == null) {
        // Beri jeda singkat agar pemrosesan deep link (jika ada) selesai.
        try {
          await signedIn.timeout(const Duration(seconds: 3));
        } on TimeoutException {
          if (auth.currentSession == null) {
            throw Exception('Masuk dengan Google dibatalkan.');
          }
        }
      }
    } finally {
      listener.dispose();
    }
  }

  @override
  Future<void> signOut() async {
    try {
      await _client.auth.signOut();
    } catch (e) {
      throw Exception(friendlyAuthError(e));
    }
  }
}

/// Double untuk widget test / mode tanpa Supabase: cek kredensial di memori.
/// Akun dummy `alea@skinsight.id` / `skinsight123` bawaan agar alur widget
/// test tetap jalan; akun baru ikut terdaftar lewat [signUp].
class FakeAuthService implements AuthService {
  final Map<String, String> _passwords = {'alea@skinsight.id': 'skinsight123'};

  @override
  Future<void> signUp(
      {required String name,
      required String email,
      required String password}) async {
    validateRegister(name: name, email: email, password: password);
    final key = email.trim();
    if (_passwords.containsKey(key)) {
      throw Exception('Email sudah terdaftar. Silakan masuk.');
    }
    _passwords[key] = password;
  }

  @override
  Future<void> signIn({required String email, required String password}) async {
    if (_passwords[email.trim()] != password) {
      throw Exception('Email atau password salah.');
    }
  }

  @override
  Future<void> signInWithGoogle() async {}

  @override
  Future<void> signOut() async {}
}
