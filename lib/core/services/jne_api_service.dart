import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;

import 'cors_proxy.dart';

/// Servicio para consultar la API oficial de Voto Informado del JNE.
///
/// Fuente: https://votoinformado.jne.gob.pe
/// API:    https://web.jne.gob.pe/serviciovotoinformado/api/votoinf/
class JneApiService {
  static const String _base =
      'https://web.jne.gob.pe/serviciovotoinformado/api/votoinf';
  static const String _baseElectoral =
      'https://apiplataformaelectoral3.jne.gob.pe/api/v1/candidato';
  static const String _baseIA =
      'https://votoinformadoia.jne.gob.pe/ServiciosWeb/api/v1';

  static const String _imageBase = 'https://mpesije.jne.gob.pe/apidocs/';

  static const int _idProceso = 124; // Elecciones Generales 2026

  // Tipos de elección
  static const int tipoPresidencial = 1;
  static const int tipoParlamentoAndino = 3;
  static const int tipoSenadores = 14;
  static const int tipoDiputados = 15;
  static const int tipoSenadorDistritoUnico = 20;
  static const int tipoSenadorDepartamental = 21;

  // Departamentos (ubigeo)
  static const Map<String, String> departamentos = {
    'Todos': '',
    'Amazonas': '01',
    'Ancash': '02',
    'Apurimac': '03',
    'Arequipa': '04',
    'Ayacucho': '05',
    'Cajamarca': '06',
    'Cusco': '07',
    'Huancavelica': '08',
    'Huanuco': '09',
    'Ica': '10',
    'Junin': '11',
    'La Libertad': '12',
    'Lambayeque': '13',
    'Lima': '140100',
    'Loreto': '15',
    'Madre de Dios': '16',
    'Moquegua': '17',
    'Pasco': '18',
    'Piura': '19',
    'Puno': '20',
    'San Martin': '21',
    'Tacna': '22',
    'Tumbes': '23',
    'Callao': '24',
    'Ucayali': '25',
  };

  // ── Candidatos por tipo de elección ─────────────────────────────────────

  /// Candidatos presidenciales (solo cargo 1 = Presidente).
  Future<List<Map<String, dynamic>>> getCandidatosPresidente() async {
    final raw = await _listarCandidatos(tipoPresidencial);
    final presidentes = raw.where((c) => c['idCargo'] == 1).toList();
    return presidentes.map(_mapCandidato).toList();
  }

  /// Diputados por departamento.
  Future<List<Map<String, dynamic>>> getDiputados(
      [String departamento = 'Lima']) async {
    final ubigeo = departamentos[departamento] ?? '140100';
    final raw = await _listarCandidatos(tipoDiputados, ubigeo: ubigeo);
    return raw.map(_mapCandidato).toList();
  }

  /// Senadores por departamento.
  Future<List<Map<String, dynamic>>> getSenadores(
      [String departamento = 'Lima']) async {
    final ubigeo = departamentos[departamento] ?? '140100';
    final raw =
        await _listarCandidatos(tipoSenadorDepartamental, ubigeo: ubigeo);
    return raw.map(_mapCandidato).toList();
  }

  /// Candidatos al Parlamento Andino.
  Future<List<Map<String, dynamic>>> getParlamentoAndino() async {
    final raw = await _listarCandidatos(tipoParlamentoAndino);
    return raw.map(_mapCandidato).toList();
  }

  // ── Plan de gobierno ────────────────────────────────────────────────────

  /// Obtiene el plan de gobierno de una organización política.
  Future<Map<String, dynamic>?> getPlanGobierno(int idOrganizacionPolitica,
      {int idTipoEleccion = tipoPresidencial}) async {
    final body = {
      'pageSize': 10,
      'skip': 1,
      'filter': {
        'idProcesoElectoral': _idProceso,
        'idTipoEleccion': idTipoEleccion.toString(),
        'idOrganizacionPolitica': idOrganizacionPolitica.toString(),
        'txDatoCandidato': '',
        'idJuradoElectoral': '0',
      },
    };
    final result = await _post('$_base/plangobierno', body);
    final data = result['data'];
    if (data is List && data.isNotEmpty) {
      return Map<String, dynamic>.from(data.first as Map);
    }
    return null;
  }

  /// Obtiene el detalle del plan de gobierno por dimensiones.
  Future<Map<String, dynamic>> getPlanGobiernoDetalle(
      int idPlanGobierno) async {
    return _get('$_base/detalle-plangobierno?IdPlanGobierno=$idPlanGobierno');
  }

  /// Obtiene la hoja de vida consolidada de un candidato.
  Future<Map<String, dynamic>> getHojaVida(
      String dni, int idOrganizacionPolitica) async {
    final body = {
      'idProcesoElectoral': _idProceso,
      'strDocumentoIdentidad': dni,
      'idOrganizacionPolitica': idOrganizacionPolitica.toString(),
    };
    return _post('$_base/HVConsolidado', body);
  }

