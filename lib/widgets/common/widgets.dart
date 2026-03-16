import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings_qu.dart';
import '../../core/models/candidato.dart';
import '../../core/services/favorites_service.dart';

/// Badge de semáforo de viabilidad 🟢🟡🔴
class ViabilidadBadge extends StatelessWidget {
  final ViabilidadPropuesta viabilidad;
  final bool compact;

  const ViabilidadBadge({
    super.key,
    required this.viabilidad,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final (color, bg, label, emoji) = switch (viabilidad) {
      ViabilidadPropuesta.alta => (
          AppColors.viable,
          AppColors.viableLight,
          'Alta',
          '🟢'
        ),
      ViabilidadPropuesta.media => (
          AppColors.doubtful,
          AppColors.doubtfulLight,
          'Media',
          '🟡'
        ),
      ViabilidadPropuesta.baja => (
          AppColors.inviable,
          AppColors.inviableLight,
          'Baja',
          '🔴'
        ),
    };

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 6 : 10,
        vertical: compact ? 2 : 4,
      ),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(emoji, style: TextStyle(fontSize: compact ? 10 : 12)),
          const SizedBox(width: 4),
          Text(
            compact ? '' : 'Viabilidad $label',
            style: TextStyle(
              color: color,
              fontSize: compact ? 10 : 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

/// Badge de propuesta reciclada 🔄 — muestra fuente al tocarlo
class PropuestaRecicladaBadge extends StatelessWidget {
  final String? referencia;
  final String? fuente;

  const PropuestaRecicladaBadge({super.key, this.referencia, this.fuente});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        showDialog(
          context: context,
          builder: (_) => AlertDialog(
            title: const Row(
              children: [
                Text('🔄', style: TextStyle(fontSize: 20)),
                SizedBox(width: 8),
                Text('Propuesta Reciclada', style: TextStyle(fontSize: 16)),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Esta propuesta ya fue presentada en una elección anterior.',
                  style: TextStyle(fontSize: 13, height: 1.5),
                ),
                if (referencia != null && referencia!.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  const Text('Referencia:',
                      style:
                          TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                  const SizedBox(height: 4),
                  Text(referencia!, style: const TextStyle(fontSize: 13)),
                ],
                if (fuente != null && fuente!.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  const Text('Fuente:',
                      style:
                          TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                  const SizedBox(height: 4),
                  Text(fuente!,
                      style: const TextStyle(
                          fontSize: 13, color: AppColors.accent)),
                ],
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cerrar'),
              ),
            ],
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: AppColors.recycledLight,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.recycled.withOpacity(0.4)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('🔄', style: TextStyle(fontSize: 11)),
            const SizedBox(width: 4),
            Text(
              'Reciclada',
              style: TextStyle(
                color: AppColors.recycled,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Tag de fuente con fecha
class SourceTag extends StatelessWidget {
  final String fuente;
  final DateTime? fecha;
  final IconData icon;

  const SourceTag({
    super.key,
    required this.fuente,
    this.fecha,
    this.icon = Icons.verified_outlined,
  });

  @override
  Widget build(BuildContext context) {
    final fechaStr = fecha != null
        ? '${fecha!.day.toString().padLeft(2, '0')}/${fecha!.month.toString().padLeft(2, '0')}/${fecha!.year}'
        : null;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 12, color: AppColors.textSecondary),
        const SizedBox(width: 4),
        Text(
          fechaStr != null ? '$fuente · $fechaStr' : fuente,
          style: const TextStyle(
            fontSize: 11,
            color: AppColors.textSecondary,
            fontStyle: FontStyle.italic,
          ),
        ),
      ],
    );
  }
}

/// Resuelve la categoría de favoritos según el tipo de elección del candidato.
FavoriteCategory favCategoryFromCandidato(Map<String, dynamic> c) {
  final tipo = c['tipoEleccion'] as int? ?? c['idTipoEleccion'] as int? ?? 1;
  return switch (tipo) {
    3 => FavoriteCategory.andino,
    14 || 20 || 21 => FavoriteCategory.senador,
    15 => FavoriteCategory.diputado,
    _ => FavoriteCategory.presidente,
  };
}

/// Card de candidato para listas
class CandidatoCard extends ConsumerWidget {
  final Map<String, dynamic> candidato;
  final VoidCallback onTap;
  final bool showEncuesta;

  const CandidatoCard({
    super.key,
    required this.candidato,
    required this.onTap,
    this.showEncuesta = true,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final nombre = candidato['nombreCompleto'] as String? ?? 'Sin nombre';
    final partido = candidato['partido'] as String? ?? '';
    final pct = (candidato['porcentajeEncuesta'] as num?)?.toDouble() ?? 0.0;
    final fotoUrl = candidato['fotoUrl'] as String?;
    final region = candidato['region'] as String? ?? '';
    final id = candidato['id'] as String? ?? '';
    final favCategory = favCategoryFromCandidato(candidato);
    final isFav = ref.watch(favoritesProvider
        .select((favs) => favs[favCategory]?.contains(id) ?? false));

    final partidoColor =
        AppColors.partidoColors[partido] ?? AppColors.partidoColors['default']!;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
      elevation: 0.5,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              // Avatar — fixed 48x48
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.surfaceVariant,
                  border: Border.all(
                    color: partidoColor.withOpacity(0.5),
                    width: 2,
                  ),
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

              // Info — takes remaining space
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      nombre,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        if ((candidato['simboloPartidoUrl'] as String?)
                                ?.isNotEmpty ==
                            true)
                          ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: CachedNetworkImage(
                              imageUrl:
                                  candidato['simboloPartidoUrl'] as String,
                              width: 20,
                              height: 20,
                              fit: BoxFit.contain,
                              placeholder: (_, __) => Container(
                                width: 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  color: partidoColor,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              errorWidget: (_, __, ___) => Container(
                                width: 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  color: partidoColor,
                                  shape: BoxShape.circle,
                                ),
                              ),
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
                              fontWeight: FontWeight.w500,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    if (region.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        '📍 $region',
                        style: const TextStyle(
                          fontSize: 10,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              // Encuesta % — compact
              if (showEncuesta && pct > 0) ...[
                const SizedBox(width: 8),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '${pct.toStringAsFixed(1)}%',
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary,
                      ),
                    ),
                    const Text(
                      'encuesta',
                      style: TextStyle(
                        fontSize: 9,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ],

              // Favorite toggle
              GestureDetector(
                onTap: () => ref
                    .read(favoritesProvider.notifier)
                    .toggle(favCategory, id),
                child: Padding(
                  padding: const EdgeInsets.all(4),
                  child: Icon(
                    isFav ? Icons.favorite : Icons.favorite_border,
                    size: 20,
                    color: isFav ? Colors.red : AppColors.textHint,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Riesgo de corrupción badge
class RiesgoCorrupcionBadge extends StatelessWidget {
  final NivelRiesgoCorrupcion nivel;

  const RiesgoCorrupcionBadge({super.key, required this.nivel});

  @override
  Widget build(BuildContext context) {
    final (color, bg, label) = switch (nivel) {
      NivelRiesgoCorrupcion.bajo => (
          AppColors.viable,
          AppColors.viableLight,
          'Riesgo Bajo'
        ),
      NivelRiesgoCorrupcion.medio => (
          AppColors.doubtful,
          AppColors.doubtfulLight,
          'Riesgo Medio'
        ),
      NivelRiesgoCorrupcion.alto => (
          AppColors.inviable,
          AppColors.inviableLight,
          'Riesgo Alto'
        ),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.shield_outlined, size: 13, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

/// Loading shimmer placeholder
class LoadingCard extends StatelessWidget {
  const LoadingCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: AppColors.surfaceVariant,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                      height: 13, width: 160, color: AppColors.surfaceVariant),
                  const SizedBox(height: 6),
                  Container(
                      height: 10, width: 100, color: AppColors.surfaceVariant),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Separador de sección con título
class SectionHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget? trailing;

  const SectionHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: Theme.of(context).textTheme.headlineSmall),
                if (subtitle != null)
                  Text(subtitle!, style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
          ),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}

/// Banner de neutralidad
class NeutralidadBanner extends StatelessWidget {
  const NeutralidadBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.accentLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.accent.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.balance_outlined, size: 16, color: AppColors.accent),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'VotaClaro es 100% neutral. Ningún partido financia esta app.',
              style: TextStyle(
                fontSize: 12,
                color: AppColors.accent,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Leyenda visual para semáforos de viabilidad y badges de propuestas
class LeyendaSemaforo extends StatelessWidget {
  const LeyendaSemaforo({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.info_outline,
                  size: 14, color: AppColors.textSecondary),
              SizedBox(width: 6),
              Text('Leyenda',
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary)),
            ],
          ),
          const SizedBox(height: 10),
          _LeyendaRow(
              emoji: '🟢',
              label: 'Viabilidad Alta',
              desc: 'Propuesta realista y factible'),
          _LeyendaRow(
              emoji: '🟡',
              label: 'Viabilidad Media',
              desc: 'Requiere condiciones específicas'),
          _LeyendaRow(
              emoji: '🔴',
              label: 'Viabilidad Baja',
              desc: 'Difícil de implementar'),
          const Divider(height: 16),
          _LeyendaRow(
              emoji: '🔄',
              label: 'Reciclada',
              desc: 'Propuesta repetida de otra elección'),
          _LeyendaRow(
              emoji: '🛡️',
              label: 'Riesgo Corrupción',
              desc: 'Nivel bajo / medio / alto'),
        ],
      ),
    );
  }
}

class _LeyendaRow extends StatelessWidget {
  final String emoji;
  final String label;
  final String desc;
  const _LeyendaRow(
      {required this.emoji, required this.label, required this.desc});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 14)),
          const SizedBox(width: 8),
          Text(label,
              style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary)),
          const SizedBox(width: 6),
          Expanded(
            child: Text(desc,
                style: const TextStyle(
                    fontSize: 11, color: AppColors.textSecondary)),
          ),
        ],
      ),
    );
  }
}
// ─── Language selector button (3 languages: ES / QU / EN) ────────────────────

/// Reusable AppBar action button that shows a popup menu for language selection.
class LanguageSelectorButton extends ConsumerWidget {
  const LanguageSelectorButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final idioma = ref.watch(idiomaProvider);
    return PopupMenuButton<IdiomaApp>(
      tooltip: '',
      icon: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: AppColors.primary.withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.primary.withOpacity(0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(idioma.flag, style: const TextStyle(fontSize: 14)),
            const SizedBox(width: 4),
            Text(
              idioma.code.toUpperCase(),
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: AppColors.primary,
              ),
            ),
          ],
        ),
      ),
      onSelected: (selected) {
        ref.read(idiomaProvider.notifier).cambiar(selected);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${selected.flag} ${selected.label}'),
            duration: const Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
          ),
        );
      },
      itemBuilder: (_) => IdiomaApp.values.map((lang) {
        final isActive = lang == idioma;
        return PopupMenuItem<IdiomaApp>(
          value: lang,
          child: Row(
            children: [
              Text(lang.flag, style: const TextStyle(fontSize: 16)),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  lang.label,
                  style: TextStyle(
                    fontWeight: isActive ? FontWeight.w700 : FontWeight.w400,
                  ),
                ),
              ),
              if (isActive)
                const Icon(Icons.check, size: 16, color: AppColors.primary),
            ],
          ),
        );
      }).toList(),
    );
  }
}
