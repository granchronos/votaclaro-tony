import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Idiomas disponibles en VotaClaro.
enum IdiomaApp { es, qu, en }

extension IdiomaAppExt on IdiomaApp {
  String get label => switch (this) {
        IdiomaApp.es => 'Español',
        IdiomaApp.qu => 'Runasimi (Quechua)',
        IdiomaApp.en => 'English',
      };
  String get code => switch (this) {
        IdiomaApp.es => 'es',
        IdiomaApp.qu => 'qu',
        IdiomaApp.en => 'en',
      };
  String get flag => switch (this) {
        IdiomaApp.es => '🇵🇪',
        IdiomaApp.qu => '🏔️',
        IdiomaApp.en => '🌐',
      };
}

/// Provider que persiste el idioma seleccionado.
final idiomaProvider = StateNotifierProvider<IdiomaNotifier, IdiomaApp>((ref) {
  return IdiomaNotifier();
});

class IdiomaNotifier extends StateNotifier<IdiomaApp> {
  IdiomaNotifier() : super(IdiomaApp.es) {
    _cargar();
  }

  static const _key = 'idioma_app';

  Future<void> _cargar() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_key);
    if (saved == 'qu') state = IdiomaApp.qu;
    if (saved == 'en') state = IdiomaApp.en;
  }

  Future<void> cambiar(IdiomaApp idioma) async {
    state = idioma;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, idioma.code);
  }

  /// Cycles through ES → QU → EN → ES
  void toggle() {
    final next = switch (state) {
      IdiomaApp.es => IdiomaApp.qu,
      IdiomaApp.qu => IdiomaApp.en,
      IdiomaApp.en => IdiomaApp.es,
    };
    cambiar(next);
  }
}

// ─── Cadenas traducidas ───────────────────────────────────────────────────────

/// Cadenas en quechua adaptadas para los ciudadanos andinos de Perú.
/// Dialecto de referencia: Quechua Ayacucho-Chanka (quy) — el más hablado.
class AppStringsQu {
  AppStringsQu._();

  static const appName = 'VotaClaro';
  static const appTagline = 'Qampa votuyki, qampa kamachinayki';

  // Navegación
  static const navHome = 'Qallariy';
  static const navCandidatos = 'Akllakunas';
  static const navComparar = 'Tupachiy';
  static const navMiVoto = 'Ñoqapa Votuy';
  static const navEncuestas = 'Tapukuykuna';
  static const navNoticias = 'Willakuykuna';

  // Pantalla candidatos
  static const candidatosTitle = 'Akllakunas 2026';
  static const modPresidente = 'Waranqa kamachiq';
  static const modCongreso = 'Congreso';
  static const modParlamentoAndino = 'Andino Parlamento';

  // Mi voto
  static const miVotoTitle = 'Ñoqapa Votuy Tupachiy';
  static const miVotoSubtitle =
      'Pichqa allin munayniyoqta akllay, qampa akllakinaykita tariy';

  // Noticias
  static const noticiasTitle = 'Chiqaq Willakuykuna';

  // Cómo votar
  static const comoVotarTitle = 'Imayna votana';

  // Encuestas
  static const encuestasTitle = 'Tapukuykuna';

  // General
  static const comparar = 'Tupachiy';
  static const sinDatos = 'Mana imapis kanchu';
  static const errorGeneral = 'Pantachiypim karqa. Watiqmanta kaway.';
  static const cargando = 'Hamushanmi...';

  // Como votar — pasos
  static const paso1 = 'Votana wasiykita tariykuy';
  static const paso2 = 'Votana wasiman chayay';
  static const paso3 = 'Riqsichikunayki';
  static const paso4 = 'Cédula chukchachikuy';
  static const paso5 = 'Aspata qillqay (✗)';
  static const paso6 = 'Dobleay, ánforaman churay';
  static const paso7 = 'DNI-ykipi selloykita chasqiy';

  // Viabilidad
  static const viableAlta = 'Allin Atikuyniyoq';
  static const viableMedia = 'Chawpi Atikuyniyoq';
  static const viableBaja = 'Pisi Atikuyniyoq';
}
