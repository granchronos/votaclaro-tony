import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../constants/app_strings_qu.dart';

/// Provides the current [AppL10n] based on the active [IdiomaApp].
/// Rebuilds every screen that watches it when the language changes.
final translationsProvider = Provider<AppL10n>((ref) {
  final idioma = ref.watch(idiomaProvider);
  return AppL10n.of(idioma);
});

// ─────────────────────────────────────────────────────────────────────────────
// AppL10n — all UI strings in ES / QU / EN
// ─────────────────────────────────────────────────────────────────────────────

class AppL10n {
  // ── App-wide ──────────────────────────────────────────────────────────────
  final String appName;
  final String appTagline;
  final String eleccionYear;
  final String eleccionFecha;

  // ── Navigation ────────────────────────────────────────────────────────────
  final String navHome;
  final String navCandidatos;
  final String navComparar;
  final String navMiVoto;
  final String navEncuestas;
  final String navNoticias;

  // ── Home ──────────────────────────────────────────────────────────────────
  final String heroBadge;
  final String heroTitle;
  final String heroSubtitle;
  final String chipEncuestas;
  final String chipPatrimonio;
  final String chipAnalisis;
  final String tabPresidente;
  final String tabDiputados;
  final String tabSenadores;
  final String tabAndino;
  final String candidatosPresidenciales;
  final String candidatosSubtitulo;
  final String verTodos;
  final String accesoRapido;
  final String acercaDe;
  final String cerrar;
  final String disclaimerNeutralidad;
  final String disclaimerPrivacidad;
  final String disclaimerFuentes;

  // ── Candidates ────────────────────────────────────────────────────────────
  final String candidatosTitle;
  final String buscarHint;
  final String filtrarPartido;
  final String limpiarFiltros;
  final String patrimonioDeclarado;
  final String verPerfilCompleto;
  final String sinCandidatos;
  final String cargandoCandidatos;
  final String actualizarLista;
  final String encuestasNacionales;

  // ── Candidato card/labels ─────────────────────────────────────────────────
  final String viableAlta;
  final String viableMedia;
  final String viableBaja;
  final String propuestaReciclada;
  final String secPerfil;
  final String secPatrimonio;
  final String secPropuestas;
  final String secPros;
  final String secContras;
  final String secPredictivo;
  final String secHistorial;
  final String secAsistencia;
  final String modPresidente;
  final String modCongreso;
  final String modParlamentoAndino;

  // ── News ──────────────────────────────────────────────────────────────────
  final String noticiasTitle;
  final String todasCategorias;
  final String leerArticulo;
  final String errorCargandoNoticias;
  final String haceHora;
  final String haceDias;
  final String hoy;

  // ── Mi Voto ───────────────────────────────────────────────────────────────
  final String miVotoTitle;
  final String miVotoSubtitle;
  final String miVotoMatch;
  final String selecciona5;
  final String calcularIdeal;
  final String reiniciar;
  final String comoVotarTooltip;
  final String resultadosSubtitulo;
  final String simuladorDisclaimer;

  // ── Comparar ──────────────────────────────────────────────────────────────
  final String compararTitle;
  final String seleccionaCandidato;
  final String analizandoIA;
  final String compararBtn;
  final String compararNivelCosmetico;
  final String compararNivelModerado;
  final String compararNivelRadical;

  // ── Encuestas ─────────────────────────────────────────────────────────────
  final String encuestasTitle;
  final String encuestasFuentes;
  final String margenError;
  final String verFuente;
  final String actualizadoEl;

  // ── Cómo Votar ────────────────────────────────────────────────────────────
  final String comoVotarTitle;
  final String tutorialTab;
  final String simularVotoTab;
  final String recursosJneTab;

  final String paso1Titulo;
  final String paso1Desc;
  final List<String> paso1Detalle;

  final String paso2Titulo;
  final String paso2Desc;
  final List<String> paso2Detalle;

  final String paso3Titulo;
  final String paso3Desc;
  final List<String> paso3Detalle;

  final String paso4Titulo;
  final String paso4Desc;
  final List<String> paso4Detalle;

  final String paso5Titulo;
  final String paso5Desc;
  final List<String> paso5Detalle;

  final String paso6Titulo;
  final String paso6Desc;
  final List<String> paso6Detalle;

  final String paso7Titulo;
  final String paso7Desc;
  final List<String> paso7Detalle;

  // Simulador cédula
  final String simuladorTitle;
  final String simuladorSubtitle;
  final String confirmarVoto;
  final String simuladorDialogTitle;
  final String simuladorDialogMsg;
  final String simuladorMsgFiscal;
  final String simuladorMsgSello;
  final String entendido;

  // Recursos JNE
  final String recurso1Titulo;
  final String recurso1Desc;
  final String recurso2Titulo;
  final String recurso2Desc;
  final String recurso3Titulo;
  final String recurso3Desc;
  final String recurso4Titulo;
  final String recurso4Desc;
  final String recurso5Titulo;
  final String recurso5Desc;
  final String recurso6Titulo;
  final String recurso6Desc;
  final String recurso7Titulo;
  final String recurso7Desc;
  final String recurso8Titulo;
  final String recurso8Desc;
  final String recurso9Titulo;
  final String recurso9Desc;

