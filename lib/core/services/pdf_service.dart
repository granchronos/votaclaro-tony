import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:syncfusion_flutter_pdf/pdf.dart';

import 'cors_proxy.dart';

/// Servicio para descargar y parsear PDFs de planes de gobierno.
class PdfService {
  final Dio _dio;

  PdfService({Dio? dio}) : _dio = dio ?? Dio();

  /// Descarga y extrae texto de un PDF desde una URL.
  /// Retorna el texto completo del documento.
  Future<String> extractTextFromUrl(String url) async {
    try {
      // On web, proxy through CORS Edge Function
      final downloadUrl = kIsWeb ? CorsProxy.imageUrl(url) : url;

      // Descargar el PDF
      final response = await _dio.get<List<int>>(
        downloadUrl,
        options: Options(
          responseType: ResponseType.bytes,
          followRedirects: true,
          receiveTimeout: const Duration(seconds: 30),
          validateStatus: (status) => status != null && status < 500,
        ),
      );

      if (response.statusCode != 200 || response.data == null) {
        throw Exception('Failed to download PDF: ${response.statusCode}');
      }

      // Convertir a Uint8List
      final bytes = Uint8List.fromList(response.data!);

      // Cargar el documento PDF
      final document = PdfDocument(inputBytes: bytes);

      // Extraer texto de todas las páginas
      final textExtractor = PdfTextExtractor(document);
      final text = textExtractor.extractText();

      // Cerrar el documento
      document.dispose();

      return text;
    } catch (e) {
      throw Exception('Error extracting PDF text: $e');
    }
  }

