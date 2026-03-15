import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import '../models/electoral_models.dart';
import 'cors_proxy.dart';

/// Obtiene encuestas de intención de voto presidencial desde un JSON alojado
/// externamente (GitHub Gist u otro hosting estático).
/// En iOS/Android consulta directamente; en web usa proxy CORS.
/// Si falla el fetch remoto, carga desde assets/data/encuestas.json.
class EncuestasRemoteService {
  static const String gistUrl =
      'https://gist.githubusercontent.com/granchronos/e213c6773db98bda538e78473b1cf508/raw/encuestas.json';

  Future<List<Encuesta>> fetchEncuestas() async {
    try {
      final uri = Uri.parse(gistUrl);
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
              .toList()
            ..sort((a, b) => b.fechaPublicacion.compareTo(a.fechaPublicacion));
        }
      }
    } catch (_) {}

    // Fallback: load from local asset bundle
    return _loadFromAsset();
  }

  Future<List<Encuesta>> _loadFromAsset() async {
    try {
      final raw = await rootBundle.loadString('assets/data/encuestas.json');
      final list = jsonDecode(raw) as List;
      return list
          .whereType<Map<String, dynamic>>()
          .map(Encuesta.fromJson)
          .toList()
        ..sort((a, b) => b.fechaPublicacion.compareTo(a.fechaPublicacion));
    } catch (_) {
      return [];
    }
  }
}
