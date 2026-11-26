import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

/// Cache lokal di penyimpanan HP agar data (riwayat, journey, profil, foto)
/// langsung tampil saat aplikasi dibuka atau tanpa koneksi.
///
/// Data dipisah per pengguna (`<support>/skinsight_cache/<user_id>/`) dan
/// dihapus saat pengguna keluar. Semua kegagalan diabaikan (cache bersifat
/// pelengkap; sumber kebenaran tetap server).
class LocalCache {
  LocalCache._();
  static final instance = LocalCache._();

  String? _userId;
  Directory? _root;

  /// Untuk tes: arahkan cache ke folder sementara tanpa path_provider.
  @visibleForTesting
  Directory? overrideRoot;

  String? get userId => _userId;
  bool get isActive => _userId != null;

  /// Pilih pengguna aktif; wajib dipanggil sebelum baca/tulis.
  void useUser(String userId) {
    if (_userId == userId) return;
    _userId = userId;
    _root = null;
  }

  Future<Directory?> _dir() async {
    final uid = _userId;
    if (uid == null) return null;
    if (_root != null) return _root;
    try {
      final base = overrideRoot ?? await getApplicationSupportDirectory();
      final dir = Directory('${base.path}/skinsight_cache/$uid');
      await dir.create(recursive: true);
      return _root = dir;
    } on Object catch (e) {
      debugPrint('Cache lokal tidak tersedia: $e');
      return null;
    }
  }

  File _file(Directory dir, String name) => File('${dir.path}/$name');

  Future<Map<String, dynamic>?> readJson(String name) async {
    final dir = await _dir();
    if (dir == null) return null;
    try {
      final file = _file(dir, '$name.json');
      if (!await file.exists()) return null;
      return jsonDecode(await file.readAsString()) as Map<String, dynamic>;
    } on Object catch (e) {
      debugPrint('Baca cache $name gagal: $e');
      return null;
    }
  }

  Future<void> writeJson(String name, Map<String, dynamic> data) async {
    final dir = await _dir();
    if (dir == null) return;
    try {
      // Tulis ke file sementara lalu rename agar file tidak rusak bila terputus.
      final tmp = _file(dir, '$name.json.tmp');
      await tmp.writeAsString(jsonEncode(data), flush: true);
      await tmp.rename(_file(dir, '$name.json').path);
    } on Object catch (e) {
      debugPrint('Tulis cache $name gagal: $e');
    }
  }

  Future<Uint8List?> readBytes(String name) async {
    final dir = await _dir();
    if (dir == null) return null;
    try {
      final file = _file(dir, name);
      if (!await file.exists()) return null;
      return await file.readAsBytes();
    } on Object {
      return null;
    }
  }

  Future<bool> hasBytes(String name) async {
    final dir = await _dir();
    if (dir == null) return false;
    try {
      return await _file(dir, name).exists();
    } on Object {
      return false;
    }
  }

  Future<void> writeBytes(String name, Uint8List bytes) async {
    final dir = await _dir();
    if (dir == null) return;
    try {
      final file = _file(dir, name);
      await file.parent.create(recursive: true);
      await file.writeAsBytes(bytes, flush: true);
    } on Object catch (e) {
      debugPrint('Tulis foto cache $name gagal: $e');
    }
  }

  Future<void> deleteFile(String name) async {
    final dir = await _dir();
    if (dir == null) return;
    try {
      final file = _file(dir, name);
      if (await file.exists()) await file.delete();
    } on Object {
      // Abaikan: berkas cache yang tertinggal tidak berbahaya.
    }
  }

  /// Hapus seluruh cache pengguna aktif (dipanggil saat keluar akun),
  /// karena berisi foto wajah dan data pribadi.
  Future<void> clearUser() async {
    final dir = await _dir();
    _userId = null;
    _root = null;
    if (dir == null) return;
    try {
      if (await dir.exists()) await dir.delete(recursive: true);
    } on Object catch (e) {
      debugPrint('Hapus cache lokal gagal: $e');
    }
  }
}

/// Target sinkronisasi yang dapat memulihkan datanya dari cache lokal.
abstract interface class LocalCacheable {
  Future<void> loadFromCache();
}
