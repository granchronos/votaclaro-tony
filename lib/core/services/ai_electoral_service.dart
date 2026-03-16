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
  static final String _aiProxyEndpoint =
      '${const String.fromEnvironment('SUPABASE_URL', defaultValue: '')}/functions/v1/ai-proxy';
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
Genera el perfil COMPLETO y DETALLADO del candidato $tipoLabel "$nombreOId" para Elecciones Generales Perú 2026.

INSTRUCCIONES CLAVE:
- Incluye AL MENOS 5 propuestas principales de su plan de gobierno.
- Cada propuesta debe tener descripción concisa pero sustancial (2-3 oraciones).
- Los pros y contras deben ser ESPECÍFICOS al candidato (mínimo 4 cada uno), no genéricos.
- El resumenPerfil debe ser un párrafo denso con trayectoria política, cargos previos, logros y controversias.
- El analisisPredictivo debe comparar con un político peruano similar del pasado.
- Si no tienes dato verificado, usa "SIN_DATO_VERIFICADO" — NUNCA inventes cifras.
- Las fuentes deben ser reales: JNE, ONPE, Datum, Ipsos, CPI, medios serios.

Responde ÚNICAMENTE en este JSON (sin markdown, sin texto extra):

{
  "nombreCompleto": "",
  "partido": "",
  "porcentajeEncuesta": 0.0,
  "fuenteEncuesta": "[Encuestadora, mes año]",
  "edad": 0,
  "profesion": "",
  "region": "",
  "resumenPerfil": "Párrafo completo: trayectoria, cargos, logros, controversias, posición ideológica.",
  "patrimonio": {
    "totalBienes": 0.0,
    "totalDeudas": 0.0,
    "ingresoAnual": 0.0,
    "descripcionBienes": "Detalle de inmuebles, vehículos, inversiones declaradas.",
    "fuenteJNE": "",
    "fechaDeclaracion": ""
  },
  "propuestas": [
    {
      "numero": 1,
      "area": "Economía|Seguridad|Salud|Educación|Medio Ambiente|Infraestructura|Anticorrupción|Social",
      "descripcion": "Descripción concisa de la propuesta (2-3 oraciones con cifras si aplica).",
      "viabilidad": "alta|media|baja",
      "esReciclada": false,
      "referenciaPropuestaAnterior": "Si esReciclada=true: quién la propuso y cuándo",
      "fuenteVerificacion": "[Plan de gobierno/declaración pública con fecha]"
    }
  ],
  "pros": ["Fortaleza específica 1 con contexto", "Fortaleza 2", "Fortaleza 3", "Fortaleza 4"],
  "contras": ["Debilidad específica 1 con contexto", "Debilidad 2", "Debilidad 3", "Debilidad 4"],
  "analisisPredictivo": {
    "comparadoCon": "Político peruano similar",
    "similitudes": ["Similitud 1", "Similitud 2"],
    "resultadoHistorico": "Qué pasó con ese político similar — éxito o fracaso y por qué.",
    "probabilidadCumplimiento": 0.0,
    "riesgoCorrupcion": "bajo|medio|alto",
    "justificacionRiesgo": "Razones concretas basadas en antecedentes, entorno partidario, declaraciones juradas.",
    "fuenteAnalisis": "[Fuentes verificables]"
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

  /// Modelos Gemini a intentar en orden de prioridad (más quota → menos quota).
  /// gemini-2.0-flash-lite: 1500 RPD free tier
  /// gemini-2.0-flash: 500 RPD free tier
  /// gemini-flash-latest: 20 RPD free tier (resuelve a gemini-3-flash)
  static const _geminiModels = [
    'gemini-2.0-flash-lite',
    'gemini-2.0-flash',
    'gemini-flash-latest',
  ];

  Future<Map<String, dynamic>> _query(String userMessage) async {
    if (kIsWeb) {
      return await _queryViaProxy(userMessage);
    }

    final geminiKey = dotenv.env['GEMINI_API_KEY'] ?? '';
    final claudeKey = dotenv.env['CLAUDE_API_KEY'] ?? '';
    final openaiKey = dotenv.env['OPENAI_API_KEY'] ?? '';

    // 1. Intentar cada modelo Gemini en orden (más quota primero)
    if (geminiKey.isNotEmpty && geminiKey != 'your_gemini_api_key_here') {
      for (final model in _geminiModels) {
        try {
          final result = await _queryGemini(userMessage, geminiKey, model);
          _logger.i('✅ Gemini $model respondió correctamente');
          return result;
        } on DioException catch (e) {
          final code = e.response?.statusCode ?? 0;
          if (code == 429 || code == 503) {
            // Verificar si es rate-limit por minuto (esperar) o por día (saltar)
            final body = e.response?.data;
            final retryDelay = _extractRetryDelay(body);
            if (retryDelay != null && retryDelay.inSeconds <= 90) {
              // Rate-limit por minuto — vale la pena esperar
              _logger.w(
                  'Gemini $model rate-limited, esperando ${retryDelay.inSeconds}s...');
              await Future.delayed(retryDelay);
              try {
                return await _queryGemini(userMessage, geminiKey, model);
              } catch (_) {
                // Si falla de nuevo, probar siguiente modelo
              }
            }
            _logger.w('Gemini $model agotado ($code), probando siguiente...');
            continue;
          }
          if (code == 500) {
            await Future.delayed(const Duration(seconds: 2));
            try {
              return await _queryGemini(userMessage, geminiKey, model);
            } catch (_) {
              continue;
            }
          }
          _logger.e('Gemini $model error inesperado ($code)');
          continue;
        }
      }
    }

    // 2. Fallback: Claude (Haiku — el más rápido y barato)
    if (claudeKey.isNotEmpty && claudeKey != 'your_claude_api_key_here') {
      final claudeModels = [
        'claude-3-haiku-20240307',
        'claude-3-5-haiku-20241022'
      ];
      for (final model in claudeModels) {
        try {
          final result = await _queryClaude(userMessage, claudeKey, model);
          _logger.i('✅ Claude $model respondió correctamente');
          return result;
        } on DioException catch (e) {
          final code = e.response?.statusCode ?? 0;
          if (code == 429 || code == 529) {
            _logger.w('Claude $model agotado ($code), probando siguiente...');
            continue;
          }
          _logger.w('Claude $model falló ($code)');
          break; // Error no-retryable (400 = créditos, 401 = auth)
        }
      }
    }

    // 3. Fallback: OpenAI (gpt-4o-mini — el más barato)
    if (openaiKey.isNotEmpty && openaiKey != 'your_openai_api_key_here') {
      final model = dotenv.env['OPENAI_MODEL'] ?? 'gpt-4o-mini';
      try {
        final result = await _queryOpenAI(userMessage, openaiKey, model);
        _logger.i('✅ OpenAI $model respondió correctamente');
        return result;
      } on DioException catch (e) {
        _logger.w('OpenAI $model falló: ${e.response?.statusCode}');
      }
    }

    _logger.w('Todos los proveedores IA fallaron — sin datos');
    return {'error': 'all_providers_exhausted', 'data': null};
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
    String model,
  ) async {
    final response = await _dio.post(
      _openaiEndpoint,
      options: Options(headers: {
        'Authorization': 'Bearer $apiKey',
        'Content-Type': 'application/json',
      }),
      data: jsonEncode({
        'model': model,
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

  Map<String, dynamic> _parseJsonResponse(String content) {
    try {
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

  /// Extrae el retryDelay de una respuesta 429 de Gemini.
  Duration? _extractRetryDelay(dynamic responseBody) {
    try {
      if (responseBody is! Map) return null;
      final details = (responseBody['error'] as Map?)?['details'] as List?;
      if (details == null) return null;
      for (final detail in details) {
        if (detail is Map && detail.containsKey('retryDelay')) {
          final delayStr = detail['retryDelay'] as String? ?? '';
          // Formato: "52s" o "44.939510061s"
          final match = RegExp(r'(\d+)').firstMatch(delayStr);
          if (match != null) {
            return Duration(seconds: int.parse(match.group(1)!) + 1);
          }
        }
      }
    } catch (_) {}
    return null;
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
