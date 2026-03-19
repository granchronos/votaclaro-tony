import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/constants/app_colors.dart';
import '../../core/l10n/app_l10n.dart';
import '../../core/services/providers.dart';
import '../../widgets/common/widgets.dart';

/// Pantalla tutorial + simulador de votación peruana.
/// Enseña paso a paso cómo votar y permite al usuario simular la cédula.
class ComoVotarScreen extends ConsumerStatefulWidget {
  const ComoVotarScreen({super.key});

  @override
  ConsumerState<ComoVotarScreen> createState() => _ComoVotarScreenState();
}

class _ComoVotarScreenState extends ConsumerState<ComoVotarScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabs;
  int? _cedulaSeleccion;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = ref.watch(translationsProvider);
    return Scaffold(
      appBar: AppBar(
        title: Text(t.comoVotarTitle),
        actions: const [FontSizeAdjuster(), LanguageSelectorButton()],
        bottom: TabBar(
          controller: _tabs,
          indicatorColor: AppColors.primary,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textSecondary,
          tabs: [
            Tab(text: t.tutorialTab),
            Tab(text: t.simularVotoTab),
            Tab(text: t.recursosJneTab),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabs,
        children: [
          const _TutorialTab(),
          _SimuladorTab(
            seleccion: _cedulaSeleccion,
            onSeleccionar: (i) => setState(() => _cedulaSeleccion = i),
          ),
          const _RecursosJneTab(),
        ],
      ),
    );
  }
}

// ─── TAB 1: Tutorial paso a paso ─────────────────────────────────────────────

class _TutorialTab extends ConsumerWidget {
  const _TutorialTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = ref.watch(translationsProvider);
    final pasos = [
      _Paso(
          numero: 1,
          emoji: '🪪',
          titulo: t.paso1Titulo,
          descripcion: t.paso1Desc,
          detalle: List<String>.from(t.paso1Detalle),
          color: const Color(0xFF1976D2)),
      _Paso(
          numero: 2,
          emoji: '🏫',
          titulo: t.paso2Titulo,
          descripcion: t.paso2Desc,
          detalle: List<String>.from(t.paso2Detalle),
          color: const Color(0xFF388E3C)),
      _Paso(
          numero: 3,
          emoji: '🗂️',
          titulo: t.paso3Titulo,
          descripcion: t.paso3Desc,
          detalle: List<String>.from(t.paso3Detalle),
          color: const Color(0xFFF57C00)),
      _Paso(
          numero: 4,
          emoji: '🗳️',
          titulo: t.paso4Titulo,
          descripcion: t.paso4Desc,
          detalle: List<String>.from(t.paso4Detalle),
          color: const Color(0xFF7B1FA2)),
      _Paso(
          numero: 5,
          emoji: '✗',
          titulo: t.paso5Titulo,
          descripcion: t.paso5Desc,
          detalle: List<String>.from(t.paso5Detalle),
          color: const Color(0xFFC62828),
          esImportante: true),
      _Paso(
          numero: 6,
          emoji: '📄',
          titulo: t.paso6Titulo,
          descripcion: t.paso6Desc,
          detalle: List<String>.from(t.paso6Detalle),
          color: const Color(0xFF00796B)),
      _Paso(
          numero: 7,
          emoji: '🖊️',
          titulo: t.paso7Titulo,
          descripcion: t.paso7Desc,
          detalle: List<String>.from(t.paso7Detalle),
          color: const Color(0xFF1565C0)),
    ];
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      itemCount: pasos.length + 1,
      itemBuilder: (context, index) {
        if (index == 0) return _HeaderBanner(t: t);
        return _PasoCard(paso: pasos[index - 1]);
      },
    );
  }
}

