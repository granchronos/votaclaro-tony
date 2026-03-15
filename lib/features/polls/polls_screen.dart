import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/constants/app_colors.dart';
import '../../core/l10n/app_l10n.dart';
import '../../core/models/electoral_models.dart';
import '../../core/services/providers.dart';
import '../../widgets/common/widgets.dart';

class EncuestasScreen extends ConsumerWidget {
  const EncuestasScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = ref.watch(translationsProvider);
    final encuestasAsync = ref.watch(encuestasProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(t.encuestasTitle),
        actions: [
          const LanguageSelectorButton(),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.invalidate(encuestasProvider),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async => ref.invalidate(encuestasProvider),
        child: encuestasAsync.when(
          data: (list) {
            if (list.isEmpty) return Center(child: Text(t.sinDatos));
            final daysOldSinceLatest = DateTime.now()
                .difference(list.first.fechaPublicacion)
                .inDays;
            return ListView(
              padding: const EdgeInsets.only(bottom: 32),
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      const Icon(Icons.verified,
                          size: 16, color: AppColors.viable),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          t.encuestasFuentes,
                          style: const TextStyle(
                              fontSize: 12, color: AppColors.textSecondary),
                        ),
                      ),
                    ],
                  ),
                ),
                if (daysOldSinceLatest > 7)
                  _StalenessWarning(daysOld: daysOldSinceLatest),
                ...list.map((e) => _EncuestaCard(encuesta: e)),
              ],
            );
          },
          loading: () => const Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation(AppColors.primary),
            ),
          ),
          error: (e, _) => Center(child: Text(t.errorGeneral)),
        ),
      ),
    );
  }
}

class _EncuestaCard extends StatelessWidget {
  final Encuesta encuesta;

  const _EncuestaCard({required this.encuesta});

  @override
  Widget build(BuildContext context) {
    // Sort results by descending percentage
    final resultados = List<ResultadoEncuesta>.from(encuesta.resultados)
      ..sort((a, b) => b.porcentaje.compareTo(a.porcentaje));
    final daysOld =
        DateTime.now().difference(encuesta.fechaPublicacion).inDays;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.accentLight,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    encuesta.empresa,
                    style: const TextStyle(
                        color: AppColors.accent,
                        fontWeight: FontWeight.w700,
                        fontSize: 12),
                  ),
                ),
                const SizedBox(width: 8),
                if (encuesta.esCertificada)
                  const Icon(Icons.verified, size: 16, color: AppColors.viable),
                const Spacer(),
                _DaysAgoBadge(daysOld: daysOld),
              ],
            ),

            const SizedBox(height: 6),

            Text(
              '${encuesta.metodologia} — n=${encuesta.muestreo}  ±${encuesta.margenError}%',
              style:
                  const TextStyle(fontSize: 11, color: AppColors.textSecondary),
            ),

            const Divider(height: 20),

            // Barras horizontales
            ...resultados.map((r) {
              final maxPct = resultados.first.porcentaje;
              final relativeWidth = maxPct > 0 ? r.porcentaje / maxPct : 0.0;
              final partidoColor = AppColors.partidoColors[r.partido] ??
                  AppColors.partidoColors['default']!;

              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
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
                        Text(
                          '${r.porcentaje.toStringAsFixed(1)}%',
                          style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: partidoColor),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    LayoutBuilder(
                      builder: (context, constraints) {
                        return Stack(
                          children: [
                            Container(
                              height: 10,
                              width: constraints.maxWidth,
                              decoration: BoxDecoration(
                                color: AppColors.border,
                                borderRadius: BorderRadius.circular(5),
                              ),
                            ),
                            AnimatedContainer(
                              duration: const Duration(milliseconds: 800),
                              height: 10,
                              width: constraints.maxWidth * relativeWidth,
                              decoration: BoxDecoration(
                                color: partidoColor,
                                borderRadius: BorderRadius.circular(5),
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ],
                ),
              );
            }).toList(),

            const Divider(height: 16),

            // Margen de error
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Margen de error: ±${encuesta.margenError}%',
                  style: const TextStyle(
                      fontSize: 11, color: AppColors.textSecondary),
                ),
                GestureDetector(
                  onTap: () async {
                    final uri = Uri.parse(encuesta.urlFuente);
                    if (await canLaunchUrl(uri)) {
                      await launchUrl(uri);
                    }
                  },
                  child: const Row(
                    children: [
                      Icon(Icons.open_in_new,
                          size: 12, color: AppColors.accent),
                      SizedBox(width: 4),
                      Text('Ver fuente',
                          style:
                              TextStyle(fontSize: 11, color: AppColors.accent)),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Indicador de días desde la encuesta ─────────────────────────────────────

class _DaysAgoBadge extends StatelessWidget {
  final int daysOld;
  const _DaysAgoBadge({required this.daysOld});

  @override
  Widget build(BuildContext context) {
    final Color color;
    final String label;

    if (daysOld <= 7) {
      color = AppColors.viable;
      label = 'Reciente';
    } else if (daysOld <= 21) {
      color = AppColors.doubtful;
      label = 'Hace $daysOld días';
    } else {
      color = AppColors.inviable;
      label = 'Hace $daysOld días';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Text(
        label,
        style: TextStyle(
            fontSize: 10, color: color, fontWeight: FontWeight.w600),
      ),
    );
  }
}

// ─── Banner de datos desactualizados ─────────────────────────────────────────

class _StalenessWarning extends StatelessWidget {
  final int daysOld;
  const _StalenessWarning({required this.daysOld});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.doubtful.withOpacity(0.10),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.doubtful.withOpacity(0.4)),
      ),
      child: Row(
        children: [
          const Icon(Icons.schedule, size: 16, color: AppColors.doubtful),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'La encuesta más reciente tiene $daysOld días. Toca ↺ para buscar datos nuevos.',
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.doubtful,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
