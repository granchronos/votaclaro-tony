import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;

/// Helper para hacer fetch desde Flutter Web a través de la
/// Supabase Edge Function `cors-proxy`, que reenvía la petición
/// al URL destino con los headers CORS correctos.
///
/// En plataformas nativas (iOS/Android) no se usa — las llamadas
/// van directo al destino.
class CorsProxy {
  CorsProxy._();

  // URL de la Edge Function. Se llena con las compile-time defines
  // de env.web.json (SUPABASE_URL).
  static const String _supabaseUrl = kIsWeb
      ? String.fromEnvironment('SUPABASE_URL',
          defaultValue: 'https://efbrpoustizkyldlqoit.supabase.co')
      : '';

  static const String _supabaseAnonKey = kIsWeb
      ? String.fromEnvironment('SUPABASE_ANON_KEY', defaultValue: '')
      : '';

  static String get _proxyBase => '$_supabaseUrl/functions/v1/cors-proxy';

  /// GET a través del proxy CORS.
  static Future<http.Response> get(
    Uri targetUri, {
    Map<String, String>? headers,
  }) {
    final proxyUri = Uri.parse(_proxyBase);
    final mergedHeaders = <String, String>{
      'x-target-url': targetUri.toString(),
      if (_supabaseAnonKey.isNotEmpty) 'apikey': _supabaseAnonKey,
      if (headers != null) ...headers,
    };
    return http.get(proxyUri, headers: mergedHeaders);
  }

  /// POST a través del proxy CORS.
  static Future<http.Response> post(
    Uri targetUri, {
    Map<String, String>? headers,
    Object? body,
  }) {
    final proxyUri = Uri.parse(_proxyBase);
    final mergedHeaders = <String, String>{
      'x-target-url': targetUri.toString(),
      if (_supabaseAnonKey.isNotEmpty) 'apikey': _supabaseAnonKey,
      if (headers != null) ...headers,
    };
    return http.post(proxyUri, headers: mergedHeaders, body: body);
  }

  /// Rewrites a URL to go through the CORS proxy (for Image.network, etc.).
  /// On native platforms returns the original URL unchanged.
  static String imageUrl(String url) {
    if (!kIsWeb || url.isEmpty) return url;
    return '$_proxyBase?url=${Uri.encodeComponent(url)}';
  }
}