class _HeaderBanner extends StatelessWidget {
  final AppL10n t;
  const _HeaderBanner({required this.t});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFD32F2F), Color(0xFFE53935)],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          const Text('🇵🇪', style: TextStyle(fontSize: 36)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  t.eleccionYear,
                  style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 15),
                ),
                const SizedBox(height: 4),
                Text(
                  t.eleccionFecha,
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PasoCard extends StatefulWidget {
  final _Paso paso;
  const _PasoCard({required this.paso});

  @override
  State<_PasoCard> createState() => _PasoCardState();
}

class _PasoCardState extends State<_PasoCard> {
  bool _expandido = false;

  @override
  Widget build(BuildContext context) {
    final p = widget.paso;
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: p.esImportante
            ? BorderSide(color: p.color.withOpacity(0.5), width: 2)
            : BorderSide.none,
      ),
      child: InkWell(
        onTap: () => setState(() => _expandido = !_expandido),
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: p.color.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    alignment: Alignment.center,
                    child: Text(p.emoji, style: const TextStyle(fontSize: 18)),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: p.color,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                'Paso ${p.numero}',
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold),
                              ),
                            ),
                            if (p.esImportante) ...[
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFC62828),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: const Text(
                                  '⚠️ CLAVE',
                                  style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold),
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          p.titulo,
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    _expandido ? Icons.expand_less : Icons.expand_more,
                    color: AppColors.textSecondary,
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(p.descripcion,
                  style: const TextStyle(fontSize: 13, height: 1.5)),
              if (_expandido) ...[
                const SizedBox(height: 10),
                ...p.detalle.map(
                  (d) => Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('•  ',
                            style: TextStyle(
                                color: p.color, fontWeight: FontWeight.bold)),
                        Expanded(
                          child: Text(d,
                              style:
                                  const TextStyle(fontSize: 13, height: 1.4)),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// ─── TAB 2: Simulador de cédula ───────────────────────────────────────────────

class _SimuladorTab extends ConsumerWidget {
  final int? seleccion;
  final void Function(int) onSeleccionar;

  const _SimuladorTab({required this.seleccion, required this.onSeleccionar});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = ref.watch(translationsProvider);
    final candidatosAsync = ref.watch(candidatosPresidenteProvider);

    return Column(
      children: [
        // Instrucción
        Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.primaryLight.withOpacity(0.15),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.primary.withOpacity(0.3)),
          ),
          child: Row(
            children: [
              const Icon(Icons.touch_app, color: AppColors.primary, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  t.simuladorSubtitle,
                  style: const TextStyle(
                      fontSize: 13, color: AppColors.textSecondary),
                ),
              ),
            ],
          ),
        ),

        // Cédula simulada con candidatos reales
        Expanded(
          child: candidatosAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (err, stack) => Center(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline,
                        size: 48, color: AppColors.inviable),
                    const SizedBox(height: 12),
                    Text(
                      'Error al cargar candidatos',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      err.toString(),
                      style: const TextStyle(fontSize: 12),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
            data: (candidatos) {
              if (candidatos.isEmpty) {
                return const Center(
                  child: Text('No hay candidatos disponibles'),
                );
              }

              // Convertir candidatos reales a formato para el simulador
              final candidatosSimulados =
                  candidatos.asMap().entries.map((entry) {
                final idx = entry.key;
                final c = entry.value;
                final partido = c['partido'] as String? ?? 'Sin partido';
                final nombre = c['nombreCompleto'] as String? ?? 'Sin nombre';
                final partidoColor = AppColors.partidoColors[partido] ??
                    AppColors.partidoColors['default']!;

                return _CandidatoSimulado(
                  numero: idx + 1,
                  nombre: nombre,
                  partido: partido,
                  colorPartido: partidoColor,
                  fotoUrl: c['fotoUrl'] as String?,
                );
              }).toList();

              return SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: _CedulaSufragio(
                  candidatos: candidatosSimulados,
                  seleccion: seleccion,
                  onSeleccionar: onSeleccionar,
                ),
              );
            },
          ),
        ),

        // Botón confirmar
        if (seleccion != null)
          candidatosAsync.maybeWhen(
            data: (candidatos) {
              if (seleccion! >= 0 && seleccion! < candidatos.length) {
                final candidato = candidatos[seleccion!];
                return Padding(
                  padding: const EdgeInsets.all(16),
                  child: ElevatedButton.icon(
                    onPressed: () => _mostrarConfirmacion(
                      context,
                      t,
                      candidato['nombreCompleto'] as String? ?? 'Candidato',
                    ),
                    icon: const Icon(Icons.how_to_vote),
                    label: Text(
                        '${t.confirmarVoto}: ${candidato['nombreCompleto']}'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(double.infinity, 50),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                    ),
                  ),
                );
              }
              return const SizedBox.shrink();
            },
            orElse: () => const SizedBox.shrink(),
          ),
      ],
    );
  }

  void _mostrarConfirmacion(
      BuildContext context, AppL10n t, String nombreCandidato) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(t.simuladorDialogTitle),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              t.simuladorDialogMsg.replaceAll('{nombre}', nombreCandidato),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            _ConfirmItem(emoji: '✅', text: t.simuladorMsgFiscal),
            _ConfirmItem(emoji: '✅', text: t.simuladorMsgSello),
            const SizedBox(height: 12),
            Text(
              nombreCandidato,
              textAlign: TextAlign.center,
              style: const TextStyle(
                  fontWeight: FontWeight.bold, color: AppColors.primary),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(t.entendido),
          ),
        ],
      ),
    );
  }
}

