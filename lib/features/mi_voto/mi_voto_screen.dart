import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../core/l10n/app_l10n.dart';
import '../../core/models/electoral_models.dart';
import '../../core/services/providers.dart';
import '../../widgets/common/widgets.dart';

class MiVotoScreen extends ConsumerWidget {
  const MiVotoScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = ref.watch(translationsProvider);
    final state = ref.watch(miVotoProvider);
    final notifier = ref.read(miVotoProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: Text(t.miVotoTitle),
        actions: [
          const FontSizeAdjuster(),
          const LanguageSelectorButton(),
          IconButton(
            icon: const Icon(Icons.how_to_vote_outlined),
            tooltip: t.comoVotarTooltip,
            onPressed: () => context.go('/mi-voto/como-votar'),
          ),
          if (state.resultados != null)
            TextButton(
              onPressed: notifier.reiniciar,
              child: Text(t.reiniciar),
            ),
        ],
      ),
      body: state.resultados != null
          ? _ResultadosView(resultados: state.resultados!)
          : _SelectorView(state: state, notifier: notifier),
    );
  }
}

class _SelectorView extends ConsumerWidget {
  final MiVotoState state;
  final MiVotoNotifier notifier;

  const _SelectorView({required this.state, required this.notifier});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = ref.watch(translationsProvider);
    final prioridades = PriudadCiudadana.values;
    final seleccionadas = state.prioridades;
    final faltantes = 5 - seleccionadas.length;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [AppColors.primary, AppColors.primaryDark],
            ),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            children: [
              Text(
                '🗳️ ${t.selecciona5}',
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 6),
              Text(
                t.miVotoSubtitle,
                style: const TextStyle(color: Colors.white70, fontSize: 13),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              LinearProgressIndicator(
                value: seleccionadas.length / 5,
                backgroundColor: Colors.white24,
                valueColor: const AlwaysStoppedAnimation(Colors.white),
                minHeight: 6,
              ),
              const SizedBox(height: 6),
              Text(
                seleccionadas.isEmpty
                    ? t.selecciona5
                    : faltantes > 0
                        ? '$faltantes más para continuar'
                        : '¡Listo! Calcula tu match',
                style: const TextStyle(
                    color: Colors.white, fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        const Text(
          '¿Qué le importa más al Perú que quieres?',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: prioridades.map((p) {
            final isSelected = seleccionadas.contains(p);
            final isDisabled = !isSelected && seleccionadas.length >= 5;

            return AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              child: FilterChip(
                label: Text('${p.icon} ${p.label}'),
                selected: isSelected,
                onSelected:
                    isDisabled ? null : (_) => notifier.togglePrioridad(p),
                selectedColor: AppColors.primary,
                checkmarkColor: Colors.white,
                labelStyle: TextStyle(
                  color: isSelected
                      ? Colors.white
                      : isDisabled
                          ? AppColors.textHint
                          : AppColors.textPrimary,
                  fontSize: 13,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                ),
                backgroundColor: isDisabled
                    ? AppColors.surfaceVariant.withOpacity(0.5)
                    : AppColors.surfaceVariant,
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 24),
        if (state.error != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Text(state.error!,
                style: const TextStyle(color: AppColors.inviable)),
          ),
        ElevatedButton.icon(
          onPressed: seleccionadas.length >= 3 && !state.isLoading
              ? notifier.calcularMatch
              : null,
          icon: state.isLoading
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Icon(Icons.calculate),
          label: Text(
            state.isLoading ? '...' : t.calcularIdeal,
          ),
        ),
        const SizedBox(height: 16),
        const NeutralidadBanner(),
        const SizedBox(height: 8),
        Center(
          child: Text(
            t.disclaimerPrivacidad,
            style:
                const TextStyle(fontSize: 11, color: AppColors.textSecondary),
            textAlign: TextAlign.center,
          ),
        ),
      ],
    );
  }
}

class _ResultadosView extends ConsumerWidget {
  final List<ResultadoMiVoto> resultados;

  const _ResultadosView({required this.resultados});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = ref.watch(translationsProvider);
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.viableLight,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.viable.withOpacity(0.3)),
          ),
          child: Column(
            children: [
              const Text('🎯 Tus candidatos ideales',
                  style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: AppColors.viable)),
              const SizedBox(height: 4),
              Text(
                t.resultadosSubtitulo,
                style: const TextStyle(
                    fontSize: 12, color: AppColors.textSecondary),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        ...resultados.asMap().entries.map((e) {
          final rank = e.key + 1;
          final r = e.value;
          return GestureDetector(
            onTap: () => context.go('/candidatos/${r.candidatoId}'),
            child: _ResultadoCard(rank: rank, resultado: r),
          );
        }),
        const SizedBox(height: 16),
        const NeutralidadBanner(),
        const SizedBox(height: 8),
        Center(
          child: Text(
            t.simuladorDisclaimer,
            style:
                const TextStyle(fontSize: 11, color: AppColors.textSecondary),
            textAlign: TextAlign.center,
          ),
        ),
        const SizedBox(height: 32),
      ],
    );
  }
}

