import 'dart:async' show Timer;
import 'dart:math' show exp, sqrt;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'candidatos_cache_service.dart';
import '../models/electoral_models.dart';
import '../services/ai_electoral_service.dart';
import '../services/rss_news_service.dart';
import '../services/jne_api_service.dart';
import '../services/encuestas_remote_service.dart';
import '../services/pdf_service.dart';
import '../services/supabase_service.dart';
import '../services/cors_proxy.dart';

// ─── Servicios singleton ─────────────────────────────────────────────────────

final rssNewsServiceProvider = Provider<RssNewsService>((ref) {
  return RssNewsService();
});

final jneApiServiceProvider = Provider<JneApiService>((ref) {
  return JneApiService();
});

final encuestasRemoteServiceProvider = Provider<EncuestasRemoteService>((ref) {
  return EncuestasRemoteService();
});

final aiServiceProvider = Provider<AiElectoralService>((ref) {
  return AiElectoralService();
});

final pdfServiceProvider = Provider<PdfService>((ref) {
  return PdfService();
});

/// Singleton de SupabaseService (acceso directo a la instancia estática).
final supabaseServiceProvider = Provider<SupabaseService>((ref) {
  return SupabaseService.instance;
});

// ─── Configuración de Usuario ────────────────────────────────────────────────────

/// Provider para el modo de tema (light/dark/system).
/// El valor inicial se carga desde SharedPreferences/Supabase en [VotaClaro._loadSavedTheme].
final themeModeProvider = StateProvider<ThemeMode>((ref) {
  return ThemeMode.light;
});

// ─── Candidatos (todos desde API JNE Voto Informado) ─────────────────────────

/// Candidatos presidenciales desde la API real del JNE.
final candidatosPresidenteProvider =
    FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
  // Keep alive to avoid refetching on navigation
  ref.keepAlive();
  final cache = ref.read(candidatosCacheServiceProvider);
  final jne = ref.read(jneApiServiceProvider);

  final hit = await cache.get('presidente');
  if (hit != null && hit.data.isNotEmpty) {
    if (DateTime.now().difference(hit.ts) > const Duration(minutes: 5)) {
      Future.microtask(() async {
        try {
          final fresh = await jne.getCandidatosPresidente();
          if (fresh.isNotEmpty) await cache.set('presidente', fresh);
        } catch (_) {}
      });
    }
    return hit.data;
  }

  try {
    final data = await jne.getCandidatosPresidente();
    if (data.isNotEmpty) {
      await cache.set('presidente', data);
      return data;
    }
  } catch (_) {}

  return []; // Sin datos offline — API es la única fuente real
});

/// Diputados (Congresistas) por departamento desde JNE.
final candidatosCongresoProvider = FutureProvider.autoDispose
    .family<List<Map<String, dynamic>>, String>((ref, departamento) async {
  final cache = ref.read(candidatosCacheServiceProvider);
  final jne = ref.read(jneApiServiceProvider);
  final cacheKey = 'diputados_$departamento';

  final hit = await cache.get(cacheKey);
  if (hit != null && hit.data.isNotEmpty) {
    if (DateTime.now().difference(hit.ts) > const Duration(minutes: 5)) {
      Future.microtask(() async {
        try {
          final fresh = await jne.getDiputados(departamento);
          if (fresh.isNotEmpty) await cache.set(cacheKey, fresh);
        } catch (_) {}
      });
    }
    return hit.data;
  }

  try {
    final data = await jne.getDiputados(departamento);
    if (data.isNotEmpty) {
      await cache.set(cacheKey, data);
      return data;
    }
  } catch (_) {}

  return [];
});

/// Candidatos al Parlamento Andino desde JNE.
final candidatosAndinoProvider =
    FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
  final cache = ref.read(candidatosCacheServiceProvider);
  final jne = ref.read(jneApiServiceProvider);

  final hit = await cache.get('andino');
  if (hit != null && hit.data.isNotEmpty) {
    if (DateTime.now().difference(hit.ts) > const Duration(minutes: 5)) {
      Future.microtask(() async {
        try {
          final fresh = await jne.getParlamentoAndino();
          if (fresh.isNotEmpty) await cache.set('andino', fresh);
        } catch (_) {}
      });
    }
    return hit.data;
  }

  try {
    final data = await jne.getParlamentoAndino();
    if (data.isNotEmpty) {
      await cache.set('andino', data);
      return data;
    }
  } catch (_) {}

  return [];
});

/// Senadores por departamento desde JNE.
final candidatosSenadoresProvider = FutureProvider.autoDispose
    .family<List<Map<String, dynamic>>, String>((ref, departamento) async {
  final cache = ref.read(candidatosCacheServiceProvider);
  final jne = ref.read(jneApiServiceProvider);
  final cacheKey = 'senadores_$departamento';

  final hit = await cache.get(cacheKey);
  if (hit != null && hit.data.isNotEmpty) {
    if (DateTime.now().difference(hit.ts) > const Duration(minutes: 5)) {
      Future.microtask(() async {
        try {
          final fresh = await jne.getSenadores(departamento);
          if (fresh.isNotEmpty) await cache.set(cacheKey, fresh);
        } catch (_) {}
      });
    }
    return hit.data;
  }

  try {
    final data = await jne.getSenadores(departamento);
    if (data.isNotEmpty) {
      await cache.set(cacheKey, data);
      return data;
    }
  } catch (_) {}

  return [];
});