class _ConfirmItem extends StatelessWidget {
  final String emoji;
  final String text;
  const _ConfirmItem({required this.emoji, required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Text(emoji),
          const SizedBox(width: 8),
          Expanded(child: Text(text, style: const TextStyle(fontSize: 13))),
        ],
      ),
    );
  }
}

// ─── Cédula de sufragio ───────────────────────────────────────────────────────

class _CedulaSufragio extends StatelessWidget {
  final List<_CandidatoSimulado> candidatos;
  final int? seleccion;
  final void Function(int) onSeleccionar;

  const _CedulaSufragio({
    required this.candidatos,
    required this.seleccion,
    required this.onSeleccionar,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.black, width: 2),
        borderRadius: BorderRadius.circular(4),
        boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 8)],
      ),
      child: Column(
        children: [
          // ── Encabezado oficial ──
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
            color: const Color(0xFFD32F2F),
            child: Column(
              children: const [
                Text(
                  'OFICINA NACIONAL DE PROCESOS ELECTORALES',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5),
                ),
                SizedBox(height: 2),
                Text(
                  'CÉDULA DE SUFRAGIO',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold),
                ),
                Text(
                  'ELECCIONES GENERALES 2026 — PRESIDENTE',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white70, fontSize: 9),
                ),
              ],
            ),
          ),

          // ── Instrucción en la cédula ──
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            color: const Color(0xFFFFF9C4),
            child: const Text(
              'Marque con un ASPA (✗) dentro del recuadro de su candidato preferido',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
            ),
          ),

          // ── Separador ──
          Container(height: 1, color: Colors.black),

          // ── Filas de candidatos ──
          ...candidatos.asMap().entries.map(
                (e) => _FilaCandidato(
                  candidato: e.value,
                  isSelected: seleccion == e.key,
                  onTap: () => onSeleccionar(e.key),
                ),
              ),

          // ── Pie de página ──
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(8),
            decoration: const BoxDecoration(
              border: Border(top: BorderSide(color: Colors.black)),
            ),
            child: const Text(
              '⚠️ Simulación educativa — VotaClaro · No es una cédula oficial',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 9, color: Colors.grey),
            ),
          ),
        ],
      ),
    );
  }
}

class _FilaCandidato extends StatelessWidget {
  final _CandidatoSimulado candidato;
  final bool isSelected;
  final VoidCallback onTap;

  const _FilaCandidato({
    required this.candidato,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: isSelected
              ? candidato.colorPartido.withOpacity(0.08)
              : Colors.white,
          border: const Border(bottom: BorderSide(color: Colors.black26)),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        child: Row(
          children: [
            // Número
            SizedBox(
              width: 28,
              child: Text(
                '${candidato.numero}',
                textAlign: TextAlign.center,
                style:
                    const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
              ),
            ),
            const SizedBox(width: 4),
            // Símbolo partido (círculo de color)
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: candidato.colorPartido,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.black26),
              ),
              alignment: Alignment.center,
              child: Text(
                candidato.partido.substring(0, 1),
                style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 18),
              ),
            ),
            const SizedBox(width: 8),
            // Nombre y partido
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    candidato.nombre,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                  Text(
                    candidato.partido,
                    style: const TextStyle(color: Colors.grey, fontSize: 10),
                  ),
                ],
              ),
            ),
            // Casilla de marcar (aspa)
            Container(
              width: 40,
              height: 40,
              margin: const EdgeInsets.only(right: 4),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.black, width: 2),
                color: isSelected ? Colors.white : Colors.grey.shade100,
              ),
              alignment: Alignment.center,
              child: isSelected
                  ? Text(
                      '✗',
                      style: TextStyle(
                          color: candidato.colorPartido,
                          fontSize: 28,
                          fontWeight: FontWeight.bold),
                    )
                  : const SizedBox.shrink(),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── TAB 3: Recursos JNE ─────────────────────────────────────────────────────