  /// Obtiene complemento de hoja de vida.
  Future<Map<String, dynamic>> getHojaVidaComplemento(int idHojaVida) async {
    return _get('$_base/hojavida?idHojaVida=$idHojaVida');
  }

  /// Obtiene la fórmula presidencial (presidente + vicepresidentes) por organización.
  /// Usa listarCanditatos y agrupa por idOrganizacionPolitica.
  /// Retorna lista de candidatos con idCargo: 1=Presidente, 2=VP1, 3=VP2.
  Future<List<Map<String, dynamic>>> getFormulaPresidencial(
      int idOrganizacionPolitica) async {
    final raw = await _listarCandidatos(tipoPresidencial);
    final formula = raw
        .where((c) => c['idOrganizacionPolitica'] == idOrganizacionPolitica)
        .toList();
    // Ordenar: Presidente (1), VP1 (2), VP2 (3)
    formula.sort((a, b) =>
        ((a['idCargo'] as int?) ?? 0).compareTo((b['idCargo'] as int?) ?? 0));
    return formula.map(_mapCandidato).toList();
  }

  /// Obtiene anotaciones marginales de un candidato por idHojaVida.
  /// Usa la API de Plataforma Electoral (distinta base).
  Future<List<Map<String, dynamic>>> getAnotacionMarginal(
      int idHojaVida) async {
    final result =
        await _get('$_baseElectoral/anotacion-marginal?IdHojaVida=$idHojaVida');
    final data = result['data'];
    if (data is List) {
      return data.map((e) => Map<String, dynamic>.from(e as Map)).toList();
    }
    return [];
  }

  /// Búsqueda avanzada de candidatos por organización política.
  Future<List<Map<String, dynamic>>> busquedaAvanzada({
    required int idOrganizacionPolitica,
    int idTipoEleccion = tipoPresidencial,
  }) async {
    final body = {
      'pageSize': 20,
      'skip': 1,
      'filter': {
        'IdTipoEleccion': idTipoEleccion.toString(),
        'IdOrganizacionPolitica': idOrganizacionPolitica,
        'ubigeo': '0',
        'IdAnioExperiencia': 0,
        'cargoOcupado': [0],
        'IdSentenciaDeclarada': 0,
        'IdGradoAcademico': 0,
        'IdExpedienteDadiva': 0,
        'IdProcesoElectoral': _idProceso,
        'IdEstado': 0,
      },
    };
    final result = await _post('$_base/avanzada-voto', body);
    final data = result['data'];
    if (data is List) {
      return data.map((e) => Map<String, dynamic>.from(e as Map)).toList();
    }
    return [];
  }

  // ── JNE IA API ─────────────────────────────────────────────────────────

  /// Lista de partidos políticos con logos y fotos de candidatos.
  /// Retorna [{IDORGANIZACIONPOLITICA, TXORGANIZACIONPOLITICA,
  ///   TXURLORGANIZACIONPOLITICA (logo SVG), TXURLFOTOCANDIDATO}]
  Future<List<Map<String, dynamic>>> getPartidosPoliticos(
      int idTipoEleccion) async {
    final body = {
      'idProcesoElectoral': _idProceso,
      'strUbiDepartamento': '',
      'idTipoEleccion': idTipoEleccion,
    };
    final result = await _post('$_baseIA/ListaPartidosPoliticos', body);
    final data = result['data'];
    if (data is List) {
      return data.map((e) => Map<String, dynamic>.from(e as Map)).toList();
    }
    return [];
  }

  /// Búsqueda integrada de candidatos con hoja de vida desde JNE IA API.
  /// Retorna datos enriquecidos: títulos, profesiones, sentencias, fotos, etc.
  Future<List<Map<String, dynamic>>> buscarCandidatoIA({
    required String texto,
    int idTipoEleccion = tipoPresidencial,
    String ubigeo = '',
  }) async {
    final body = {
      'texto': texto,
      'idProcesoElectoral': _idProceso,
      'strUbiDepartamento': ubigeo,
      'idTipoEleccion': idTipoEleccion,
    };
    final result =
        await _post('$_baseIA/candidato/hoja-de-vida-integrado/filtrar', body);
    final data = result['data'];
    if (data is Map && data['resultados'] is List) {
      return (data['resultados'] as List)
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList();
    }
    return [];
  }

  // ── URLs directas ──────────────────────────────────────────────────────

  /// URL de la foto del candidato en el servidor del JNE.
  /// En web se proxea a través de la Edge Function para evitar CORS.
  static String fotoUrl(String? guidFoto) {
    if (guidFoto == null || guidFoto.isEmpty) return '';
    return CorsProxy.imageUrl('$_imageBase$guidFoto');
  }