/// Partidos políticos con logos desde JNE IA API.
final partidosPoliticosProvider = FutureProvider.autoDispose
    .family<List<Map<String, dynamic>>, int>((ref, idTipoEleccion) async {
  final jne = ref.read(jneApiServiceProvider);
  return jne.getPartidosPoliticos(idTipoEleccion);
});

/// Perfil enriquecido: busca candidato + trae HojaVida y Plan de Gobierno del JNE.
final candidatoPerfilProvider = FutureProvider.autoDispose
    .family<Map<String, dynamic>, String>((ref, candidatoId) async {
  Map<String, dynamic>? base;

  // Buscar en las 4 listas cargadas
  for (final future in [
    ref.read(candidatosPresidenteProvider.future),
    ref.read(candidatosCongresoProvider('Lima').future),
    ref.read(candidatosSenadoresProvider('Lima').future),
    ref.read(candidatosAndinoProvider.future),
  ]) {
    try {
      final list = await future;
      final match = list.where((c) => c['id'] == candidatoId);
      if (match.isNotEmpty) {
        base = Map<String, dynamic>.from(match.first);
        break;
      }
    } catch (_) {}
  }

  if (base == null) return {};

  final jne = ref.read(jneApiServiceProvider);
  final idOP = base['idOrganizacionPolitica'] as int? ?? 0;
  final dni = base['dni'] as String? ?? '';

  // Enriquecer con HojaVida, Plan de Gobierno y Fórmula Presidencial en paralelo
  final results = await Future.wait([
    (dni.isNotEmpty && idOP > 0)
        ? jne.getHojaVida(dni, idOP)
        : Future.value(<String, dynamic>{}),
    (idOP > 0) ? jne.getPlanGobierno(idOP) : Future.value(null),
    (idOP > 0)
        ? jne.getFormulaPresidencial(idOP)
        : Future.value(<Map<String, dynamic>>[]),
  ]);

  final hvRaw = results[0] as Map<String, dynamic>? ?? {};
  final planMeta = results[1] as Map<String, dynamic>?;
  final formulaRaw = results[2] as List<Map<String, dynamic>>? ?? [];

  // ─ Fórmula presidencial (Presidente + VP1 + VP2) ─
  base['formulaPresidencial'] = formulaRaw;

  // ─ Hoja de vida ─
  final hvData = hvRaw['data'] as Map<String, dynamic>? ?? {};
  final personal = hvData['oDatosPersonales'] as Map<String, dynamic>? ?? {};
  final experiencia = hvData['lExperienciaLaboral'] as List? ?? [];
  final eduUni = hvData['lEduUniversitaria'] as List? ?? [];
  final eduPosgrado = hvData['lEduPosgrado'] as List? ?? [];
  final cargosElec = hvData['lCargoEleccion'] as List? ?? [];
  final sentPenal = hvData['lSentenciaPenal'] as List? ?? [];
  final sentObliga = hvData['lSentenciaObliga'] as List? ?? [];
  final ingresos = hvData['oIngresos'] as Map<String, dynamic>? ?? {};
  final bienesMueble = hvData['lBienMueble'] as List? ?? [];
  final bienesInmueble = hvData['lBienInmueble'] as List? ?? [];
  final titularidad = hvData['lTitularidad'] as List? ?? [];
  final infoAdicional = hvData['lInfoAdicional'] as List? ?? [];
  final renunciaOP = hvData['lRenunciaOP'] as List? ?? [];

  base['hojaVida'] = {
    'nacimiento': personal['strPaisNacimiento'] ?? '',
    'domicilio':
        '${personal['strDomiDepartamento'] ?? ''}, ${personal['strDomiDistrito'] ?? ''}',
    'educacion': [
      ...eduUni.map((e) {
        final mapa = e as Map<String, dynamic>;
        return {
          'tipo': 'Universidad',
          'centro': mapa['strUniversidad'] ?? '',
          'carrera': mapa['strCarreraUni'] ?? '',
          'concluido': mapa['strConcluidoEduUni'] == '1',
        };
      }),
      ...eduPosgrado.map((e) {
        final mapa = e as Map<String, dynamic>;
        return {
          'tipo': 'Posgrado',
          'centro': mapa['strCenEstudioPosgrado'] ?? '',
          'carrera': mapa['strEspecialidadPosgrado'] ?? '',
          'concluido': mapa['strConcluidoPosgrado'] == '1',
        };
      }),
    ],
    'experiencia': experiencia.map((e) {
      final mapa = e as Map<String, dynamic>;
      return {
        'centro': mapa['strCentroTrabajo'] ?? '',
        'cargo': mapa['strOcupacionProfesion'] ?? '',
        'desde': mapa['strAnioTrabajoDesde'] ?? '',
        'hasta': mapa['strAnioTrabajoHasta'] ?? '',
      };
    }).toList(),
    'cargosEleccion': cargosElec.map((e) {
      final mapa = e as Map<String, dynamic>;
      return {
        'cargo': mapa['strCargoEleccion'] ?? '',
        'desde': mapa['strAnioCargoElecDesde'] ?? '',
        'hasta': mapa['strAnioCargoElecHasta'] ?? '',
        'partido': mapa['strOrgPolCargoElec'] ?? '',
      };
    }).toList(),
    'sentenciasPenales': sentPenal.length,
    'sentenciasObligatorias': sentObliga.length,
    'renuncias': renunciaOP.map((e) {
      final mapa = e as Map<String, dynamic>;
      return {
        'partido': mapa['strOrgPolRenunciaOP'] ?? '',
        'anio': mapa['strAnioRenunciaOP'] ?? '',
      };
    }).toList(),
    'ingresoPublico': _parseDouble(ingresos['decRemuBrutaPublico']),
    'ingresoPrivado': _parseDouble(ingresos['decRemuBrutaPrivado']),
    'bienesMueble': bienesMueble.map((e) {
      final mapa = e as Map<String, dynamic>;
      return {
        'descripcion': mapa['strVehiculo'] ?? '',
        'valor': _parseDouble(mapa['decValor']),
      };
    }).toList(),
    'bienesInmueble': bienesInmueble.map((e) {
      final mapa = e as Map<String, dynamic>;
      return {
        'direccion': mapa['strDireccion'] ?? mapa['strPartidaRegistral'] ?? '',
        'valor': _parseDouble(mapa['decAutoavaluo']),
      };
    }).toList(),
    'titularidad': titularidad.map((e) {
      final mapa = e as Map<String, dynamic>;
      return {
        'empresa': mapa['strPersonaJuridica'] ?? '',
        'tipo': mapa['strTipoTitularidad'] ?? '',
        'valor': _parseDouble(mapa['decValor']),
      };
    }).toList(),
    'infoAdicional': infoAdicional
        .map((e) =>
            (e as Map<String, dynamic>)['strInfoAdicional'] as String? ?? '')
        .where((s) => s.isNotEmpty)
        .toList(),
  };

  // ─ Plan de gobierno ─
  if (planMeta != null) {
    final idPlan = planMeta['idPlanGobierno'] as int? ?? 0;
    final rutaCompleto = planMeta['txRutaCompleto'] as String? ?? '';
    final rutaResumen = planMeta['txRutaResumen'] as String? ?? '';

    Map<String, dynamic> detalle = {};
    if (idPlan > 0) {
      // Check Supabase cache first
      final supa = ref.read(supabaseServiceProvider);
      final cached = await supa.getCachedPlan(idOP);
      if (cached != null && cached.isNotEmpty) {
        detalle = cached;
      } else {
        detalle = await jne.getPlanGobiernoDetalle(idPlan);
        if (detalle.isNotEmpty) {
          supa.cachePlan(idOP, detalle);
        }
      }
    }

    base['planGobierno'] = {
      'rutaCompleto': rutaCompleto,
      'rutaResumen': rutaResumen,
      'dimensiones': {
        'Social': (detalle['dimensionSocial'] as List? ?? [])
            .map((e) => Map<String, dynamic>.from(e as Map))
            .toList(),
        'Económica': (detalle['dimensionEconomica'] as List? ?? [])
            .map((e) => Map<String, dynamic>.from(e as Map))
            .toList(),
        'Ambiental': (detalle['dimensionAmbiental'] as List? ?? [])
            .map((e) => Map<String, dynamic>.from(e as Map))
            .toList(),
        'Institucional': (detalle['dimensionInstitucional'] as List? ?? [])
            .map((e) => Map<String, dynamic>.from(e as Map))
            .toList(),
      },
    };
  }

  return base;
});