class _ResultadoCard extends ConsumerWidget {
  final int rank;
  final ResultadoMiVoto resultado;

  const _ResultadoCard({required this.rank, required this.resultado});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = ref.watch(translationsProvider);
    final matchPct = resultado.porcentajeMatch;
    final color = matchPct >= 70
        ? AppColors.viable
        : matchPct >= 40
            ? AppColors.doubtful
            : AppColors.inviable;

    final partidoColor = AppColors.partidoColors[resultado.partido] ??
        AppColors.partidoColors['default']!;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // Rank badge
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: rank == 1
                        ? const Color(0xFFFFD700)
                        : rank == 2
                            ? const Color(0xFFC0C0C0)
                            : rank == 3
                                ? const Color(0xFFCD7F32)
                                : AppColors.surfaceVariant,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      '#$rank',
                      style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                          color: rank <= 3
                              ? Colors.white
                              : AppColors.textSecondary),
                    ),
                  ),
                ),
                const SizedBox(width: 12),

                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(resultado.nombreCandidato,
                          style: Theme.of(context).textTheme.titleMedium),
                      Row(
                        children: [
                          Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                  color: partidoColor, shape: BoxShape.circle)),
                          const SizedBox(width: 6),
                          Flexible(
                            child: Text(resultado.partido,
                                style: TextStyle(
                                    fontSize: 12, color: partidoColor),
                                overflow: TextOverflow.ellipsis),
                          ),
                          if (resultado.edad > 0) ...[
                            const SizedBox(width: 8),
                            Text('${resultado.edad} años',
                                style: const TextStyle(
                                    fontSize: 11,
                                    color: AppColors.textSecondary)),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),

                // Match %
                Column(
                  children: [
                    Text(
                      '${matchPct.toStringAsFixed(0)}%',
                      style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w700,
                          color: color),
                    ),
                    Text(t.miVotoMatch,
                        style: const TextStyle(
                            fontSize: 10, color: AppColors.textSecondary)),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 10),

            // Progress bar
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: matchPct / 100,
                backgroundColor: AppColors.border,
                valueColor: AlwaysStoppedAnimation(color),
                minHeight: 6,
              ),
            ),

            const SizedBox(height: 10),

            Text(resultado.explicacion,
                style: const TextStyle(
                    fontSize: 13, color: AppColors.textSecondary, height: 1.4)),

            // Tap to navigate indicator
            const SizedBox(height: 8),
            const Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text('Ver perfil completo',
                    style: TextStyle(
                        fontSize: 11,
                        color: AppColors.primary,
                        fontWeight: FontWeight.w600)),
                SizedBox(width: 4),
                Icon(Icons.chevron_right, size: 16, color: AppColors.primary),
              ],
            ),

            // Alertas de contradicción
            if (resultado.alertasContradiccion.isNotEmpty) ...[
              const SizedBox(height: 10),
              ...resultado.alertasContradiccion.map((a) => Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    margin: const EdgeInsets.only(bottom: 6),
                    decoration: BoxDecoration(
                      color: AppColors.doubtfulLight,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                          color: AppColors.doubtful.withOpacity(0.4)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.warning_amber_rounded,
                            size: 14, color: AppColors.doubtful),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            a,
                            style: const TextStyle(
                                fontSize: 11, color: AppColors.doubtful),
                          ),
                        ),
                      ],
                    ),
                  )),
            ],
          ],
        ),
      ),
    );
  }
}
