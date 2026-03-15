/// Constantes de texto — español peruano claro
class AppStrings {
  AppStrings._();

  static const String appName = 'VotaClaro';
  static const String appTagline = 'Tu voto, tu decisión — bien informada';
  static const String eleccionYear = 'Elecciones Generales 2026';

  // Navigation
  static const String navHome = 'Inicio';
  static const String navCandidatos = 'Candidatos';
  static const String navComparar = 'Comparar';
  static const String navMiVoto = 'Mi Voto';
  static const String navEncuestas = 'Encuestas';
  static const String navNoticias = 'Noticias';

  // Modules
  static const String modPresidente = 'Presidente';
  static const String modCongreso = 'Congreso';
  static const String modParlamentoAndino = 'Parl. Andino';

  // Viabilidad
  static const String viableAlta = 'Viabilidad Alta';
  static const String viableMedia = 'Viabilidad Media';
  static const String viableBaja = 'Viabilidad Baja';
  static const String propuestaReciclada = 'Propuesta reciclada';

  // Sections
  static const String secPerfil = 'Perfil Rápido';
  static const String secPatrimonio = 'Patrimonio Declarado';
  static const String secPropuestas = 'Top 10 Propuestas';
  static const String secPros = 'A favor';
  static const String secContras = 'En contra';
  static const String secPredictivo = '¿Qué pasaría si gana?';
  static const String secHistorial = 'Historial Legislativo';
  static const String secAsistencia = 'Asistencia al Pleno';

  // Mi Voto
  static const String miVotoTitle = 'Simulador Mi Voto Ideal';
  static const String miVotoSubtitle =
      'Elige tus 5 prioridades y encuentra tu candidato ideal';
  static const String miVotoMatch = '% de coincidencia';
  static const String miVotoAlerta = '⚠️ Contradicción detectada';

  // Comparar
  static const String compararTitle = 'Comparar Candidatos';
  static const String compararVs = 'vs';
  static const String compararNivelCosmetico = 'Diferencia Cosmética';
  static const String compararNivelModerado = 'Diferencia Moderada';
  static const String compararNivelRadical = 'Diferencia Radical';

  // Encuestas
  static const String encuestasTitle = 'Encuestas Certificadas';
  static const String encuestasFuentes = 'Datos: Datum · Ipsos · CPI · GfK';
  static const String encuestasActualizadas = 'Actualizado: ';

  // Noticias
  static const String noticiasTitle = 'Noticias Verificadas';
  static const String noticiasFuentes =
      'Ojo Público · IDL-Reporteros · Convoca.pe';

  // Errors / States
  static const String loadingMsg = 'Consultando fuentes verificadas...';
  static const String errorGeneral =
      'No se pudo cargar la información. Verifica tu conexión.';
  static const String sinDatos = 'Sin datos verificados disponibles.';
  static const String fuenteNoDisponible = 'Fuente no disponible al momento';

  // AI
  static const String aiConsultando = 'Consultando agente ELECTORAL_PE_2026...';
  static const String aiActualizando = 'Actualizando todas las fuentes...';
  static const String aiFuenteJNE = 'Fuente: JNE';
  static const String aiFuenteONPE = 'Fuente: ONPE';

  // Disclaimers
  static const String disclaimerNeutralidad =
      'VotaClaro no apoya a ningún partido ni candidato. '
      'Esta app es financiada por donaciones ciudadanas y observadores electorales independientes.';
  static const String disclaimerPrivacidad =
      'Tu preferencia de voto no es almacenada ni compartida.';
  static const String disclaimerFuentes =
      'Datos extraídos de fuentes oficiales: JNE, ONPE, Datum, Ipsos Perú, CPI, GfK Perú.';

  // Cómo votar
  static const String comoVotarTitle = 'Cómo Votar 2026';
  static const String comoVotarBoton = '🗳️ Cómo votar';

  // Quechua (basic)
  static const String quechuaVotar = 'Munay-llankay';

  // Fuentes de noticias (descripciones)
  static const String fuenteIdlDesc =
      'IDL-Reporteros — Investigación sobre corrupción y nexos ilegales';
  static const String fuenteEpicentroDesc =
      'Epicentro TV — Reportajes de investigación sobre candidatos';
  static const String fuenteSudacaDesc =
      'Sudaca.pe — Perfiles técnicos y psicológicos de candidatos';
  static const String fuenteRppDesc =
      'RPP Noticias — Cobertura minuto a minuto de debates y mítines';
  static const String fuenteCanalNDesc =
      'Canal N — Debates completos y análisis post-debate 24/7';
  static const String fuenteElComercioDesc =
      'El Comercio — Cuadros comparativos de planes de gobierno';
  static const String fuenteOjoPublicoDesc =
      'OjoPúblico / Ojo Biónico — Fact-check de declaraciones en debates';
  static const String fuenteIpsosDesc =
      'Ipsos Perú — Encuestas publicadas en El Comercio / Cuarto Poder';
  static const String fuenteIepDesc =
      'IEP — Encuestas con foco en el interior del país (La República)';
}
