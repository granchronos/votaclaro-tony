import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:intl/intl.dart';
import '../../core/constants/app_colors.dart';
import '../../core/l10n/app_l10n.dart';
import '../../core/models/electoral_models.dart';
import '../../core/services/providers.dart';
import '../../core/services/rss_news_service.dart';
import '../../widgets/common/widgets.dart';

class NoticiasScreen extends ConsumerStatefulWidget {
  const NoticiasScreen({super.key});

  @override
  ConsumerState<NoticiasScreen> createState() => _NoticiasScreenState();
}

class _NoticiasScreenState extends ConsumerState<NoticiasScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  static const _categorias = [
    null, // Todas
    CategoriaFuente.investigacion,
    CategoriaFuente.factcheck,
    CategoriaFuente.minutaminuto,
    CategoriaFuente.analisis,
    CategoriaFuente.perfiles,
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _categorias.length, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = ref.watch(translationsProvider);
    return Scaffold(
      appBar: AppBar(
        title: Text(t.noticiasTitle),
        actions: [
          const FontSizeAdjuster(),
          const LanguageSelectorButton(),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              ref.invalidate(noticiasProvider);
              ref.invalidate(noticiasPorCategoriaProvider);
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          indicatorColor: AppColors.primary,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textSecondary,
          tabs: [
            Tab(text: t.todasCategorias),
            ...CategoriaFuente.values.map((c) => Tab(text: c.label)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: _categorias
            .map((categoria) => _NoticiasTab(categoria: categoria))
            .toList(),
      ),
    );
  }
}

// ─── Tab de una categoría ─────────────────────────────────────────────────────

class _NoticiasTab extends ConsumerWidget {
  final CategoriaFuente? categoria;

  const _NoticiasTab({this.categoria});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final noticiasAsync = categoria == null
        ? ref.watch(noticiasProvider)
        : ref.watch(noticiasPorCategoriaProvider(categoria));

    return RefreshIndicator(
      onRefresh: () async {
        if (categoria == null) {
          ref.invalidate(noticiasProvider);
        } else {
          ref.invalidate(noticiasPorCategoriaProvider(categoria));
        }
      },
      child: noticiasAsync.when(
        data: (list) => list.isEmpty
            ? _EmptyState()
            : ListView(
                padding: const EdgeInsets.only(bottom: 32),
                children: [
                  _FuentesBanner(categoria: categoria),
                  ...list.map((n) => _NoticiaCard(noticia: n)),
                ],
              ),
        loading: () => const Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation(AppColors.primary)),
              SizedBox(height: 16),
              Text('Cargando noticias verificadas…',
                  style: TextStyle(color: AppColors.textSecondary)),
            ],
          ),
        ),
        error: (e, _) => const _EmptyState(error: true),
      ),
    );
  }
}

class _EmptyState extends ConsumerWidget {
  final bool error;
  const _EmptyState({this.error = false});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = ref.watch(translationsProvider);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(error ? '⚠️' : '📭', style: const TextStyle(fontSize: 48)),
            const SizedBox(height: 16),
            Text(
              error ? t.errorCargandoNoticias : t.sinDatos,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}

class _FuentesBanner extends StatelessWidget {
  final CategoriaFuente? categoria;
  const _FuentesBanner({this.categoria});

  @override
  Widget build(BuildContext context) {
    final fuentes = categoria == null
        ? RssNewsService.fuentes
        : RssNewsService.fuentes
            .where((f) => f.categoria == categoria)
            .toList();

    final nombres = fuentes.map((f) => f.emoji).join(' ');

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.viableLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.viable.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.fact_check, size: 16, color: AppColors.viable),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '$nombres  ${fuentes.map((f) => f.nombre).join(' · ')}',
              style: const TextStyle(
                  fontSize: 11,
                  color: AppColors.viable,
                  fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}

class _NoticiaCard extends StatelessWidget {
  final Noticia noticia;

  const _NoticiaCard({required this.noticia});

  @override
  Widget build(BuildContext context) {
    final dateStr = DateFormat('dd/MM/yyyy').format(noticia.fechaPublicacion);
    final medioColor = _medioColor(noticia.medioComunicacion);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: InkWell(
        onTap: () async {
          final uri = Uri.parse(noticia.urlFuente);
          if (await canLaunchUrl(uri)) {
            await launchUrl(uri, mode: LaunchMode.externalApplication);
          }
        },
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header: medio + fecha
              Row(
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: medioColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: medioColor.withOpacity(0.3)),
                    ),
                    child: Row(
                      children: [
                        if (noticia.esFactChecked) ...[
                          const Icon(Icons.fact_check,
                              size: 11, color: AppColors.viable),
                          const SizedBox(width: 4),
                        ],
                        Text(
                          noticia.medioComunicacion,
                          style: TextStyle(
                              color: medioColor,
                              fontSize: 11,
                              fontWeight: FontWeight.w700),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  Text(
                    dateStr,
                    style: const TextStyle(
                        fontSize: 11, color: AppColors.textSecondary),
                  ),
                ],
              ),

              const SizedBox(height: 10),

              // Imagen (si hay)
              if (noticia.imagenUrl != null) ...[
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Image.network(
                    noticia.imagenUrl!,
                    height: 160,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => const SizedBox(),
                  ),
                ),
                const SizedBox(height: 10),
              ],

              // Título
              Text(
                noticia.titulo,
                style: const TextStyle(
                    fontWeight: FontWeight.w700, fontSize: 15, height: 1.3),
              ),

              const SizedBox(height: 6),

              // Resumen
              Text(
                noticia.resumen,
                style: const TextStyle(
                    fontSize: 13, color: AppColors.textSecondary, height: 1.4),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),

              // Tags candidatos
              if (noticia.tagsCandiatos.isNotEmpty) ...[
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  children: noticia.tagsCandiatos
                      .map((tag) => Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.accentLight,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              '#$tag',
                              style: const TextStyle(
                                  fontSize: 11, color: AppColors.accent),
                            ),
                          ))
                      .toList(),
                ),
              ],

              const SizedBox(height: 8),

              Row(
                children: [
                  const Icon(Icons.open_in_new,
                      size: 12, color: AppColors.accent),
                  const SizedBox(width: 4),
                  Text(
                    'Leer en ${noticia.medioComunicacion}',
                    style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.accent,
                        fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _medioColor(String medio) => switch (medio) {
        'OjoPúblico' => const Color(0xFF1A6B5A),
        'IDL-Reporteros' => const Color(0xFF7B2D8B),
        'Convoca.pe' => const Color(0xFF1A4FBF),
        'Epicentro TV' => const Color(0xFF6A1B9A),
        'Sudaca.pe' => const Color(0xFF0277BD),
        'RPP Noticias' => const Color(0xFFD32F2F),
        'Canal N' => const Color(0xFF1565C0),
        'El Comercio' => const Color(0xFF1B5E20),
        _ => AppColors.accent,
      };
}
