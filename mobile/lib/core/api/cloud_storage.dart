
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Penyimpanan foto di Supabase Storage (bucket privat `skin-scans`).
/// File disimpan di `<user_id>/<nama>` sehingga policy RLS hanya mengizinkan pemiliknya.
class CloudStorage {
  const CloudStorage._();

  static const bucket = 'skin-scans';

  static SupabaseClient? get _client {
    try {
      return Supabase.instance.client;
    } on Object {
      return null;
    }
  }

  static String? get userId => _client?.auth.currentUser?.id;

  /// Mengunggah [bytes] sebagai `<user_id>/<name>`; mengembalikan path, atau null bila gagal.
  static Future<String?> upload(String name, Uint8List bytes) async {
    final client = _client;
    final uid = userId;
    if (client == null || uid == null) return null;
    final path = '$uid/$name';
    try {
      await client.storage.from(bucket).uploadBinary(
            path,
            bytes,
            fileOptions: const FileOptions(
              contentType: 'image/jpeg',
              upsert: true,
            ),
          );
      return path;
    } on Object catch (e) {
      debugPrint('Upload foto gagal ($path): $e');
      return null;
    }
  }

  static Future<Uint8List?> download(String path) async {
    final client = _client;
    if (client == null) return null;
    try {
      return await client.storage.from(bucket).download(path);
    } on Object catch (e) {
      debugPrint('Unduh foto gagal ($path): $e');
      return null;
    }
  }

  static Future<void> remove(List<String> paths) async {
    final client = _client;
    if (client == null || paths.isEmpty) return;
    try {
      await client.storage.from(bucket).remove(paths);
    } on Object catch (e) {
      debugPrint('Hapus foto gagal: $e');
    }
  }
}
