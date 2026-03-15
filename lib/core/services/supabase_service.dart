import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Servicio central de Supabase: caché persistente, preferencias y analytics.
///
/// Diseño tolerante a fallos: todos los métodos manejan errores silenciosamente
/// para que la app funcione sin conexión o si las tablas aún no existen.
class SupabaseService {
  SupabaseService._();

  static final SupabaseService instance = SupabaseService._();

  SupabaseClient get _client => Supabase.instance.client;

  /// Indica si se pudo conectar a Supabase y las tablas existen.
  bool _isReady = false;
  bool get isReady => _isReady;

  /// Verifica conexión y existencia de tablas al arrancar.
  /// Retorna true si todo funciona.
  Future<bool> healthCheck() async {
    try {
      // Test: intentar leer de user_preferences (tabla más simple)
      await _client
          .from('user_preferences')
          .select('session_id')
          .limit(1);
      _isReady = true;
      debugPrint('[Supabase] ✅ Conectado — tablas OK');
      return true;
    } catch (e) {
      _isReady = false;
      debugPrint('[Supabase] ❌ No conectado: $e');
      debugPrint('[Supabase] ⚠️ La app funcionará con caché local únicamente.');
      debugPrint('[Supabase] 💡 Crea las tablas en: https://supabase.com/dashboard/project/efbrpoustizkyldlqoit/sql');
      return false;
    }
  }

  // ─────────────────────────────────────────────────────────────────────
  //  Session / Device ID
  // ─────────────────────────────────────────────────────────────────────

  /// ID de sesión persistente (anónimo) generado una sola vez al instalar la app.
  String? _sessionId;

  Future<String> getSessionId() async {
    if (_sessionId != null) return _sessionId!;
    final prefs = await SharedPreferences.getInstance();
    _sessionId = prefs.getString('_session_id');
    if (_sessionId == null) {
      final rng = Random.secure();
      final bytes = List<int>.generate(16, (_) => rng.nextInt(256));
      _sessionId = bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
      await prefs.setString('_session_id', _sessionId!);
    }
    return _sessionId!;
  }

  // ─────────────────────────────────────────────────────────────────────
  //  Preferencias de usuario
  // ─────────────────────────────────────────────────────────────────────

  /// Lee una preferencia guardada en Supabase (fallback: SharedPreferences).
  Future<String?> getUserPreference(String key) async {
    // Primero buscar localmente para respuesta inmediata
    final prefs = await SharedPreferences.getInstance();
    final local = prefs.getString('pref_$key');

    // Intentar sincronizar desde Supabase en segundo plano
    if (_isReady) {
      try {
        final sessionId = await getSessionId();
        final row = await _client
            .from('user_preferences')
            .select('preferences')
            .eq('session_id', sessionId)
            .maybeSingle();
        if (row != null) {
          final map = row['preferences'] as Map<String, dynamic>? ?? {};
          final remoteVal = map[key] as String?;
          if (remoteVal != null && remoteVal != local) {
            await prefs.setString('pref_$key', remoteVal);
            return remoteVal;
          }
        }
      } catch (e) {
        debugPrint('[Supabase] getUserPreference($key) error: $e');
      }
    }

    return local;
  }

  /// Guarda una preferencia en SharedPreferences (inmediato) y Supabase (asíncrono).
  Future<void> saveUserPreference(String key, String value) async {
    // Persistencia local inmediata
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('pref_$key', value);

    // Sincronización remota sin bloquear la UI
    if (_isReady) {
      try {
        final sessionId = await getSessionId();
        final existing = await _client
            .from('user_preferences')
            .select('preferences')
            .eq('session_id', sessionId)
            .maybeSingle();

        final currentPrefs = (existing?['preferences'] as Map<String, dynamic>?)
                ?.cast<String, dynamic>() ??
            {};
        currentPrefs[key] = value;

        await _client.from('user_preferences').upsert({
          'session_id': sessionId,
          'preferences': currentPrefs,
          'updated_at': DateTime.now().toIso8601String(),
        });
      } catch (e) {
        debugPrint('[Supabase] saveUserPreference($key) error: $e');
      }
    }
  }

  // ─────────────────────────────────────────────────────────────────────
  //  Caché de candidatos
  // ─────────────────────────────────────────────────────────────────────

  /// Retorna candidatos cacheados para un tipo dado (ej. 'presidente', 'congreso_Lima').
  /// Retorna null si no hay caché o está vencida.
  Future<List<Map<String, dynamic>>?> getCachedCandidatos(
    String tipo, {
    Duration maxAge = const Duration(hours: 6),
  }) async {
    if (!_isReady) return null;
    try {
      final row = await _client
          .from('candidatos_cache')
          .select('data, updated_at')
          .eq('tipo', tipo)
          .maybeSingle();

      if (row == null) return null;

      final updatedAt = DateTime.tryParse(row['updated_at'] as String? ?? '');
      if (updatedAt != null && DateTime.now().difference(updatedAt) > maxAge) {
        return null; // Caché vencida
      }

      final rawList = row['data'] as List<dynamic>? ?? [];
      return rawList.cast<Map<String, dynamic>>();
    } catch (e) {
      debugPrint('[Supabase] getCachedCandidatos($tipo) error: $e');
      return null;
    }
  }