  // ── Common ────────────────────────────────────────────────────────────────
  final String cargando;
  final String errorGeneral;
  final String sinDatos;
  final String reintentar;
  final String verMas;
  final String actualizar;

  const AppL10n._({
    required this.appName,
    required this.appTagline,
    required this.eleccionYear,
    required this.eleccionFecha,
    required this.navHome,
    required this.navCandidatos,
    required this.navComparar,
    required this.navMiVoto,
    required this.navEncuestas,
    required this.navNoticias,
    required this.heroBadge,
    required this.heroTitle,
    required this.heroSubtitle,
    required this.chipEncuestas,
    required this.chipPatrimonio,
    required this.chipAnalisis,
    required this.tabPresidente,
    required this.tabDiputados,
    required this.tabSenadores,
    required this.tabAndino,
    required this.candidatosPresidenciales,
    required this.candidatosSubtitulo,
    required this.verTodos,
    required this.accesoRapido,
    required this.acercaDe,
    required this.cerrar,
    required this.disclaimerNeutralidad,
    required this.disclaimerPrivacidad,
    required this.disclaimerFuentes,
    required this.candidatosTitle,
    required this.buscarHint,
    required this.filtrarPartido,
    required this.limpiarFiltros,
    required this.patrimonioDeclarado,
    required this.verPerfilCompleto,
    required this.sinCandidatos,
    required this.cargandoCandidatos,
    required this.actualizarLista,
    required this.encuestasNacionales,
    required this.viableAlta,
    required this.viableMedia,
    required this.viableBaja,
    required this.propuestaReciclada,
    required this.secPerfil,
    required this.secPatrimonio,
    required this.secPropuestas,
    required this.secPros,
    required this.secContras,
    required this.secPredictivo,
    required this.secHistorial,
    required this.secAsistencia,
    required this.modPresidente,
    required this.modCongreso,
    required this.modParlamentoAndino,
    required this.noticiasTitle,
    required this.todasCategorias,
    required this.leerArticulo,
    required this.errorCargandoNoticias,
    required this.haceHora,
    required this.haceDias,
    required this.hoy,
    required this.miVotoTitle,
    required this.miVotoSubtitle,
    required this.miVotoMatch,
    required this.selecciona5,
    required this.calcularIdeal,
    required this.reiniciar,
    required this.comoVotarTooltip,
    required this.resultadosSubtitulo,
    required this.simuladorDisclaimer,
    required this.compararTitle,
    required this.seleccionaCandidato,
    required this.analizandoIA,
    required this.compararBtn,
    required this.compararNivelCosmetico,
    required this.compararNivelModerado,
    required this.compararNivelRadical,
    required this.encuestasTitle,
    required this.encuestasFuentes,
    required this.margenError,
    required this.verFuente,
    required this.actualizadoEl,
    required this.comoVotarTitle,
    required this.tutorialTab,
    required this.simularVotoTab,
    required this.recursosJneTab,
    required this.paso1Titulo,
    required this.paso1Desc,
    required this.paso1Detalle,
    required this.paso2Titulo,
    required this.paso2Desc,
    required this.paso2Detalle,
    required this.paso3Titulo,
    required this.paso3Desc,
    required this.paso3Detalle,
    required this.paso4Titulo,
    required this.paso4Desc,
    required this.paso4Detalle,
    required this.paso5Titulo,
    required this.paso5Desc,
    required this.paso5Detalle,
    required this.paso6Titulo,
    required this.paso6Desc,
    required this.paso6Detalle,
    required this.paso7Titulo,
    required this.paso7Desc,
    required this.paso7Detalle,
    required this.simuladorTitle,
    required this.simuladorSubtitle,
    required this.confirmarVoto,
    required this.simuladorDialogTitle,
    required this.simuladorDialogMsg,
    required this.simuladorMsgFiscal,
    required this.simuladorMsgSello,
    required this.entendido,
    required this.recurso1Titulo,
    required this.recurso1Desc,
    required this.recurso2Titulo,
    required this.recurso2Desc,
    required this.recurso3Titulo,
    required this.recurso3Desc,
    required this.recurso4Titulo,
    required this.recurso4Desc,
    required this.recurso5Titulo,
    required this.recurso5Desc,
    required this.recurso6Titulo,
    required this.recurso6Desc,
    required this.recurso7Titulo,
    required this.recurso7Desc,
    required this.recurso8Titulo,
    required this.recurso8Desc,
    required this.recurso9Titulo,
    required this.recurso9Desc,
    required this.cargando,
    required this.errorGeneral,
    required this.sinDatos,
    required this.reintentar,
    required this.verMas,
    required this.actualizar,
  });

  static AppL10n of(IdiomaApp idioma) => switch (idioma) {
        IdiomaApp.es => _es,
        IdiomaApp.qu => _qu,
        IdiomaApp.en => _en,
      };

