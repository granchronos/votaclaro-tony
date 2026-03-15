import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../core/l10n/app_l10n.dart';
import '../../core/services/providers.dart';
import '../../widgets/common/widgets.dart';
import '../../widgets/common/theme_mode_selector.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  String _searchQuery = '';
  String? _filtroRiesgo; // 'ALTO', 'MEDIO', 'BAJO'

  @override
  Widget build(BuildContext context) {
    final t = ref.watch(translationsProvider);
    final selectedTab = ref.watch(selectedEleccionTabProvider);
    final encuestas = ref.watch(encuestasProvider);

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: const BoxDecoration(
                color: AppColors.primary,
                shape: BoxShape.circle,
              ),
              child:
                  const Icon(Icons.how_to_vote, color: Colors.white, size: 18),
            ),
            const SizedBox(width: 10),
            Text(t.appName),
          ],
        ),
        actions: [
          const ThemeModeSelector(),
          const LanguageSelectorButton(),
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: () => _showAboutDialog(context, t),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(candidatosPresidenteProvider);
          ref.invalidate(encuestasProvider);
          ref.invalidate(topCandidatosPorEncuestaProvider);
        },
        child: ListView(
          children: [
            const _HeroBanner(),
            const NeutralidadBanner(),
            const _EleccionTabs(),

            // Search bar
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
              child: TextField(
                onChanged: (v) => setState(() => _searchQuery = v),
                decoration: InputDecoration(
                  hintText: '🔍 Buscar por nombre o partido...',
                  prefixIcon: const Icon(Icons.search, size: 20),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.close, size: 18),
                          onPressed: () {
                            setState(() => _searchQuery = '');
                            FocusScope.of(context).unfocus();
                          },
                        )
                      : null,
                  contentPadding: const EdgeInsets.symmetric(vertical: 10),
                  filled: true,
                  fillColor: AppColors.surfaceVariant,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),

            // Filter chips - risk level
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _FilterChipCustom(
                      label: '🟢 Riesgo Bajo',
                      selected: _filtroRiesgo == 'BAJO',
                      color: AppColors.viable,
                      onTap: () => setState(() => _filtroRiesgo =
                          _filtroRiesgo == 'BAJO' ? null : 'BAJO'),
                    ),
                    const SizedBox(width: 8),
                    _FilterChipCustom(
                      label: '🟡 Riesgo Medio',
                      selected: _filtroRiesgo == 'MEDIO',
                      color: AppColors.doubtful,
                      onTap: () => setState(() => _filtroRiesgo =
                          _filtroRiesgo == 'MEDIO' ? null : 'MEDIO'),
                    ),
                    const SizedBox(width: 8),
                    _FilterChipCustom(
                      label: '🔴 Riesgo Alto',
                      selected: _filtroRiesgo == 'ALTO',
                      color: AppColors.inviable,
                      onTap: () => setState(() => _filtroRiesgo =
                          _filtroRiesgo == 'ALTO' ? null : 'ALTO'),
                    ),
                  ],
                ),
              ),
            ),

            // Dynamic section header based on selected tab
            SectionHeader(
              title: selectedTab == 0
                  ? '📊 Top 5 — Encuestas 2026'
                  : selectedTab == 1
                      ? '🗳️ Top 4 Candidatos al Congreso'
                      : '🌍 Top 4 Parlamento Andino',
              subtitle: selectedTab == 0
                  ? 'Promedio de intención de voto (${_getEncuestasList(ref)})'
                  : selectedTab == 1
                      ? 'Cabezas de lista por partido y región'
                      : 'Lista nacional — 5 escaños titulares',
              trailing: selectedTab == 0
                  ? TextButton(
                      onPressed: () => context.go('/candidatos'),
                      child: Text(t.verTodos),
                    )
                  : null,
            ),
            // Dynamic candidate list based on selected tab
            _CandidatosList(
              tabIndex: selectedTab,
              searchQuery: _searchQuery,
              filtroRiesgo: _filtroRiesgo,
            ),
            encuestas.when(
              data: (list) => list.isNotEmpty
                  ? _EncuestaBanner(encuesta: list.first)
                  : const SizedBox(),
              loading: () => const SizedBox(),
              error: (_, __) => const SizedBox(),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                t.disclaimerFuentes,
                style: Theme.of(context).textTheme.labelSmall,
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  String _getEncuestasList(WidgetRef ref) {
    final enc = ref.watch(encuestasProvider);
    return enc.when(
      data: (list) {
        final empresas = list.map((e) => e.empresa).toSet().take(3).join(', ');
        return empresas.isNotEmpty ? empresas : 'encuestadoras';
      },
      loading: () => 'cargando...',
      error: (_, __) => 'encuestadoras',
    );
  }

  void _showAboutDialog(BuildContext context, AppL10n t) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(t.acercaDe),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(t.appTagline),
            const SizedBox(height: 12),
            Text(t.disclaimerNeutralidad),
            const SizedBox(height: 8),
            Text(t.disclaimerPrivacidad),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(t.cerrar),
          ),
        ],
      ),
    );
  }
}