double _parseDouble(dynamic val) {
  if (val == null) return 0.0;
  if (val is num) return val.toDouble();
  return double.tryParse(val.toString()) ?? 0.0;
}

// ─── Comparación ─────────────────────────────────────────────────────────────

final comparacionProvider = FutureProvider.autoDispose
    .family<Map<String, dynamic>, ({String candidatoA, String candidatoB})>(
        (ref, params) async {
  final aiService = ref.read(aiServiceProvider);
  final result = await aiService.compararCandidatos(
    candidatoA: params.candidatoA,
    candidatoB: params.candidatoB,
  );
  return result['data'] ?? {};
});

// ─── Mi Voto ─────────────────────────────────────────────────────────────────

class MiVotoState {
  final List<PriudadCiudadana> prioridades;
  final List<ResultadoMiVoto>? resultados;
  final bool isLoading;
  final String? error;

  const MiVotoState({
    this.prioridades = const [],
    this.resultados,
    this.isLoading = false,
    this.error,
  });

  MiVotoState copyWith({
    List<PriudadCiudadana>? prioridades,
    List<ResultadoMiVoto>? resultados,
    bool? isLoading,
    String? error,
  }) =>
      MiVotoState(
        prioridades: prioridades ?? this.prioridades,
        resultados: resultados ?? this.resultados,
        isLoading: isLoading ?? this.isLoading,
        error: error,
      );
}