  // ═══════════════════════════════════════════════════════════════════════════
  // ESPAÑOL (oficial)
  // ═══════════════════════════════════════════════════════════════════════════
  static const _es = AppL10n._(
    appName: 'VotaClaro',
    appTagline: 'Tu voto, tu decisión — bien informada',
    eleccionYear: 'Elecciones Generales 2026',
    eleccionFecha: '12 de abril de 2026',
    navHome: 'Inicio',
    navCandidatos: 'Candidatos',
    navComparar: 'Comparar',
    navMiVoto: 'Mi Voto',
    navEncuestas: 'Encuestas',
    navNoticias: 'Noticias',
    heroBadge: '🗳️ Elecciones Generales 2026',
    heroTitle: 'Tu voto,\nbien informado.',
    heroSubtitle:
        'Datos verificados del JNE, ONPE, Datum e Ipsos.\nSin sesgos. Sin publicidad partidaria.',
    chipEncuestas: '📊 Encuestas\ncertificadas',
    chipPatrimonio: '⚖️ Patrimonio\nJNE',
    chipAnalisis: '🔮 Análisis\npredictivo',
    tabPresidente: '🏛️ Presidente',
    tabDiputados: '🏛️ Diputados',
    tabSenadores: '🏛️ Senadores',
    tabAndino: '🌍 P. Andino',
    candidatosPresidenciales: '🏛️ Candidatos presidenciales',
    candidatosSubtitulo: 'Ordenados por encuesta promedio ponderado',
    verTodos: 'Ver todos',
    accesoRapido: '⚡ Acceso rápido',
    acercaDe: 'Acerca de VotaClaro',
    cerrar: 'Cerrar',
    disclaimerNeutralidad:
        'VotaClaro no apoya a ningún partido ni candidato. Esta app es financiada por donaciones ciudadanas y observadores electorales independientes.',
    disclaimerPrivacidad:
        'Tu preferencia de voto no es almacenada ni compartida.',
    disclaimerFuentes:
        'Datos extraídos de fuentes oficiales: JNE, ONPE, Datum, Ipsos Perú, CPI, GfK Perú.',
    candidatosTitle: 'Candidatos 2026',
    buscarHint: 'Buscar candidato...',
    filtrarPartido: 'Filtrar por partido',
    limpiarFiltros: 'Limpiar filtros',
    patrimonioDeclarado: 'Patrimonio Declarado',
    verPerfilCompleto: 'Ver perfil completo',
    sinCandidatos: 'Sin candidatos encontrados',
    cargandoCandidatos: 'Cargando candidatos...',
    actualizarLista: 'Actualizar lista',
    encuestasNacionales: 'Encuestas nacionales',
    viableAlta: 'Viabilidad Alta',
    viableMedia: 'Viabilidad Media',
    viableBaja: 'Viabilidad Baja',
    propuestaReciclada: 'Propuesta reciclada',
    secPerfil: 'Perfil Rápido',
    secPatrimonio: 'Patrimonio Declarado',
    secPropuestas: 'Top 10 Propuestas',
    secPros: 'A favor',
    secContras: 'En contra',
    secPredictivo: '¿Qué pasaría si gana?',
    secHistorial: 'Historial Legislativo',
    secAsistencia: 'Asistencia al Pleno',
    modPresidente: 'Presidente',
    modCongreso: 'Congreso',
    modParlamentoAndino: 'Parl. Andino',
    noticiasTitle: 'Noticias Verificadas',
    todasCategorias: 'Todas',
    leerArticulo: 'Leer artículo',
    errorCargandoNoticias: 'Error al cargar noticias',
    haceHora: 'hace 1 hora',
    haceDias: 'hace {n} días',
    hoy: 'hoy',
    miVotoTitle: 'Simulador Mi Voto Ideal',
    miVotoSubtitle: 'Elige tus 5 prioridades y encuentra tu candidato ideal',
    miVotoMatch: '% de coincidencia',
    selecciona5: 'Selecciona 5 prioridades',
    calcularIdeal: 'Calcular mi candidato ideal',
    reiniciar: 'Reiniciar',
    comoVotarTooltip: 'Cómo votar',
    resultadosSubtitulo: 'Ordenados por % de coincidencia con tus prioridades',
    simuladorDisclaimer:
        'Este simulador es orientativo. Tu voto es personal y secreto.',
    compararTitle: 'Comparar Candidatos',
    seleccionaCandidato: 'Selecciona un candidato',
    analizandoIA: 'Analizando con IA...',
    compararBtn: 'Comparar candidatos',
    compararNivelCosmetico: 'Diferencia Cosmética',
    compararNivelModerado: 'Diferencia Moderada',
    compararNivelRadical: 'Diferencia Radical',
    encuestasTitle: 'Encuestas Certificadas',
    encuestasFuentes: 'Datos: Datum · Ipsos · CPI · GfK',
    margenError: 'Margen de error',
    verFuente: 'Ver fuente',
    actualizadoEl: 'Actualizado: ',
    comoVotarTitle: 'Cómo Votar 2026',
    tutorialTab: '📚 Tutorial',
    simularVotoTab: '🗳️ Simular voto',
    recursosJneTab: '🔗 Recursos JNE',
    paso1Titulo: 'Verifica tu local de votación',
    paso1Desc:
        'Lleva tu DNI vigente. Consulta tu local de votación en la web de la ONPE: https://consultavoto.onpe.gob.pe',
    paso1Detalle: [
      'El local está asignado según tu domicilio en el DNI.',
      'Si cambiaste de domicilio, consulta si actualizaste tu padrón.',
      'Si eres peruano en el exterior, consulta la ONPE consular.',
    ],
    paso2Titulo: 'Llega a tu local de votación',
    paso2Desc:
        'El día de las elecciones (12 de abril de 2026) los locales abren a las 8:00 a.m. y cierran a las 4:00 p.m.',
    paso2Detalle: [
      'Busca la mesa de sufragio con tu número según el padrón.',
      'La fila está organizada por orden alfabético o número de DNI.',
      'Los fiscales de partido pueden pedirte identificación.',
    ],
    paso3Titulo: 'Identifícate ante el personero',
    paso3Desc:
        'Entrega tu DNI al miembro de mesa. Te buscarán en el padrón electoral y firmarás el acta.',
    paso3Detalle: [
      'El personero anota tu firma o huella.',
      'Verifica que tu nombre esté bien escrito en el acta.',
      'Si hay error en el padrón, el personero puede corregirlo con acta.',
    ],
    paso4Titulo: 'Ingresa a la cabina de votación',
    paso4Desc:
        'Recibirás una cédula de sufragio por cada tipo de elección (presidente, congresista, parlamentario andino).',
    paso4Detalle: [
      'La cabina es privada — nadie puede ver tu voto.',
      'No permitas que alguien entre a la cabina contigo.',
      'Si tienes alguna duda, puedes llamar al personero antes.',
    ],
    paso5Titulo: 'Marca el aspa (✗) en la cédula',
    paso5Desc:
        'Dibuja claramente una X (aspa) dentro del recuadro del candidato/partido de tu preferencia.',
    paso5Detalle: [
      'Solo una X válida por cédula.',
      'Si marcas más de un candidato, el voto es nulo.',
      'Puedes votar en blanco — es un voto válido.',
      'No hagas otras marcas fuera del recuadro.',
    ],
    paso6Titulo: 'Dobla la cédula y deposítala',
    paso6Desc:
        'Dobla la cédula por las líneas marcadas y deposítala en la ánfora frente a los personeros.',
    paso6Detalle: [
      'Dobla correctamente para no mostrar tu elección.',
      'Deposítala en presencia de los miembros de mesa.',
      'No te llevres la cédula — es un delito electoral.',
    ],
    paso7Titulo: 'Sello en el DNI y empastado',
    paso7Desc:
        'Recibirás un sello de votación en tu DNI y firmas el padrón. ¡Ya votaste!',
    paso7Detalle: [
      'El sello acredita que ejerciste tu derecho a votar.',
      'El empastado de tinta en el dedo es opcional según la mesa.',
      'Puedes consultar los resultados en ONPE desde las 4:00 p.m.',
    ],
    simuladorTitle: '🗳️ Simulador de cédula',
    simuladorSubtitle:
        'Elige un candidato como si fuera el día de las elecciones',
    confirmarVoto: 'Confirmar voto',
    simuladorDialogTitle: '🗳️ Voto simulado depositado',
    simuladorDialogMsg:
        'Elegiste a {nombre}.\nEn el simulador, tu voto fue depositado correctamente.',
    simuladorMsgFiscal:
        '🧑‍⚖️ El fiscal de mesa observa la transparencia del proceso.',
    simuladorMsgSello: '✅ Recibirás el sello en tu DNI al terminar.',
    entendido: 'Entendido',
    recurso1Titulo: '🗺️ Consulta tu local de votación',
    recurso1Desc: 'Ubica tu mesa de sufragio según tu DNI (ONPE oficial).',
    recurso2Titulo: '📋 Voto Informado (JNE)',
    recurso2Desc:
        'Planes de gobierno, hojas de vida y sanciones de todos los candidatos.',
    recurso3Titulo: '🔍 INFOGOB — Organizaciones políticas',
    recurso3Desc:
        'Historial de partidos, líderes, financiamiento y sanciones electorales.',
    recurso4Titulo: '💰 Declara JNE (Hojas de Vida)',
    recurso4Desc:
        'Declaraciones juradas de bienes y rentas de todos los postulantes.',
    recurso5Titulo: '👁️ Ojo Biónico — OjoPúblico',
    recurso5Desc:
        'Fact-check para verificar declaraciones de candidatos en debates.',
    recurso6Titulo: '🔍 IDL-Reporteros',
    recurso6Desc:
        'Investigaciones sobre corrupción, nexos con economías ilegales y antecedentes.',
    recurso7Titulo: '📊 Ipsos Perú — Encuestas',
    recurso7Desc: 'Encuestas de intención de voto publicadas en El Comercio.',
    recurso8Titulo: '📈 IEP — Instituto de Estudios Peruanos',
    recurso8Desc:
        'Encuestas con enfoque en el interior del país. Publica en La República.',
    recurso9Titulo: '⚠️ Multa por no votar (ONPE)',
    recurso9Desc:
        'Consulta si tienes multas electorales pendientes o solicita constancia de no infracción.',
    cargando: 'Consultando fuentes verificadas...',
    errorGeneral: 'No se pudo cargar la información. Verifica tu conexión.',
    sinDatos: 'Sin datos verificados disponibles.',
    reintentar: 'Reintentar',
    verMas: 'Ver más',
    actualizar: 'Actualizar',
  );

