import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

/// Menormalkan `API_BASE_URL` agar selalu berakhiran `/api/v1` (tanpa duplikasi).
/// Menerima `http://10.0.2.2:8000` maupun `http://10.0.2.2:8000/api/v1`.
String normalizeApiBaseUrl(String raw) {
  var trimmed = raw.trim();
  while (trimmed.endsWith('/')) {
    trimmed = trimmed.substring(0, trimmed.length - 1);
  }
  if (trimmed.isEmpty) {
    return 'http://10.0.2.2:8000/api/v1';
  }
  if (trimmed.endsWith('/api/v1')) {
    return trimmed;
  }
  return '$trimmed/api/v1';
}

const _rawApiBaseUrl = String.fromEnvironment(
  'API_BASE_URL',
  defaultValue: 'http://10.0.2.2:8000/api/v1',
);

/// Alamat backend FastAPI ternormalisasi (`/api/v1`).
/// Ganti saat build: `--dart-define=API_BASE_URL=http://<IP-PC>:8000` atau `https://...`.
final String apiBaseUrl = normalizeApiBaseUrl(_rawApiBaseUrl);

class ApiException implements Exception {
  const ApiException(this.statusCode, this.message);
  final int statusCode;
  final String message;

  @override
  String toString() => 'ApiException($statusCode): $message';
}

/// Klien HTTP tipis untuk backend SkinSight dengan circuit-breaker cepat.
///
/// Saat berjalan di HP fisik tanpa backend lokal (`10.0.2.2:8000`), request
/// pertama gagal cepat dalam 2 detik lalu menandai backend sementara tidak
/// terjangkau selama 2 menit agar semua operasi langsung memakai Supabase SDK
/// tanpa menunggu timeout berulang-ulang.
class ApiClient {
  ApiClient({http.Client? client, String? baseUrl, String? Function()? tokenProvider})
      : _client = client ?? http.Client(),
        _baseUrl = normalizeApiBaseUrl(baseUrl ?? apiBaseUrl),
        _tokenProvider = tokenProvider ?? _supabaseToken;

  static final instance = ApiClient();

  final http.Client _client;
  final String _baseUrl;
  final String? Function() _tokenProvider;

  static const _probeTimeout = Duration(seconds: 2);
  static const _connectedTimeout = Duration(seconds: 12);
  static const _cooldown = Duration(minutes: 2);

  bool _everConnected = false;
  DateTime? _unreachableUntil;

  String get baseUrl => _baseUrl;

  String? get accessToken => _tokenProvider();

  static String? _supabaseToken() {
    try {
      return Supabase.instance.client.auth.currentSession?.accessToken;
    } on Object {
      return null;
    }
  }

  /// Apakah sesi auth tersedia untuk memanggil backend.
  bool get isAvailable => _tokenProvider() != null;

  /// True bila backend tidak sedang dalam cooldown akibat gagal koneksi.
  bool get isReachableNow {
    final until = _unreachableUntil;
    if (until == null) return true;
    if (DateTime.now().isAfter(until)) {
      _unreachableUntil = null;
      return true;
    }
    return false;
  }

  /// Gunakan ini sebelum mencoba memanggil backend FastAPI; bila false,
  /// pemanggil dapat langsung memakai fallback Supabase SDK tanpa delay.
  bool get shouldAttemptBackend => isAvailable && isReachableNow;

  /// Reset circuit-breaker (mis. saat user menarik refresh atau login ulang).
  void resetCircuitBreaker() {
    _unreachableUntil = null;
  }

  Duration get _timeout => _everConnected ? _connectedTimeout : _probeTimeout;

  Uri _uri(String path, [Map<String, dynamic>? query]) {
    final normalizedPath = path.startsWith('/') ? path : '/$path';
    final params = query?.map((k, v) => MapEntry(k, '$v'));
    return Uri.parse('$_baseUrl$normalizedPath').replace(queryParameters: params);
  }

  Map<String, String> _headers({bool json = true}) {
    final token = _tokenProvider();
    return {
      if (json) 'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  Future<dynamic> get(String path, {Map<String, dynamic>? query}) =>
      _send(() => _client.get(_uri(path, query), headers: _headers()));

  Future<dynamic> post(String path, {Object? body}) => _send(() =>
      _client.post(_uri(path), headers: _headers(), body: jsonEncode(body ?? {})));

  Future<dynamic> put(String path, {Object? body}) => _send(() =>
      _client.put(_uri(path), headers: _headers(), body: jsonEncode(body ?? {})));

  Future<dynamic> patch(String path, {Object? body}) => _send(() =>
      _client.patch(_uri(path), headers: _headers(), body: jsonEncode(body ?? {})));

  Future<dynamic> delete(String path, {Map<String, dynamic>? query}) =>
      _send(() => _client.delete(_uri(path, query), headers: _headers()));

  Future<dynamic> _send(Future<http.Response> Function() request) async {
    final http.Response response;
    try {
      response = await request().timeout(_timeout);
    } on TimeoutException {
      _unreachableUntil = DateTime.now().add(_cooldown);
      throw const ApiException(0, 'Server tidak merespons.');
    } on Object catch (e) {
      _unreachableUntil = DateTime.now().add(_cooldown);
      throw ApiException(0, 'Tidak dapat terhubung ke server: $e');
    }
    _everConnected = true;
    _unreachableUntil = null;
    final text = utf8.decode(response.bodyBytes);
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return text.isEmpty ? null : jsonDecode(text);
    }
    var message = text;
    try {
      final decoded = jsonDecode(text);
      if (decoded is Map && decoded['detail'] != null) {
        message = '${decoded['detail']}';
      }
    } on Object {
      // Body bukan JSON; pakai teks mentah.
    }
    debugPrint('API ${response.statusCode}: $message');
    throw ApiException(response.statusCode, message);
  }
}
