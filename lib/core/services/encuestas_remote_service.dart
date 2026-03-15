import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import '../models/electoral_models.dart';

/// Obtiene encuestas de intención de voto presidencial desde un JSON alojado
/// externamente (GitHub Gist u otro hosting estático).
/// En iOS/Android consulta directamente; en web usa proxy CORS.
/// Si falla el fetch remoto, carga desde assets/data/encuestas.json.
class EncuestasRemoteService {
  static const String gistUrl =
      'https://gist.githubusercontent.com/granchronos/e213c6773db98bda538e78473b1cf508/raw/encuestas.json';

  static const String _corsProxy = 'https://api.allorigins.win/raw?url=';

  Future<List<Encuesta>> fetchEncuestas() async {
    try {
      // On native platforms (iOS/Android) there's no CORS — fetch directly
      final Uri uri;
      if (kIsWeb) {
        uri = Uri.parse('$_corsProxy${Uri.encodeComponent(gistUrl)}');
      } else {
        uri = Uri.parse(gistUrl);
      }

      final res = await http.get(uri, headers: {
        'Accept': 'application/json'
      }).timeout(const Duration(seconds: 10));

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
