import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../core/services/favorites_service.dart';
import '../../core/services/providers.dart';

class FavoritosScreen extends ConsumerStatefulWidget {
  const FavoritosScreen({super.key});

  @override
  ConsumerState<FavoritosScreen> createState() => _FavoritosScreenState();
}

class _FavoritosScreenState extends ConsumerState<FavoritosScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;

  static const _tabs = [
    (FavoriteCategory.presidente, '🏛️ Presidente'),
    (FavoriteCategory.diputado, '🏛️ Diputados'),
    (FavoriteCategory.senador, '🏛️ Senadores'),
    (FavoriteCategory.andino, '🌍 P. Andino'),
  ];

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: _tabs.length, vsync: this);
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final favs = ref.watch(favoritesProvider);
    final totalCount = favs.values.fold<int>(0, (s, set) => s + set.length);

    return Scaffold(
      appBar: AppBar(
        title: const Text('⭐ Mis Favoritos'),
        bottom: TabBar(
          controller: _tabCtrl,
          isScrollable: true,
          tabAlignment: TabAlignment.start,
          labelStyle:
              const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
          tabs: _tabs.map((t) {
            final count = favs[t.$1]?.length ?? 0;
            return Tab(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(t.$2),
                  if (count > 0) ...[
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 1),
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text('$count',
                          style: const TextStyle(
                              fontSize: 10, color: Colors.white)),
                    ),
                  ],
                ],
              ),
            );
          }).toList(),
        ),
      ),
      body: totalCount == 0
          ? _EmptyState()
          : TabBarView(
              controller: _tabCtrl,
              children:
                  _tabs.map((t) => _FavoritesList(category: t.$1)).toList(),
            ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.favorite_border,
                  size: 40, color: AppColors.primary),
            ),
            const SizedBox(height: 20),
            const Text(
              'Aún no tienes favoritos',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Text(
              'Toca el ❤️ en cualquier candidato para\nguardarlo aquí y seguirlo de cerca',
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 13, color: AppColors.textSecondary, height: 1.5),
            ),
          ],
        ),
      ),
    );
  }
}

class _FavoritesList extends ConsumerWidget {
  final FavoriteCategory category;
  const _FavoritesList({required this.category});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final favs = ref.watch(favoritesProvider);
    final ids = favs[category] ?? {};

    if (ids.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.person_search,
                  size: 48, color: AppColors.textSecondary.withOpacity(0.4)),
              const SizedBox(height: 12),
              Text(
                'Sin favoritos en esta categoría',
                style: TextStyle(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w500),
              ),
            ],
          ),
        ),
      );
    }

    // Resolve candidate data from the appropriate provider
    final candidatesAsync = _getCandidatesAsync(ref, category);

    return candidatesAsync.when(
      data: (allCandidates) {
        final matched = allCandidates
            .where((c) => ids.contains(c['id'] as String?))
            .toList();

        if (matched.isEmpty) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(32),
              child: Text('Cargando candidatos...',
                  style: TextStyle(color: AppColors.textSecondary)),
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.symmetric(vertical: 8),
          itemCount: matched.length,
          itemBuilder: (_, i) {
            final c = matched[i];
            return _FavoriteCandidateCard(
              candidato: c,
              category: category,
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, __) => const Center(
        child: Text('Error al cargar candidatos',
            style: TextStyle(color: AppColors.textSecondary)),
      ),
    );
  }

  AsyncValue<List<Map<String, dynamic>>> _getCandidatesAsync(
      WidgetRef ref, FavoriteCategory cat) {
    switch (cat) {
      case FavoriteCategory.presidente:
        return ref.watch(candidatosPresidenteProvider);
      case FavoriteCategory.diputado:
        return ref.watch(candidatosCongresoProvider(''));
      case FavoriteCategory.senador:
        return ref.watch(candidatosSenadoresProvider(''));
      case FavoriteCategory.andino:
        return ref.watch(candidatosAndinoProvider);
    }
  }
}

class _FavoriteCandidateCard extends ConsumerWidget {
  final Map<String, dynamic> candidato;
  final FavoriteCategory category;

  const _FavoriteCandidateCard({
    required this.candidato,
    required this.category,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final nombre = candidato['nombreCompleto'] as String? ?? '';
    final partido = candidato['partido'] as String? ?? '';
    final fotoUrl = candidato['fotoUrl'] as String?;
    final simbolo = candidato['simboloPartidoUrl'] as String?;
    final id = candidato['id'] as String? ?? '';
    final partidoColor =
        AppColors.partidoColors[partido] ?? AppColors.partidoColors['default']!;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      elevation: 0.5,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => context.go('/candidatos/$id'),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // Avatar
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.surfaceVariant,
                  border: Border.all(color: partidoColor, width: 2),
                ),
                child: fotoUrl != null
                    ? ClipOval(
                        child: CachedNetworkImage(
                          imageUrl: fotoUrl,
                          width: 48,
                          height: 48,
                          fit: BoxFit.cover,
                          placeholder: (_, __) => const Icon(Icons.person,
                              size: 22, color: AppColors.textSecondary),
                          errorWidget: (_, __, ___) => const Icon(Icons.person,
                              size: 22, color: AppColors.textSecondary),
                        ),
                      )
                    : const Icon(Icons.person,
                        size: 22, color: AppColors.textSecondary),
              ),
              const SizedBox(width: 12),
              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(nombre,
                        style: const TextStyle(
                            fontSize: 14, fontWeight: FontWeight.w700),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        if (simbolo != null && simbolo.isNotEmpty)
                          ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: CachedNetworkImage(
                              imageUrl: simbolo,
                              width: 18,
                              height: 18,
                              fit: BoxFit.contain,
                              placeholder: (_, __) => Container(
                                  width: 8,
                                  height: 8,
                                  decoration: BoxDecoration(
                                      color: partidoColor,
                                      shape: BoxShape.circle)),
                              errorWidget: (_, __, ___) => Container(
                                  width: 8,
                                  height: 8,
                                  decoration: BoxDecoration(
                                      color: partidoColor,
                                      shape: BoxShape.circle)),
                            ),
                          )
                        else
                          Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                  color: partidoColor, shape: BoxShape.circle)),
                        const SizedBox(width: 5),
                        Expanded(
                          child: Text(partido,
                              style: TextStyle(
                                  fontSize: 11,
                                  color: partidoColor,
                                  fontWeight: FontWeight.w500),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              // Remove button
              IconButton(
                icon: const Icon(Icons.favorite, color: Colors.red, size: 22),
                onPressed: () {
                  ref.read(favoritesProvider.notifier).toggle(category, id);
                },
                tooltip: 'Quitar de favoritos',
              ),
            ],
          ),
        ),
      ),
    );
  }
}