class MiVotoNotifier extends StateNotifier<MiVotoState> {
  MiVotoNotifier(this._ref) : super(const MiVotoState());

  final Ref _ref;

  /// Mapea las prioridades del usuario a las dimensiones del plan de gobierno JNE.
  static const Map<String, String> _prioridadToDimension = {
    'Seguridad ciudadana': 'dimensionInstitucional',
    'Empleo y economía': 'dimensionEconomica',
    'Salud universal': 'dimensionSocial',
    'Educación de calidad': 'dimensionSocial',
    'Lucha contra corrupción': 'dimensionInstitucional',
    'Medio ambiente': 'dimensionAmbiental',
    'Descentralización': 'dimensionInstitucional',
    'Igualdad de género': 'dimensionSocial',
    'Derechos humanos': 'dimensionSocial',
    'Relaciones exteriores': 'dimensionEconomica',
    'Agricultura y zonas rurales': 'dimensionEconomica',
    'Transporte e infraestructura': 'dimensionEconomica',
  };

  /// Keywords per priority for proposal-level matching
  static const Map<String, List<String>> _prioridadKeywords = {
    'Seguridad ciudadana': [
      'seguridad',
      'polici',
      'delincuencia',
      'crimen',
      'violencia',
      'narco',
      'inseguridad',
      'patrullaje',
      'serenazgo',
      'orden',
      'penitenciar',
    ],
    'Empleo y economía': [
      'empleo',
      'trabajo',
      'econom',
      'productiv',
      'inversion',
      'pyme',
      'empresa',
      'salar',
      'formal',
      'desempleo',
      'competitiv',
    ],
    'Salud universal': [
      'salud',
      'hospital',
      'medic',
      'sanitar',
      'vacun',
      'enferm',
      'atencion primaria',
      'sis',
      'essalud',
      'clinica',
    ],
    'Educación de calidad': [
      'educac',
      'escuel',
      'universid',
      'docent',
      'maestro',
      'aprendiz',
      'curricul',
      'analfabet',
      'beca',
      'formac',
    ],
    'Lucha contra corrupción': [
      'corrupc',
      'transparenc',
      'rendicion',
      'fiscaliz',
      'control',
      'integridad',
      'soborno',
      'lavado',
      'controlor',
    ],
    'Medio ambiente': [
      'ambient',
      'contaminac',
      'ecolog',
      'reciclaj',
      'sostenib',
      'cambio climatico',
      'deforestac',
      'biodiversid',
      'agua',
      'residuo',
    ],
    'Descentralización': [
      'descentraliz',
      'region',
      'municipal',
      'subnacional',
      'local',
      'territorio',
      'provincial',
      'gobernanza',
    ],
    'Igualdad de género': [
      'genero',
      'mujer',
      'feminicid',
      'igualdad',
      'paridad',
      'violencia de genero',
      'brecha',
      'maternidad',
    ],
    'Derechos humanos': [
      'derechos humanos',
      'libertad',
      'discriminac',
      'inclusion',
      'vulnerab',
      'indigena',
      'discapacid',
    ],
    'Relaciones exteriores': [
      'exterior',
      'internacion',
      'diplomac',
      'tratado',
      'comercio exterior',
      'exportac',
      'frontera',
      'alianza',
    ],
    'Agricultura y zonas rurales': [
      'agr',
      'rural',
      'campesino',
      'riego',
      'cosecha',
      'ganaderi',
      'agroexport',
      'tierra',
      'siembra',
    ],
    'Transporte e infraestructura': [
      'transporte',
      'infraestruct',
      'carretera',
      'vial',
      'ferroviar',
      'puente',
      'puerto',
      'aeropuerto',
      'metro',
    ],
  };

  void togglePrioridad(PriudadCiudadana prioridad) {
    final current = List<PriudadCiudadana>.from(state.prioridades);
    if (current.contains(prioridad)) {
      current.remove(prioridad);
    } else if (current.length < 5) {
      current.add(prioridad);
    }
    state = state.copyWith(prioridades: current);
  }

