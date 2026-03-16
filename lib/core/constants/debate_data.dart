/// Datos oficiales de los Debates Presidenciales EG 2026
/// Fuente: https://votoinformadoia.jne.gob.pe/debates
class DebateData {
  DebateData._();

  static const debates = [
    DebateInfo(
      title: 'Debate 1',
      date: 'Lun 23 Mar',
      fullDate: 'Lunes 23 de marzo de 2026',
      phase: 'Primera fase',
      topics:
          'Seguridad ciudadana y lucha contra la criminalidad · Integridad pública y lucha contra la corrupción',
      moderator1: 'Claudia Chiroque',
      moderator2: 'Fernando Carvallo',
      participants: [
        'AVANZA PAÍS - PARTIDO DE INTEGRACIÓN SOCIAL',
        'PODEMOS PERÚ',
        'PARTIDO POLÍTICO COOPERACIÓN POPULAR',
        'PARTIDO DE LOS TRABAJADORES Y EMPRENDEDORES PTE-PERÚ',
        'ALIANZA PARA EL PROGRESO',
        'AHORA NACIÓN - AN',
        'PRIMERO LA GENTE - COMUNIDAD, ECOLOGÍA, LIBERTAD Y PROGRESO',
        'PARTIDO DEMÓCRATA VERDE',
        'RENOVACIÓN POPULAR',
        'PARTIDO POLÍTICO INTEGRIDAD DEMOCRÁTICA',
        'PARTIDO PAÍS PARA TODOS',
        'PARTIDO FRENTE DE LA ESPERANZA 2021',
      ],
    ),
    DebateInfo(
      title: 'Debate 2',
      date: 'Mar 24 Mar',
      fullDate: 'Martes 24 de marzo de 2026',
      phase: 'Primera fase',
      topics:
          'Seguridad ciudadana y lucha contra la criminalidad · Integridad pública y lucha contra la corrupción',
      moderator1: 'Claudia Chiroque',
      moderator2: 'Fernando Carvallo',
      participants: [
        'FE EN EL PERÚ',
        'FUERZA Y LIBERTAD',
        'PARTIDO DEMOCRÁTICO FEDERAL',
        'PARTIDO POLÍTICO PRIN',
        'PARTIDO CÍVICO OBRAS',
        'PARTIDO DEMÓCRATA UNIDO PERÚ',
        'PARTIDO POLÍTICO PERÚ ACCIÓN',
        'PARTIDO POLÍTICO NACIONAL PERÚ LIBRE',
        'PARTIDO SÍCREO',
        'PARTIDO DEMOCRÁTICO SOMOS PERÚ',
        'PERÚ MODERNO',
        'JUNTOS POR EL PERÚ',
      ],
    ),
    DebateInfo(
      title: 'Debate 3',
      date: 'Mié 25 Mar',
      fullDate: 'Miércoles 25 de marzo de 2026',
      phase: 'Primera fase',
      topics:
          'Seguridad ciudadana y lucha contra la criminalidad · Integridad pública y lucha contra la corrupción',
      moderator1: 'Claudia Chiroque',
      moderator2: 'Fernando Carvallo',
      participants: [
        'SALVEMOS AL PERÚ',
        'PARTIDO DEL BUEN GOBIERNO',
        'PARTIDO POLÍTICO PERÚ PRIMERO',
        'PARTIDO APRISTA PERUANO',
        'LIBERTAD POPULAR',
        'PROGRESEMOS',
        'PARTIDO MORADO',
        'UNIDAD NACIONAL',
        'ALIANZA ELECTORAL VENCEREMOS',
        'FUERZA POPULAR',
        'PARTIDO PATRIÓTICO DEL PERÚ',
        'UN CAMINO DIFERENTE',
      ],
    ),
    DebateInfo(
      title: 'Debate 4',
      date: 'Lun 30 Mar',
      fullDate: 'Lunes 30 de marzo de 2026',
      phase: 'Segunda fase',
      topics:
          'Empleo, desarrollo y emprendimiento · Educación, innovación y tecnología',
      moderator1: 'Angélica Valdés',
      moderator2: 'Pedro Tenorio',
      participants: [
        'PERÚ MODERNO',
        'PARTIDO DEMOCRÁTICO SOMOS PERÚ',
        'FE EN EL PERÚ',
        'FUERZA Y LIBERTAD',
        'PARTIDO DEMÓCRATA VERDE',
        'PARTIDO SÍCREO',
        'PARTIDO POLÍTICO COOPERACIÓN POPULAR',
        'PARTIDO POLÍTICO PRIN',
        'ALIANZA ELECTORAL VENCEREMOS',
        'PARTIDO FRENTE DE LA ESPERANZA 2021',
        'PARTIDO PAÍS PARA TODOS',
        'PARTIDO APRISTA PERUANO',
      ],
    ),
    DebateInfo(
      title: 'Debate 5',
      date: 'Mar 31 Mar',
      fullDate: 'Martes 31 de marzo de 2026',
      phase: 'Segunda fase',
      topics:
          'Empleo, desarrollo y emprendimiento · Educación, innovación y tecnología',
      moderator1: 'Angélica Valdés',
      moderator2: 'Pedro Tenorio',
      participants: [
        'PARTIDO PATRIÓTICO DEL PERÚ',
        'PARTIDO MORADO',
        'JUNTOS POR EL PERÚ',
        'PROGRESEMOS',
        'FUERZA POPULAR',
        'RENOVACIÓN POPULAR',
        'PRIMERO LA GENTE - COMUNIDAD, ECOLOGÍA, LIBERTAD Y PROGRESO',
        'PARTIDO POLÍTICO PERÚ PRIMERO',
        'PARTIDO DEMÓCRATA UNIDO PERÚ',
        'PARTIDO POLÍTICO NACIONAL PERÚ LIBRE',
        'PARTIDO POLÍTICO PERÚ ACCIÓN',
        'UNIDAD NACIONAL',
      ],
    ),
    DebateInfo(
      title: 'Debate 6',
      date: 'Mié 1 Abr',
      fullDate: 'Miércoles 1 de abril de 2026',
      phase: 'Segunda fase',
      topics:
          'Empleo, desarrollo y emprendimiento · Educación, innovación y tecnología',
      moderator1: 'Angélica Valdés',
      moderator2: 'Pedro Tenorio',
      participants: [
        'PARTIDO CÍVICO OBRAS',
        'LIBERTAD POPULAR',
        'PODEMOS PERÚ',
        'ALIANZA PARA EL PROGRESO',
        'PARTIDO POLÍTICO INTEGRIDAD DEMOCRÁTICA',
        'UN CAMINO DIFERENTE',
        'PARTIDO DEL BUEN GOBIERNO',
        'PARTIDO DEMOCRÁTICO FEDERAL',
        'AHORA NACIÓN - AN',
        'SALVEMOS AL PERÚ',
        'PARTIDO DE LOS TRABAJADORES Y EMPRENDEDORES PTE-PERÚ',
        'AVANZA PAÍS - PARTIDO DE INTEGRACIÓN SOCIAL',
      ],
    ),
  ];

