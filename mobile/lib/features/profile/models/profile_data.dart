import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../../../core/api/api_client.dart';
import '../../../core/api/cloud_storage.dart';
import '../../../core/api/cloud_sync.dart';
import '../../../core/api/supabase_direct.dart';

/// Data profil pengguna. Disimpan di tabel `profiles` lewat backend
/// (`GET/PUT /users/me`) dengan fallback otomatis langsung ke Supabase SDK.
/// Nilai dummy `Alea Kucing` hanya muncul pada mode offline/widget test tanpa
/// sesi Supabase; pengguna yang login (Google/email) selalu memakai data asli.
class ProfileData extends ChangeNotifier {
  ProfileData() {
    current = this;
    final cached = _lastRemote;
    if (cached != null) {
      unawaited(_applyRemote(cached));
    } else {
      syncFromAuthImmediate(notify: false);
    }
  }

  /// Instance yang sedang dipakai UI; target penarikan data dari server.
  static ProfileData? current;
  static Map<String, dynamic>? _lastRemote;

  /// Pendaftar untuk [CloudSync.attach].
  static final CloudSyncable syncTarget = _ProfileSyncTarget();

  static const _offlineFallbackName = 'Alea Kucing';
  static const _offlineFallbackPhone = '+62 812-3456-7890';
  static const _offlineFallbackEmail = 'alea.kucing@email.com';

  String name = _offlineFallbackName;
  String phone = _offlineFallbackPhone;
  String email = _offlineFallbackEmail;
  Uint8List? photoBytes;
  String? _avatarPath;

  final List<Future<void>> _pendingWrites = [];

  ApiClient get _api => ApiClient.instance;

  /// Terapkan langsung identitas asli dari Supabase Auth (Google/email)
  /// agar nama dummy `Alea Kucing` tidak pernah tampil saat user sudah login.
  void syncFromAuthImmediate({bool notify = true}) {
    final user = SupabaseDirect.currentUser;
    if (user == null) return;
    final authName = SupabaseDirect.extractDisplayName(user);
    final authEmail = user.email?.trim();
    final authAvatar = SupabaseDirect.extractAvatarUrl(user);

    var changed = false;
    if (authName != null &&
        (SupabaseDirect.isPlaceholderName(name) || name == _offlineFallbackName)) {
      name = authName;
      changed = true;
    }
    if (authEmail != null && authEmail.isNotEmpty && email != authEmail) {
      email = authEmail;
      changed = true;
    }
    if (phone == _offlineFallbackPhone) {
      phone = '';
      changed = true;
    }
    if (_avatarPath == null && authAvatar != null) {
      _avatarPath = authAvatar;
      unawaited(_loadAvatarIfNeeded(authAvatar));
    }
    if (changed && notify) notifyListeners();
  }

