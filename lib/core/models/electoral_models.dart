import 'package:equatable/equatable.dart';

/// Encuesta de intención de voto
class Encuesta extends Equatable {
  final String id;
  final String empresa; // Datum, Ipsos, CPI, GfK
  final String metodologia;
  final int muestreo;
  final double margenError;
  final DateTime fechaPublicacion;
  final List<ResultadoEncuesta> resultados;
  final String urlFuente;
  final bool esCertificada;

  const Encuesta({
    required this.id,
    required this.empresa,
    required this.metodologia,
    required this.muestreo,
    required this.margenError,
    required this.fechaPublicacion,
    required this.resultados,
    required this.urlFuente,
    this.esCertificada = true,
  });

  factory Encuesta.fromJson(Map<String, dynamic> j) => Encuesta(
        id: j['id'] as String,
        empresa: j['empresa'] as String,
        metodologia: j['metodologia'] as String,
        muestreo: (j['muestreo'] as num).toInt(),
        margenError: (j['margenError'] as num).toDouble(),
        fechaPublicacion: DateTime.parse(j['fechaPublicacion'] as String),
        resultados: (j['resultados'] as List)
            .map((r) => ResultadoEncuesta.fromJson(r as Map<String, dynamic>))
            .toList(),
        urlFuente: j['urlFuente'] as String,
        esCertificada: j['esCertificada'] as bool? ?? true,
      );

  @override
  List<Object?> get props => [id, empresa, fechaPublicacion];
}

class ResultadoEncuesta extends Equatable {
  final String candidatoId;
  final String nombreCandidato;
  final String partido;
  final double porcentaje;

  const ResultadoEncuesta({
    required this.candidatoId,
    required this.nombreCandidato,
    required this.partido,
    required this.porcentaje,
  });

  factory ResultadoEncuesta.fromJson(Map<String, dynamic> j) =>
      ResultadoEncuesta(
        candidatoId: j['candidatoId'] as String,
        nombreCandidato: j['nombreCandidato'] as String,
        partido: j['partido'] as String,
        porcentaje: (j['porcentaje'] as num).toDouble(),
      );

  @override
  List<Object?> get props => [candidatoId, porcentaje];
}

/// Noticia fact-checked
class Noticia extends Equatable {
  final String id;
  final String titulo;
  final String resumen;
  final String urlFuente;
  final String medioComunicacion; // Ojo Público, IDL-Reporteros, Convoca.pe
  final DateTime fechaPublicacion;
  final List<String> tagsCandiatos;
  final bool esFactChecked;
  final String? imagenUrl;

  const Noticia({
    required this.id,
    required this.titulo,
    required this.resumen,
    required this.urlFuente,
    required this.medioComunicacion,
    required this.fechaPublicacion,
    required this.tagsCandiatos,
    this.esFactChecked = true,
    this.imagenUrl,
  });

  @override
  List<Object?> get props => [id, urlFuente];
}

/// Comparación cara a cara entre dos candidatos
class ComparacionCandidatos extends Equatable {
  final String candidatoAId;
  final String candidatoBId;
  final Map<DimensionComparacion, ComparacionDimension> dimensiones;
  final NivelDiferenciaReal nivelDiferencia;
  final double porcentajePropuestasRecicladas;
  final DateTime generadoEn;

  const ComparacionCandidatos({
    required this.candidatoAId,
    required this.candidatoBId,
    required this.dimensiones,
    required this.nivelDiferencia,
    required this.porcentajePropuestasRecicladas,
    required this.generadoEn,
  });

  @override
  List<Object?> get props => [candidatoAId, candidatoBId, generadoEn];
}

enum DimensionComparacion {
  economia,
  seguridad,
  salud,
  educacion,
  corrupcion,
  medioAmbiente,
  descentralizacion,
  relacionesExteriores,
}

extension DimensionComparacionLabel on DimensionComparacion {
  String get label {
    switch (this) {
      case DimensionComparacion.economia:
        return 'Economía';
      case DimensionComparacion.seguridad:
        return 'Seguridad';
      case DimensionComparacion.salud:
        return 'Salud';
      case DimensionComparacion.educacion:
        return 'Educación';
      case DimensionComparacion.corrupcion:
        return 'Corrupción';
      case DimensionComparacion.medioAmbiente:
        return 'Medio Ambiente';
      case DimensionComparacion.descentralizacion:
        return 'Descentralización';
      case DimensionComparacion.relacionesExteriores:
        return 'Rel. Exteriores';
    }
  }

