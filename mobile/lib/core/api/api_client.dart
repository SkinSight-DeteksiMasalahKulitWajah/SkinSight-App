import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

/// Alamat backend FastAPI. Ganti saat build: `--dart-define=API_BASE_URL=https://...`.
/// Default `10.0.2.2` = localhost komputer dari emulator Android.
const apiBaseUrl = String.fromEnvironment(
  'API_BASE_URL',
  defaultValue: 'http://10.0.2.2:8000/api/v1',
);

class ApiException implements Exception {
  const ApiException(this.statusCode, this.message);
  final int statusCode;
  final String message;

  @override
  String toString() => 'ApiException($statusCode): $message';
}

/// Klien HTTP tipis untuk backend SkinSight. Otomatis menyertakan access token
/// Supabase. Bila belum ada sesi (mis. widget test), [isAvailable] bernilai false
/// dan pemanggil harus melewati sinkronisasi.
class ApiClient {
  ApiClient({http.Client? client, String? baseUrl, String? Function()? tokenProvider})
      : _client = client ?? http.Client(),
        _baseUrl = baseUrl ?? apiBaseUrl,
        _tokenProvider = tokenProvider ?? _supabaseToken;

  static final instance = ApiClient();

  final http.Client _client;
  final String _baseUrl;
  final String? Function() _tokenProvider;

  static const _timeout = Duration(seconds: 20);

  static String? _supabaseToken() {
    try {
      return Supabase.instance.client.auth.currentSession?.accessToken;
    } on Object {
      return null;
    }
  }

  bool get isAvailable => _tokenProvider() != null;

  Uri _uri(String path, [Map<String, dynamic>? query]) {
    final params = query?.map((k, v) => MapEntry(k, '$v'));
    return Uri.parse('$_baseUrl$path').replace(queryParameters: params);
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
      throw const ApiException(0, 'Server tidak merespons.');
    } on Object catch (e) {
      throw ApiException(0, 'Tidak dapat terhubung ke server: $e');
    }
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
