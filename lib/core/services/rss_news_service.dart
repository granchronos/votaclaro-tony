import 'dart:convert' show utf8;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;
import 'package:xml/xml.dart';
import '../models/electoral_models.dart';

/// Servicio que agrega RSS de fuentes periodísticas verificadas peruanas.
/// En web usa el proxy allorigins.win para evitar CORS; en iOS/Android va directo.
class RssNewsService {
  static const String _corsProxy = 'https://api.allorigins.win/raw?url=';

  // ── Fuentes ───────────────────────────────────────────────────────────────
  static const List<FuenteRss> fuentes = [
    FuenteRss(
      nombre: 'IDL-Reporteros',
      url: 'https://idl-reporteros.pe/feed/',
      categoria: CategoriaFuente.investigacion,
      emoji: '🔍',
    ),
    FuenteRss(
      nombre: 'Wayka.pe',
      url: 'https://wayka.pe/feed/',
      categoria: CategoriaFuente.investigacion,
      emoji: '📺',
    ),
    FuenteRss(
      nombre: 'Sudaca.pe',
      url: 'https://sudaca.pe/feed/',
      categoria: CategoriaFuente.perfiles,
      emoji: '🧠',
    ),
    FuenteRss(
      nombre: 'RPP Noticias',
      url: 'https://rpp.pe/feed',
      categoria: CategoriaFuente.minutaminuto,
      emoji: '📻',
    ),
    FuenteRss(
      nombre: 'Canal N',
      url: 'https://canaln.pe/feed',
      categoria: CategoriaFuente.minutaminuto,
      emoji: '📡',
    ),
    FuenteRss(
      nombre: 'El Comercio — Política',
      url: 'https://elcomercio.pe/arcio/rss/category/politica/',
      categoria: CategoriaFuente.analisis,
      emoji: '📰',
    ),
    FuenteRss(
      nombre: 'El Comercio — Opinión',
      url: 'https://elcomercio.pe/arcio/rss/category/opinion/',
      categoria: CategoriaFuente.analisis,
      emoji: '✍️',
    ),
    FuenteRss(
      nombre: 'Chequeado',
      url: 'https://chequeado.com/feed/',
      categoria: CategoriaFuente.factcheck,
      emoji: '✅',
    ),
    FuenteRss(
      nombre: 'EC Data',
      url: 'https://elcomercio.pe/arcio/rss/category/ecdata/',
      categoria: CategoriaFuente.factcheck,
      emoji: '📊',
    ),
  ];

  // ── Encuestas externas (metadata solamente) ───────────────────────────────
  static const List<_FuenteEncuesta> fuentesEncuestas = [
    _FuenteEncuesta(
      nombre: 'Ipsos Perú',
      url: 'https://www.ipsos.com/es-pe/politica',
      publicadoEn: 'El Comercio / Cuarto Poder',
    ),
    _FuenteEncuesta(
      nombre: 'IEP',
      url: 'https://iep.org.pe/encuestas/',
      publicadoEn: 'La República',
    ),
    _FuenteEncuesta(
      nombre: 'Datum Internacional',
      url: 'https://datum.com.pe',
      publicadoEn: 'Perú21',
    ),
  ];

  // ── Obtener todas las noticias ────────────────────────────────────────────
  Future<List<Noticia>> fetchAll({CategoriaFuente? categoria}) async {
    final toFetch = categoria != null
        ? fuentes.where((f) => f.categoria == categoria).toList()
        : fuentes;

    final results = await Future.wait(
      toFetch.map((f) => _fetchFeed(f)),
    );

    return results.expand((list) => list).toList()
      ..sort((a, b) => b.fechaPublicacion.compareTo(a.fechaPublicacion));
  }

  Future<List<Noticia>> _fetchFeed(FuenteRss fuente) async {
    try {
      // On native (iOS/Android) fetch directly; on web use CORS proxy
      final Uri uri;
      if (kIsWeb) {
        final encoded = Uri.encodeComponent(fuente.url);
        uri = Uri.parse('$_corsProxy$encoded');
      } else {
        uri = Uri.parse(fuente.url);
      }
      final res = await http.get(uri, headers: {
        'Accept': 'application/rss+xml, application/xml, text/xml'
      }).timeout(const Duration(seconds: 15));
      if (res.statusCode != 200) return [];
      // Decode from bytes as UTF-8 to handle tildes/accents correctly
      final body = utf8.decode(res.bodyBytes, allowMalformed: true);
      return _parseRss(body, fuente);
    } catch (_) {
      return [];
    }
  }

