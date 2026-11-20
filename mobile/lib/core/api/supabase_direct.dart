import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Akses langsung ke Supabase Postgres (PostgREST + RLS) sebagai fallback
/// otomatis saat backend FastAPI tidak terjangkau (mis. di HP fisik tanpa
/// server lokal aktif). Menggunakan skema & RLS policy tabel yang sama persis.
class SupabaseDirect {
  const SupabaseDirect._();

  static const _placeholderNames = <String>{
    '',
    'pengguna skinsight',
    'alea kucing',
  };

  static bool isPlaceholderName(String? value) =>
      _placeholderNames.contains((value ?? '').trim().toLowerCase());

  static SupabaseClient? get client {
    try {
      return Supabase.instance.client;
    } on Object {
      return null;
    }
  }

  static User? get currentUser {
    try {
      return client?.auth.currentUser;
    } on Object {
      return null;
    }
  }

  static String? get userId => currentUser?.id;

  static bool get isSignedIn => currentUser != null;

  /// Ekstrak nama asli dari akun Google / Supabase Auth metadata.
  static String? extractDisplayName(User? user) {
    if (user == null) return null;
    final meta = user.userMetadata;
    if (meta != null) {
      for (final key in const [
        'full_name',
        'name',
        'preferred_username',
        'user_name',
      ]) {
        final raw = meta[key];
        if (raw is String && raw.trim().isNotEmpty && !isPlaceholderName(raw)) {
          return raw.trim();
        }
      }
      final given = meta['given_name'] is String
          ? (meta['given_name'] as String).trim()
          : '';
      final family = meta['family_name'] is String
          ? (meta['family_name'] as String).trim()
          : '';
      final combined = '$given $family'.trim();
      if (combined.isNotEmpty) return combined;
    }
    final email = user.email?.trim() ?? '';
    if (email.contains('@')) {
      final prefix = email.split('@').first.trim();
      if (prefix.isNotEmpty) return prefix;
    }
    return null;
  }

  /// Ekstrak URL foto profil dari akun Google / Supabase Auth metadata.
  static String? extractAvatarUrl(User? user) {
    final meta = user?.userMetadata;
    if (meta == null) return null;
    for (final key in const ['avatar_url', 'picture']) {
      final raw = meta[key];
      if (raw is String && raw.trim().isNotEmpty) {
        return raw.trim();
      }
    }
    return null;
  }

  // ---------------------------------------------------------------- Profiles

  static Future<Map<String, dynamic>?> syncProfile({
    String? fullName,
    String? avatarUrl,
  }) async {
    final c = client;
    final user = currentUser;
    if (c == null || user == null) return null;

    final existing = await c
        .from('profiles')
        .select()
        .eq('id', user.id)
        .maybeSingle();

    final desiredName =
        (fullName != null && !isPlaceholderName(fullName))
            ? fullName.trim()
            : extractDisplayName(user);
    final desiredAvatar =
        (avatarUrl != null && avatarUrl.trim().isNotEmpty)
            ? avatarUrl.trim()
            : extractAvatarUrl(user);

    if (existing == null) {
      final inserted = await c
          .from('profiles')
          .upsert({
            'id': user.id,
            'email': user.email ?? '',
            if (desiredName != null) 'full_name': desiredName,
            if (desiredAvatar != null) 'avatar_url': desiredAvatar,
          }, onConflict: 'id')
          .select()
          .single();
      return Map<String, dynamic>.from(inserted);
    }

    final patch = <String, dynamic>{};
    final currentName = existing['full_name'] as String?;
    if (isPlaceholderName(currentName) && desiredName != null) {
      patch['full_name'] = desiredName;
    }
    final currentAvatar = existing['avatar_url'] as String?;
    if ((currentAvatar == null || currentAvatar.isEmpty) &&
        desiredAvatar != null) {
      patch['avatar_url'] = desiredAvatar;
    }
    if (patch.isEmpty) return Map<String, dynamic>.from(existing);

    final updated = await c
        .from('profiles')
        .update(patch)
        .eq('id', user.id)
        .select()
        .single();
    return Map<String, dynamic>.from(updated);
  }

  static Future<void> updateProfile(Map<String, dynamic> fields) async {
    final c = client;
    final user = currentUser;
    if (c == null || user == null) return;
    await c.from('profiles').upsert({
      'id': user.id,
      'email': user.email ?? '',
      ...fields,
    }, onConflict: 'id');
  }

  // ------------------------------------------------------------ Scan Records