  Future<void> calcularMatch() async {
    if (state.prioridades.length < 3) return;

    state = state.copyWith(isLoading: true, error: null);

    try {
      final jne = _ref.read(jneApiServiceProvider);
      final supa = _ref.read(supabaseServiceProvider);
      final candidatos = await _ref.read(candidatosPresidenteProvider.future);
      final labels = state.prioridades.map((p) => p.label).toList();

      // 1. Fetch all plan details — Supabase cache first, then API
      final detalleFutures = candidatos.map((c) async {
        final idOP = c['idOrganizacionPolitica'] as int? ?? 0;
        if (idOP <= 0) return <String, dynamic>{};

        // L1: Supabase cache
        final cached = await supa.getCachedPlan(idOP);
        if (cached != null && cached.isNotEmpty) return cached;

        // L2: JNE API
        final plan = await jne.getPlanGobierno(idOP).catchError((_) => null);
        if (plan == null) return <String, dynamic>{};
        final idPlan = plan['idPlanGobierno'] as int? ?? 0;
        if (idPlan <= 0) return <String, dynamic>{};

        final detalle = await jne
            .getPlanGobiernoDetalle(idPlan)
            .catchError((_) => <String, dynamic>{});
        if (detalle.isNotEmpty) supa.cachePlan(idOP, detalle);
        return detalle;
      }).toList();
      final detalles = await Future.wait(detalleFutures);

      // 3. Score all candidates with keyword-level matching (not just dimension count)
      final resultados = <ResultadoMiVoto>[];
      for (int i = 0; i < candidatos.length; i++) {
        final c = candidatos[i];
        final detalle = detalles[i] as Map<String, dynamic>? ?? {};
        final nombre = c['nombreCompleto'] as String? ?? '';
        final partido = c['partido'] as String? ?? '';
        final id = c['id'] as String? ?? '';
        final edad = (c['edad'] as num?)?.toInt() ?? 0;

        double score = 0;
        final matchedAreas = <String>[];
        final weakAreas = <String>[];

        for (final label in labels) {
          final dim = _prioridadToDimension[label] ?? 'dimensionSocial';
          final items = detalle[dim] as List? ?? [];
          final keywords = _prioridadKeywords[label] ?? [];

          // Count proposals that match keywords for this specific priority
          int keywordMatches = 0;
          for (final item in items) {
            final text = [
              (item['txPgProblema'] ?? '').toString(),
              (item['txPgObjetivo'] ?? '').toString(),
              (item['txPgMeta'] ?? '').toString(),
            ].join(' ').toLowerCase();

            final hasKeyword = keywords.any((kw) => text.contains(kw));
            if (hasKeyword) keywordMatches++;
          }

          // Score based on keyword-matched proposals (not just dimension count)
          if (keywordMatches >= 3) {
            score += 10;
            matchedAreas.add('$label ($keywordMatches propuestas específicas)');
          } else if (keywordMatches >= 2) {
            score += 7;
            matchedAreas.add(label);
          } else if (keywordMatches == 1) {
            score += 4;
          } else if (items.isNotEmpty) {
            // Has proposals in the dimension but none match the specific priority
            score += 1;
            weakAreas.add('$label (propuestas genéricas, no específicas)');
          } else {
            // No proposals at all in this dimension
            score += 0;
            weakAreas.add('$label (sin propuestas)');
          }
        }

        final maxPossible = labels.length * 10.0;
        final matchPct = maxPossible > 0 ? (score / maxPossible) * 100 : 0.0;

        final buffer = StringBuffer();
        if (edad > 0) {
          buffer.write('👤 $edad años. ');
        }
        if (matchedAreas.isNotEmpty) {
          buffer.write('✅ Fuerte en: ${matchedAreas.join(", ")}. ');
        }
        if (weakAreas.isNotEmpty) {
          buffer.write('⚠️ Débil en: ${weakAreas.join(", ")}. ');
        }
        buffer.write('[Fuente: Plan de gobierno JNE 2026]');

        final alertas = <String>[];
        for (final label in labels) {
          final dim = _prioridadToDimension[label] ?? 'dimensionSocial';
          final items = detalle[dim] as List? ?? [];
          final keywords = _prioridadKeywords[label] ?? [];
          final keywordMatches = items.where((item) {
            final text = [
              (item['txPgProblema'] ?? '').toString(),
              (item['txPgObjetivo'] ?? '').toString(),
              (item['txPgMeta'] ?? '').toString(),
            ].join(' ').toLowerCase();
            return keywords.any((kw) => text.contains(kw));
          }).length;
          if (keywordMatches == 0) {
            alertas.add('⚠️ No tiene propuestas específicas sobre: $label');
          }
        }

        resultados.add(ResultadoMiVoto(
          candidatoId: id,
          nombreCandidato: nombre,
          partido: partido,
          porcentajeMatch: matchPct,
          explicacion: buffer.toString(),
          alertasContradiccion: alertas,
          edad: edad,
        ));
      }

      resultados.sort((a, b) => b.porcentajeMatch.compareTo(a.porcentajeMatch));

      state = state.copyWith(isLoading: false, resultados: resultados);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  void reiniciar() => state = const MiVotoState();
}

final miVotoProvider =
    StateNotifierProvider<MiVotoNotifier, MiVotoState>((ref) {
  return MiVotoNotifier(ref);
});

// ─── Encuestas ───────────────────────────────────────────────────────────────

/// Encuestas de intención de voto obtenidas desde un GitHub Gist mantenido
/// manualmente por el administrador.  Ver [EncuestasRemoteService] para el
/// formato JSON y las instrucciones de actualización.
/// Se refresca automáticamente cada 30 minutos para mantener datos al día.
final encuestasProvider = FutureProvider<List<Encuesta>>((ref) async {
  // Auto-refresh cada 15 minutos — siempre trae lo último de Peru21/Ipsos
  final timer = Timer(const Duration(minutes: 15), ref.invalidateSelf);
  ref.onDispose(timer.cancel);

  final service = ref.read(encuestasRemoteServiceProvider);
  return service.fetchEncuestas();
});

// ─── Noticias (RSS en vivo) ───────────────────────────────────────────────────

final noticiasProvider = FutureProvider.autoDispose<List<Noticia>>((ref) async {
  final rssService = ref.read(rssNewsServiceProvider);
  return rssService.fetchAll();
});

/// Provider filtrado por categoría
final noticiasPorCategoriaProvider = FutureProvider.autoDispose
    .family<List<Noticia>, CategoriaFuente?>((ref, categoria) async {
  final rssService = ref.read(rssNewsServiceProvider);
  return rssService.fetchAll(categoria: categoria);
});

// ─── JNE Candidatos ──────────────────────────────────────────────────────────

final candidatosJneProvider =
    FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
  return ref.read(candidatosPresidenteProvider.future);
});

