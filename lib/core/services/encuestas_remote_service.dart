import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import '../models/electoral_models.dart';
import 'cors_proxy.dart';

/// Obtiene encuestas de intención de voto presidencial.
///
/// Flujo de datos (en orden de prioridad):
/// 1. **Live scraping** — Supabase Edge Function `scrape-encuestas` que raspa
///    Peru21/Ipsos en tiempo real para obtener la data más reciente.
/// 2. **GitHub Gist** — JSON mantenido manualmente como respaldo confiable.
/// 3. **Asset local** — `assets/data/encuestas.json` empaquetado en la app.
///
/// Los resultados de las 3 fuentes se _fusionan_ por `id` para no perder
/// encuestas antiguas que solo están en el Gist/local, ni encuestas nuevas
/// que solo aparecen en el scraping.
class EncuestasRemoteService {
  static const String _gistUrl =
      'https://gist.githubusercontent.com/granchronos/e213c6773db98bda538e78473b1cf508/raw/encuestas.json';

  /// URL de la Edge Function de scraping.
  static String get _scrapeUrl {
    const base = String.fromEnvironment('SUPABASE_URL');
    return '$base/functions/v1/scrape-encuestas';
  }

  Future<List<Encuesta>> fetchEncuestas() async {
    final Map<String, Encuesta> merged = {};

    // ── Fuente 3: Local asset (siempre disponible) ──
    final local = await _loadFromAsset();
    for (final e in local) {
      merged[e.id] = e;
    }

    // ── Fuente 2: GitHub Gist ──
    final gist = await _fetchFromGist();
    for (final e in gist) {
      merged[e.id] = e; // sobrescribe si existe — el Gist es más confiable
    }

    // ── Fuente 1: Live scraping (mayor prioridad) ──
    final live = await _fetchFromScraper();
    for (final e in live) {
      merged[e.id] = e;
    }

    final result = merged.values.toList()
      ..sort((a, b) => b.fechaPublicacion.compareTo(a.fechaPublicacion));

    return result;
  }

  // ── Live scraping via Supabase Edge Function ──────────────────────────────

  Future<List<Encuesta>> _fetchFromScraper() async {
    try {
      final url = _scrapeUrl;
      if (url.isEmpty || url.startsWith('/')) return [];

      final uri = Uri.parse(url);
      const anonKey = String.fromEnvironment('SUPABASE_ANON_KEY');
      final headers = {
        'Accept': 'application/json',
        if (anonKey.isNotEmpty) 'apikey': anonKey,
        if (anonKey.isNotEmpty) 'Authorization': 'Bearer $anonKey',
      };

      final res = await http
          .get(uri, headers: headers)
          .timeout(const Duration(seconds: 15));

      if (res.statusCode == 200) {
        final body = jsonDecode(res.body) as Map<String, dynamic>;
        final raw = body['encuestas'] as List? ?? [];
        if (raw.isNotEmpty) {
          return raw
              .whereType<Map<String, dynamic>>()
              .map(Encuesta.fromJson)
              .toList();
        }
      }
    } catch (_) {}
    return [];
  }

  // ── GitHub Gist ───────────────────────────────────────────────────────────

  Future<List<Encuesta>> _fetchFromGist() async {
    try {
      final uri = Uri.parse(_gistUrl);
      final headers = {'Accept': 'application/json'};
      final http.Response res;
      if (kIsWeb) {
        res = await CorsProxy.get(uri, headers: headers)
            .timeout(const Duration(seconds: 10));
      } else {
        res = await http
            .get(uri, headers: headers)
            .timeout(const Duration(seconds: 10));
      }

      if (res.statusCode == 200) {
        final raw = jsonDecode(res.body);
        if (raw is List && raw.isNotEmpty) {
          return raw
              .whereType<Map<String, dynamic>>()
              .map(Encuesta.fromJson)
              .toList();
        }
      }
    } catch (_) {}
    return [];
  }

  // ── Local asset ───────────────────────────────────────────────────────────

  Future<List<Encuesta>> _loadFromAsset() async {
    try {
      final raw = await rootBundle.loadString('assets/data/encuestas.json');
      final list = jsonDecode(raw) as List;
      return list
          .whereType<Map<String, dynamic>>()
          .map(Encuesta.fromJson)
          .toList();
    } catch (_) {
      return [];
    }
  }
}