  /// Returns the debate indices (0-based) where a party participates.
  /// Uses normalized comparison stripping accents for robust matching.
  static List<int> debatesForParty(String partyName) {
    final norm = _normalize(partyName);
    if (norm.isEmpty) return [];
    final result = <int>[];
    for (var i = 0; i < debates.length; i++) {
      if (debates[i].participants.any((p) => _normalize(p) == norm)) {
        result.add(i);
      }
    }
    // If exact normalized match failed, try contains-based match
    if (result.isEmpty) {
      for (var i = 0; i < debates.length; i++) {
        if (debates[i].participants.any(
            (p) => _normalize(p).contains(norm) || norm.contains(_normalize(p)))) {
          result.add(i);
        }
      }
    }
    return result;
  }

  /// Strips accents/diacritics and lowercases for comparison.
  static String _normalize(String s) {
    const _accents = 'àáâãäåèéêëìíîïòóôõöùúûüýñçÀÁÂÃÄÅÈÉÊËÌÍÎÏÒÓÔÕÖÙÚÛÜÝÑÇ';
    const _plain   = 'aaaaaaeeeeiiiioooooouuuuynccaaaaaaeeeeiiiioooooouuuuyncc';
    final buf = StringBuffer();
    for (final ch in s.toLowerCase().runes) {
      final c = String.fromCharCode(ch);
      final idx = _accents.indexOf(c);
      buf.write(idx >= 0 ? _plain[idx] : c);
    }
    return buf.toString().replaceAll(RegExp(r'[^a-z0-9 ]'), '').replaceAll(RegExp(r'\s+'), ' ').trim();
  }
}

class DebateInfo {
  final String title;
  final String date;
  final String fullDate;
  final String phase;
  final String topics;
  final String moderator1;
  final String moderator2;
  final List<String> participants;

  const DebateInfo({
    required this.title,
    required this.date,
    required this.fullDate,
    required this.phase,
    required this.topics,
    required this.moderator1,
    required this.moderator2,
    required this.participants,
  });
}
