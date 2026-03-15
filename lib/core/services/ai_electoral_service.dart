import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:logger/logger.dart';
import '../models/candidato.dart';

/// Proveedor de IA disponible
enum AiProvider { gemini, claude }

/// Servicio de IA — Agente ELECTORAL_PE_2026
/// Proveedor principal: Gemini (Google) — FREE TIER
/// Fallback: Claude API (haiku-3 — free tier)
class AiElectoralService {
  static final AiElectoralService _instance = AiElectoralService._internal();
  factory AiElectoralService() => _instance;
  AiElectoralService._internal();

  final _dio = Dio();
  final _logger = Logger();

  /// Proveedor activo — cambiable en runtime desde la UI
  AiProvider activeProvider = AiProvider.gemini;

  static const String _geminiBaseUrl =
      'https://generativelanguage.googleapis.com/v1beta/models';
  static const String _claudeEndpoint = 'https://api.anthropic.com/v1/messages';
  static const String _openaiEndpoint =
      'https://api.openai.com/v1/chat/completions';

  /// Supabase Edge Function que actúa como proxy seguro de IA en web.
  /// Las API keys de Gemini/Claude viven en Supabase Vault, nunca en el cliente.
  static const String _aiProxyEndpoint =
      '${String.fromEnvironment('SUPABASE_URL', defaultValue: '')}/functions/v1/ai-proxy';
  static const String _supabaseAnonKey =
      String.fromEnvironment('SUPABASE_ANON_KEY', defaultValue: '');

  /// Prompt maestro del agente ELECTORAL_PE_2026
  static const String _systemPrompt = '''
Eres ELECTORAL_PE_2026, un agente experto en política peruana con acceso a:
- JNE (jne.gob.pe) — candidaturas oficiales, hojas de vida, patrimonio
- ONPE (onpe.gob.pe) — resultados históricos y simulacros electorales
- Datum, Ipsos Perú, CPI, GFK Perú — encuestas certificadas más recientes
- Declaraciones juradas de candidatos (SUNAT/JNE)
- Archivo histórico del Congreso (1980–2024)
- Fact-checkers: Ojo Público, IDL-Reporteros, Convoca.pe

TU MISIÓN: Informar al ciudadano peruano con datos verificables, neutralidad política
y análisis predictivo basado en evidencia. NUNCA emitas opinión subjetiva.
Cuando no tengas datos, dilo claramente con "SIN_DATO_VERIFICADO".
Prioriza brevedad y la decisión. El contexto es Elecciones Generales Perú 2026.

REGLAS DE ORO:
1. NEUTRALIDAD: Ningún partido favorecido. Datos = argumentos.
2. FUENTE SIEMPRE: Cada dato lleva su fuente y fecha entre corchetes [Fuente: X, Fecha: Y].
3. BREVEDAD: Si puedes decirlo en 5 palabras, no uses 10.
4. SEMÁFORO: usa exactamente 🟢 Alta | 🟡 Media | 🔴 Baja para viabilidad.
5. RECICLADA: usa exactamente 🔄 + referencia si la propuesta ya fue prometida antes.
6. LENGUAJE: Español peruano claro. Sin tecnicismos innecesarios.
7. PATRIMONIO: Siempre mostrar patrimonio como contexto de credibilidad.
8. Siempre responde en JSON válido según el esquema solicitado.
''';

  // ─── MÓDULO 1: Perfil de candidato presidencial ─────────────────────────────

  Future<Map<String, dynamic>> obtenerPerfilCandidato({
    required String nombreOId,
    TipoCandidatura tipo = TipoCandidatura.presidente,
  }) async {
    final tipoLabel = tipo == TipoCandidatura.presidente
        ? 'presidencial'
        : tipo == TipoCandidatura.congresista
            ? 'congresista'
            : 'parlamentario andino';

    final prompt = '''
Genera el perfil completo del candidato $tipoLabel "$nombreOId" para Elecciones 2026 Perú.
Responde ÚNICAMENTE en este JSON (sin markdown, sin texto extra):

{
  "nombreCompleto": "",
  "partido": "",
  "porcentajeEncuesta": 0.0,
  "fuenteEncuesta": "",
  "edad": 0,
  "profesion": "",
  "region": "",
  "resumenPerfil": "",
  "patrimonio": {
    "totalBienes": 0.0,
    "totalDeudas": 0.0,
    "ingresoAnual": 0.0,
    "descripcionBienes": "",
    "fuenteJNE": "",
    "fechaDeclaracion": ""
  },
  "propuestas": [
    {
      "numero": 1,
      "area": "",
      "descripcion": "",
      "viabilidad": "alta|media|baja",
      "esReciclada": false,
      "referenciaPropuestaAnterior": null,
      "fuenteVerificacion": ""
    }
  ],
  "pros": ["", "", ""],
  "contras": ["", "", ""],
  "analisisPredictivo": {
    "comparadoCon": "",
    "similitudes": ["", ""],
    "resultadoHistorico": "",
    "probabilidadCumplimiento": 0.0,
    "riesgoCorrupcion": "bajo|medio|alto",
    "justificacionRiesgo": "",
    "fuenteAnalisis": ""
  }${tipo != TipoCandidatura.presidente ? ''',
  "historialLegislativo": {
    "proyectosPresente": 0,
    "proyectosAprobados": 0,
    "tasaAsistencia": 0.0,
    "votosPolemicos": [""],
    "periodoLegislativo": ""
  }''' : ''}
}
''';

    return await _query(prompt);
  }

