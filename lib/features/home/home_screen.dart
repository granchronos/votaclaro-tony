import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/debate_data.dart';
import '../../core/l10n/app_l10n.dart';
import '../../core/services/providers.dart';
import '../../core/services/favorites_service.dart';
import '../../widgets/common/widgets.dart';
import '../../widgets/common/theme_mode_selector.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  String _searchQuery = '';

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
            const _DebatesBanner(),
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
      builder: (dialogContext) => AlertDialog(
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
            onPressed: () => Navigator.pop(dialogContext),
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

class _DebatesBanner extends StatelessWidget {
  const _DebatesBanner();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = isDark ? const Color(0xFF90CAF9) : const Color(0xFF1565C0);
    final debates = DebateData.debates;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? [const Color(0xFF1E293B), const Color(0xFF0F172A)]
              : [const Color(0xFFE3F2FD), const Color(0xFFBBDEFB)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: accent.withOpacity(0.15),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: accent.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(Icons.record_voice_over_rounded,
                      color: accent, size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Debates Presidenciales 2026',
                        style: TextStyle(
                          color:
                              isDark ? Colors.white : const Color(0xFF1A237E),
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '6 debates · 36 candidatos · 12 por fecha',
                        style: TextStyle(
                          color: isDark ? Colors.white54 : Colors.blueGrey,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE53935).withOpacity(0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: const BoxDecoration(
                          color: Color(0xFFE53935),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Text(
                        '20:00h',
                        style: TextStyle(
                          color: Color(0xFFE53935),
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
            child: Text(
              '📍 Centro de Convenciones de Lima · Transmisión JNE Media',
              style: TextStyle(
                color: isDark ? Colors.white38 : Colors.blueGrey.shade600,
                fontSize: 10,
              ),
            ),
          ),
          SizedBox(
            height: 116,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 14),
              itemCount: debates.length,
              separatorBuilder: (_, __) => const SizedBox(width: 10),
              itemBuilder: (_, i) => _DebateCard(
                debate: debates[i],
                index: i,
                isDark: isDark,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DebateCard extends StatelessWidget {
  final DebateInfo debate;
  final int index;
  final bool isDark;
  const _DebateCard({
    required this.debate,
    required this.index,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final isPhase2 = index >= 3;
    final phaseColor = isPhase2
        ? (isDark ? Colors.tealAccent : const Color(0xFF00897B))
        : (isDark ? Colors.amber : const Color(0xFFF57F17));

    return GestureDetector(
      onTap: () => _showDebateDetail(context, debate, phaseColor),
      child: Container(
        width: 170,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isDark
              ? Colors.white.withOpacity(0.06)
              : Colors.white.withOpacity(0.7),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: phaseColor.withOpacity(0.3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
              decoration: BoxDecoration(
                color: phaseColor.withOpacity(0.12),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                debate.date,
                style: TextStyle(
                  color: phaseColor,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              '${debate.title} — ${debate.phase}',
              style: TextStyle(
                color: isDark ? Colors.white : const Color(0xFF1A237E),
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const Spacer(),
            Text(
              _shortTopics(debate.topics),
              style: TextStyle(
                color: isDark ? Colors.white54 : Colors.blueGrey,
                fontSize: 10,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  String _shortTopics(String topics) {
    final parts = topics.split(' · ');
    return parts.map((t) {
      final words = t.split(' ');
      if (words.length <= 3) return t;
      // Take first word + last meaningful word
      return '${words[0]} y ${words.last}';
    }).join('\n');
  }

  void _showDebateDetail(
      BuildContext context, DebateInfo debate, Color phaseColor) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.92,
        minChildSize: 0.4,
        builder: (_, scrollController) => Container(
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E293B) : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: ListView(
            controller: scrollController,
            padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    color: Colors.grey.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: phaseColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(Icons.record_voice_over_rounded,
                        color: phaseColor, size: 24),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          debate.title,
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: isDark ? Colors.white : Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: phaseColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            debate.phase,
                            style: TextStyle(
                              color: phaseColor,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              _DetailRow(
                icon: Icons.calendar_today_rounded,
                label: debate.fullDate,
                isDark: isDark,
              ),
              const SizedBox(height: 10),
              _DetailRow(
                icon: Icons.schedule_rounded,
                label: '20:00 horas — Transmisión en vivo por JNE Media',
                isDark: isDark,
              ),
              const SizedBox(height: 10),
              _DetailRow(
                icon: Icons.location_on_outlined,
                label: 'Centro de Convenciones de Lima',
                isDark: isDark,
              ),
              const SizedBox(height: 20),
              // Topics
              Text(
                'Temas',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
              const SizedBox(height: 8),
              ...debate.topics.split(' · ').map((topic) => Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          margin: const EdgeInsets.only(top: 6),
                          width: 6,
                          height: 6,
                          decoration: BoxDecoration(
                            color: phaseColor,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            topic,
                            style: TextStyle(
                              fontSize: 13,
                              color: isDark ? Colors.white70 : Colors.black54,
                            ),
                          ),
                        ),
                      ],
                    ),
                  )),
              const SizedBox(height: 20),
              // Moderators
              Text(
                'Moderadores',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  _ModeratorChip(
                      name: debate.moderator1,
                      isDark: isDark,
                      color: phaseColor),
                  const SizedBox(width: 10),
                  _ModeratorChip(
                      name: debate.moderator2,
                      isDark: isDark,
                      color: phaseColor),
                ],
              ),
              const SizedBox(height: 20),
              // Candidates section
              Text(
                'Orden de participación — sorteo JNE',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
              const SizedBox(height: 10),
              ...List.generate(debate.participants.length, (i) {
                final party = debate.participants[i];
                return _ParticipantTile(
                  order: i + 1,
                  partyName: party,
                  isDark: isDark,
                  phaseColor: phaseColor,
                );
              }),
              const SizedBox(height: 16),
              // Format info
              Text(
                'Formato del debate',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
              const SizedBox(height: 10),
              _FormatItem(
                number: '1',
                title: 'Debate temático',
                desc: '1 min exposición + 2.5 min interacción',
                isDark: isDark,
                color: phaseColor,
              ),
              _FormatItem(
                number: '2',
                title: 'Participación ciudadana',
                desc: 'Preguntas de ciudadanos — 1\'30" de respuesta',
                isDark: isDark,
                color: phaseColor,
              ),
              _FormatItem(
                number: '3',
                title: 'Debate temático',
                desc: '1 min exposición + 2.5 min interacción',
                isDark: isDark,
                color: phaseColor,
              ),
              _FormatItem(
                number: '4',
                title: 'Mensaje final',
                desc: '1 min por candidato para cerrar',
                isDark: isDark,
                color: phaseColor,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ParticipantTile extends ConsumerWidget {
  final int order;
  final String partyName;
  final bool isDark;
  final Color phaseColor;
  const _ParticipantTile({
    required this.order,
    required this.partyName,
    required this.isDark,
    required this.phaseColor,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Try to match with presidential candidates to get symbol URL & candidate name
    final candidatos = ref.watch(candidatosPresidenteProvider);
    String? symbolUrl;
    String? candidatoNombre;
    final partyUpper = partyName.toUpperCase();
    candidatos.whenData((list) {
      for (final c in list) {
        final pOrig =
            (c['partidoOriginal'] as String? ?? c['partido'] as String? ?? '')
                .toUpperCase();
        if (pOrig == partyUpper ||
            pOrig.contains(partyUpper) ||
            partyUpper.contains(pOrig)) {
          symbolUrl = c['simboloPartidoUrl'] as String?;
          candidatoNombre = c['nombreCompleto'] as String?;
          break;
        }
      }
    });

    final displayName = _titleCaseParty(partyName);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.04) : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? Colors.white.withOpacity(0.06) : Colors.grey.shade200,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 26,
            height: 26,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: phaseColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '$order',
              style: TextStyle(
                color: phaseColor,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: 10),
          if (symbolUrl != null && symbolUrl!.isNotEmpty)
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: CachedNetworkImage(
                imageUrl: symbolUrl!,
                width: 28,
                height: 28,
                fit: BoxFit.contain,
                errorWidget: (_, __, ___) => Icon(
                  Icons.groups_rounded,
                  size: 20,
                  color: isDark ? Colors.white24 : Colors.grey.shade400,
                ),
              ),
            )
          else
            Icon(
              Icons.groups_rounded,
              size: 20,
              color: isDark ? Colors.white24 : Colors.grey.shade400,
            ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  displayName,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (candidatoNombre != null)
                  Text(
                    candidatoNombre!,
                    style: TextStyle(
                      fontSize: 10,
                      color: isDark ? Colors.white38 : Colors.grey,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _titleCaseParty(String s) {
    return s.split(' ').map((w) {
      if (w.isEmpty) return w;
      final lower = w.toLowerCase();
      const small = {
        'de',
        'del',
        'la',
        'el',
        'y',
        'e',
        'en',
        'al',
        'para',
        'por'
      };
      if (small.contains(lower)) return lower;
      return lower[0].toUpperCase() + lower.substring(1);
    }).join(' ');
  }
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isDark;
  const _DetailRow(
      {required this.icon, required this.label, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: isDark ? Colors.white38 : Colors.blueGrey),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              color: isDark ? Colors.white70 : Colors.black54,
            ),
          ),
        ),
      ],
    );
  }
}

class _ModeratorChip extends StatelessWidget {
  final String name;
  final bool isDark;
  final Color color;
  const _ModeratorChip(
      {required this.name, required this.isDark, required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.15)),
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 14,
              backgroundColor: color.withOpacity(0.15),
              child: Icon(Icons.mic, size: 14, color: color),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                name,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FormatItem extends StatelessWidget {
  final String number;
  final String title;
  final String desc;
  final bool isDark;
  final Color color;
  const _FormatItem({
    required this.number,
    required this.title,
    required this.desc,
    required this.isDark,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 24,
            height: 24,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              number,
              style: TextStyle(
                color: color,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
                Text(
                  desc,
                  style: TextStyle(
                    fontSize: 11,
                    color: isDark ? Colors.white38 : Colors.grey,
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

/// Displays the candidate list for the selected election tab (president/congress/andean)
class _CandidatosList extends ConsumerWidget {
  final int tabIndex;
  final String searchQuery;
  const _CandidatosList({
    required this.tabIndex,
    required this.searchQuery,
  });

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
class _TopCandidatoCard extends ConsumerWidget {
  final Map<String, dynamic> candidato;
  final double promedioEncuesta;
  final VoidCallback onTap;

  const _TopCandidatoCard({
    required this.candidato,
    required this.promedioEncuesta,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final nombre = candidato['nombreCompleto'] as String? ?? 'Sin nombre';
    final partido = candidato['partido'] as String? ?? '';
    final fotoUrl = candidato['fotoUrl'] as String?;
    final simboloUrl = candidato['simboloPartidoUrl'] as String?;
    final id = candidato['id'] as String? ?? '';
    final partidoColor =
        AppColors.partidoColors[partido] ?? AppColors.partidoColors['default']!;
    final isFav = ref.watch(favoritesProvider.select(
        (favs) => favs[FavoriteCategory.presidente]?.contains(id) ?? false));

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
                            child: CachedNetworkImage(
                              imageUrl: fotoUrl,
                              width: 48,
                              height: 48,
                              fit: BoxFit.cover,
                              placeholder: (_, __) => const Icon(Icons.person,
                                  size: 22, color: AppColors.textSecondary),
                              errorWidget: (_, __, ___) => const Icon(
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
                            if (simboloUrl != null && simboloUrl.isNotEmpty)
                              ClipRRect(
                                borderRadius: BorderRadius.circular(4),
                                child: CachedNetworkImage(
                                  imageUrl: simboloUrl,
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

              // Favorite toggle row
              Align(
                alignment: Alignment.centerRight,
                child: GestureDetector(
                  onTap: () => ref
                      .read(favoritesProvider.notifier)
                      .toggle(FavoriteCategory.presidente, id),
                  child: Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Icon(
                      isFav ? Icons.favorite : Icons.favorite_border,
                      size: 20,
                      color: isFav ? Colors.red : AppColors.textHint,
                    ),
                  ),
                ),
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