  /// Almacena una lista de candidatos en la caché de Supabase.
  Future<void> cacheCandidatos(
    String tipo,
    List<Map<String, dynamic>> candidatos,
  ) async {
    if (candidatos.isEmpty || !_isReady) return;
    try {
      await _client.from('candidatos_cache').upsert({
        'tipo': tipo,
        'data': candidatos,
        'updated_at': DateTime.now().toIso8601String(),
      });
      debugPrint('[Supabase] ✅ Cached ${candidatos.length} candidatos ($tipo)');
    } catch (e) {
      debugPrint('[Supabase] cacheCandidatos($tipo) error: $e');
    }
  }

  /// Caché de planes de gobierno individuales.
  Future<Map<String, dynamic>?> getCachedPlan(
      int idOrganizacionPolitica) async {
    if (!_isReady) return null;
    try {
      final row = await _client
          .from('planes_cache')
          .select('plan_data, updated_at')
          .eq('id_organizacion_politica', idOrganizacionPolitica)
          .maybeSingle();

      if (row == null) return null;

      final updatedAt = DateTime.tryParse(row['updated_at'] as String? ?? '');
      if (updatedAt != null &&
          DateTime.now().difference(updatedAt) > const Duration(hours: 12)) {
        return null;
      }
      return row['plan_data'] as Map<String, dynamic>?;
    } catch (e) {
      debugPrint('[Supabase] getCachedPlan($idOrganizacionPolitica) error: $e');
      return null;
    }
  }

  Future<void> cachePlan(
    int idOrganizacionPolitica,
    Map<String, dynamic> planData,
  ) async {
    if (!_isReady) return;
    try {
      await _client.from('planes_cache').upsert({
        'id_organizacion_politica': idOrganizacionPolitica,
        'plan_data': planData,
        'updated_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      debugPrint('[Supabase] cachePlan($idOrganizacionPolitica) error: $e');
    }
  }

  // ─────────────────────────────────────────────────────────────────────
  //  Sincronización en segundo plano
  // ─────────────────────────────────────────────────────────────────────

  /// Dispara sincronización en segundo plano sin bloquear.
  /// Llamo esto al inicio de la app para calentar el caché remoto.
  void scheduleBgSync(Future<void> Function() syncTask) {
    Future.microtask(() async {
      try {
        await syncTask();
      } catch (e) {
        debugPrint('[SupabaseService] bg sync error: $e');
      }
    });
  }

  // ─────────────────────────────────────────────────────────────────────
  //  Analytics de uso
  // ─────────────────────────────────────────────────────────────────────

  /// Registra un evento de uso en Supabase.
  ///
  /// [eventType] — nombre del evento (ej. 'view_candidate', 'compare_candidates').
  /// [properties] — datos adicionales del evento (opcional).
  Future<void> trackEvent(
    String eventType, {
    Map<String, dynamic>? properties,
  }) async {
    // Respetar la configuración de analytics
    try {
      final prefs = await SharedPreferences.getInstance();
      final analyticsEnabled = prefs.getBool('analytics_enabled') ?? true;
      if (!analyticsEnabled) return;
    } catch (_) {}

    // No trackear en debug si está marcado así
    if (kDebugMode) {
      debugPrint('[Analytics] $eventType ${properties ?? ''}');
    }

    if (!_isReady) return;
    try {
      final sessionId = await getSessionId();
      await _client.from('analytics_events').insert({
        'event_type': eventType,
        'properties': properties ?? {},
        'session_id': sessionId,
        'created_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      debugPrint('[Supabase] trackEvent($eventType) error: $e');
    }
  }

  /// Shortcut para trackear vista de pantalla.
  Future<void> trackScreenView(String screenName,
          {Map<String, dynamic>? extra}) =>
      trackEvent('screen_view', properties: {'screen': screenName, ...?extra});

  /// Shortcut para trackear vista de candidato.
  Future<void> trackCandidateView(
    String candidatoId,
    String candidatoNombre,
  ) =>
      trackEvent('view_candidate', properties: {
        'candidato_id': candidatoId,
        'candidato_nombre': candidatoNombre,
      });

  /// Shortcut para trackear comparación.
  Future<void> trackComparison(String candidatoA, String candidatoB) =>
      trackEvent('compare_candidates', properties: {
        'candidato_a': candidatoA,
        'candidato_b': candidatoB,
      });

  /// Shortcut para trackear uso del simulador.
  Future<void> trackSimulatorVote(String candidatoNombre) =>
      trackEvent('simulator_vote', properties: {
        'candidato': candidatoNombre,
      });
}