  // ─── MÓDULO 4: Comparador entre candidatos ──────────────────────────────────

  Future<Map<String, dynamic>> compararCandidatos({
    required String candidatoA,
    required String candidatoB,
  }) async {
    final prompt = '''
Compara "$candidatoA" vs "$candidatoB" para Elecciones Perú 2026.
Responde ÚNICAMENTE en este JSON:

{
  "dimensiones": {
    "economia": {"posicionA": "", "posicionB": "", "scoreA": 0, "scoreB": 0, "analisis": ""},
    "seguridad": {"posicionA": "", "posicionB": "", "scoreA": 0, "scoreB": 0, "analisis": ""},
    "salud": {"posicionA": "", "posicionB": "", "scoreA": 0, "scoreB": 0, "analisis": ""},
    "educacion": {"posicionA": "", "posicionB": "", "scoreA": 0, "scoreB": 0, "analisis": ""},
    "corrupcion": {"posicionA": "", "posicionB": "", "scoreA": 0, "scoreB": 0, "analisis": ""},
    "medioAmbiente": {"posicionA": "", "posicionB": "", "scoreA": 0, "scoreB": 0, "analisis": ""},
    "descentralizacion": {"posicionA": "", "posicionB": "", "scoreA": 0, "scoreB": 0, "analisis": ""},
    "relacionesExteriores": {"posicionA": "", "posicionB": "", "scoreA": 0, "scoreB": 0, "analisis": ""}
  },
  "nivelDiferencia": "cosmetico|moderado|radical",
  "porcentajePropuestasRecicladas": 0.0,
  "resumenComparacion": ""
}
''';

    return await _query(prompt);
  }

  // ─── MÓDULO 5: Simulador Mi Voto Ideal ──────────────────────────────────────

  Future<List<Map<String, dynamic>>> simularMiVoto({
    required List<String> prioridades,
    required List<String> candidatosIds,
  }) async {
    final prioridadesStr = prioridades.join(', ');
    final candidatosStr = candidatosIds.join(', ');

    final prompt = '''
El ciudadano tiene estas 5 prioridades: [$prioridadesStr].
Candidatos a evaluar: [$candidatosStr].
Para Elecciones Perú 2026, calcula el match %.
Responde ÚNICAMENTE en este JSON array:

[
  {
    "candidatoId": "",
    "nombreCandidato": "",
    "partido": "",
    "porcentajeMatch": 0.0,
    "explicacion": "",
    "alertasContradiccion": []
  }
]
''';

    final result = await _query(prompt);
    // El resultado es un array
    if (result['data'] is List) {
      return List<Map<String, dynamic>>.from(result['data']);
    }
    return [];
  }

  // ─── Consulta general al agente ─────────────────────────────────────────────

  Future<Map<String, dynamic>> consultaLibre(String pregunta) async {
    return await _query(pregunta);
  }

  // ─── HTTP Core ───────────────────────────────────────────────────────────────

  Future<Map<String, dynamic>> _query(String userMessage) async {
    try {
      // En web: todas las llamadas de IA van por la Edge Function de Supabase.
      // Las API keys viven en Supabase Vault — nunca en el bundle JavaScript.
      if (kIsWeb) {
        return await _queryViaProxy(userMessage);
      }

      // En mobile: usar API keys cargadas desde .env (dotenv)
      // Respetar el proveedor seleccionado por el usuario
      if (activeProvider == AiProvider.gemini) {
        final key = dotenv.env['GEMINI_API_KEY'] ?? '';
        final model = dotenv.env['GEMINI_MODEL'] ?? 'gemini-flash-latest';
        if (key.isNotEmpty && key != 'your_gemini_api_key_here') {
          return await _queryGemini(userMessage, key, model);
        }
      } else {
        final key = dotenv.env['CLAUDE_API_KEY'] ?? '';
        // Free tier usa claude-3-haiku-20240307 (el más barato / free tier)
        final model = dotenv.env['CLAUDE_MODEL'] ?? 'claude-3-haiku-20240307';
        if (key.isNotEmpty && key != 'your_claude_api_key_here') {
          return await _queryClaude(userMessage, key, model);
        }
      }

      // Fallback automático al otro proveedor
      final geminiKey = dotenv.env['GEMINI_API_KEY'] ?? '';
      if (geminiKey.isNotEmpty && geminiKey != 'your_gemini_api_key_here') {
        return await _queryGemini(
            userMessage, geminiKey, 'gemini-flash-latest');
      }

      // Último recurso: OpenAI
      final openaiKey = dotenv.env['OPENAI_API_KEY'] ?? '';
      if (openaiKey.isNotEmpty && openaiKey != 'your_openai_api_key_here') {
        return await _queryOpenAI(userMessage, openaiKey);
      }

      _logger.w('No API key configured — returning mock data');
      return _mockResponse(userMessage);
    } catch (e) {
      _logger.e('AI query failed: $e');
      return {'error': e.toString(), 'data': null};
    }
  }