  /// Parsea el texto del plan de gobierno y lo estructura por secciones.
  /// Retorna un mapa con las secciones detectadas.
  Map<String, dynamic> parseStructuredPlan(String text) {
    // ── Limpieza profunda del texto extraído ──
    var clean = text
        // Quitar caracteres de control y basura de PDF
        .replaceAll(RegExp(r'[\x00-\x08\x0B\x0C\x0E-\x1F\x7F]'), '')
        // Quitar secuencias de Q, X, letras sueltas repetidas (artefactos OCR)
        .replaceAll(RegExp(r'\b[QXZqxz]{2,}\b'), '')
        // Quitar secuencias de puntuación sin sentido (ej: ...., ----, ====)
        .replaceAll(RegExp(r'[.\-=_]{4,}'), '')
        // Quitar números de página sueltos (ej: "12", "Página 3")
        .replaceAll(
            RegExp(r'(?:^|\n)\s*(?:Página\s*)?\d{1,3}\s*(?:\n|$)',
                caseSensitive: false),
            '\n')
        // Quitar headers/footers repetitivos de JNE
        .replaceAll(
            RegExp(
                r'(?:JURADO\s+NACIONAL\s+DE\s+ELECCIONES|PLAN\s+DE\s+GOBIERNO|REGISTRO\s+DE\s+ORGANIZACIONES\s+POL[IÍ]TICAS)',
                caseSensitive: false),
            '')
        // Quitar cadenas de un solo carácter repetido con espacios (ej: "Q Q Q Q")
        .replaceAll(RegExp(r'(?:\w\s){5,}'), ' ')
        // Normalizar espacios
        .replaceAll(RegExp(r'[ \t]+'), ' ')
        // Normalizar saltos de línea
        .replaceAll(RegExp(r'\n\s*\n\s*\n+'), '\n\n')
        .trim();

    // Quitar líneas que son solo números, puntuación o muy cortas (< 10 chars)
    final lines = clean.split('\n');
    final goodLines = lines.where((line) {
      final trimmed = line.trim();
      if (trimmed.length < 10) return false;
      // Quitar líneas que son mayormente números/puntuación
      final alphaCount =
          trimmed.replaceAll(RegExp(r'[^a-záéíóúñA-ZÁÉÍÓÚÑ]'), '').length;
      return alphaCount > trimmed.length * 0.4; // Al menos 40% letras
    }).toList();
    clean = goodLines.join('\n');

    if (clean.length < 50) {
      return {
        'textoCompleto': '',
        'longitudTotal': 0,
        'resumen': '',
        'secciones': <String, String>{},
        'tieneSecciones': false,
      };
    }

    // ── Detectar secciones temáticas ──
    final sections = <String, String>{};
    final sectionPatterns = {
      'Seguridad Ciudadana': RegExp(
        r'(?:SEGURIDAD\s+(?:CIUDADANA|NACIONAL|P[UÚ]BLICA)|ORDEN\s+(?:INTERNO|P[UÚ]BLICO)|LUCHA\s+CONTRA\s+(?:LA\s+)?(?:DELINCUENCIA|CRIMINALIDAD|INSEGURIDAD))[:\s.]*(.*?)(?=(?:DIMENSI[OÓ]N|CAP[IÍ]TULO|SECCI[OÓ]N|\n[A-ZÁÉÍÓÚÑ\s]{15,}\n|$))',
        caseSensitive: false,
        dotAll: true,
      ),
      'Economía y Empleo': RegExp(
        r'(?:DESARROLLO\s+ECON[OÓ]MICO|ECONOM[IÍ]A|REACTIVACI[OÓ]N\s+ECON[OÓ]MICA|EMPLEO|POL[IÍ]TICA\s+ECON[OÓ]MICA)[:\s.]*(.*?)(?=(?:DIMENSI[OÓ]N|CAP[IÍ]TULO|SECCI[OÓ]N|\n[A-ZÁÉÍÓÚÑ\s]{15,}\n|$))',
        caseSensitive: false,
        dotAll: true,
      ),
      'Educación': RegExp(
        r'(?:EDUCACI[OÓ]N|DESARROLLO\s+EDUCATIVO|CALIDAD\s+EDUCATIVA)[:\s.]*(.*?)(?=(?:DIMENSI[OÓ]N|CAP[IÍ]TULO|SECCI[OÓ]N|\n[A-ZÁÉÍÓÚÑ\s]{15,}\n|$))',
        caseSensitive: false,
        dotAll: true,
      ),
      'Salud': RegExp(
        r'(?:SALUD|SISTEMA\s+(?:DE\s+)?SALUD|SALUD\s+P[UÚ]BLICA)[:\s.]*(.*?)(?=(?:DIMENSI[OÓ]N|CAP[IÍ]TULO|SECCI[OÓ]N|\n[A-ZÁÉÍÓÚÑ\s]{15,}\n|$))',
        caseSensitive: false,
        dotAll: true,
      ),
      'Medio Ambiente': RegExp(
        r'(?:MEDIO\s+AMBIENTE|DESARROLLO\s+SOSTENIBLE|CAMBIO\s+CLIM[AÁ]TICO|POL[IÍ]TICA\s+AMBIENTAL)[:\s.]*(.*?)(?=(?:DIMENSI[OÓ]N|CAP[IÍ]TULO|SECCI[OÓ]N|\n[A-ZÁÉÍÓÚÑ\s]{15,}\n|$))',
        caseSensitive: false,
        dotAll: true,
      ),
      'Corrupción': RegExp(
        r'(?:LUCHA\s+CONTRA\s+LA\s+CORRUPCI[OÓ]N|ANTICORRUPCI[OÓ]N|TRANSPARENCIA)[:\s.]*(.*?)(?=(?:DIMENSI[OÓ]N|CAP[IÍ]TULO|SECCI[OÓ]N|\n[A-ZÁÉÍÓÚÑ\s]{15,}\n|$))',
        caseSensitive: false,
        dotAll: true,
      ),
    };

    for (final entry in sectionPatterns.entries) {
      final match = entry.value.firstMatch(clean);
      if (match != null && match.group(1) != null) {
        var content = _cleanSectionText(match.group(1)!);
        if (content.length > 800) {
          // Cortar en el último punto antes de 800 chars
          final cutIdx = content.lastIndexOf('.', 800);
          content =
              '${content.substring(0, cutIdx > 400 ? cutIdx + 1 : 800)}...';
        }
        if (content.length >= 30) {
          sections[entry.key] = content;
        }
      }
    }

    // ── Construir resumen inteligente ──
    // Buscar primeros párrafos con contenido real (no headers)
    String resumen = '';
    final parrafos = clean.split(RegExp(r'\n\n+'));
    final buenos = <String>[];
    for (final p in parrafos) {
      final trimmed = p.trim();
      // Párrafo útil: >40 chars, no todo mayúsculas, tiene oraciones
      if (trimmed.length > 40 &&
          trimmed != trimmed.toUpperCase() &&
          trimmed.contains(RegExp(r'[.,:;]'))) {
        buenos.add(trimmed);
        if (buenos.join(' ').length > 600) break;
      }
    }
    resumen = buenos.isNotEmpty
        ? buenos.join('\n\n')
        : (clean.length > 400 ? '${clean.substring(0, 400)}...' : clean);

    // Limitar resumen
    if (resumen.length > 700) {
      final cutIdx = resumen.lastIndexOf('.', 700);
      resumen = '${resumen.substring(0, cutIdx > 300 ? cutIdx + 1 : 700)}...';
    }

    return {
      'textoCompleto': clean,
      'longitudTotal': clean.length,
      'resumen': resumen,
      'secciones': sections,
      'tieneSecciones': sections.isNotEmpty,
    };
  }

  /// Limpia el texto de una sección detectada.
  String _cleanSectionText(String raw) {
    return raw
        .replaceAll(RegExp(r'\s+'), ' ')
        .replaceAll(RegExp(r'^\s*[.\-:;,]+\s*'), '')
        .trim();
  }

  /// Extrae keywords relevantes del texto para análisis.
  List<String> extractKeywords(String text) {
    final keywords = <String>[];

    // Keywords relacionados con seguridad
    final securityKeywords = [
      'seguridad',
      'policía',
      'delincuencia',
      'crimen',
      'narcotráfico',
      'extorsión',
      'sicariato',
      'violencia',
      'robo',
      'penitenciario',
    ];

    // Keywords relacionados con economía
    final economyKeywords = [
      'economía',
      'empleo',
      'inversión',
      'desarrollo',
      'pobreza',
      'pib',
      'crecimiento',
      'empresas',
      'comercio',
      'producción',
    ];

    final normalizedText = text.toLowerCase();

    for (final keyword in [...securityKeywords, ...economyKeywords]) {
      if (normalizedText.contains(keyword)) {
        keywords.add(keyword);
      }
    }

    return keywords.toSet().toList();
  }
}