  void updateName(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) return;
    name = trimmed;
    notifyListeners();
    _trackWrite(_pushName(trimmed));
  }

  void updatePhone(String value) {
    final trimmed = value.trim();
    phone = trimmed;
    notifyListeners();
    _trackWrite(_pushFields({'phone': trimmed}));
  }

  /// Email dikelola Supabase Auth; perubahan hanya berlaku di tampilan lokal.
  void updateEmail(String value) {
    email = value.trim();
    notifyListeners();
  }

  void updatePhoto(Uint8List value) {
    photoBytes = value;
    notifyListeners();
    _trackWrite(_pushAvatar(value));
  }

  void _trackWrite(Future<void> future) {
    _pendingWrites.add(future);
    future.whenComplete(() => _pendingWrites.remove(future));
  }

  Future<void> _pushName(String fullName) async {
    await _pushFields({'full_name': fullName});
    await SupabaseDirect.updateAuthDisplayName(fullName);
  }

  Future<void> _pushFields(Map<String, dynamic> fields) async {
    if (!SupabaseDirect.isSignedIn && !_api.isAvailable) return;
    if (_api.shouldAttemptBackend) {
      try {
        await _api.put('/users/me', body: fields);
        return;
      } on Object catch (e) {
        debugPrint('Simpan profil via backend gagal, fallback ke Supabase: $e');
      }
    }
    try {
      await SupabaseDirect.updateProfile(fields);
    } on Object catch (e) {
      debugPrint('Simpan profil ke Supabase gagal: $e');
    }
  }

  Future<void> _pushAvatar(Uint8List bytes) async {
    if (!SupabaseDirect.isSignedIn && !_api.isAvailable) return;
    final path = await CloudStorage.upload('avatar.jpg', bytes);
    if (path == null) return;
    _avatarPath = path;
    await _pushFields({'avatar_url': path});
  }

  void _apply(Map<String, dynamic> json) {
    final user = SupabaseDirect.currentUser;
    final authName = SupabaseDirect.extractDisplayName(user);
    final authEmail = user?.email?.trim();
    final authAvatar = SupabaseDirect.extractAvatarUrl(user);

    final remoteName = (json['full_name'] as String?)?.trim();
    if (remoteName != null && !SupabaseDirect.isPlaceholderName(remoteName)) {
      name = remoteName;
    } else if (authName != null) {
      name = authName;
    }

    final phoneValue = (json['phone'] as String?)?.trim();
    phone = phoneValue ?? '';

    final emailValue = (json['email'] as String?)?.trim();
    if (emailValue != null && emailValue.isNotEmpty) {
      email = emailValue;
    } else if (authEmail != null && authEmail.isNotEmpty) {
      email = authEmail;
    }

    final remoteAvatar = (json['avatar_url'] as String?)?.trim();
    _avatarPath =
        (remoteAvatar != null && remoteAvatar.isNotEmpty) ? remoteAvatar : authAvatar;
    notifyListeners();
  }

  static Future<void> _pullRemote() async {
    current?.syncFromAuthImmediate();
    final user = SupabaseDirect.currentUser;
    final api = ApiClient.instance;
    if (user == null && !api.isAvailable) return;

    final displayName = SupabaseDirect.extractDisplayName(user);
    final avatarUrl = SupabaseDirect.extractAvatarUrl(user);

    Map<String, dynamic>? json;
    if (api.shouldAttemptBackend) {
      try {
        json = await api.post('/users/sync', body: {
          if (displayName != null) 'full_name': displayName,
          if (avatarUrl != null) 'avatar_url': avatarUrl,
        }) as Map<String, dynamic>;
      } on Object catch (e) {
        debugPrint('Sync profil via backend gagal, fallback ke Supabase: $e');
      }
    }

    json ??= await SupabaseDirect.syncProfile(
      fullName: displayName,
      avatarUrl: avatarUrl,
    );

    if (json == null) return;
    _lastRemote = json;
    await current?._applyRemote(json);
  }

  Future<void> _applyRemote(Map<String, dynamic> json) async {
    _apply(json);
    final path = _avatarPath;
    if (path != null && path.isNotEmpty && photoBytes == null) {
      await _loadAvatarIfNeeded(path);
    }
  }

  Future<void> _loadAvatarIfNeeded(String path) async {
    try {
      Uint8List? bytes;
      if (path.startsWith('http://') || path.startsWith('https://')) {
        final resp = await http
            .get(Uri.parse(path))
            .timeout(const Duration(seconds: 10));
        if (resp.statusCode == 200 && resp.bodyBytes.isNotEmpty) {
          bytes = resp.bodyBytes;
        }
      } else {
        bytes = await CloudStorage.download(path);
      }
      if (bytes != null && bytes.isNotEmpty) {
        photoBytes = bytes;
        notifyListeners();
      }
    } on Object catch (e) {
      debugPrint('Gagal memuat foto profil ($path): $e');
    }
  }

  Future<void> _flush() async {
    if (_pendingWrites.isEmpty) return;
    await Future.wait(List<Future<void>>.of(_pendingWrites));
  }

  void _reset() {
    name = _offlineFallbackName;
    phone = _offlineFallbackPhone;
    email = _offlineFallbackEmail;
    photoBytes = null;
    _avatarPath = null;
    notifyListeners();
  }
}

class _ProfileSyncTarget implements CloudSyncable {
  @override
  Future<void> pullFromServer() => ProfileData._pullRemote();

  @override
  Future<void> flushPending() async {
    await ProfileData.current?._flush();
  }

  @override
  void clearLocal() {
    ProfileData._lastRemote = null;
    ProfileData.current?._reset();
  }
}