  static Future<List<Map<String, dynamic>>> fetchScanHistory() async {
    final c = client;
    final uid = userId;
    if (c == null || uid == null) return const [];
    final rows = await c
        .from('scan_records')
        .select()
        .eq('user_id', uid)
        .order('analyzed_at', ascending: false);
    return (rows as List)
        .map((e) => Map<String, dynamic>.from(e as Map))
        .toList();
  }

  static Future<void> upsertScanRecord(Map<String, dynamic> payload) async {
    final c = client;
    final uid = userId;
    if (c == null || uid == null) return;
    await c.from('scan_records').upsert(
      {'user_id': uid, ...payload},
      onConflict: 'id',
    );
  }

  static Future<void> updateScanRecord(
    String id,
    Map<String, dynamic> fields,
  ) async {
    final c = client;
    final uid = userId;
    if (c == null || uid == null) return;
    await c
        .from('scan_records')
        .update(fields)
        .eq('id', id)
        .eq('user_id', uid);
  }

  static Future<void> deleteScanRecord(String id) async {
    final c = client;
    final uid = userId;
    if (c == null || uid == null) return;
    await c.from('scan_records').delete().eq('id', id).eq('user_id', uid);
  }

  // -------------------------------------------------------- Quiz Submissions

  static Future<void> submitQuiz(Map<String, dynamic> answers) async {
    final c = client;
    final uid = userId;
    if (c == null || uid == null) return;
    await c.from('quiz_submissions').insert({
      'user_id': uid,
      'answers': answers,
    });
  }

  static Future<Map<String, dynamic>?> fetchLatestQuiz() async {
    final c = client;
    final uid = userId;
    if (c == null || uid == null) return null;
    final row = await c
        .from('quiz_submissions')
        .select()
        .eq('user_id', uid)
        .order('submitted_at', ascending: false)
        .limit(1)
        .maybeSingle();
    return row == null ? null : Map<String, dynamic>.from(row);
  }

  // --------------------------------------------------- Journeys & Check-ins

  static Future<List<Map<String, dynamic>>> fetchJourneysWithCheckins() async {
    final c = client;
    final uid = userId;
    if (c == null || uid == null) return const [];
    final rows = await c
        .from('skin_journeys')
        .select('*, journey_checkins(*)')
        .eq('user_id', uid)
        .order('is_pinned', ascending: false)
        .order('created_at', ascending: false);

    return (rows as List).map((raw) {
      final map = Map<String, dynamic>.from(raw as Map);
      final checkins = ((map.remove('journey_checkins') as List?) ?? const [])
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList()
        ..sort((a, b) =>
            '${a['checkin_date']}'.compareTo('${b['checkin_date']}'));
      map['checkins'] = checkins;
      return map;
    }).toList();
  }

  static Future<void> upsertJourney(
    String id,
    Map<String, dynamic> body,
  ) async {
    final c = client;
    final uid = userId;
    if (c == null || uid == null) return;
    await c.from('skin_journeys').upsert(
      {'id': id, 'user_id': uid, ...body},
      onConflict: 'id',
    );
  }

  static Future<void> setJourneyDeletedAt(
    String id,
    DateTime? deletedAt,
  ) async {
    final c = client;
    final uid = userId;
    if (c == null || uid == null) return;
    await c
        .from('skin_journeys')
        .update({'deleted_at': deletedAt?.toUtc().toIso8601String()})
        .eq('id', id)
        .eq('user_id', uid);
  }

  static Future<void> deleteJourneyPermanently(String id) async {
    final c = client;
    final uid = userId;
    if (c == null || uid == null) return;
    await c.from('skin_journeys').delete().eq('id', id).eq('user_id', uid);
  }

  static Future<void> upsertCheckin(Map<String, dynamic> body) async {
    final c = client;
    final uid = userId;
    if (c == null || uid == null) return;
    await c.from('journey_checkins').upsert(body, onConflict: 'id');
  }

  /// Helper untuk memperbarui password langsung melalui Supabase Auth.
  static Future<void> updatePassword(String newPassword) async {
    final c = client;
    if (c == null || currentUser == null) return;
    await c.auth.updateUser(UserAttributes(password: newPassword));
  }

  /// Helper untuk menyelaraskan nama ke metadata Supabase Auth (best-effort).
  static Future<void> updateAuthDisplayName(String fullName) async {
    final c = client;
    if (c == null || currentUser == null) return;
    try {
      await c.auth.updateUser(
        UserAttributes(data: {'full_name': fullName, 'name': fullName}),
      );
    } on Object catch (e) {
      debugPrint('Update auth display name dilewati: $e');
    }
  }
}