class _HeroBanner extends ConsumerWidget {
  const _HeroBanner();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = ref.watch(translationsProvider);
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primary, AppColors.primaryDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              t.heroBadge,
              style: const TextStyle(color: Colors.white, fontSize: 12),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            t.heroTitle,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.w700,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            t.heroSubtitle,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 13,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _StatChip(t.chipEncuestas),
              const SizedBox(width: 8),
              _StatChip(t.chipPatrimonio),
              const SizedBox(width: 8),
              _StatChip(t.chipAnalisis),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final String label;
  const _StatChip(this.label);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white.withOpacity(0.3)),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.w500,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }
}

class _EleccionTabs extends ConsumerStatefulWidget {
  const _EleccionTabs();

  @override
  ConsumerState<_EleccionTabs> createState() => _EleccionTabsState();
}

class _EleccionTabsState extends ConsumerState<_EleccionTabs> {
  @override
  Widget build(BuildContext context) {
    final t = ref.watch(translationsProvider);
    final selected = ref.watch(selectedEleccionTabProvider);
    final tabs = [t.tabPresidente, t.tabDiputados, t.tabSenadores, t.tabAndino];
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: List.generate(tabs.length, (i) {
            final isSelected = selected == i;
            return Padding(
              padding: EdgeInsets.only(right: i < tabs.length - 1 ? 8 : 0),
              child: GestureDetector(
                onTap: () =>
                    ref.read(selectedEleccionTabProvider.notifier).state = i,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding:
                      const EdgeInsets.symmetric(vertical: 10, horizontal: 18),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppColors.primary
                        : AppColors.surfaceVariant,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    tabs[i],
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color:
                          isSelected ? Colors.white : AppColors.textSecondary,
                    ),
                  ),
                ),
              ),
            );
          }),
        ),
      ),
    );
  }
}

/// Custom filter chip with better design
class _FilterChipCustom extends StatelessWidget {
  final String label;
  final bool selected;
  final Color color;
  final VoidCallback onTap;

  const _FilterChipCustom({
    required this.label,
    required this.selected,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? color.withOpacity(0.15) : AppColors.surfaceVariant,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? color : AppColors.border,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
            color: selected ? color : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }
}

/// Displays the candidate list for the selected election tab (president/congress/andean)
class _CandidatosList extends ConsumerWidget {
  final int tabIndex;
  final String searchQuery;
  final String? filtroRiesgo;
  const _CandidatosList({
    required this.tabIndex,
    required this.searchQuery,
    this.filtroRiesgo,
  });

  /// Calculates risk level from candidate data (matches profile logic)
  static String _calcRiesgoNivel(Map<String, dynamic> c) {
    int score = 0;
    // We don't have full HV here, but we can use basic indicators
    final sentPen = (c['sentenciasPenales'] as num?)?.toInt() ?? 0;
    final sentObl = (c['sentenciasObligatorias'] as num?)?.toInt() ?? 0;
    if (sentPen > 0) score += 3;
    if (sentObl > 0) score += 2;
    // Use poll presence as proxy — low unknown risk
    if (score >= 5) return 'ALTO';
    if (score >= 3) return 'MEDIO';
    return 'BAJO';
  }