  Future<Map<String, dynamic>> _queryGemini(
    String message,
    String apiKey,
    String model,
  ) async {
    final endpoint = '$_geminiBaseUrl/$model:generateContent';

    final response = await _dio.post(
      endpoint,
      options: Options(headers: {
        'Content-Type': 'application/json',
        'X-goog-api-key': apiKey,
      }),
      data: jsonEncode({
        'system_instruction': {
          'parts': [
            {'text': _systemPrompt}
          ]
        },
        'contents': [
          {
            'parts': [
              {'text': message}
            ]
          }
        ],
        'generationConfig': {
          'temperature': 0.1,
          'maxOutputTokens': 4096,
        },
      }),
    );

    final candidates = response.data['candidates'] as List?;
    if (candidates == null || candidates.isEmpty) {
      return {'error': 'gemini_empty_response', 'data': null};
    }

    final text = candidates[0]['content']['parts'][0]['text'] as String? ?? '';
    return _parseJsonResponse(text);
  }

  Future<Map<String, dynamic>> _queryClaude(
    String message,
    String apiKey,
    String model,
  ) async {
    final response = await _dio.post(
      _claudeEndpoint,
      options: Options(headers: {
        'x-api-key': apiKey,
        'anthropic-version': '2023-06-01',
        'content-type': 'application/json',
      }),
      data: jsonEncode({
        'model': model,
        'max_tokens': 4096,
        'system': _systemPrompt,
        'messages': [
          {'role': 'user', 'content': message}
        ],
      }),
    );

    final content = response.data['content'][0]['text'] as String;
    return _parseJsonResponse(content);
  }

  Future<Map<String, dynamic>> _queryOpenAI(
    String message,
    String apiKey,
  ) async {
    final response = await _dio.post(
      _openaiEndpoint,
      options: Options(headers: {
        'Authorization': 'Bearer $apiKey',
        'Content-Type': 'application/json',
      }),
      data: jsonEncode({
        'model': 'gpt-4o',
        'messages': [
          {'role': 'system', 'content': _systemPrompt},
          {'role': 'user', 'content': message},
        ],
        'temperature': 0.1,
        'response_format': {'type': 'json_object'},
      }),
    );

    final content = response.data['choices'][0]['message']['content'] as String;
    return _parseJsonResponse(content);
  }

  /// Proxy para web: llama a la Supabase Edge Function `ai-proxy`.
  /// Las API keys de IA viven en Supabase Vault y nunca se exponen al cliente.
  Future<Map<String, dynamic>> _queryViaProxy(String userMessage) async {
    if (_aiProxyEndpoint.startsWith('/functions')) {
      _logger.w('SUPABASE_URL no configurado — proxy IA no disponible');
      return _mockResponse(userMessage);
    }
    final response = await _dio.post(
      _aiProxyEndpoint,
      options: Options(headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $_supabaseAnonKey',
        'apikey': _supabaseAnonKey,
      }),
      data: jsonEncode({
        'prompt': userMessage,
        'systemPrompt': _systemPrompt,
      }),
    );
    final text = response.data['text'] as String? ?? '';
    if (text.isEmpty) {
      return {'error': 'proxy_empty_response', 'data': null};
    }
    return _parseJsonResponse(text);
  }

  Map<String, dynamic> _parseJsonResponse(String content) {    try {
      // Limpiar posible markdown ```json ... ```
      String clean = content.trim();
      if (clean.startsWith('```')) {
        clean = clean.replaceFirst(RegExp(r'^```json?\n?'), '');
        clean = clean.replaceFirst(RegExp(r'\n?```$'), '');
      }

      final parsed = jsonDecode(clean);
      if (parsed is List) {
        return {'data': parsed};
      }
      return {'data': parsed};
    } catch (e) {
      _logger.e('JSON parse error: $e — raw: $content');
      return {'error': 'parse_error', 'raw': content, 'data': null};
    }
  }

  /// Respuesta simulada para desarrollo sin API key
  Map<String, dynamic> _mockResponse(String message) {
    return {
      'data': {
        '_mock': true,
        '_aviso':
            'Configura CLAUDE_API_KEY o OPENAI_API_KEY en .env para datos reales',
      }
    };
  }
}