  List<Noticia> _parseRss(String xmlBody, FuenteRss fuente) {
    try {
      final doc = XmlDocument.parse(xmlBody);
      final items = doc.findAllElements('item');
      return items.take(8).map((item) {
        final title = _text(item, 'title');
        final link = _text(item, 'link');
        final desc = _text(item, 'description');
        final pubDate = _text(item, 'pubDate');
        final enclosureUrl =
            item.findElements('enclosure').firstOrNull?.getAttribute('url');

        return Noticia(
          id: '${fuente.nombre}_${link.hashCode.abs()}',
          titulo: _stripHtml(title).trim(),
          resumen: _truncate(_stripHtml(desc), 240),
          urlFuente: link.isNotEmpty ? link : fuente.url,
          medioComunicacion: fuente.nombre,
          fechaPublicacion: _parseRssDate(pubDate),
          tagsCandiatos: [],
          esFactChecked: fuente.categoria == CategoriaFuente.factcheck ||
              fuente.categoria == CategoriaFuente.investigacion,
          imagenUrl: enclosureUrl,
        );
      }).toList();
    } catch (_) {
      return [];
    }
  }

  // ── Helpers ───────────────────────────────────────────────────────────────
  String _text(XmlElement el, String tag) =>
      el.findElements(tag).firstOrNull?.innerText.trim() ?? '';

  String _stripHtml(String html) => html
      .replaceAll(RegExp(r'<[^>]*>'), '')
      .replaceAll('&amp;', '&')
      .replaceAll('&lt;', '<')
      .replaceAll('&gt;', '>')
      .replaceAll('&quot;', '"')
      .replaceAll('&#39;', "'")
      .replaceAll('&aacute;', 'á')
      .replaceAll('&eacute;', 'é')
      .replaceAll('&iacute;', 'í')
      .replaceAll('&oacute;', 'ó')
      .replaceAll('&uacute;', 'ú')
      .replaceAll('&ntilde;', 'ñ')
      .replaceAll('&Ntilde;', 'Ñ')
      .replaceAll('&iquest;', '¿')
      .replaceAll('&iexcl;', '¡')
      .replaceAll('&nbsp;', ' ')
      .replaceAllMapped(
          RegExp(r'&#(\d+);'), (m) => String.fromCharCode(int.parse(m[1]!)))
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();

  String _truncate(String s, int max) =>
      s.length <= max ? s : '${s.substring(0, max)}…';

  DateTime _parseRssDate(String date) {
    if (date.isEmpty) return DateTime.now();
    try {
      // ISO 8601
      return DateTime.parse(date);
    } catch (_) {}
    try {
      // RFC 822: "Wed, 05 Mar 2026 12:00:00 +0000"
      const months = {
        'Jan': '01',
        'Feb': '02',
        'Mar': '03',
        'Apr': '04',
        'May': '05',
        'Jun': '06',
        'Jul': '07',
        'Aug': '08',
        'Sep': '09',
        'Oct': '10',
        'Nov': '11',
        'Dec': '12',
      };
      var d = date.trim();
      for (final e in months.entries) {
        d = d.replaceAll(' ${e.key} ', ' ${e.value} ');
      }
      // "Wed, 05 03 2026 12:00:00 +0000"
      final parts = d.split(RegExp(r'[\s,]+'));
      final dateParts = parts.where((p) => p.isNotEmpty).toList();
      if (dateParts.length >= 5) {
        final day = dateParts[1].padLeft(2, '0');
        final month = dateParts[2];
        final year = dateParts[3];
        final time = dateParts[4];
        return DateTime.parse('$year-$month-${day}T$time');
      }
    } catch (_) {}
    return DateTime.now();
  }
}

// ── Modelos internos ──────────────────────────────────────────────────────────

enum CategoriaFuente {
  investigacion,
  factcheck,
  minutaminuto,
  analisis,
  perfiles,
}

extension CategoriaFuenteExt on CategoriaFuente {
  String get label => switch (this) {
        CategoriaFuente.investigacion => '🔍 Investigación',
        CategoriaFuente.factcheck => '✅ Fact-Check',
        CategoriaFuente.minutaminuto => '⚡ Minuto a Minuto',
        CategoriaFuente.analisis => '📊 Análisis',
        CategoriaFuente.perfiles => '🧠 Perfiles',
      };
}

class FuenteRss {
  final String nombre;
  final String url;
  final CategoriaFuente categoria;
  final String emoji;

  const FuenteRss({
    required this.nombre,
    required this.url,
    required this.categoria,
    required this.emoji,
  });
}

class _FuenteEncuesta {
  final String nombre;
  final String url;
  final String publicadoEn;

  const _FuenteEncuesta({
    required this.nombre,
    required this.url,
    required this.publicadoEn,
  });
}