// ─── Real-time candidatos: caché L1/L2 + paginación + pull-to-refresh ─────────

final candidatosCacheServiceProvider = Provider<CandidatosCacheService>((ref) {
  return CandidatosCacheService();
});

/// Immutable UI state for an infinite-scroll, pull-to-refresh candidate list.
class CandidatosPageState {
  final List<Map<String, dynamic>> items;
  final bool isLoading;
  final bool isLoadingMore;
  final bool hasMore;
  final int page;
  final DateTime? fetchedAt;
  final String? error;

  const CandidatosPageState({
    this.items = const [],
    this.isLoading = false,
    this.isLoadingMore = false,
    this.hasMore = false,
    this.page = 0,
    this.fetchedAt,
    this.error,
  });

  CandidatosPageState copyWith({
    List<Map<String, dynamic>>? items,
    bool? isLoading,
    bool? isLoadingMore,
    bool? hasMore,
    int? page,
    DateTime? fetchedAt,
    String? error,
  }) =>
      CandidatosPageState(
        items: items ?? this.items,
        isLoading: isLoading ?? this.isLoading,
        isLoadingMore: isLoadingMore ?? this.isLoadingMore,
        hasMore: hasMore ?? this.hasMore,
        page: page ?? this.page,
        fetchedAt: fetchedAt ?? this.fetchedAt,
        error: error ?? this.error,
      );
}

/// Notifier that manages fetching, caching, and pagination for any candidate
/// list.  The full result set is fetched once; subsequent "pages" are sliced
/// client-side for instant infinite scroll with zero extra network calls.
class CandidatosNotifier extends StateNotifier<CandidatosPageState> {
  CandidatosNotifier({
    required CandidatosCacheService cache,
    required String cacheKey,
    required Future<List<Map<String, dynamic>>> Function() fetchFn,
    Future<List<Map<String, dynamic>>> Function()? fallbackFn,
    SupabaseService? supabase,
  })  : _cache = cache,
        _cacheKey = cacheKey,
        _fetchFn = fetchFn,
        _fallbackFn = fallbackFn ?? (() async => []),
        _supabase = supabase,
        super(const CandidatosPageState());

  final CandidatosCacheService _cache;
  final String _cacheKey;
  final Future<List<Map<String, dynamic>>> Function() _fetchFn;
  final Future<List<Map<String, dynamic>>> Function() _fallbackFn;
  final SupabaseService? _supabase;

  static const int _pageSize = 20;
  List<Map<String, dynamic>> _all = [];
  bool _initialised = false;

  /// Called once on provider creation.
  /// Serves L1/L2 cache immediately; silently refreshes if stale (> 5 min).
  Future<void> init() async {
    if (_initialised) return;
    _initialised = true;
    state = state.copyWith(isLoading: true, error: null);

    // L1/L2: local cache
    final hit = await _cache.get(_cacheKey);
    if (hit != null && hit.data.isNotEmpty) {
      _all = hit.data;
      _applyPage(reset: true, fetchedAt: hit.ts);
      if (DateTime.now().difference(hit.ts) > const Duration(minutes: 5)) {
        _silentRefresh();
      }
      return;
    }

    // L3: Supabase remote cache
    if (_supabase != null && _supabase.isReady) {
      final remote = await _supabase.getCachedCandidatos(_cacheKey);
      if (remote != null && remote.isNotEmpty) {
        _all = remote;
        await _cache.set(_cacheKey, _all);
        _applyPage(reset: true, fetchedAt: DateTime.now());
        _silentRefresh(); // refresh from API in background
        return;
      }
    }

    await _fetchAndPersist();
  }

  /// Pull-to-refresh: invalidates cache and fetches fresh data.
  Future<void> refresh() async {
    await _cache.invalidate(_cacheKey);
    _all = [];
    state = state.copyWith(isLoading: true, error: null);
    await _fetchAndPersist();
  }

