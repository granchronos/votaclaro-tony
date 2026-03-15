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
    // Limpiar el texto
    final cleanText = text
        .replaceAll(RegExp(r'\s+'), ' ')
        .replaceAll(RegExp(r'\n{3,}'), '\n\n')
        .trim();

    // Detectar secciones comunes en planes de gobierno
    final sections = <String, String>{};

    // Patrones de secciones comunes
    final sectionPatterns = {
      'Resumen Ejecutivo': RegExp(
        r'(?:RESUMEN\s+EJECUTIVO|INTRODUCCIÓN|PRESENTACIÓN)[:\s]*(.*?)(?=(?:DIMENSIÓN|PROBLEMA|OBJETIVO|CAPÍTULO|SECCIÓN|$))',
        caseSensitive: false,
        dotAll: true,
      ),
      'Seguridad': RegExp(
        r'(?:SEGURIDAD\s+(?:CIUDADANA|NACIONAL)|ORDEN\s+PÚBLICO|LUCHA\s+CONTRA)[:\s]*(.*?)(?=(?:DIMENSIÓN|PROBLEMA|CAPÍTULO|SECCIÓN|$))',
        caseSensitive: false,
        dotAll: true,
      ),
      'Economía': RegExp(
        r'(?:DESARROLLO\s+ECONÓMICO|ECONOMÍA|REACTIVACIÓN\s+ECONÓMICA)[:\s]*(.*?)(?=(?:DIMENSIÓN|PROBLEMA|CAPÍTULO|SECCIÓN|$))',
        caseSensitive: false,
        dotAll: true,
      ),
      'Educación': RegExp(
        r'(?:EDUCACIÓN|DESARROLLO\s+EDUCATIVO)[:\s]*(.*?)(?=(?:DIMENSIÓN|PROBLEMA|CAPÍTULO|SECCIÓN|$))',
        caseSensitive: false,
        dotAll: true,
      ),
      'Salud': RegExp(
        r'(?:SALUD|SISTEMA\s+DE\s+SALUD)[:\s]*(.*?)(?=(?:DIMENSIÓN|PROBLEMA|CAPÍTULO|SECCIÓN|$))',
        caseSensitive: false,
        dotAll: true,
      ),
      'Medio Ambiente': RegExp(
        r'(?:MEDIO\s+AMBIENTE|DESARROLLO\s+SOSTENIBLE|CAMBIO\s+CLIMÁTICO)[:\s]*(.*?)(?=(?:DIMENSIÓN|PROBLEMA|CAPÍTULO|SECCIÓN|$))',
        caseSensitive: false,
        dotAll: true,
      ),
    };

    // Extraer secciones
    for (final entry in sectionPatterns.entries) {
      final match = entry.value.firstMatch(cleanText);
      if (match != null && match.group(1) != null) {
        var content = match.group(1)!.trim();
        // Limitar a primeros 1000 caracteres por sección
        if (content.length > 1000) {
          content = '${content.substring(0, 1000)}...';
        }
        sections[entry.key] = content;
      }
    }

    // Extraer propuestas generales (primeros párrafos)
    final initialText = cleanText.length > 500
        ? '${cleanText.substring(0, 500)}...'
        : cleanText;

    return {
      'textoCompleto': cleanText,
      'longitudTotal': cleanText.length,
      'resumen': initialText,
      'secciones': sections,
      'tieneSecciones': sections.isNotEmpty,
    };
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