  List<Map<String, dynamic>> _applyFilters(List<Map<String, dynamic>> list) {
    var filtered = list;
    if (searchQuery.isNotEmpty) {
      final q = searchQuery.toLowerCase();
      filtered = filtered.where((c) {
        final nombre = (c['nombreCompleto'] as String? ?? '').toLowerCase();
        final partido = (c['partido'] as String? ?? '').toLowerCase();
        return nombre.contains(q) || partido.contains(q);
      }).toList();
    }
    // Risk filter not applied for non-presidential (no data)
    return filtered;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = ref.watch(translationsProvider);

    if (tabIndex == 0) {
      // Presidential — Top 5 sorted by encuesta average
      final topAsync = ref.watch(topCandidatosPorEncuestaProvider);
      return topAsync.when(
        data: (list) {
          var filtered = _applyFilters(list);
          // Risk filter for presidential
          if (filtroRiesgo != null) {
            filtered = filtered
                .where((c) => _calcRiesgoNivel(c) == filtroRiesgo)
                .toList();
          }
          if (filtered.isEmpty) {
            return Padding(
              padding: const EdgeInsets.all(24),
              child: Center(
                child: Text(
                  searchQuery.isNotEmpty || filtroRiesgo != null
                      ? 'Sin resultados para el filtro aplicado'
                      : t.sinCandidatos,
                  style: const TextStyle(color: AppColors.textSecondary),
                ),
              ),
            );
          }
          return Column(
            children: filtered.take(5).map((c) {
              final prom = (c['promedioEncuesta'] as num?)?.toDouble() ?? 0;
              return _TopCandidatoCard(
                candidato: c,
                promedioEncuesta: prom,
                onTap: () => context.go('/candidatos/${c['id']}'),
              );
            }).toList(),
          );
        },
        loading: () => Column(
          children: List.generate(3, (_) => const LoadingCard()),
        ),
        error: (e, _) => Padding(
          padding: const EdgeInsets.all(24),
          child: Text(t.errorGeneral,
              style: const TextStyle(color: AppColors.textSecondary)),
        ),
      );
    } else if (tabIndex == 1) {
      // Diputados (Deputies)
      final candidatos = ref.watch(candidatosCongresoProvider('Lima'));
      return candidatos.when(
        data: (list) {
          final filtered = _applyFilters(list);
          return Column(
            children: filtered
                .take(4)
                .map((c) => CandidatoCard(
                      candidato: c,
                      showEncuesta: false,
                      onTap: () => context.go('/candidatos/${c['id']}'),
                    ))
                .toList(),
          );
        },
        loading: () => Column(
          children: List.generate(3, (_) => const LoadingCard()),
        ),
        error: (e, _) => Padding(
          padding: const EdgeInsets.all(24),
          child: Text(t.errorGeneral,
              style: const TextStyle(color: AppColors.textSecondary)),
        ),
      );
    } else if (tabIndex == 2) {
      // Senadores
      final candidatos = ref.watch(candidatosSenadoresProvider('Lima'));
      return candidatos.when(
        data: (list) {
          final filtered = _applyFilters(list);
          if (filtered.isEmpty) {
            return Padding(
              padding: const EdgeInsets.all(24),
              child: Center(
                child: Text(
                  searchQuery.isNotEmpty
                      ? 'Sin resultados para el filtro aplicado'
                      : t.sinCandidatos,
                  style: const TextStyle(color: AppColors.textSecondary),
                ),
              ),
            );
          }
          return Column(
            children: filtered
                .take(4)
                .map((c) => CandidatoCard(
                      candidato: c,
                      showEncuesta: false,
                      onTap: () => context.go('/candidatos/${c['id']}'),
                    ))
                .toList(),
          );
        },
        loading: () => Column(
          children: List.generate(3, (_) => const LoadingCard()),
        ),
        error: (e, _) => Padding(
          padding: const EdgeInsets.all(24),
          child: Text(t.errorGeneral,
              style: const TextStyle(color: AppColors.textSecondary)),
        ),
      );
    } else {
      // Andean Parliament candidates
      final candidatos = ref.watch(candidatosAndinoProvider);
      return candidatos.when(
        data: (list) {
          final filtered = _applyFilters(list);
          return Column(
            children: filtered
                .take(4)
                .map((c) => CandidatoCard(
                      candidato: c,
                      showEncuesta: false,
                      onTap: () => context.go('/candidatos/${c['id']}'),
                    ))
                .toList(),
          );
        },
        loading: () => Column(
          children: List.generate(3, (_) => const LoadingCard()),
        ),
        error: (e, _) => Padding(
          padding: const EdgeInsets.all(24),
          child: Text(t.errorGeneral,
              style: const TextStyle(color: AppColors.textSecondary)),
        ),
      );
    }
  }
}

/// Top candidate card with poll %, party symbol, and "qué pasaría" section
class _TopCandidatoCard extends StatelessWidget {
  final Map<String, dynamic> candidato;
  final double promedioEncuesta;
  final VoidCallback onTap;

