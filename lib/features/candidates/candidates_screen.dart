import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../core/l10n/app_l10n.dart';
import '../../core/services/providers.dart';
import '../../widgets/common/widgets.dart';

class CandidatosScreen extends ConsumerStatefulWidget {
  const CandidatosScreen({super.key});

  @override
  ConsumerState<CandidatosScreen> createState() => _CandidatosScreenState();
}

class _CandidatosScreenState extends ConsumerState<CandidatosScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _searchQuery = '';
  String? _filtroPartido;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = ref.watch(translationsProvider);
    return Scaffold(
      appBar: AppBar(
        title: Text(t.candidatosTitle),
        actions: [const LanguageSelectorButton()],
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(text: t.tabPresidente),
            Tab(text: t.tabSenadores),
            Tab(text: t.tabDiputados),
            Tab(text: t.tabAndino),
          ],
          indicatorColor: AppColors.primary,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textSecondary,
        ),
      ),
      body: Column(
        children: [
          // Search + Filter bar
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    onChanged: (v) => setState(() => _searchQuery = v),
                    decoration: InputDecoration(
                      hintText: t.buscarHint,
                      prefixIcon: const Icon(Icons.search, size: 20),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.close, size: 18),
                              onPressed: () {
                                _searchController.clear();
                                setState(() => _searchQuery = '');
                                FocusScope.of(context).unfocus();
                              },
                            )
                          : null,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: () => _showFiltrosSheet(context, t),
                  icon: Badge(
                    isLabelVisible: _filtroPartido != null,
                    child: const Icon(Icons.tune),
                  ),
                  style: IconButton.styleFrom(
                    backgroundColor: _filtroPartido != null
                        ? AppColors.accent.withOpacity(0.1)
                        : AppColors.surfaceVariant,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ],
            ),
          ),

          if (_filtroPartido != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
              child: Row(
                children: [
                  Chip(
                    label: Text(_filtroPartido!),
                    onDeleted: () => setState(() => _filtroPartido = null),
                    deleteIcon: const Icon(Icons.close, size: 14),
                    backgroundColor: AppColors.accentLight,
                    labelStyle: const TextStyle(
                      color: AppColors.accent,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),

          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _CandidatosList(
                  tipo: 'presidente',
                  searchQuery: _searchQuery,
                  filtroPartido: _filtroPartido,
                  sortAlpha: true,
                ),
                _CandidatosList(
                  tipo: 'senadores_Lima',
                  searchQuery: _searchQuery,
                  filtroPartido: _filtroPartido,
                  sortAlpha: true,
                  headerBanner: const _BicameralBanner(tipo: 'senadores'),
                ),
                _CandidatosList(
                  tipo: 'congreso_Lima',
                  searchQuery: _searchQuery,
                  filtroPartido: _filtroPartido,
                  sortAlpha: true,
                  headerBanner: const _BicameralBanner(tipo: 'diputados'),
                ),
                _CandidatosList(
                  tipo: 'andino',
                  searchQuery: _searchQuery,
                  filtroPartido: _filtroPartido,
                  sortAlpha: true,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showFiltrosSheet(BuildContext context, AppL10n t) {
    // Get dynamic party list from active tab's candidates
    const tipos = ['presidente', 'senadores_Lima', 'congreso_Lima', 'andino'];
    final activeTipo = tipos[_tabController.index];
    final state = ref.read(candidatosPaginadosProvider(activeTipo));
    final partidos = state.items
        .map((c) => c['partido'] as String? ?? '')
        .where((p) => p.isNotEmpty)
        .toSet()
        .toList()
      ..sort();

    String searchPartido = '';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => StatefulBuilder(
        builder: (ctx, setSheetState) {
          final filtered = searchPartido.isEmpty
              ? partidos
              : partidos
                  .where((p) =>
                      p.toLowerCase().contains(searchPartido.toLowerCase()))
                  .toList();

          return DraggableScrollableSheet(
            initialChildSize: 0.5,
            minChildSize: 0.3,
            maxChildSize: 0.7,
            expand: false,
            builder: (_, scrollCtrl) => Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Handle
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: AppColors.border,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(t.filtrarPartido,
                      style: Theme.of(context).textTheme.headlineSmall),
                  const SizedBox(height: 12),
                  // Search within parties
                  TextField(
                    onChanged: (v) => setSheetState(() => searchPartido = v),
                    decoration: InputDecoration(
                      hintText: 'Buscar partido...',
                      prefixIcon: const Icon(Icons.search, size: 18),
                      contentPadding: const EdgeInsets.symmetric(vertical: 8),
                      filled: true,
                      fillColor: AppColors.surfaceVariant,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: Consumer(
                      builder: (ctx, logoRef, _) {
                        final logosAsync =
                            logoRef.watch(partidosPoliticosProvider(1));
                        final logoMap = logosAsync.when(
                          data: (list) {
                            final m = <String, String>{};
                            for (final item in list) {
                              final raw =
                                  item['TXORGANIZACIONPOLITICA'] as String? ??
                                      '';
                              final n = raw
                                  .split(' ')
                                  .map((w) => w.isEmpty
                                      ? w
                                      : '${w[0].toUpperCase()}${w.substring(1).toLowerCase()}')
                                  .join(' ');
                              final u = item['TXURLORGANIZACIONPOLITICA']
                                      as String? ??
                                  '';
                              if (n.isNotEmpty && u.isNotEmpty) m[n] = u;
                            }
                            return m;
                          },
                          loading: () => <String, String>{},
                          error: (_, __) => <String, String>{},
                        );
                        return ListView.builder(
                          controller: scrollCtrl,
                          itemCount: filtered.length,
                          itemBuilder: (_, i) {
                            final p = filtered[i];
                            final isSelected = _filtroPartido == p;
                            final color = AppColors.partidoColors[p] ??
                                AppColors.partidoColors['default']!;
                            final logoUrl = logoMap[p];
                            return ListTile(
                              dense: true,
                              leading: SizedBox(
                                width: 32,
                                height: 32,
                                child: Stack(
                                  alignment: Alignment.center,
                                  children: [
                                    Container(
                                      width: 12,
                                      height: 12,
                                      decoration: BoxDecoration(
                                        color: color,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                    if (logoUrl != null)
                                      SvgPicture.network(
                                        logoUrl,
                                        width: 28,
                                        height: 28,
                                        fit: BoxFit.contain,
                                        placeholderBuilder: (_) =>
                                            const SizedBox(),
                                      ),
                                  ],
                                ),
                              ),
                              title: Text(p,
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: isSelected
                                        ? FontWeight.w700
                                        : FontWeight.w400,
                                    color: isSelected
                                        ? AppColors.accent
                                        : AppColors.textPrimary,
                                  )),
                              trailing: isSelected
                                  ? const Icon(Icons.check_circle,
                                      color: AppColors.accent, size: 20)
                                  : null,
                              onTap: () {
                                setState(() =>
                                    _filtroPartido = isSelected ? null : p);
                                Navigator.pop(context);
                              },
                            );
                          },
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: TextButton.icon(
                      onPressed: () {
                        setState(() => _filtroPartido = null);
                        Navigator.pop(context);
                      },
                      icon: const Icon(Icons.clear_all, size: 18),
                      label: Text(t.limpiarFiltros),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

// ── Real-time list with L1/L2 cache, pull-to-refresh, and infinite scroll ────

class _CandidatosList extends ConsumerStatefulWidget {
  final String tipo;
  final String searchQuery;
  final String? filtroPartido;
  final bool sortAlpha;
  final Widget? headerBanner;

  const _CandidatosList({
    required this.tipo,
    required this.searchQuery,
    this.filtroPartido,
    this.sortAlpha = false,
    this.headerBanner,
  });

  @override
  ConsumerState<_CandidatosList> createState() => _CandidatosListState();
}

class _CandidatosListState extends ConsumerState<_CandidatosList> {
  late final ScrollController _scrollCtrl;

  @override
  void initState() {
    super.initState();
    _scrollCtrl = ScrollController()..addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollCtrl.dispose();
    super.dispose();
  }

  void _onScroll() {
    final pos = _scrollCtrl.position;
    if (pos.pixels >= pos.maxScrollExtent - 250) {
      ref.read(candidatosPaginadosProvider(widget.tipo).notifier).loadMore();
    }
  }

  Future<void> _onRefresh() =>
      ref.read(candidatosPaginadosProvider(widget.tipo).notifier).refresh();

  @override
  Widget build(BuildContext context) {
    final t = ref.watch(translationsProvider);
    final state = ref.watch(candidatosPaginadosProvider(widget.tipo));

    // Initial full-screen skeleton
    if (state.isLoading && state.items.isEmpty) {
      return ListView(
        children: List.generate(5, (_) => const LoadingCard()),
      );
    }

    // Full-screen error with retry
    if (state.error != null && state.items.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.wifi_off,
                size: 48, color: AppColors.textSecondary),
            const SizedBox(height: 12),
            Text(t.errorGeneral,
                style: const TextStyle(color: AppColors.textSecondary)),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: _onRefresh,
              icon: const Icon(Icons.refresh),
              label: Text(t.reintentar),
            ),
          ],
        ),
      );
    }

    // Apply local search + filter on the already-loaded page
    var filtered = state.items.toList();
    if (widget.sortAlpha) {
      filtered.sort((a, b) {
        final na = (a['nombreCompleto'] as String? ?? '').toLowerCase();
        final nb = (b['nombreCompleto'] as String? ?? '').toLowerCase();
        return na.compareTo(nb);
      });
    }
    if (widget.searchQuery.isNotEmpty) {
      final q = widget.searchQuery.toLowerCase();
      filtered = filtered.where((c) {
        final nombre = (c['nombreCompleto'] as String? ?? '').toLowerCase();
        final partido = (c['partido'] as String? ?? '').toLowerCase();
        return nombre.contains(q) || partido.contains(q);
      }).toList();
    }
    if (widget.filtroPartido != null) {
      filtered =
          filtered.where((c) => c['partido'] == widget.filtroPartido).toList();
    }

    // Enrich candidates with partido logo URLs
    final logosAsync = ref.watch(partidosPoliticosProvider(1));
    final logoMap = logosAsync.when(
      data: (list) {
        final m = <String, String>{};
        for (final item in list) {
          final raw = item['TXORGANIZACIONPOLITICA'] as String? ?? '';
          final n = raw
              .split(' ')
              .map((w) => w.isEmpty
                  ? w
                  : '${w[0].toUpperCase()}${w.substring(1).toLowerCase()}')
              .join(' ');
          final u = item['TXURLORGANIZACIONPOLITICA'] as String? ?? '';
          if (n.isNotEmpty && u.isNotEmpty) m[n] = u;
        }
        return m;
      },
      loading: () => <String, String>{},
      error: (_, __) => <String, String>{},
    );
    if (logoMap.isNotEmpty) {
      filtered = filtered.map((c) {
        final partido = c['partido'] as String? ?? '';
        final logo = logoMap[partido];
        return logo != null ? {...c, 'logoPartidoUrl': logo} : c;
      }).toList();
    }

    return RefreshIndicator(
      onRefresh: _onRefresh,
      child: CustomScrollView(
        controller: _scrollCtrl,
        // Ensures RefreshIndicator works even when content is short
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          // Optional header banner (e.g. bicameral info)
          if (widget.headerBanner != null)
            SliverToBoxAdapter(child: widget.headerBanner!),

          // "Actualizado hace X" status bar
          if (state.fetchedAt != null)
            SliverToBoxAdapter(
              child: _FreshnessBar(
                fetchedAt: state.fetchedAt!,
                total: state.items.length,
                hasMore: state.hasMore,
              ),
            ),

          if (filtered.isEmpty)
            SliverFillRemaining(
              child: Center(
                child: Text(t.sinCandidatos,
                    style: const TextStyle(color: AppColors.textSecondary)),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.only(top: 4, bottom: 8),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (ctx, i) => CandidatoCard(
                    candidato: filtered[i],
                    onTap: () => ctx.go('/candidatos/${filtered[i]['id']}'),
                  ),
                  childCount: filtered.length,
                ),
              ),
            ),

          // Load-more indicator / end-of-list footer
          SliverToBoxAdapter(
            child: state.isLoadingMore
                ? const Padding(
                    padding: EdgeInsets.symmetric(vertical: 20),
                    child: Center(child: CircularProgressIndicator()),
                  )
                : state.hasMore
                    ? const SizedBox(height: 80)
                    : Padding(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        child: Center(
                          child: Text(
                            state.items.isEmpty
                                ? ''
                                : '${state.items.length} candidatos cargados',
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 11,
                            ),
                          ),
                        ),
                      ),
          ),
        ],
      ),
    );
  }
}

// ── Compact bicameral info banner ─────────────────────────────────────────────

/// Shown at the top of the Senadores / Diputados list to explain the
/// restored bicameral system for the 2026 elections in a concise way.
class _BicameralBanner extends StatelessWidget {
  final String tipo; // 'senadores' | 'diputados'
  const _BicameralBanner({required this.tipo});

  @override
  Widget build(BuildContext context) {
    final esSenado = tipo == 'senadores';
    final color = esSenado ? const Color(0xFF1A237E) : const Color(0xFF00695C);
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 10, 16, 4),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.07),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.22)),
      ),
      child: Row(
        children: [
          Text(esSenado ? '🏛️' : '📜', style: const TextStyle(fontSize: 22)),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  esSenado
                      ? 'Senado — nuevo 2026'
                      : 'Cámara de Diputados — 130 escaños',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                    color: color,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  esSenado
                      ? '60 departamentales (2 por región)  ·  30 lista nacional  ·  5 años'
                      : '130 diputados por circunscripción departamental  ·  5 años',
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.textSecondary,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

/// Thin banner showing cache freshness and total count.
class _FreshnessBar extends StatelessWidget {
  final DateTime fetchedAt;
  final int total;
  final bool hasMore;

  const _FreshnessBar({
    required this.fetchedAt,
    required this.total,
    required this.hasMore,
  });

  @override
  Widget build(BuildContext context) {
    final diff = DateTime.now().difference(fetchedAt);
    final time = diff.inMinutes < 1
        ? 'hace un momento'
        : diff.inMinutes < 60
            ? 'hace ${diff.inMinutes} min'
            : 'hace ${diff.inHours} h';
    return ColoredBox(
      color: AppColors.surfaceVariant,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
        child: Row(
          children: [
            const Icon(Icons.update, size: 13, color: AppColors.textSecondary),
            const SizedBox(width: 5),
            Text(
              'Actualizado $time  ·  $total${hasMore ? '+' : ''} candidatos',
              style:
                  const TextStyle(fontSize: 11, color: AppColors.textSecondary),
            ),
            const Spacer(),
            const Icon(Icons.arrow_downward,
                size: 11, color: AppColors.textSecondary),
            const SizedBox(width: 3),
            const Text('Desliza para actualizar',
                style: TextStyle(fontSize: 10, color: AppColors.textSecondary)),
          ],
        ),
      ),
    );
  }
}