  // ═══════════════════════════════════════════════════════════════════════════
  // RUNASIMI / QUECHUA (oficial) — dialecto Ayacucho-Chanka (quy)
  // ═══════════════════════════════════════════════════════════════════════════
  static const _qu = AppL10n._(
    appName: 'VotaClaro',
    appTagline: 'Qampa votuyki, qampa kamachinayki',
    eleccionYear: '2026 Hatun Akllakuy',
    eleccionFecha: '2026 abril killap 12-ninpi',
    navHome: 'Qallariy',
    navCandidatos: 'Akllakunas',
    navComparar: 'Tupachiy',
    navMiVoto: 'Ñoqapa Votuy',
    navEncuestas: 'Tapukuykuna',
    navNoticias: 'Willakuykuna',
    heroBadge: '🗳️ 2026 Hatun Akllakuy',
    heroTitle: 'Qampa votuyki,\nallinmi yachaqasqa.',
    heroSubtitle:
        'JNE, ONPE, Datum, Ipsos nisqakunamanta chiqaq willakuykuna.\nMana qaqanchiyuq. Mana partidomanta willakuychu.',
    chipEncuestas: '📊 Tapukuykuna\nachkay',
    chipPatrimonio: '⚖️ Kapuynin\nJNE',
    chipAnalisis: '🔮 Hamuq\nRikuchiy',
    tabPresidente: '🏛️ Waranqa Kamachiq',
    tabDiputados: '🏛️ Diputados',
    tabSenadores: '🏛️ Senadores',
    tabAndino: '🌍 Andino Parl.',
    candidatosPresidenciales: '🏛️ Presidente Akllakunas',
    candidatosSubtitulo: 'Tapukuypi rikurisqankupi',
    verTodos: 'Llapanta qaway',
    accesoRapido: '⚡ Usqay yaykuy',
    acercaDe: 'VotaClaro Haqay Kaymanta',
    cerrar: 'Wichqay',
    disclaimerNeutralidad:
        'VotaClaro mana mayqin partidota waqaiyanchu. Kay app ciudadanokunap yanapayninwan kausan.',
    disclaimerPrivacidad:
        'Qampa munasqayki mana waqaykunachu nitaq willakuykunachu.',
    disclaimerFuentes:
        'Willakuykuna JNE, ONPE, Datum, Ipsos Perú, CPI, GfK Perú nisqakunamanta.',
    candidatosTitle: 'Akllakunas 2026',
    buscarHint: 'Akllakuyta maskay...',
    filtrarPartido: 'Partidopi filtranay',
    limpiarFiltros: 'Limpianay',
    patrimonioDeclarado: 'Kapuynin Willay',
    verPerfilCompleto: 'Tukuy rikuchiy',
    sinCandidatos: 'Mana akllakunam',
    cargandoCandidatos: 'Akllakunata hamushanmi...',
    actualizarLista: 'Listata mosqoychiy',
    encuestasNacionales: 'Nación tapukuykuna',
    viableAlta: 'Allin Atikuyniyoq',
    viableMedia: 'Chawpi Atikuyniyoq',
    viableBaja: 'Pisi Atikuyniyoq',
    propuestaReciclada: 'Ñawpaq nisqanmi',
    secPerfil: 'Usqay Rikuchiy',
    secPatrimonio: 'Kapuynin Willay',
    secPropuestas: 'Top 10 Munasqankuna',
    secPros: 'Allinnin',
    secContras: 'Mana allinnin',
    secPredictivo: 'Imayna kanqa?',
    secHistorial: 'Ñawpaq Rurasqankuna',
    secAsistencia: 'Plenoman Hamusqan',
    modPresidente: 'Waranqa kamachiq',
    modCongreso: 'Congreso',
    modParlamentoAndino: 'Andino Parlamento',
    noticiasTitle: 'Chiqaq Willakuykuna',
    todasCategorias: 'Llapan',
    leerArticulo: 'Qillqata ñawinchaykuy',
    errorCargandoNoticias: 'Willakuykuna mana chayamurchuq',
    haceHora: 'sapa horamanta',
    haceDias: '{n} punchawmanta',
    hoy: 'kunan punchaw',
    miVotoTitle: 'Ñoqapa Votuy Tupachiy',
    miVotoSubtitle:
        'Pichqa allin munayniyoqta akllay, qampa akllakinaykita tariy',
    miVotoMatch: '% Tupanakuy',
    selecciona5: 'Pichqa munayniyoqta akllay',
    calcularIdeal: 'Ñoqapa akllakinayta tariy',
    reiniciar: 'Qallarimuy',
    comoVotarTooltip: 'Imayna votana',
    resultadosSubtitulo: 'Qampa munasqaykiwan tupanchisqan siminpi',
    simuladorDisclaimer:
        'Kay tupachiy yachachiqlla. Qampa votuy qampaqllan kachun.',
    compararTitle: 'Akllakunata Tupachiy',
    seleccionaCandidato: 'Akllakuyta akllay',
    analizandoIA: 'IA nisqanwan qawashanki...',
    compararBtn: 'Akllakunata Tupachiy',
    compararNivelCosmetico: 'Huchuy Raqriy',
    compararNivelModerado: 'Chawpi Raqriy',
    compararNivelRadical: 'Hatun Raqriy',
    encuestasTitle: 'Achkay Tapukuykuna',
    encuestasFuentes: 'Willakuy: Datum · Ipsos · CPI · GfK',
    margenError: 'Pantachiy silin',
    verFuente: 'Pukyu qaway',
    actualizadoEl: 'Mosqoychisqa: ',
    comoVotarTitle: 'Imayna Votana 2026',
    tutorialTab: '📚 Yachaqanakuy',
    simularVotoTab: '🗳️ Votuyta Tupachiy',
    recursosJneTab: '🔗 JNE Yanapakuykuna',
    paso1Titulo: 'Votana wasikita tariykuy',
    paso1Desc:
        'DNI nisqaykita apay. Votana wasikita ONPE nisqapi qaway: https://consultavoto.onpe.gob.pe',
    paso1Detalle: [
      'Votana wasi DNI nisqaypi willasqan tiyanpi.',
      'Domicilioykita tikrasqaykipi, padronpi cambiasqaykita qaway.',
      'Perú llaqtapi mana kaqtiypi, ONPE consular nisqata tapuy.',
    ],
    paso2Titulo: 'Votana wasiman chayay',
    paso2Desc:
        'Akllakuy punchaw (2026 abril 12-pi) votana wasikunam 8:00 a.m.-pi kicharikun 4:00 p.m.-kama.',
    paso2Detalle: [
      'Padronpi qillqasqa mesaykita maskay.',
      'Fila nisqa apellidonikiman hinan kachkan.',
      'Partido fiscalkunam riqsichikunaykita mañakuyta atinku.',
    ],
    paso3Titulo: 'Riqsichikunayki',
    paso3Desc:
        'Mesa miembroman DNI nisqaykita quy. Padronpi maskasunqam, actapi firmawanki.',
    paso3Detalle: [
      'Personero nisqam qillqanaykim waqaychan.',
      'Actapi sutiyki allinmi qillqasqa kasqanta qaway.',
      'Padronpi pantasqa kaqtinki, personero actawan allichanqa.',
    ],
    paso4Titulo: 'Votana wasiman yaykuy',
    paso4Desc:
        'Sapa akllakuy mudupi sapa cédulata chasqinki (presidente, congresista, parlamentario andino).',
    paso4Detalle: [
      'Cabina nisqa wasichapi ima riqisunqachu votuykita.',
      'Mana pim cabinaman yaykuyta atinchu qamwan khuska.',
      'Tapukuyniyki kaqtinki, personerota mañakuy yaykuymantam ñawpaq.',
    ],
    paso5Titulo: 'Cédulapi aspata qillqay (✗)',
    paso5Desc:
        'Munasqayki candidato/partidop recuadropi munayta rikuchinanpaq aspa (X) qillqay.',
    paso5Detalle: [
      'Sapa cédulapi huk X kachun.',
      'Iskaytam qillqarqayki chayqa voto nulo nin.',
      'Mana pitapas munaspayki lluqsiy — chayqa voto blanco, válido.',
      'Mana recuadro-manta lluchuy.',
    ],
    paso6Titulo: 'Dobleay, ánforaman churay',
    paso6Desc:
        'Cédulata señalanqan ratan dobleay, personerokunap ñawpaqinpi ánforaman churay.',
    paso6Detalle: [
      'Allin dobleay munasqaykita ama rikuchinaykipaq.',
      'Mesa miembrokunap ñawpaqinpi churay.',
      'Cédulata mana apakunki — electoralmi delito.',
    ],
    paso7Titulo: 'DNI-ykipi selloykita chasqiy',
    paso7Desc:
        'Votana sellon DNI nisqaykipi churasqa, padronpi firmawanki. ¡Voturqankim!',
    paso7Detalle: [
      'Sellon voturqasqaykita riqsichin.',
      'Manchasqa tintap nisqa sello hukninpin mesanpi.',
      'Resultadokunata ONPE nisqapi 4:00 p.m.-manta qaway atinki.',
    ],
    simuladorTitle: '🗳️ Cédula Tupachiy',
    simuladorSubtitle: 'Huk candidatota akllay, akllakuy punchawahinam',
    confirmarVoto: 'Votuy allinmi',
    simuladorDialogTitle: '🗳️ Tupachiy votuy churarasqa',
    simuladorDialogMsg:
        '{nombre} nisqata akllasqanki.\nTupachiypi votuy allinmi churarasqa.',
    simuladorMsgFiscal: '🧑‍⚖️ Mesa fiscal nisqam proceso chiqaqninpi qawan.',
    simuladorMsgSello: '✅ Tukukuspayki DNI nisqaykipi sellon kanqa.',
    entendido: 'Yachachini',
    recurso1Titulo: '🗺️ Votana wasikita tariykuy',
    recurso1Desc: 'DNI nisqanman hina mesaykita tariykuy (ONPE oficial).',
    recurso2Titulo: '📋 Voto Informado (JNE)',
    recurso2Desc: 'Llapan candidatokunap gobierno plankuna, vida hojakuna.',
    recurso3Titulo: '🔍 INFOGOB — Organizaciones políticas',
    recurso3Desc:
        'Partido, líder, financiamiento, sanción nisqakunap historialninku.',
    recurso4Titulo: '💰 Declara JNE (Vida Hojakuna)',
    recurso4Desc:
        'Llapan candidatokunap kapuyninkuwan rentankukunap jurada declaracionninku.',
    recurso5Titulo: '👁️ Ojo Biónico — OjoPúblico',
    recurso5Desc:
        'Candidatokunap rimayninkuta qiqinchiy llapanta tapullankupaq.',
    recurso6Titulo: '🔍 IDL-Reporteros',
    recurso6Desc:
        'Quchayta qaway willay: corrupción, ilícito haciendas, antecedentes.',
    recurso7Titulo: '📊 Ipsos Perú — Tapukuykuna',
    recurso7Desc: 'Votu munakuq tapukuykuna El Comercio willakuypi.',
    recurso8Titulo: '📈 IEP — Instituto de Estudios Peruanos',
    recurso8Desc: 'Tapukuykuna provinciakunapi. La República willakuypi.',
    recurso9Titulo: '⚠️ Mana Votusqa Multayki (ONPE)',
    recurso9Desc:
        'Kuska qaway electoral multaykita utaq constanciayta mañakuy.',
    cargando: 'Chiqaq pukuykunas tapushanmi...',
    errorGeneral: 'Pantachiypim karqa. Conexionniykita qaway.',
    sinDatos: 'Mana imapis kanchu.',
    reintentar: 'Watiqmanta',
    verMas: 'Astawan qaway',
    actualizar: 'Mosqoychiy',
  );