  const _TopCandidatoCard({
    required this.candidato,
    required this.promedioEncuesta,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final nombre = candidato['nombreCompleto'] as String? ?? 'Sin nombre';
    final partido = candidato['partido'] as String? ?? '';
    final fotoUrl = candidato['fotoUrl'] as String?;
    final logoPartidoUrl = candidato['logoPartidoUrl'] as String?;
    final partidoColor =
        AppColors.partidoColors[partido] ?? AppColors.partidoColors['default']!;

    final enfoque = _getEnfoqueBrief(partido);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
      elevation: 0.5,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  // Avatar — fixed 48x48
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.surfaceVariant,
                      border: Border.all(color: partidoColor, width: 2.5),
                    ),
                    child: fotoUrl != null
                        ? ClipOval(
                            child: Image.network(
                              fotoUrl,
                              width: 48,
                              height: 48,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => const Icon(
                                  Icons.person,
                                  size: 22,
                                  color: AppColors.textSecondary),
                            ),
                          )
                        : const Icon(Icons.person,
                            size: 22, color: AppColors.textSecondary),
                  ),
                  const SizedBox(width: 10),

                  // Name + party
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          nombre,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            if (logoPartidoUrl != null)
                              SizedBox(
                                width: 20,
                                height: 20,
                                child: Stack(
                                  alignment: Alignment.center,
                                  children: [
                                    Container(
                                      width: 8,
                                      height: 8,
                                      decoration: BoxDecoration(
                                        color: partidoColor,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                    SvgPicture.network(
                                      logoPartidoUrl,
                                      width: 20,
                                      height: 20,
                                      fit: BoxFit.contain,
                                      placeholderBuilder: (_) =>
                                          const SizedBox(),
                                    ),
                                  ],
                                ),
                              )
                            else
                              Container(
                                width: 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  color: partidoColor,
                                  shape: BoxShape.circle,
                                ),
                              ),
                            const SizedBox(width: 5),
                            Expanded(
                              child: Text(
                                partido,
                                style: TextStyle(
                                  fontSize: 11,
                                  color: partidoColor,
                                  fontWeight: FontWeight.w600,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              // "Qué pasaría si gana" section
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.accent.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.accent.withOpacity(0.1)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.how_to_vote,
                        size: 14, color: AppColors.accent),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            '¿Qué pasaría si gana?',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: AppColors.accent,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            enfoque,
                            style: const TextStyle(
                              fontSize: 10,
                              color: AppColors.textPrimary,
                              height: 1.3,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.chevron_right,
                        size: 14, color: AppColors.textHint),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Brief "qué pasaría" description based on party/candidate known tendencies
  String _getEnfoqueBrief(String partido) {
    // Generic enfoque by well-known parties
    final enfoques = {
      'Renovación Popular':
          'Enfoque conservador: seguridad, inversión privada, valores tradicionales. Reformas institucionales estrictas.',
      'Fuerza Popular':
          'Enfoque económico: libre mercado, seguridad ciudadana, programas sociales focalizados.',
      'Alianza para el Progreso':
          'Enfoque pragmático: infraestructura, descentralización, inversión en educación y salud.',
      'Ahora Nación':
          'Enfoque social-progresista: salud universal, educación pública, derechos laborales.',
      'País para Todos':
          'Enfoque de unidad: diálogo político, reformas institucionales, programas sociales.',
      'Somos Perú':
          'Enfoque municipalista: descentralización, gestión pública eficiente, seguridad ciudadana.',
      'Perú Primero':
          'Enfoque reformista: modernización del Estado, inversión y competitividad económica.',
      'Podemos Perú':
          'Enfoque populista: programas de asistencia, inversión en infraestructura, empleo.',
      'Cooperación Popular':
          'Enfoque socialdemócrata: Estado fuerte, programas sociales, defensa del trabajador.',
      'Partido Cívico OBRAS':
          'Enfoque mediático-social: grandes obras, comunicación directa, programas populares.',
    };
    return enfoques[partido] ??
        'Toca para ver el perfil completo y análisis detallado del enfoque de gobierno.';
  }
}

class _EncuestaBanner extends StatelessWidget {
  final dynamic encuesta;
  const _EncuestaBanner({required this.encuesta});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.accentLight,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.accent.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '📊 ${encuesta.empresa}',
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  color: AppColors.accent,
                ),
              ),
              SourceTag(
                  fuente: 'Certificada', fecha: encuesta.fechaPublicacion),
            ],
          ),
          const SizedBox(height: 12),
          ...encuesta.resultados.take(3).map<Widget>((r) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: Text(
                      r.nombreCandidato,
                      style: const TextStyle(
                          fontSize: 13, fontWeight: FontWeight.w500),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Expanded(
                    flex: 5,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: r.porcentaje / 100,
                        backgroundColor: AppColors.border,
                        valueColor:
                            const AlwaysStoppedAnimation(AppColors.accent),
                        minHeight: 8,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${r.porcentaje.toStringAsFixed(1)}%',
                    style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppColors.accent),
                  ),
                ],
              ),
            );
          }).toList(),
        ],
      ),
    );
  }
}