  /// Loads the next page from the already-fetched full list (client-side).
  Future<void> loadMore() async {
    if (state.isLoadingMore || !state.hasMore) return;
    state = state.copyWith(isLoadingMore: true);
    await Future.delayed(const Duration(milliseconds: 120)); // smooth UX
    _applyPage();
  }

  // ── Private ──────────────────────────────────────────────────────────────

  Future<void> _fetchAndPersist() async {
    try {
      final data = await _fetchFn();
      _all = data.isNotEmpty ? data : await _fallbackFn();
      await _cache.set(_cacheKey, _all);
      // Persist to Supabase L3
      if (_all.isNotEmpty && _supabase != null && _supabase.isReady) {
        _supabase.cacheCandidatos(_cacheKey, _all);
      }
      _applyPage(reset: true, fetchedAt: DateTime.now());
    } catch (_) {
      _all = await _fallbackFn();
      _applyPage(reset: true, fetchedAt: DateTime.now());
    }
  }

  /// Background refresh — updates state silently without showing a spinner.
  Future<void> _silentRefresh() async {
    try {
      final data = await _fetchFn();
      if (data.isNotEmpty) {
        _all = data;
        await _cache.set(_cacheKey, _all);
        _applyPage(reset: true, fetchedAt: DateTime.now());
      }
    } catch (_) {}
  }

  void _applyPage({bool reset = false, DateTime? fetchedAt}) {
    final already = reset ? 0 : state.items.length;
    final newPage = reset ? 1 : state.page + 1;
    final end = (newPage * _pageSize).clamp(0, _all.length);
    if (already >= end && !reset) {
      state = state.copyWith(
          isLoading: false, isLoadingMore: false, hasMore: false);
      return;
    }
    final slice = _all.sublist(already, end);
    final items = reset ? slice : [...state.items, ...slice];
    state = state.copyWith(
      items: items,
      isLoading: false,
      isLoadingMore: false,
      hasMore: end < _all.length,
      page: newPage,
      fetchedAt: fetchedAt ?? state.fetchedAt,
      error: null,
    );
  }
}

/// Provider family keyed by candidate type string:
///   'presidente'  — JNE Voto Informado real API
///   'congreso'    — JNE diputados (Lima por defecto)
///   'senadores'   — JNE senadores (Lima por defecto)
///   'andino'      — JNE Parlamento Andino
final candidatosPaginadosProvider = StateNotifierProvider.family
    .autoDispose<CandidatosNotifier, CandidatosPageState, String>((ref, tipo) {
  final cache = ref.read(candidatosCacheServiceProvider);
  final jne = ref.read(jneApiServiceProvider);

  final Future<List<Map<String, dynamic>>> Function() fetchFn;

  if (tipo == 'presidente') {
    fetchFn = jne.getCandidatosPresidente;
  } else if (tipo.startsWith('congreso')) {
    final dep = tipo.contains('_') ? tipo.split('_').last : 'Lima';
    fetchFn = () => jne.getDiputados(dep);
  } else if (tipo.startsWith('senadores')) {
    final dep = tipo.contains('_') ? tipo.split('_').last : 'Lima';
    fetchFn = () => jne.getSenadores(dep);
  } else if (tipo == 'andino') {
    fetchFn = jne.getParlamentoAndino;
  } else {
    fetchFn = () async => [];
  }

  final supa = ref.read(supabaseServiceProvider);
  final notifier = CandidatosNotifier(
    cache: cache,
    cacheKey: tipo,
    fetchFn: fetchFn,
    fallbackFn: () async => [],
    supabase: supa,
  );
  notifier.init();
  return notifier;
});

// ─── Top candidatos por promedio de encuestas ───────────────────────────────