  // ═══════════════════════════════════════════════════════════════════════════
  // ENGLISH (optional)
  // ═══════════════════════════════════════════════════════════════════════════
  static const _en = AppL10n._(
    appName: 'VotaClaro',
    appTagline: 'Your vote, your decision — well informed',
    eleccionYear: 'General Elections 2026',
    eleccionFecha: 'April 12, 2026',
    navHome: 'Home',
    navCandidatos: 'Candidates',
    navComparar: 'Compare',
    navMiVoto: 'My Vote',
    navEncuestas: 'Polls',
    navNoticias: 'News',
    heroBadge: '🗳️ General Elections 2026',
    heroTitle: 'Your vote,\nwell informed.',
    heroSubtitle:
        'Verified data from JNE, ONPE, Datum & Ipsos.\nNo bias. No partisan advertising.',
    chipEncuestas: '📊 Certified\nPolls',
    chipPatrimonio: '⚖️ Assets\nJNE',
    chipAnalisis: '🔮 Predictive\nAnalysis',
    tabPresidente: '🏛️ President',
    tabDiputados: '🏛️ Deputies',
    tabSenadores: '🏛️ Senators',
    tabAndino: '🌍 Andean Parl.',
    candidatosPresidenciales: '🏛️ Presidential Candidates',
    candidatosSubtitulo: 'Sorted by weighted average poll',
    verTodos: 'View all',
    accesoRapido: '⚡ Quick Access',
    acercaDe: 'About VotaClaro',
    cerrar: 'Close',
    disclaimerNeutralidad:
        'VotaClaro does not support any party or candidate. This app is funded by citizen donations and independent electoral observers.',
    disclaimerPrivacidad: 'Your voting preference is not stored or shared.',
    disclaimerFuentes:
        'Data from official sources: JNE, ONPE, Datum, Ipsos Peru, CPI, GfK Peru.',
    candidatosTitle: 'Candidates 2026',
    buscarHint: 'Search candidate...',
    filtrarPartido: 'Filter by party',
    limpiarFiltros: 'Clear filters',
    patrimonioDeclarado: 'Declared Assets',
    verPerfilCompleto: 'View full profile',
    sinCandidatos: 'No candidates found',
    cargandoCandidatos: 'Loading candidates...',
    actualizarLista: 'Refresh list',
    encuestasNacionales: 'National polls',
    viableAlta: 'High Viability',
    viableMedia: 'Medium Viability',
    viableBaja: 'Low Viability',
    propuestaReciclada: 'Reused proposal',
    secPerfil: 'Quick Profile',
    secPatrimonio: 'Declared Assets',
    secPropuestas: 'Top 10 Proposals',
    secPros: 'In favor',
    secContras: 'Against',
    secPredictivo: 'What if they win?',
    secHistorial: 'Legislative History',
    secAsistencia: 'Plenary Attendance',
    modPresidente: 'President',
    modCongreso: 'Congress',
    modParlamentoAndino: 'Andean Parl.',
    noticiasTitle: 'Verified News',
    todasCategorias: 'All',
    leerArticulo: 'Read article',
    errorCargandoNoticias: 'Error loading news',
    haceHora: '1 hour ago',
    haceDias: '{n} days ago',
    hoy: 'today',
    miVotoTitle: 'My Ideal Vote Simulator',
    miVotoSubtitle: 'Choose your 5 priorities and find your ideal candidate',
    miVotoMatch: '% match',
    selecciona5: 'Select 5 priorities',
    calcularIdeal: 'Calculate my ideal candidate',
    reiniciar: 'Reset',
    comoVotarTooltip: 'How to vote',
    resultadosSubtitulo: 'Sorted by % match with your priorities',
    simuladorDisclaimer:
        'This simulator is a guide. Your vote is personal and secret.',
    compararTitle: 'Compare Candidates',
    seleccionaCandidato: 'Select a candidate',
    analizandoIA: 'Analyzing with AI...',
    compararBtn: 'Compare candidates',
    compararNivelCosmetico: 'Cosmetic Difference',
    compararNivelModerado: 'Moderate Difference',
    compararNivelRadical: 'Radical Difference',
    encuestasTitle: 'Certified Polls',
    encuestasFuentes: 'Data: Datum · Ipsos · CPI · GfK',
    margenError: 'Margin of error',
    verFuente: 'View source',
    actualizadoEl: 'Updated: ',
    comoVotarTitle: 'How to Vote 2026',
    tutorialTab: '📚 Tutorial',
    simularVotoTab: '🗳️ Simulate vote',
    recursosJneTab: '🔗 JNE Resources',
    paso1Titulo: 'Find your polling place',
    paso1Desc:
        'Bring your valid ID (DNI). Check your polling place on the ONPE website: https://consultavoto.onpe.gob.pe',
    paso1Detalle: [
      'Your polling location is assigned based on your address in your DNI.',
      'If you changed address, check if your electoral register was updated.',
      'If you are Peruvian abroad, contact your consular ONPE.',
    ],
    paso2Titulo: 'Arrive at your polling place',
    paso2Desc:
        'On election day (April 12, 2026), polling stations open at 8:00 a.m. and close at 4:00 p.m.',
    paso2Detalle: [
      'Find your ballot table according to the electoral register.',
      'The line is organized alphabetically or by DNI number.',
      'Party observers may ask for identification.',
    ],
    paso3Titulo: 'Identify yourself',
    paso3Desc:
        'Hand your DNI to the table member. They will look you up in the register and you will sign the record.',
    paso3Detalle: [
      'The official records your signature or fingerprint.',
      'Verify your name is correctly spelled on the record.',
      'If there is an error in the register, the official can correct it.',
    ],
    paso4Titulo: 'Enter the voting booth',
    paso4Desc:
        'You will receive one ballot for each type of election (president, congressman, Andean parliamentarian).',
    paso4Detalle: [
      'The booth is private — no one can see your vote.',
      'Do not allow anyone to enter the booth with you.',
      'If you have questions, you may ask the official before entering.',
    ],
    paso5Titulo: 'Mark the X on the ballot',
    paso5Desc:
        'Draw a clear X inside the box of your preferred candidate/party.',
    paso5Detalle: [
      'Only one valid X per ballot.',
      'If you mark more than one candidate, the vote is void.',
      'You may vote blank — it is a valid vote.',
      'Do not make other marks outside the box.',
    ],
    paso6Titulo: 'Fold and deposit the ballot',
    paso6Desc:
        'Fold the ballot along the marked lines and deposit it in the ballot box in front of the officials.',
    paso6Detalle: [
      'Fold correctly so as not to reveal your choice.',
      'Deposit it in the presence of the table members.',
      'Do not take the ballot — it is an electoral offence.',
    ],
    paso7Titulo: 'Receive stamp on your ID',
    paso7Desc:
        'You will receive a voting stamp on your DNI and sign the register. You voted!',
    paso7Detalle: [
      'The stamp certifies you exercised your right to vote.',
      'The ink stamp on the finger is optional depending on the table.',
      'You can check results on the ONPE website from 4:00 p.m.',
    ],
    simuladorTitle: '🗳️ Ballot Simulator',
    simuladorSubtitle: 'Choose a candidate as if it were election day',
    confirmarVoto: 'Confirm vote',
    simuladorDialogTitle: '🗳️ Simulated vote cast',
    simuladorDialogMsg:
        'You chose {nombre}.\nIn the simulator, your vote was correctly cast.',
    simuladorMsgFiscal:
        '🧑‍⚖️ The table observer watches the transparency of the process.',
    simuladorMsgSello: '✅ You will receive the stamp on your ID when done.',
    entendido: 'Got it',
    recurso1Titulo: '🗺️ Find your polling place',
    recurso1Desc:
        'Locate your ballot table according to your DNI (official ONPE).',
    recurso2Titulo: '📋 Informed Vote (JNE)',
    recurso2Desc: 'Government plans, CVs and sanctions of all candidates.',
    recurso3Titulo: '🔍 INFOGOB — Political organizations',
    recurso3Desc:
        'History of parties, leaders, financing and electoral sanctions.',
    recurso4Titulo: '💰 Declara JNE (CVs)',
    recurso4Desc: 'Sworn declarations of assets and income of all candidates.',
    recurso5Titulo: '👁️ Ojo Biónico — OjoPúblico',
    recurso5Desc: 'Fact-check tool to verify candidate statements in debates.',
    recurso6Titulo: '🔍 IDL-Reporteros',
    recurso6Desc:
        'Investigative journalism: corruption, illegal ties, backgrounds.',
    recurso7Titulo: '📊 Ipsos Perú — Polls',
    recurso7Desc: 'Voting intention surveys published in El Comercio.',
    recurso8Titulo: '📈 IEP — Instituto de Estudios Peruanos',
    recurso8Desc:
        'Surveys with focus on non-Lima regions. Published in La República.',
    recurso9Titulo: '⚠️ Non-voter fine (ONPE)',
    recurso9Desc:
        'Check for pending electoral fines or request a no-infraction certificate.',
    cargando: 'Consulting verified sources...',
    errorGeneral: 'Could not load information. Check your connection.',
    sinDatos: 'No verified data available.',
    reintentar: 'Retry',
    verMas: 'View more',
    actualizar: 'Refresh',
  );
}