  // ── Utilitarios privados ───────────────────────────────────────────────

  /// Mapea un registro crudo del JNE al formato usado por la app.
  Map<String, dynamic> _mapCandidato(Map<String, dynamic> raw) {
    final nombres = raw['strNombres'] as String? ?? '';
    final apPat = raw['strApellidoPaterno'] as String? ?? '';
    final apMat = raw['strApellidoMaterno'] as String? ?? '';
    final fullName = _titleCase('$nombres $apPat $apMat');
    final partido = raw['strOrganizacionPolitica'] as String? ?? '';
    final fotoGuid = raw['strNombre'] as String?; // GUID.jpg
    final foto =
        (fotoGuid != null && fotoGuid.isNotEmpty) ? fotoUrl(fotoGuid) : null;
    final nacimiento = _parseFecha(raw['strFechaNacimiento'] as String? ?? '');
    final edad = nacimiento != null
        ? DateTime.now().difference(nacimiento).inDays ~/ 365
        : 0;
    final idOP = raw['idOrganizacionPolitica'];
    final dni = raw['strDocumentoIdentidad'] as String? ?? '';

    return {
      'id': 'jne_${idOP}_$dni',
      'nombreCompleto': fullName,
      'partido': _titleCase(partido),
      'porcentajeEncuesta': 0.0,
      'fuenteEncuesta': 'JNE Voto Informado 2026',
      'edad': edad,
      'profesion': raw['strCargo'] as String? ?? '',
      'region': raw['strDepartamento'] as String? ?? '',
      'resumenPerfil': '',
      'fotoUrl': foto,
      'colorPartido': null,
      'idOrganizacionPolitica': idOP,
      'dni': dni,
      'sexo': raw['strSexo'],
      'posicion': raw['intPosicion'],
      'estado': raw['strEstadoCandidato'],
      'tipoEleccion': raw['idTipoEleccion'],
      'idCargo': raw['idCargo'],
      'idHojaVida': raw['idHojaVida'],
    };
  }

  /// Llama al endpoint POST listarCanditatos del JNE.
  Future<List<Map<String, dynamic>>> _listarCandidatos(int idTipoEleccion,
      {String ubigeo = ''}) async {
    final body = {
      'idProcesoElectoral': _idProceso,
      'strUbiDepartamento': ubigeo,
      'idTipoEleccion': idTipoEleccion,
    };
    final result = await _post('$_base/listarCanditatos', body);
    final data = result['data'];
    if (data is List) {
      return data.map((e) => Map<String, dynamic>.from(e as Map)).toList();
    }
    return [];
  }

  Future<Map<String, dynamic>> _post(
      String url, Map<String, dynamic> body) async {
    try {
      final headers = {'Content-Type': 'application/json'};
      final uri = Uri.parse(url);
      final http.Response res;
      if (kIsWeb) {
        res =
            await CorsProxy.post(uri, headers: headers, body: jsonEncode(body))
                .timeout(const Duration(seconds: 15));
      } else {
        res = await http
            .post(uri, headers: headers, body: jsonEncode(body))
            .timeout(const Duration(seconds: 15));
      }
      if (res.statusCode != 200) return {};
      final decoded = jsonDecode(utf8.decode(res.bodyBytes));
      return decoded is Map<String, dynamic> ? decoded : {};
    } catch (_) {
      return {};
    }
  }

  Future<Map<String, dynamic>> _get(String url) async {
    try {
      final headers = {'Accept': 'application/json'};
      final uri = Uri.parse(url);
      final http.Response res;
      if (kIsWeb) {
        res = await CorsProxy.get(uri, headers: headers)
            .timeout(const Duration(seconds: 15));
      } else {
        res = await http
            .get(uri, headers: headers)
            .timeout(const Duration(seconds: 15));
      }
      if (res.statusCode != 200) return {};
      final decoded = jsonDecode(utf8.decode(res.bodyBytes));
      return decoded is Map<String, dynamic> ? decoded : {};
    } catch (_) {
      return {};
    }
  }

  String _titleCase(String input) {
    return input
        .toLowerCase()
        .split(' ')
        .where((w) => w.isNotEmpty)
        .map((w) => '${w[0].toUpperCase()}${w.substring(1)}')
        .join(' ');
  }

  DateTime? _parseFecha(String raw) {
    if (raw.isEmpty) return null;
    try {
      final parts = raw.split(' ').first.split('/');
      if (parts.length == 3) {
        return DateTime(
            int.parse(parts[2]), int.parse(parts[1]), int.parse(parts[0]));
      }
    } catch (_) {}
    return null;
  }
}
