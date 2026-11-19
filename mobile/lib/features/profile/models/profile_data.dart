import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/api/api_client.dart';
import '../../../core/api/cloud_storage.dart';
import '../../../core/api/cloud_sync.dart';

/// Data profil pengguna. Disimpan di tabel `profiles` lewat backend
/// (`GET/PUT /users/me`); nilai awal di bawah hanya tampil sebelum data server tiba.
class ProfileData extends ChangeNotifier {
  ProfileData() {
    current = this;
    final cached = _lastRemote;
    if (cached != null) unawaited(_applyRemote(cached));
  }

  /// Instance yang sedang dipakai UI; target penarikan data dari server.
  static ProfileData? current;
  static Map<String, dynamic>? _lastRemote;

  /// Pendaftar untuk [CloudSync.attach].
  static final CloudSyncable syncTarget = _ProfileSyncTarget();

  String name = 'Alea Kucing';
  String phone = '+62 812-3456-7890';
  String email = 'alea.kucing@email.com';
  Uint8List? photoBytes;
  String? _avatarPath;

  ApiClient get _api => ApiClient.instance;

  void updateName(String value) {
    name = value;
    notifyListeners();
    unawaited(_pushFields({'full_name': value.trim()}));
  }

  void updatePhone(String value) {
    phone = value;
    notifyListeners();
    unawaited(_pushFields({'phone': value.trim()}));
  }

  /// Email dikelola Supabase Auth; perubahan hanya berlaku di tampilan lokal.
  void updateEmail(String value) {
    email = value;
    notifyListeners();
  }

  void updatePhoto(Uint8List value) {
    photoBytes = value;
    notifyListeners();
    unawaited(_pushAvatar(value));
  }

  Future<void> _pushFields(Map<String, dynamic> fields) async {
    if (!_api.isAvailable) return;
    try {
      await _api.put('/users/me', body: fields);
    } on Object catch (e) {
      debugPrint('Simpan profil ke server gagal: $e');
    }
  }

  Future<void> _pushAvatar(Uint8List bytes) async {
    if (!_api.isAvailable) return;
    final path = await CloudStorage.upload('avatar.jpg', bytes);
    if (path == null) return;
    _avatarPath = path;
    await _pushFields({'avatar_url': path});
  }

  void _apply(Map<String, dynamic> json) {
    final fullName = json['full_name'] as String?;
    final phoneValue = json['phone'] as String?;
    final emailValue = json['email'] as String?;
    if (fullName != null && fullName.isNotEmpty) name = fullName;
    if (phoneValue != null && phoneValue.isNotEmpty) phone = phoneValue;
    if (emailValue != null && emailValue.isNotEmpty) email = emailValue;
    _avatarPath = json['avatar_url'] as String?;
    notifyListeners();
  }

  static Future<void> _pullRemote() async {
    final api = ApiClient.instance;
    if (!api.isAvailable) return;
    String? displayName;
    try {
      final meta = Supabase.instance.client.auth.currentUser?.userMetadata;
      displayName = (meta?['name'] ?? meta?['full_name']) as String?;
    } on Object {
      displayName = null;
    }
    final json = await api.post('/users/sync',
        body: {if (displayName != null) 'full_name': displayName}) as Map<String, dynamic>;
    _lastRemote = json;
    await current?._applyRemote(json);
  }

  Future<void> _applyRemote(Map<String, dynamic> json) async {
    _apply(json);
    final path = _avatarPath;
    if (path != null && photoBytes == null) {
      final bytes = await CloudStorage.download(path);
      if (bytes != null) {
        photoBytes = bytes;
        notifyListeners();
      }
    }
  }

  void _reset() {
    name = 'Alea Kucing';
    phone = '+62 812-3456-7890';
    email = 'alea.kucing@email.com';
    photoBytes = null;
    _avatarPath = null;
    notifyListeners();
  }
}

class _ProfileSyncTarget implements CloudSyncable {
  @override
  Future<void> pullFromServer() => ProfileData._pullRemote();

  @override
  void clearLocal() {
    ProfileData._lastRemote = null;
    ProfileData.current?._reset();
  }
}