  String get icon {
    switch (this) {
      case DimensionComparacion.economia:
        return '💰';
      case DimensionComparacion.seguridad:
        return '🛡️';
      case DimensionComparacion.salud:
        return '🏥';
      case DimensionComparacion.educacion:
        return '📚';
      case DimensionComparacion.corrupcion:
        return '⚖️';
      case DimensionComparacion.medioAmbiente:
        return '🌿';
      case DimensionComparacion.descentralizacion:
        return '🗺️';
      case DimensionComparacion.relacionesExteriores:
        return '🌍';
    }
  }
}

class ComparacionDimension extends Equatable {
  final String posicionA;
  final String posicionB;
  final int scoreA; // 0–10
  final int scoreB; // 0–10
  final String analisis;

  const ComparacionDimension({
    required this.posicionA,
    required this.posicionB,
    required this.scoreA,
    required this.scoreB,
    required this.analisis,
  });

  @override
  List<Object?> get props => [posicionA, posicionB];
}

enum NivelDiferenciaReal { cosmetico, moderado, radical }

extension NivelDiferenciaLabel on NivelDiferenciaReal {
  String get label {
    switch (this) {
      case NivelDiferenciaReal.cosmetico:
        return 'Diferencia Cosmética';
      case NivelDiferenciaReal.moderado:
        return 'Diferencia Moderada';
      case NivelDiferenciaReal.radical:
        return 'Diferencia Radical';
    }
  }
}

/// Prioridades ciudadanas para el simulador Mi Voto
enum PriudadCiudadana {
  seguridadCiudadana,
  empleoEconomia,
  saludUniversal,
  educacionCalidad,
  anticorrupcion,
  medioAmbiente,
  descentralizacion,
  igualdadGenero,
  derechosHumanos,
  relacionesExteriores,
  agriculturaRural,
  transporteInfraestructura,
}

extension PriudadLabel on PriudadCiudadana {
  String get label {
    switch (this) {
      case PriudadCiudadana.seguridadCiudadana:
        return 'Seguridad ciudadana';
      case PriudadCiudadana.empleoEconomia:
        return 'Empleo y economía';
      case PriudadCiudadana.saludUniversal:
        return 'Salud universal';
      case PriudadCiudadana.educacionCalidad:
        return 'Educación de calidad';
      case PriudadCiudadana.anticorrupcion:
        return 'Lucha contra corrupción';
      case PriudadCiudadana.medioAmbiente:
        return 'Medio ambiente';
      case PriudadCiudadana.descentralizacion:
        return 'Descentralización';
      case PriudadCiudadana.igualdadGenero:
        return 'Igualdad de género';
      case PriudadCiudadana.derechosHumanos:
        return 'Derechos humanos';
      case PriudadCiudadana.relacionesExteriores:
        return 'Relaciones exteriores';
      case PriudadCiudadana.agriculturaRural:
        return 'Agricultura y zonas rurales';
      case PriudadCiudadana.transporteInfraestructura:
        return 'Transporte e infraestructura';
    }
  }

  String get icon {
    switch (this) {
      case PriudadCiudadana.seguridadCiudadana:
        return '🚔';
      case PriudadCiudadana.empleoEconomia:
        return '💼';
      case PriudadCiudadana.saludUniversal:
        return '🏥';
      case PriudadCiudadana.educacionCalidad:
        return '🎓';
      case PriudadCiudadana.anticorrupcion:
        return '⚖️';
      case PriudadCiudadana.medioAmbiente:
        return '🌿';
      case PriudadCiudadana.descentralizacion:
        return '🗺️';
      case PriudadCiudadana.igualdadGenero:
        return '♀️';
      case PriudadCiudadana.derechosHumanos:
        return '✊';
      case PriudadCiudadana.relacionesExteriores:
        return '🌍';
      case PriudadCiudadana.agriculturaRural:
        return '🌾';
      case PriudadCiudadana.transporteInfraestructura:
        return '🚧';
    }
  }
}

/// Resultado del simulador Mi Voto
class ResultadoMiVoto extends Equatable {
  final String candidatoId;
  final String nombreCandidato;
  final String partido;
  final double porcentajeMatch;
  final String explicacion;
  final List<String> alertasContradiccion;
  final int edad;

  const ResultadoMiVoto({
    required this.candidatoId,
    required this.nombreCandidato,
    required this.partido,
    required this.porcentajeMatch,
    required this.explicacion,
    this.alertasContradiccion = const [],
    this.edad = 0,
  });

  @override
  List<Object?> get props => [candidatoId, porcentajeMatch];
}
