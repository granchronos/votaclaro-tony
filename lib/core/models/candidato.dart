import 'package:equatable/equatable.dart';

enum TipoCandidatura { presidente, congresista, parlamentoAndino }

enum ViabilidadPropuesta { alta, media, baja }

enum NivelRiesgoCorrupcion { bajo, medio, alto }

/// Modelo principal de candidato — cubre los 3 módulos del agente
class Candidato extends Equatable {
  final String id;
  final String nombreCompleto;
  final String partido;
  final String? fotoUrl;
  final TipoCandidatura tipo;
  final String region;
  final int edad;
  final String profesion;
  final String resumenPerfil;
  final double porcentajeEncuestaPonderado;
  final PatrimonioDeclarado patrimonio;
  final List<Propuesta> propuestas;
  final List<String> pros;
  final List<String> contras;
  final AnalisisPredictivo? analisisPredictivo;
  final HistorialLegislativo? historialLegislativo;
  final String fuenteEncuesta;
  final DateTime fechaActualizacion;

  const Candidato({
    required this.id,
    required this.nombreCompleto,
    required this.partido,
    this.fotoUrl,
    required this.tipo,
    required this.region,
    required this.edad,
    required this.profesion,
    required this.resumenPerfil,
    required this.porcentajeEncuestaPonderado,
    required this.patrimonio,
    required this.propuestas,
    required this.pros,
    required this.contras,
    this.analisisPredictivo,
    this.historialLegislativo,
    required this.fuenteEncuesta,
    required this.fechaActualizacion,
  });

  @override
  List<Object?> get props => [id, nombreCompleto, partido, tipo];
}

/// Patrimonio declarado ante JNE
class PatrimonioDeclarado extends Equatable {
  final double totalBienes;
  final double totalDeudas;
  final double ingresoAnual;
  final String descripcionBienes;
  final String fuenteJNE;
  final DateTime fechaDeclaracion;

  const PatrimonioDeclarado({
    required this.totalBienes,
    required this.totalDeudas,
    required this.ingresoAnual,
    required this.descripcionBienes,
    required this.fuenteJNE,
    required this.fechaDeclaracion,
  });

  double get patrimonioNeto => totalBienes - totalDeudas;

  @override
  List<Object?> get props => [fuenteJNE, fechaDeclaracion];
}

/// Una propuesta del candidato con semáforo de viabilidad
class Propuesta extends Equatable {
  final int numero;
  final String area;
  final String descripcion;
  final ViabilidadPropuesta viabilidad;
  final bool esReciclada;
  final String? referenciaPropuestaAnterior; // "prometida por X en año Y"
  final String? fuenteVerificacion;

  const Propuesta({
    required this.numero,
    required this.area,
    required this.descripcion,
    required this.viabilidad,
    this.esReciclada = false,
    this.referenciaPropuestaAnterior,
    this.fuenteVerificacion,
  });

  @override
  List<Object?> get props => [numero, area, descripcion];
}

/// Análisis predictivo "¿Qué pasaría si gana?"
class AnalisisPredictivo extends Equatable {
  final String comparadoCon; // Presidente histórico similar
  final List<String> similitudes;
  final String resultadoHistorico;
  final double probabilidadCumplimiento; // 0–100
  final NivelRiesgoCorrupcion riesgoCorrupcion;
  final String justificacionRiesgo;
  final String fuenteAnalisis;

  const AnalisisPredictivo({
    required this.comparadoCon,
    required this.similitudes,
    required this.resultadoHistorico,
    required this.probabilidadCumplimiento,
    required this.riesgoCorrupcion,
    required this.justificacionRiesgo,
    required this.fuenteAnalisis,
  });

  @override
  List<Object?> get props => [comparadoCon, probabilidadCumplimiento];
}

/// Historial legislativo (solo para congresistas y candidatos con paso previo)
class HistorialLegislativo extends Equatable {
  final int proyectosPresente;
  final int proyectosAprobados;
  final double tasaAsistencia; // 0–100
  final List<String> votosPolemicos;
  final String periodoLegislativo;

  const HistorialLegislativo({
    required this.proyectosPresente,
    required this.proyectosAprobados,
    required this.tasaAsistencia,
    required this.votosPolemicos,
    required this.periodoLegislativo,
  });

  @override
  List<Object?> get props => [periodoLegislativo];
}