class _RecursosJneTab extends ConsumerWidget {
  const _RecursosJneTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = ref.watch(translationsProvider);
    final recursos = [
      _Recurso(
          titulo: t.recurso1Titulo,
          descripcion: t.recurso1Desc,
          url: 'https://consultavoto.onpe.gob.pe',
          categoria: 'ONPE — Oficial'),
      _Recurso(
          titulo: t.recurso2Titulo,
          descripcion: t.recurso2Desc,
          url: 'https://votoinformado.jne.gob.pe',
          categoria: 'JNE — Oficial'),
      _Recurso(
          titulo: t.recurso3Titulo,
          descripcion: t.recurso3Desc,
          url: 'https://infogob.jne.gob.pe',
          categoria: 'JNE — Oficial'),
      _Recurso(
          titulo: t.recurso4Titulo,
          descripcion: t.recurso4Desc,
          url: 'https://declara.jne.gob.pe',
          categoria: 'JNE — Oficial'),
      _Recurso(
          titulo: t.recurso5Titulo,
          descripcion: t.recurso5Desc,
          url: 'https://ojo-publico.com/ojo-biónico',
          categoria: 'Fact-Check'),
      _Recurso(
          titulo: t.recurso6Titulo,
          descripcion: t.recurso6Desc,
          url: 'https://idl-reporteros.pe',
          categoria: 'Investigación'),
      _Recurso(
          titulo: t.recurso7Titulo,
          descripcion: t.recurso7Desc,
          url: 'https://www.ipsos.com/es-pe',
          categoria: 'Encuestas'),
      _Recurso(
          titulo: t.recurso8Titulo,
          descripcion: t.recurso8Desc,
          url: 'https://iep.org.pe',
          categoria: 'Encuestas'),
      _Recurso(
          titulo: t.recurso9Titulo,
          descripcion: t.recurso9Desc,
          url: 'https://consultamulta.onpe.gob.pe',
          categoria: 'ONPE — Oficial'),
    ];
    final agrupados = <String, List<_Recurso>>{};
    for (final r in recursos) {
      agrupados.putIfAbsent(r.categoria, () => []).add(r);
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // ── JNE TV en vivo ──────────────────────────────────────────────────
        const _JneTvCard(),
        const SizedBox(height: 8),
        // ── Recursos por categoría ──────────────────────────────────────────
        for (final entry in agrupados.entries) ...[
          Padding(
            padding: const EdgeInsets.only(top: 12, bottom: 8),
            child: Text(
              entry.key,
              style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                  color: AppColors.textSecondary),
            ),
          ),
          ...entry.value.map((r) => _RecursoCard(recurso: r)),
        ],
        const SizedBox(height: 32),
      ],
    );
  }
}

class _RecursoCard extends StatelessWidget {
  final _Recurso recurso;
  const _RecursoCard({required this.recurso});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        onTap: () async {
          final uri = Uri.parse(recurso.url);
          if (await canLaunchUrl(uri)) {
            await launchUrl(uri, mode: LaunchMode.externalApplication);
          }
        },
        title: Text(recurso.titulo,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(recurso.descripcion,
              style: const TextStyle(
                  fontSize: 12, color: AppColors.textSecondary)),
        ),
        trailing: const Icon(Icons.open_in_new,
            size: 16, color: AppColors.textSecondary),
        isThreeLine: true,
      ),
    );
  }
}

// ─── Modelos locales ──────────────────────────────────────────────────────────

class _Paso {
  final int numero;
  final String emoji;
  final String titulo;
  final String descripcion;
  final List<String> detalle;
  final Color color;
  final bool esImportante;

  const _Paso({
    required this.numero,
    required this.emoji,
    required this.titulo,
    required this.descripcion,
    required this.detalle,
    required this.color,
    this.esImportante = false,
  });
}

class _CandidatoSimulado {
  final int numero;
  final String nombre;
  final String partido;
  final Color colorPartido;
  final String? fotoUrl;

  const _CandidatoSimulado({
    required this.numero,
    required this.nombre,
    required this.partido,
    required this.colorPartido,
    this.fotoUrl,
  });
}

class _Recurso {
  final String titulo;
  final String descripcion;
  final String url;
  final String categoria;

  const _Recurso({
    required this.titulo,
    required this.descripcion,
    required this.url,
    required this.categoria,
  });
}

// ─── JNE TV ──────────────────────────────────────────────────────────────────

class _JneTvCard extends StatelessWidget {
  const _JneTvCard();

  static const _url = 'https://www.jne.gob.pe/jnetv/';

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () async {
          final uri = Uri.parse(_url);
          if (await canLaunchUrl(uri)) {
            await launchUrl(uri, mode: LaunchMode.externalApplication);
          }
        },
        child: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFFB71C1C), Color(0xFFD32F2F)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Center(
                  child: Text('📺', style: TextStyle(fontSize: 22)),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text(
                      'JNE TV — En vivo',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                      ),
                    ),
                    SizedBox(height: 3),
                    Text(
                      'Debates, transmisiones y cobertura oficial del JNE',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.play_circle_fill,
                  color: Colors.white70, size: 26),
            ],
          ),
        ),
      ),
    );
  }
}