/// Computes average poll % per candidate from all encuestas,
/// then merges with JNE candidate data, sorted by popularity (desc).
final topCandidatosPorEncuestaProvider =
    FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
  final candidatos = await ref.watch(candidatosPresidenteProvider.future);
  final encuestas = await ref.watch(encuestasProvider.future);

  if (encuestas.isEmpty || candidatos.isEmpty) return candidatos;

  // Promedio ponderado: peso = recencia × sqrt(tamaño_muestra / máximo)
  // Encuestas recientes y de mayor muestra tienen más peso en el ranking
  final maxMuestreo =
      encuestas.fold<int>(1, (m, e) => e.muestreo > m ? e.muestreo : m);
  final now = DateTime.now();
  final totalsW = <String, double>{};
  final weightsW = <String, double>{};
  final nameMap = <String, String>{}; // candidatoId → nombreCandidato

  for (final enc in encuestas) {
    final daysOld = now.difference(enc.fechaPublicacion).inDays.clamp(0, 180);
    final recencyW = exp(-daysOld / 21.0); // decaimiento cada 21 días
    final sampleW = sqrt(enc.muestreo / maxMuestreo.toDouble());
    final weight = recencyW * sampleW;

    for (final r in enc.resultados) {
      totalsW[r.candidatoId] =
          (totalsW[r.candidatoId] ?? 0) + r.porcentaje * weight;
      weightsW[r.candidatoId] = (weightsW[r.candidatoId] ?? 0) + weight;
      nameMap[r.candidatoId] = r.nombreCandidato;
    }
  }

  final promedios = <String, double>{};
  for (final id in totalsW.keys) {
    promedios[id] = totalsW[id]! / weightsW[id]!;
  }

  // Match encuesta names to JNE candidates by fuzzy name matching
  String _normalize(String s) => s
      .toLowerCase()
      .replaceAll(RegExp(r'[áàä]'), 'a')
      .replaceAll(RegExp(r'[éèë]'), 'e')
      .replaceAll(RegExp(r'[íìï]'), 'i')
      .replaceAll(RegExp(r'[óòö]'), 'o')
      .replaceAll(RegExp(r'[úùü]'), 'u')
      .replaceAll(RegExp(r'[^a-z0-9 ]'), '')
      .trim();

  final enriched = <Map<String, dynamic>>[];
  for (final c in candidatos) {
    final nombre = c['nombreCompleto'] as String? ?? '';
    final normNombre = _normalize(nombre);

    // Find best matching encuesta entry
    double bestPct = 0;
    for (final entry in nameMap.entries) {
      final normEnc = _normalize(entry.value);
      // Match by surname overlap
      final encWords = normEnc.split(' ');
      final cWords = normNombre.split(' ');
      final overlap =
          encWords.where((w) => cWords.contains(w) && w.length > 2).length;
      if (overlap >= 1 && promedios[entry.key]! > bestPct) {
        bestPct = promedios[entry.key]!;
      }
    }

    if (bestPct > 0) {
      enriched.add({...c, 'promedioEncuesta': bestPct});
    }
  }

  enriched.sort((a, b) => (b['promedioEncuesta'] as double)
      .compareTo(a['promedioEncuesta'] as double));

  // Enrich with partido logo URLs
  final logosList = await ref.watch(partidosPoliticosProvider(1).future);
  final logoMap = <String, String>{};
  for (final item in logosList) {
    final raw = item['TXORGANIZACIONPOLITICA'] as String? ?? '';
    final normalized = raw
        .split(' ')
        .map((w) => w.isEmpty
            ? w
            : '${w[0].toUpperCase()}${w.substring(1).toLowerCase()}')
        .join(' ');
    final url = item['TXURLORGANIZACIONPOLITICA'] as String? ?? '';
    if (normalized.isNotEmpty && url.isNotEmpty)
      logoMap[normalized] = CorsProxy.imageUrl(url);
  }

  return enriched.map((c) {
    final partido = c['partido'] as String? ?? '';
    final logo = logoMap[partido];
    return logo != null ? {...c, 'logoPartidoUrl': logo} : c;
  }).toList();
});

// ─── Tab de elección seleccionada en Inicio ──────────────────────────────────

final selectedEleccionTabProvider = StateProvider<int>((ref) => 0);

// ─── PDF parsing para planes de gobierno ─────────────────────────────────────

/// Parsea el contenido de un PDF de plan de gobierno desde una URL.
/// El resultado es cacheado en memoria durante la sesión.
final parsedPdfProvider = FutureProvider.autoDispose
    .family<Map<String, dynamic>, String>((ref, pdfUrl) async {
  if (pdfUrl.isEmpty) return {};

  final pdfService = ref.read(pdfServiceProvider);

  try {
    // Extraer texto del PDF
    final text = await pdfService.extractTextFromUrl(pdfUrl);

    // Parsear y estructurar el contenido
    final structured = pdfService.parseStructuredPlan(text);

    // Extraer keywords
    final keywords = pdfService.extractKeywords(text);

    return {
      ...structured,
      'keywords': keywords,
      'url': pdfUrl,
      'parsedAt': DateTime.now().toIso8601String(),
    };
  } catch (e) {
    // En caso de error, retornar información del error
    return {
      'error': e.toString(),
      'url': pdfUrl,
    };
  }
});

// ─── Análisis IA por candidato ────────────────────────────────────────────────

/// Genera el análisis predictivo IA (pros, contras, viabilidad) para un candidato.
/// Cacheado por sesión mediante autoDispose.family.
/// Falla silenciosamente — el perfil siempre muestra datos JNE aunque la IA no responda.
final aiAnalisisCandidatoProvider = FutureProvider.autoDispose
    .family<Map<String, dynamic>, String>((ref, nombre) async {
  if (nombre.isEmpty) return {};
  try {
    final ai = ref.read(aiServiceProvider);
    final result = await ai.obtenerPerfilCandidato(nombreOId: nombre);
    // El servicio retorna {data: {...}} o directamente el mapa
    if (result.containsKey('data') && result['data'] is Map) {
      return Map<String, dynamic>.from(result['data'] as Map);
    }
    return Map<String, dynamic>.from(result);
  } catch (_) {
    return {};
  }
});
