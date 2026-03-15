import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/constants/app_colors.dart';
import '../../core/l10n/app_l10n.dart';
import '../../core/services/providers.dart';
import '../../widgets/common/widgets.dart';

class CandidatoProfileScreen extends ConsumerWidget {
  final String candidatoId;

  const CandidatoProfileScreen({super.key, required this.candidatoId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = ref.watch(translationsProvider);
    final perfilAsync = ref.watch(candidatoPerfilProvider(candidatoId));

    return Scaffold(
      backgroundColor: AppColors.background,
      body: perfilAsync.when(
        data: (perfil) => perfil.isEmpty
            ? Center(child: Text(t.sinDatos))
            : _PerfilDetail(perfil: perfil),
        loading: () => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation(AppColors.primary),
              ),
              const SizedBox(height: 16),
              Text('Cargando perfil JNE...',
                  style: const TextStyle(color: AppColors.textSecondary)),
            ],
          ),
        ),
        error: (e, _) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline,
                  color: AppColors.inviable, size: 48),
              const SizedBox(height: 12),
              Text(t.errorGeneral),
            ],
          ),
        ),
      ),
    );
  }
}

class _PerfilDetail extends StatelessWidget {
  final Map<String, dynamic> perfil;
  const _PerfilDetail({required this.perfil});

  @override
  Widget build(BuildContext context) {
    final nombre = perfil['nombreCompleto'] as String? ?? 'Sin nombre';
    final partido = perfil['partido'] as String? ?? '';
    final edad = (perfil['edad'] as num?)?.toInt() ?? 0;
    final profesion = perfil['profesion'] as String? ?? '';
    final region = perfil['region'] as String? ?? '';
    final fotoUrl = perfil['fotoUrl'] as String?;
    final partidoColor =
        AppColors.partidoColors[partido] ?? AppColors.partidoColors['default']!;

    final hv = perfil['hojaVida'] as Map<String, dynamic>? ?? {};
    final plan = perfil['planGobierno'] as Map<String, dynamic>?;
    final formula = (perfil['formulaPresidencial'] as List?)
            ?.cast<Map<String, dynamic>>() ??
        [];

    return CustomScrollView(
      slivers: [
        SliverAppBar(
          expandedHeight: 220,
          pinned: true,
          backgroundColor: AppColors.surface,
          leading: Container(
            margin: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.9),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: IconButton(
              icon: const Icon(Icons.arrow_back, color: AppColors.primary),
              onPressed: () => Navigator.of(context).pop(),
              padding: EdgeInsets.zero,
            ),
          ),
          flexibleSpace: FlexibleSpaceBar(
            background: _HeaderBackground(
              nombre: nombre,
              partido: partido,
              partidoColor: partidoColor,
              edad: edad,
              profesion: profesion,
              region: region,
              fotoUrl: fotoUrl,
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ─ Fórmula Presidencial ─
              if (formula.length > 1)
                _FormulaPresidencialSection(
                  formula: formula,
                  partidoColor: partidoColor,
                ),

              // ─ Plan de Gobierno — Documentos PDF ─
              if (plan != null) _PlanGobiernoPdfSection(plan: plan),

              // ─ Análisis Rápido VotaClaro ─
              _ResumenAnaliticoSection(
                nombre: nombre,
                partido: partido,
                plan: plan,
                hv: hv,
              ),

              // ─ Educación ─
              if ((hv['educacion'] as List?)?.isNotEmpty ?? false)
                _SectionCard(
                  icon: '🎓',
                  title: 'Educación',
                  child: _EducacionSection(
                      items: List<Map<String, dynamic>>.from(hv['educacion'])),
                ),

              // ─ Experiencia laboral ─
              if ((hv['experiencia'] as List?)?.isNotEmpty ?? false)
                _SectionCard(
                  icon: '💼',
                  title: 'Experiencia Laboral',
                  child: _ExperienciaSection(
                      items:
                          List<Map<String, dynamic>>.from(hv['experiencia'])),
                ),

              // ─ Cargos de elección popular ─
              if ((hv['cargosEleccion'] as List?)?.isNotEmpty ?? false)
                _SectionCard(
                  icon: '🏛️',
                  title: 'Cargos de Elección',
                  child: _CargosSection(
                      items: List<Map<String, dynamic>>.from(
                          hv['cargosEleccion'])),
                ),

              // ─ Patrimonio ─
              _SectionCard(
                icon: '💰',
                title: 'Patrimonio Declarado',
                child: _PatrimonioJneSection(hv: hv),
              ),

              // ─ Antecedentes ─
              _SectionCard(
                icon: '⚖️',
                title: 'Antecedentes Judiciales',
                child: _AntecedentesSection(hv: hv),
              ),

              // ─ Seguridad Ciudadana ─
              if (plan != null) _SeguridadSection(plan: plan),

              // ─ Plan de Gobierno ─
              if (plan != null)
                _SectionCard(
                  icon: '📋',
                  title: 'Plan de Gobierno',
                  child: _PlanGobiernoSection(plan: plan),
                ),

              // ─ Análisis Electoral IA ─
              if (plan != null)
                _AnalisisElectoralSection(
                  nombre: nombre,
                  partido: partido,
                  plan: plan,
                  hv: hv,
                ),

              // ─ Leyenda ─
              const LeyendaSemaforo(),

              // ─ Info adicional ─
              if ((hv['infoAdicional'] as List?)?.isNotEmpty ?? false)
                _SectionCard(
                  icon: 'ℹ️',
                  title: 'Información Adicional',
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: (hv['infoAdicional'] as List)
                        .map<Widget>((info) => Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: Text(info.toString(),
                                  style: const TextStyle(
                                      fontSize: 13,
                                      color: AppColors.textSecondary,
                                      height: 1.5)),
                            ))
                        .toList(),
                  ),
                ),

              const Padding(
                padding: EdgeInsets.all(16),
                child: SourceTag(fuente: 'JNE Voto Informado 2026'),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ],
    );
  }
}

// ─── Header ──────────────────────────────────────────────────────────────────

class _HeaderBackground extends StatelessWidget {
  final String nombre, partido, region, profesion;
  final Color partidoColor;
  final int edad;
  final String? fotoUrl;

  const _HeaderBackground({
    required this.nombre,
    required this.partido,
    required this.partidoColor,
    required this.edad,
    required this.profesion,
    required this.region,
    this.fotoUrl,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(color: AppColors.surface),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 60, 16, 16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.surfaceVariant,
                border: Border.all(color: partidoColor, width: 3),
              ),
              child: fotoUrl != null && fotoUrl!.isNotEmpty
                  ? ClipOval(
                      child: Image.network(fotoUrl!,
                          fit: BoxFit.cover,
                          width: 72,
                          height: 72,
                          errorBuilder: (_, __, ___) => const Icon(Icons.person,
                              size: 40, color: AppColors.textSecondary)),
                    )
                  : const Icon(Icons.person,
                      size: 40, color: AppColors.textSecondary),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(nombre,
                      style: Theme.of(context).textTheme.headlineMedium),
                  const SizedBox(height: 4),
                  Row(children: [
                    Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                            color: partidoColor, shape: BoxShape.circle)),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(partido,
                          style: TextStyle(
                              color: partidoColor,
                              fontWeight: FontWeight.w600,
                              fontSize: 13)),
                    ),
                  ]),
                  const SizedBox(height: 4),
                  if (profesion.isNotEmpty || edad > 0 || region.isNotEmpty)
                    Text(
                      [
                        if (profesion.isNotEmpty) profesion,
                        if (edad > 0) '$edad años',
                        if (region.isNotEmpty) region,
                      ].join(' · '),
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Section card wrapper ────────────────────────────────────────────────────

class _SectionCard extends StatelessWidget {
  final String icon, title;
  final Widget child;
  const _SectionCard(
      {required this.icon, required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Text(icon, style: const TextStyle(fontSize: 18)),
              const SizedBox(width: 8),
              Text(title, style: Theme.of(context).textTheme.titleLarge),
            ]),
            const Divider(height: 20),
            child,
          ],
        ),
      ),
    );
  }
}

// ─── Fórmula Presidencial ────────────────────────────────────────────────────

class _FormulaPresidencialSection extends StatelessWidget {
  final List<Map<String, dynamic>> formula;
  final Color partidoColor;

  const _FormulaPresidencialSection({
    required this.formula,
    required this.partidoColor,
  });

  String _cargoLabel(dynamic idCargo) {
    switch (idCargo) {
      case 1:
        return 'Presidente';
      case 2:
        return '1er Vicepresidente';
      case 3:
        return '2do Vicepresidente';
      default:
        return 'Candidato';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              const Text('🇵🇪', style: TextStyle(fontSize: 18)),
              const SizedBox(width: 8),
              Text('Fórmula Presidencial',
                  style: Theme.of(context).textTheme.titleLarge),
            ]),
            const Divider(height: 20),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: formula.map((miembro) {
                final nombre =
                    miembro['nombreCompleto'] as String? ?? 'Sin nombre';
                final foto = miembro['fotoUrl'] as String?;
                final cargo = _cargoLabel(miembro['idCargo']);
                final isPresidente = miembro['idCargo'] == 1;
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Column(
                      children: [
                        Container(
                          width: isPresidente ? 68 : 56,
                          height: isPresidente ? 68 : 56,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppColors.surfaceVariant,
                            border: Border.all(
                              color: isPresidente
                                  ? partidoColor
                                  : partidoColor.withOpacity(0.5),
                              width: isPresidente ? 3 : 2,
                            ),
                          ),
                          child: foto != null && foto.isNotEmpty
                              ? ClipOval(
                                  child: Image.network(
                                    foto,
                                    fit: BoxFit.cover,
                                    width: isPresidente ? 68 : 56,
                                    height: isPresidente ? 68 : 56,
                                    errorBuilder: (_, __, ___) => Icon(
                                      Icons.person,
                                      size: isPresidente ? 32 : 24,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                )
                              : Icon(
                                  Icons.person,
                                  size: isPresidente ? 32 : 24,
                                  color: AppColors.textSecondary,
                                ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          nombre,
                          style: TextStyle(
                            fontSize: isPresidente ? 12 : 11,
                            fontWeight: isPresidente
                                ? FontWeight.w700
                                : FontWeight.w500,
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: isPresidente
                                ? partidoColor.withOpacity(0.12)
                                : AppColors.surfaceVariant,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            cargo,
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w600,
                              color: isPresidente
                                  ? partidoColor
                                  : AppColors.textSecondary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Plan de Gobierno PDF ────────────────────────────────────────────────────

class _PlanGobiernoPdfSection extends ConsumerWidget {
  final Map<String, dynamic> plan;
  const _PlanGobiernoPdfSection({required this.plan});

  Future<void> _openPdf(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rutaCompleto = plan['rutaCompleto'] as String? ?? '';
    final rutaResumen = plan['rutaResumen'] as String? ?? '';

    if (rutaCompleto.isEmpty && rutaResumen.isEmpty) return const SizedBox();

    // Intentar parsear el PDF de resumen (más liviano)
    final pdfUrl = rutaResumen.isNotEmpty ? rutaResumen : rutaCompleto;
    final parsedAsync = ref.watch(parsedPdfProvider(pdfUrl));

    return Card(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              const Text('📄', style: TextStyle(fontSize: 18)),
              const SizedBox(width: 8),
              Expanded(
                child: Text('Plan de Gobierno',
                    style: Theme.of(context).textTheme.titleLarge),
              ),
            ]),
            const Divider(height: 20),

            // Contenido parseado del PDF
            parsedAsync.when(
              loading: () => Container(
                padding: const EdgeInsets.all(16),
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Row(
                  children: [
                    SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Analizando documento del plan de gobierno...',
                        style: TextStyle(
                          fontSize: 13,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              error: (error, _) => Container(
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: AppColors.inviable.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.error_outline,
                        color: AppColors.inviable, size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'No se pudo analizar el documento automáticamente. Descarga el PDF para revisarlo.',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              data: (parsed) {
                if (parsed.containsKey('error') ||
                    !parsed.containsKey('resumen')) {
                  return Container(
                    padding: const EdgeInsets.all(12),
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.info_outline,
                            color: AppColors.primary, size: 20),
                        SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Descarga el documento para revisar las propuestas detalladas.',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                              height: 1.4,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }

                final resumen = parsed['resumen'] as String? ?? '';
                final secciones =
                    parsed['secciones'] as Map<String, dynamic>? ?? {};
                final longitudTotal = parsed['longitudTotal'] as int? ?? 0;

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Resumen inicial
                    if (resumen.isNotEmpty) ...[
                      Container(
                        padding: const EdgeInsets.all(12),
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: AppColors.primary.withOpacity(0.1),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.auto_awesome,
                                    color: AppColors.primary, size: 16),
                                const SizedBox(width: 6),
                                Text(
                                  'Resumen Automático',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.primary,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              resumen,
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.textPrimary,
                                height: 1.5,
                              ),
                              maxLines: 8,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],

                    // Secciones detectadas
                    if (secciones.isNotEmpty) ...[
                      Text(
                        'Secciones detectadas (${secciones.length})',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      ...secciones.entries.map((entry) {
                        return Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceVariant,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                entry.key,
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.primary,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                entry.value as String,
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: AppColors.textSecondary,
                                  height: 1.4,
                                ),
                                maxLines: 4,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        );
                      }),
                      const SizedBox(height: 8),
                    ],

                    // Información del documento
                    if (longitudTotal > 0)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Text(
                          'Documento de ${(longitudTotal / 1000).toStringAsFixed(1)}k caracteres',
                          style: TextStyle(
                            fontSize: 10,
                            color: AppColors.textSecondary.withOpacity(0.7),
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ),
                  ],
                );
              },
            ),

            // Botones de descarga
            if (rutaResumen.isNotEmpty)
              _PdfButton(
                icon: Icons.summarize_outlined,
                label: 'Descargar Plan Resumen',
                description: 'PDF versión resumida',
                color: AppColors.primary,
                onTap: () => _openPdf(rutaResumen),
              ),
            if (rutaResumen.isNotEmpty && rutaCompleto.isNotEmpty)
              const SizedBox(height: 10),
            if (rutaCompleto.isNotEmpty)
              _PdfButton(
                icon: Icons.description_outlined,
                label: 'Descargar Plan Completo',
                description: 'PDF versión completa',
                color: AppColors.accent,
                onTap: () => _openPdf(rutaCompleto),
              ),
            const SizedBox(height: 8),
            const Text(
              'Fuente: JNE Voto Informado 2026',
              style: TextStyle(
                fontSize: 10,
                color: AppColors.textSecondary,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PdfButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final String description;
  final Color color;
  final VoidCallback onTap;

  const _PdfButton({
    required this.icon,
    required this.label,
    required this.description,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: color.withOpacity(0.06),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.15)),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: color,
                    ),
                  ),
                  Text(
                    description,
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.open_in_new, size: 18, color: color.withOpacity(0.6)),
          ],
        ),
      ),
    );
  }
}

// ─── Educación ───────────────────────────────────────────────────────────────

class _EducacionSection extends StatelessWidget {
  final List<Map<String, dynamic>> items;
  const _EducacionSection({required this.items});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: items.map((e) {
        final tipo = e['tipo'] as String? ?? '';
        final centro = e['centro'] as String? ?? '';
        final carrera = e['carrera'] as String? ?? '';
        final concluido = e['concluido'] as bool? ?? false;
        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(tipo == 'Posgrado' ? Icons.school : Icons.account_balance,
                  size: 18, color: AppColors.primary),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(carrera,
                        style: const TextStyle(
                            fontSize: 13, fontWeight: FontWeight.w600)),
                    Text(centro,
                        style: const TextStyle(
                            fontSize: 12, color: AppColors.textSecondary)),
                    Text(concluido ? '✅ Concluido' : '⏳ No concluido',
                        style: TextStyle(
                            fontSize: 11,
                            color: concluido
                                ? AppColors.viable
                                : AppColors.doubtful)),
                  ],
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}

// ─── Experiencia laboral ────────────────────────────────────────────────────

class _ExperienciaSection extends StatelessWidget {
  final List<Map<String, dynamic>> items;
  const _ExperienciaSection({required this.items});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: items.map((e) {
        final centro = e['centro'] as String? ?? '';
        final cargo = e['cargo'] as String? ?? '';
        final desde = e['desde'] as String? ?? '';
        final hasta = e['hasta'] as String? ?? '';
        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.work_outline, size: 18, color: AppColors.accent),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(cargo,
                        style: const TextStyle(
                            fontSize: 13, fontWeight: FontWeight.w600)),
                    Text(centro,
                        style: const TextStyle(
                            fontSize: 12, color: AppColors.textSecondary)),
                    Text('$desde - $hasta',
                        style: const TextStyle(
                            fontSize: 11, color: AppColors.textSecondary)),
                  ],
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}

// ─── Cargos de elección ──────────────────────────────────────────────────────

class _CargosSection extends StatelessWidget {
  final List<Map<String, dynamic>> items;
  const _CargosSection({required this.items});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: items.map((e) {
        final cargo = e['cargo'] as String? ?? '';
        final desde = e['desde'] as String? ?? '';
        final hasta = e['hasta'] as String? ?? '';
        final partido = e['partido'] as String? ?? '';
        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.how_to_vote, size: 18, color: AppColors.primary),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Cargo electo ($desde - $hasta)',
                        style: const TextStyle(
                            fontSize: 13, fontWeight: FontWeight.w600)),
                    if (partido.isNotEmpty)
                      Text(partido,
                          style: const TextStyle(
                              fontSize: 12, color: AppColors.textSecondary)),
                  ],
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}

// ─── Patrimonio ──────────────────────────────────────────────────────────────

class _PatrimonioJneSection extends StatelessWidget {
  final Map<String, dynamic> hv;
  const _PatrimonioJneSection({required this.hv});

  @override
  Widget build(BuildContext context) {
    final ingPub = (hv['ingresoPublico'] as num?)?.toDouble() ?? 0;
    final ingPriv = (hv['ingresoPrivado'] as num?)?.toDouble() ?? 0;
    final bienesMueble = hv['bienesMueble'] as List? ?? [];
    final bienesInmueble = hv['bienesInmueble'] as List? ?? [];
    final titularidad = hv['titularidad'] as List? ?? [];

    double totalMueble = 0;
    for (final b in bienesMueble) {
      totalMueble += ((b as Map)['valor'] as num?)?.toDouble() ?? 0;
    }
    double totalInmueble = 0;
    for (final b in bienesInmueble) {
      totalInmueble += ((b as Map)['valor'] as num?)?.toDouble() ?? 0;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            _PatrimonioChip('Ingreso Público', ingPub, AppColors.accent),
            const SizedBox(width: 8),
            _PatrimonioChip('Ingreso Privado', ingPriv, AppColors.primary),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            _PatrimonioChip('B. Muebles', totalMueble, AppColors.doubtful),
            const SizedBox(width: 8),
            _PatrimonioChip('B. Inmuebles', totalInmueble, AppColors.viable),
          ],
        ),
        if (titularidad.isNotEmpty) ...[
          const SizedBox(height: 10),
          const Text('Participación en empresas:',
              style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary)),
          const SizedBox(height: 4),
          ...titularidad.map((t) {
            final m = t as Map<String, dynamic>;
            return Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text(
                  '• ${m['empresa']} (${m['tipo']}) - S/ ${_fmt(m['valor'])}',
                  style: const TextStyle(
                      fontSize: 12, color: AppColors.textSecondary)),
            );
          }),
        ],
        if (ingPub == 0 &&
            ingPriv == 0 &&
            totalMueble == 0 &&
            totalInmueble == 0)
          const Text('Sin datos de patrimonio declarados',
              style: TextStyle(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                  fontStyle: FontStyle.italic)),
      ],
    );
  }

  static String _fmt(dynamic v) {
    final d = (v as num?)?.toDouble() ?? 0;
    if (d >= 1000000) return '${(d / 1000000).toStringAsFixed(2)}M';
    if (d >= 1000) return '${(d / 1000).toStringAsFixed(0)}K';
    return d.toStringAsFixed(0);
  }
}

class _PatrimonioChip extends StatelessWidget {
  final String label;
  final double value;
  final Color color;
  const _PatrimonioChip(this.label, this.value, this.color);

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Text(label,
                style: TextStyle(
                    fontSize: 11, color: color, fontWeight: FontWeight.w500)),
            const SizedBox(height: 4),
            Text('S/ ${_PatrimonioJneSection._fmt(value)}',
                style: TextStyle(
                    fontSize: 13, color: color, fontWeight: FontWeight.w700)),
          ],
        ),
      ),
    );
  }
}

// ─── Antecedentes ────────────────────────────────────────────────────────────

class _AntecedentesSection extends StatelessWidget {
  final Map<String, dynamic> hv;
  const _AntecedentesSection({required this.hv});

  @override
  Widget build(BuildContext context) {
    final penales = (hv['sentenciasPenales'] as num?)?.toInt() ?? 0;
    final obligatorias = (hv['sentenciasObligatorias'] as num?)?.toInt() ?? 0;
    final renuncias = hv['renuncias'] as List? ?? [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _AntecedenteRow(
          icon: penales == 0 ? Icons.check_circle : Icons.warning,
          color: penales == 0 ? AppColors.viable : AppColors.inviable,
          text: penales == 0
              ? 'Sin sentencias penales'
              : '$penales sentencia(s) penal(es)',
        ),
        _AntecedenteRow(
          icon: obligatorias == 0 ? Icons.check_circle : Icons.warning,
          color: obligatorias == 0 ? AppColors.viable : AppColors.inviable,
          text: obligatorias == 0
              ? 'Sin sentencias por obligación de dar'
              : '$obligatorias sentencia(s) oblig.',
        ),
        if (renuncias.isNotEmpty) ...[
          const SizedBox(height: 6),
          const Text('Renuncias a partidos:',
              style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary)),
          ...renuncias.map((r) {
            final m = r as Map<String, dynamic>;
            return Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text('• ${m['partido']} (${m['anio']})',
                  style: const TextStyle(
                      fontSize: 12, color: AppColors.textSecondary)),
            );
          }),
        ],
        if (renuncias.isEmpty)
          _AntecedenteRow(
            icon: Icons.info_outline,
            color: AppColors.textSecondary,
            text: 'Sin renuncias a partidos registradas',
          ),
      ],
    );
  }
}

class _AntecedenteRow extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String text;
  const _AntecedenteRow(
      {required this.icon, required this.color, required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 8),
          Expanded(
              child: Text(text, style: TextStyle(fontSize: 13, color: color))),
        ],
      ),
    );
  }
}

// ─── Plan de Gobierno ────────────────────────────────────────────────────────

class _PlanGobiernoSection extends StatelessWidget {
  final Map<String, dynamic> plan;
  const _PlanGobiernoSection({required this.plan});

  static const _dimIcons = {
    'Social': '👥',
    'Económica': '📈',
    'Ambiental': '🌿',
    'Institucional': '🏛️',
  };

  static const _dimColors = {
    'Social': AppColors.primary,
    'Económica': AppColors.accent,
    'Ambiental': AppColors.viable,
    'Institucional': AppColors.doubtful,
  };

  @override
  Widget build(BuildContext context) {
    final dimensiones = plan['dimensiones'] as Map<String, dynamic>? ?? {};

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ...dimensiones.entries.map((entry) {
          final dimName = entry.key;
          final items = entry.value as List? ?? [];
          if (items.isEmpty) return const SizedBox.shrink();

          final icon = _dimIcons[dimName] ?? '📋';
          final color = _dimColors[dimName] ?? AppColors.primary;

          return _CollapsibleDimension(
            dimName: dimName,
            icon: icon,
            color: color,
            items: items,
          );
        }),
      ],
    );
  }
}

class _CollapsibleDimension extends StatefulWidget {
  final String dimName;
  final String icon;
  final Color color;
  final List items;

  const _CollapsibleDimension({
    required this.dimName,
    required this.icon,
    required this.color,
    required this.items,
  });

  @override
  State<_CollapsibleDimension> createState() => _CollapsibleDimensionState();
}

class _CollapsibleDimensionState extends State<_CollapsibleDimension> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          onTap: () => setState(() => _expanded = !_expanded),
          borderRadius: BorderRadius.circular(8),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: widget.color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Text(widget.icon, style: const TextStyle(fontSize: 14)),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                      'Dimensión ${widget.dimName} (${widget.items.length})',
                      style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: widget.color)),
                ),
                Icon(
                  _expanded ? Icons.expand_less : Icons.expand_more,
                  size: 20,
                  color: widget.color,
                ),
              ],
            ),
          ),
        ),
        if (_expanded) ...[
          const SizedBox(height: 8),
          ...widget.items.map((item) {
            final m = item as Map<String, dynamic>;
            final problema = m['txPgProblema'] as String? ?? '';
            final objetivo = m['txPgObjetivo'] as String? ?? '';
            final meta = m['txPgMeta'] as String? ?? '';
            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.surfaceVariant,
                borderRadius: BorderRadius.circular(10),
                border:
                    Border(left: BorderSide(color: widget.color, width: 3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (problema.isNotEmpty) ...[
                    const Text('Problema identificado:',
                        style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textSecondary)),
                    const SizedBox(height: 2),
                    Text(problema,
                        style: const TextStyle(fontSize: 12, height: 1.4)),
                    const SizedBox(height: 8),
                  ],
                  if (objetivo.isNotEmpty) ...[
                    const Text('Objetivo / Propuesta:',
                        style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: AppColors.viable)),
                    const SizedBox(height: 2),
                    Text(objetivo,
                        style: const TextStyle(fontSize: 12, height: 1.4)),
                  ],
                  if (meta.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('🎯 ', style: TextStyle(fontSize: 11)),
                        Expanded(
                          child: Text('Meta: $meta',
                              style: const TextStyle(
                                  fontSize: 11,
                                  color: AppColors.textSecondary,
                                  fontStyle: FontStyle.italic)),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            );
          }),
        ],
        const SizedBox(height: 4),
      ],
    );
  }
}

// ─── Seguridad Ciudadana (destacado) ─────────────────────────────────────────

class _SeguridadSection extends ConsumerWidget {
  final Map<String, dynamic> plan;
  const _SeguridadSection({required this.plan});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dimensiones = plan['dimensiones'] as Map<String, dynamic>? ?? {};
    final institucional = dimensiones['Institucional'] as List? ?? [];

    // Filtrar propuestas relacionadas con seguridad
    final keywords = [
      'seguridad',
      'inseguridad',
      'delincuencia',
      'criminalidad',
      'crimen',
      'policía',
      'policia',
      'narcotráfico',
      'narcotrafico',
      'extorsión',
      'extorsion',
      'sicariato',
      'violencia',
      'robo',
      'hurto',
      'banda',
      'penitenciar',
      'cárcel',
      'carcel',
      'orden público',
      'orden publico',
      'arma',
      'homicidio',
      'feminicidio',
      'pandilla',
      'secuestro',
    ];

    bool esSeguridad(Map<String, dynamic> item) {
      final texto = '${item['txPgProblema'] ?? ''} '
              '${item['txPgObjetivo'] ?? ''} '
              '${item['txPgMeta'] ?? ''}'
          .toLowerCase();
      return keywords.any((k) => texto.contains(k));
    }

    final propSeguridad = institucional
        .where((item) => esSeguridad(item as Map<String, dynamic>))
        .toList();

    // Si no hay match por keywords, mostrar toda la dimensión institucional
    final propuestas = propSeguridad.isNotEmpty ? propSeguridad : institucional;

    // Si no hay propuestas, intentar buscar en el PDF parseado
    if (propuestas.isEmpty) {
      final rutaResumen = plan['rutaResumen'] as String? ?? '';
      final rutaCompleto = plan['rutaCompleto'] as String? ?? '';
      final pdfUrl = rutaResumen.isNotEmpty ? rutaResumen : rutaCompleto;

      if (pdfUrl.isNotEmpty) {
        final parsedAsync = ref.watch(parsedPdfProvider(pdfUrl));

        return _SectionCard(
          icon: '🛡️',
          title: 'Seguridad Ciudadana',
          child: parsedAsync.when(
            loading: () => Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.05),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Row(
                children: [
                  SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Buscando propuestas de seguridad en el documento...',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            error: (_, __) => Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.inviable.withOpacity(0.08),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.warning_amber_rounded,
                          color: AppColors.inviable, size: 20),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'No se encontraron propuestas específicas sobre seguridad.',
                          style: TextStyle(
                              fontSize: 13,
                              color: AppColors.inviable,
                              height: 1.4,
                              fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Revisa el PDF del plan de gobierno para más información.',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                      height: 1.3,
                    ),
                  ),
                ],
              ),
            ),
            data: (parsed) {
              final secciones =
                  parsed['secciones'] as Map<String, dynamic>? ?? {};
              final seguridadText = secciones['Seguridad'] as String?;
              final textoCompleto = parsed['textoCompleto'] as String? ?? '';

              if (seguridadText != null && seguridadText.isNotEmpty) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE53935).withOpacity(0.08),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: const Color(0xFFE53935).withOpacity(0.2),
                        ),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.auto_awesome,
                              color: Color(0xFFE53935), size: 16),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Extraído del Plan de Gobierno',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFFE53935),
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  seguridadText,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: AppColors.textPrimary,
                                    height: 1.5,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              }

              // Si no hay sección específica, buscar keywords en el texto completo
              final normalizedText = textoCompleto.toLowerCase();
              final hasSecurityMentions =
                  keywords.any((k) => normalizedText.contains(k));

              if (hasSecurityMentions) {
                // Extraer fragmentos que mencionen seguridad
                final sentences = textoCompleto.split(RegExp(r'[.!?]\s+'));
                final securitySentences = sentences
                    .where(
                        (s) => keywords.any((k) => s.toLowerCase().contains(k)))
                    .take(3)
                    .toList();

                if (securitySentences.isNotEmpty) {
                  return Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceVariant,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.search,
                                color: AppColors.primary, size: 16),
                            SizedBox(width: 6),
                            Text(
                              'Menciones de seguridad encontradas',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: AppColors.primary,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        ...securitySentences.map((sentence) => Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: Text(
                                '• ${sentence.trim()}',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: AppColors.textPrimary,
                                  height: 1.4,
                                ),
                              ),
                            )),
                      ],
                    ),
                  );
                }
              }

              return Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.inviable.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.warning_amber_rounded,
                            color: AppColors.inviable, size: 20),
                        SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'No se detectaron propuestas específicas sobre seguridad ciudadana.',
                            style: TextStyle(
                                fontSize: 13,
                                color: AppColors.inviable,
                                height: 1.4,
                                fontWeight: FontWeight.w600),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Revisa el documento completo del plan de gobierno arriba.',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        );
      }

      return _SectionCard(
        icon: '🛡️',
        title: 'Seguridad Ciudadana',
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.inviable.withOpacity(0.08),
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.warning_amber_rounded,
                      color: AppColors.inviable, size: 20),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'No se encontraron propuestas específicas sobre seguridad en el análisis preliminar.',
                      style: TextStyle(
                          fontSize: 13,
                          color: AppColors.inviable,
                          height: 1.4,
                          fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 8),
              Text(
                'Revisa los documentos PDF del plan de gobierno arriba para ver todas las propuestas del candidato.',
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                  height: 1.3,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return _SectionCard(
      icon: '🛡️',
      title: 'Seguridad Ciudadana',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  const Color(0xFFE53935).withOpacity(0.08),
                  const Color(0xFFFF7043).withOpacity(0.08),
                ],
              ),
              borderRadius: BorderRadius.circular(10),
              border:
                  Border.all(color: const Color(0xFFE53935).withOpacity(0.2)),
            ),
            child: Row(
              children: [
                const Icon(Icons.shield, color: Color(0xFFE53935), size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    propSeguridad.isNotEmpty
                        ? '${propuestas.length} propuesta(s) directas sobre seguridad'
                        : '${propuestas.length} propuesta(s) institucionales (sin mención directa de seguridad)',
                    style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFFE53935)),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          ...propuestas.asMap().entries.map((entry) {
            final i = entry.key;
            final m = entry.value as Map<String, dynamic>;
            final problema = (m['txPgProblema'] as String? ?? '').trim();
            final objetivo = (m['txPgObjetivo'] as String? ?? '').trim();
            final meta = (m['txPgMeta'] as String? ?? '').trim();

            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.surfaceVariant,
                borderRadius: BorderRadius.circular(10),
                border: const Border(
                    left: BorderSide(color: Color(0xFFE53935), width: 3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Propuesta ${i + 1}',
                      style: const TextStyle(
                          fontSize: 10,
                          color: Color(0xFFE53935),
                          fontWeight: FontWeight.w700)),
                  if (problema.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    const Text('🔴 Problema identificado:',
                        style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textSecondary)),
                    const SizedBox(height: 2),
                    Text(problema,
                        style: const TextStyle(fontSize: 12, height: 1.4)),
                  ],
                  if (objetivo.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    const Text('🟢 ¿Qué propone hacer?',
                        style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: AppColors.viable)),
                    const SizedBox(height: 2),
                    Text(objetivo,
                        style: const TextStyle(fontSize: 12, height: 1.4)),
                  ],
                  if (meta.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    const Text('🎯 ¿Cómo lo medirán?',
                        style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: AppColors.accent)),
                    const SizedBox(height: 2),
                    Text(meta,
                        style: const TextStyle(
                            fontSize: 12,
                            height: 1.4,
                            fontStyle: FontStyle.italic,
                            color: AppColors.textSecondary)),
                  ],
                ],
              ),
            );
          }),
          const SizedBox(height: 4),
          const SourceTag(fuente: 'JNE — Plan de Gobierno 2026'),
        ],
      ),
    );
  }
}

// ─── Análisis Electoral IA ───────────────────────────────────────────────────

class _AnalisisElectoralSection extends ConsumerWidget {
  final String nombre;
  final String partido;
  final Map<String, dynamic> plan;
  final Map<String, dynamic> hv;

  const _AnalisisElectoralSection({
    required this.nombre,
    required this.partido,
    required this.plan,
    required this.hv,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dimensiones = plan['dimensiones'] as Map<String, dynamic>? ?? {};

    // Análisis IA asíncrono — se superpone al análisis JNE cuando está disponible
    final aiAsync = ref.watch(aiAnalisisCandidatoProvider(nombre));

    // Contar propuestas por dimensión
    final social = (dimensiones['Social'] as List?)?.length ?? 0;
    final economica = (dimensiones['Económica'] as List?)?.length ?? 0;
    final ambiental = (dimensiones['Ambiental'] as List?)?.length ?? 0;
    final institucional = (dimensiones['Institucional'] as List?)?.length ?? 0;
    final total = social + economica + ambiental + institucional;

    // Experiencia pública
    final cargos = (hv['cargosEleccion'] as List?)?.length ?? 0;
    final experiencia = (hv['experiencia'] as List?)?.length ?? 0;

    // Antecedentes
    final sentPen = (hv['sentenciasPenales'] as num?)?.toInt() ?? 0;
    final sentObl = (hv['sentenciasObligatorias'] as num?)?.toInt() ?? 0;
    final renuncias = (hv['renuncias'] as List?)?.length ?? 0;

    // Educación
    final educacion = (hv['educacion'] as List?) ?? [];
    final tienePosgrado =
        educacion.any((e) => (e as Map<String, dynamic>)['tipo'] == 'Posgrado');

    // Fortaleza principal
    final dimScores = {
      'Social': social,
      'Económica': economica,
      'Ambiental': ambiental,
      'Institucional': institucional,
    };
    final sorted = dimScores.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final fortaleza = sorted.first;
    final debilidad = sorted.last;

    // Construir análisis
    final parrafos = <_AnalisisItem>[];

    // 1. Resumen del plan
    if (total > 0) {
      final primer = nombre.split(' ').first;
      parrafos.add(_AnalisisItem(
        icon: Icons.description_outlined,
        color: AppColors.primary,
        titulo: 'Plan de Gobierno',
        texto: '$primer presenta $total propuestas distribuidas en: '
            'Social ($social), Económica ($economica), Ambiental ($ambiental), '
            'Institucional ($institucional). '
            '${fortaleza.value > 0 ? 'Su área más fuerte es ${fortaleza.key} con ${fortaleza.value} propuestas.' : ''} '
            '${debilidad.value == 0 ? '⚠️ No presenta propuestas en Dimensión ${debilidad.key}.' : ''}',
      ));
    } else {
      parrafos.add(_AnalisisItem(
        icon: Icons.warning_amber_rounded,
        color: AppColors.inviable,
        titulo: 'Plan de Gobierno',
        texto:
            'No se encontraron propuestas en el plan de gobierno registrado ante el JNE.',
      ));
    }

    // 2. Perfil del candidato
    final detalles = <String>[];
    if (cargos > 0) detalles.add('$cargos cargo(s) de elección popular');
    if (experiencia > 0)
      detalles.add('$experiencia experiencia(s) laboral(es) declarada(s)');
    if (tienePosgrado) detalles.add('formación de posgrado');
    parrafos.add(_AnalisisItem(
      icon: Icons.person_outline,
      color: AppColors.accent,
      titulo: 'Perfil',
      texto: detalles.isNotEmpty
          ? 'Cuenta con ${detalles.join(", ")}.'
          : 'No registra experiencia pública ni cargos de elección.',
    ));

    // 3. Alertas
    if (sentPen > 0 || sentObl > 0 || renuncias > 0) {
      final alertas = <String>[];
      if (sentPen > 0) alertas.add('$sentPen sentencia(s) penal(es)');
      if (sentObl > 0) alertas.add('$sentObl sentencia(s) obligatoria(s)');
      if (renuncias > 0) alertas.add('$renuncias renuncia(s) a partido(s)');
      parrafos.add(_AnalisisItem(
        icon: Icons.gavel,
        color: AppColors.inviable,
        titulo: 'Alertas',
        texto:
            'Registra: ${alertas.join(", ")}. Es importante verificar la naturaleza de cada caso.',
      ));
    } else {
      parrafos.add(_AnalisisItem(
        icon: Icons.check_circle_outline,
        color: AppColors.viable,
        titulo: 'Antecedentes',
        texto:
            'No registra sentencias penales, obligatorias ni renuncias a partidos políticos.',
      ));
    }

    // 4. Índice de solidez del plan
    String solidez;
    Color solidezColor;
    if (total >= 12) {
      solidez = 'Alto';
      solidezColor = AppColors.viable;
    } else if (total >= 6) {
      solidez = 'Medio';
      solidezColor = AppColors.doubtful;
    } else {
      solidez = 'Bajo';
      solidezColor = AppColors.inviable;
    }

    return _SectionCard(
      icon: '🤖',
      title: 'Análisis Electoral VotaClaro',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Solidez badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  solidezColor.withOpacity(0.12),
                  solidezColor.withOpacity(0.04),
                ],
              ),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: solidezColor.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                Icon(Icons.analytics, color: solidezColor, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Nivel de detalle del plan',
                          style: TextStyle(
                              fontSize: 11,
                              color: AppColors.textSecondary,
                              fontWeight: FontWeight.w600)),
                      Text(solidez,
                          style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: solidezColor)),
                    ],
                  ),
                ),
                Text('$total propuestas',
                    style: TextStyle(
                        fontSize: 12,
                        color: solidezColor,
                        fontWeight: FontWeight.w600)),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Párrafos de análisis
          ...parrafos.map((item) => Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: item.color.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(10),
                  border: Border(left: BorderSide(color: item.color, width: 3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(item.icon, size: 16, color: item.color),
                        const SizedBox(width: 6),
                        Text(item.titulo,
                            style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: item.color)),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(item.texto,
                        style: const TextStyle(fontSize: 12, height: 1.5)),
                  ],
                ),
              )),

          // ─ Análisis IA: pros, contras, análisis predictivo ─
          aiAsync.when(
            loading: () => Container(
              margin: const EdgeInsets.only(top: 4),
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.05),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Row(
                children: [
                  SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  SizedBox(width: 10),
                  Text(
                    'Generando análisis IA...',
                    style: TextStyle(
                        fontSize: 12, color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
            error: (_, __) => const SizedBox.shrink(),
            data: (ai) {
              if (ai.isEmpty) return const SizedBox.shrink();
              final pros =
                  (ai['pros'] as List?)?.cast<String>() ?? [];
              final contras =
                  (ai['contras'] as List?)?.cast<String>() ?? [];
              final analisis =
                  ai['analisisPredictivo'] as Map<String, dynamic>?;
              if (pros.isEmpty && contras.isEmpty && analisis == null) {
                return const SizedBox.shrink();
              }
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (pros.isNotEmpty) ...[
                    const Divider(height: 20),
                    Row(children: const [
                      Icon(Icons.thumb_up_outlined,
                          size: 15, color: AppColors.viable),
                      SizedBox(width: 6),
                      Text('Fortalezas',
                          style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: AppColors.viable)),
                    ]),
                    const SizedBox(height: 8),
                    ...pros.map((p) => Padding(
                          padding: const EdgeInsets.only(bottom: 5),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('🟢 ',
                                  style: TextStyle(fontSize: 12)),
                              Expanded(
                                  child: Text(p,
                                      style: const TextStyle(
                                          fontSize: 12, height: 1.4))),
                            ],
                          ),
                        )),
                  ],
                  if (contras.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Row(children: const [
                      Icon(Icons.thumb_down_outlined,
                          size: 15, color: AppColors.inviable),
                      SizedBox(width: 6),
                      Text('Debilidades',
                          style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: AppColors.inviable)),
                    ]),
                    const SizedBox(height: 8),
                    ...contras.map((c) => Padding(
                          padding: const EdgeInsets.only(bottom: 5),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('🔴 ',
                                  style: TextStyle(fontSize: 12)),
                              Expanded(
                                  child: Text(c,
                                      style: const TextStyle(
                                          fontSize: 12, height: 1.4))),
                            ],
                          ),
                        )),
                  ],
                  if (analisis != null) ...[
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.06),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                            color: AppColors.primary.withOpacity(0.2)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            children: [
                              Icon(Icons.auto_graph,
                                  size: 14, color: AppColors.primary),
                              SizedBox(width: 6),
                              Text('Análisis Predictivo IA',
                                  style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.primary)),
                            ],
                          ),
                          const SizedBox(height: 6),
                          if (analisis['probabilidadCumplimiento'] != null)
                            Text(
                              'Probabilidad de cumplimiento: ${analisis['probabilidadCumplimiento']}%',
                              style: const TextStyle(
                                  fontSize: 12, height: 1.4),
                            ),
                          if (analisis['justificacionRiesgo'] != null &&
                              (analisis['justificacionRiesgo'] as String)
                                  .isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Text(
                                analisis['justificacionRiesgo'] as String,
                                style: const TextStyle(
                                    fontSize: 11,
                                    color: AppColors.textSecondary,
                                    height: 1.4),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ],
              );
            },
          ),

          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.surfaceVariant,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Row(
              children: [
                Icon(Icons.info_outline,
                    size: 14, color: AppColors.textSecondary),
                SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Análisis generado automáticamente a partir de los datos oficiales del JNE. No constituye recomendación de voto.',
                    style: TextStyle(
                        fontSize: 10,
                        color: AppColors.textSecondary,
                        fontStyle: FontStyle.italic),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 4),
          const SourceTag(fuente: 'VotaClaro IA — Datos JNE 2026'),
        ],
      ),
    );
  }
}

class _AnalisisItem {
  final IconData icon;
  final Color color;
  final String titulo;
  final String texto;

  const _AnalisisItem({
    required this.icon,
    required this.color,
    required this.titulo,
    required this.texto,
  });
}

// ─── Resumen Analítico (collapsible cards at top) ────────────────────────────

class _ResumenAnaliticoSection extends StatelessWidget {
  final String nombre;
  final String partido;
  final Map<String, dynamic>? plan;
  final Map<String, dynamic> hv;

  const _ResumenAnaliticoSection({
    required this.nombre,
    required this.partido,
    required this.plan,
    required this.hv,
  });

  @override
  Widget build(BuildContext context) {
    final primer = nombre.split(' ').first;
    final dimensiones = (plan?['dimensiones'] as Map<String, dynamic>?) ?? {};
    final social = (dimensiones['Social'] as List?)?.length ?? 0;
    final economica = (dimensiones['Económica'] as List?)?.length ?? 0;
    final ambiental = (dimensiones['Ambiental'] as List?)?.length ?? 0;
    final institucional = (dimensiones['Institucional'] as List?)?.length ?? 0;
    final total = social + economica + ambiental + institucional;

    final cargos = (hv['cargosEleccion'] as List?)?.length ?? 0;
    final experiencia = (hv['experiencia'] as List?)?.length ?? 0;
    final sentPen = (hv['sentenciasPenales'] as num?)?.toInt() ?? 0;
    final sentObl = (hv['sentenciasObligatorias'] as num?)?.toInt() ?? 0;
    final renuncias = (hv['renuncias'] as List?)?.length ?? 0;
    final educacion = (hv['educacion'] as List?) ?? [];
    final tienePosgrado =
        educacion.any((e) => (e as Map)['tipo'] == 'Posgrado');

    // Patrimonio para riesgo de corrupción
    final ingresoPublico = (hv['ingresoPublico'] as num?)?.toDouble() ?? 0;
    final ingresoPrivado = (hv['ingresoPrivado'] as num?)?.toDouble() ?? 0;
    double totalBienes = 0;
    for (final b in (hv['bienesMueble'] as List? ?? [])) {
      totalBienes += ((b as Map)['valor'] as num?)?.toDouble() ?? 0;
    }
    for (final b in (hv['bienesInmueble'] as List? ?? [])) {
      totalBienes += ((b as Map)['valor'] as num?)?.toDouble() ?? 0;
    }
    final patrimonioTotal = ingresoPublico + ingresoPrivado + totalBienes;

    // ── Calcular métricas ──
    final riesgo =
        _calcRiesgo(sentPen, sentObl, renuncias, total, patrimonioTotal);
    final cumplimiento = _calcCumplimiento(dimensiones, total);
    final enfoque = _calcEnfoque(social, economica, ambiental, institucional);
    final escenario = _buildEscenario(primer, enfoque, total, cargos, sentPen);
    final presPeruano =
        _presidentePeruano(social, economica, ambiental, institucional);
    final presInternacional =
        _presidenteInternacional(social, economica, ambiental, institucional);

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Column(
          children: [
            // Title bar
            Container(
              padding: const EdgeInsets.all(14),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppColors.primary, AppColors.primaryDark],
                ),
                borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.psychology, color: Colors.white, size: 22),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Text('Análisis VotaClaro',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w700)),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text('$total propuestas',
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w600)),
                  ),
                ],
              ),
            ),

            // ── Riesgo ──
            _CollapsibleTile(
              icon: Icons.warning_amber_rounded,
              color: riesgo.color,
              title: 'Nivel de Riesgo',
              badge: riesgo.label,
              badgeColor: riesgo.color,
              content: riesgo.detalle,
            ),

            const Divider(height: 1),

            // ── Qué pasaría si gana ──
            _CollapsibleTile(
              icon: Icons.how_to_vote,
              color: AppColors.accent,
              title: '¿Qué pasaría si gana?',
              badge: enfoque.primario,
              badgeColor: AppColors.accent,
              content: escenario,
            ),

            const Divider(height: 1),

            // ── Cumplimiento ──
            _CollapsibleTile(
              icon: Icons.fact_check,
              color: cumplimiento.color,
              title: 'Cumplimiento estimado',
              badge: '${cumplimiento.porcentaje}%',
              badgeColor: cumplimiento.color,
              content: cumplimiento.detalle,
            ),

            const Divider(height: 1),

            // ── Enfoque ──
            _CollapsibleTile(
              icon: Icons.center_focus_strong,
              color: AppColors.primary,
              title: 'Enfoque político',
              badge: enfoque.primario,
              badgeColor: AppColors.primary,
              content: enfoque.detalle,
            ),

            const Divider(height: 1),

            // ── Presidente peruano similar ──
            _CollapsibleTile(
              icon: Icons.flag,
              color: const Color(0xFFD32F2F),
              title: 'Presidente peruano similar',
              badge: presPeruano.nombre,
              badgeColor: const Color(0xFFD32F2F),
              content: presPeruano.detalle,
            ),

            const Divider(height: 1),

            // ── Referente internacional ──
            _CollapsibleTile(
              icon: Icons.public,
              color: const Color(0xFF1565C0),
              title: 'Referente internacional',
              badge: presInternacional.nombre,
              badgeColor: const Color(0xFF1565C0),
              content: presInternacional.detalle,
            ),

            // Footer
            Container(
              padding: const EdgeInsets.all(10),
              decoration: const BoxDecoration(
                color: AppColors.surfaceVariant,
                borderRadius:
                    BorderRadius.vertical(bottom: Radius.circular(16)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.info_outline,
                      size: 12, color: AppColors.textSecondary),
                  SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Análisis generado por VotaClaro a partir de datos oficiales JNE. No constituye recomendación de voto.',
                      style: TextStyle(
                          fontSize: 9,
                          color: AppColors.textSecondary,
                          fontStyle: FontStyle.italic),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Helpers de cálculo ──

  _RiesgoData _calcRiesgo(
      int sentPen, int sentObl, int renuncias, int totalProps, double patrimonio) {
    int score = 0;
    final razones = <String>[];

    if (sentPen > 0) {
      score += 3;
      razones.add('$sentPen sentencia(s) penal(es) declarada(s)');
    }
    if (sentObl > 0) {
      score += 2;
      razones.add('$sentObl sentencia(s) obligatoria(s)');
    }
    if (renuncias >= 2) {
      score += 2;
      razones.add('$renuncias renuncias a partidos (inestabilidad partidaria)');
    } else if (renuncias == 1) {
      score += 1;
      razones.add('$renuncias renuncia a partido');
    }
    if (totalProps < 3) {
      score += 2;
      razones.add('Muy pocas propuestas registradas ($totalProps)');
    } else if (totalProps < 6) {
      score += 1;
      razones.add(
          'Plan de gobierno con detalle limitado ($totalProps propuestas)');
    }

    // Patrimonio: valores extremos pueden indicar riesgo
    if (patrimonio > 0) {
      if (patrimonio > 5000000) {
        // >5M soles — patrimonio muy alto, mayor exposición
        score += 1;
        razones.add('Patrimonio declarado elevado (S/ ${_fmtPatrimonio(patrimonio)}) — mayor exposición a conflictos de interés');
      }
      // Patrimonio normal o bajo no suma riesgo
    } else if (totalProps > 0) {
      // Sin declarar patrimonio teniendo plan
      razones.add('Sin patrimonio declarado o S/ 0');
    }

    if (razones.isEmpty) {
      razones.add('Sin antecedentes negativos significativos');
    }

    Color color;
    String label;
    if (score >= 5) {
      label = 'ALTO';
      color = AppColors.inviable;
    } else if (score >= 3) {
      label = 'MEDIO';
      color = AppColors.doubtful;
    } else {
      label = 'BAJO';
      color = AppColors.viable;
    }

    return _RiesgoData(
      label: label,
      color: color,
      detalle: razones.join('\n• ').replaceRange(0, 0, '• '),
    );
  }

  String _fmtPatrimonio(double amount) {
    if (amount >= 1e6) return '${(amount / 1e6).toStringAsFixed(1)}M';
    if (amount >= 1e3) return '${(amount / 1e3).toStringAsFixed(0)}K';
    return amount.toStringAsFixed(0);
  }

  _CumplimientoData _calcCumplimiento(Map<String, dynamic> dims, int total) {
    if (total == 0) {
      return _CumplimientoData(
        porcentaje: 0,
        color: AppColors.inviable,
        detalle: 'Sin propuestas registradas en el plan de gobierno. '
            'No es posible estimar cumplimiento.',
      );
    }

    int conMeta = 0;
    int conObjetivo = 0;
    for (final entry in dims.entries) {
      for (final item in (entry.value as List? ?? [])) {
        final m = item as Map<String, dynamic>;
        if ((m['txPgMeta'] as String? ?? '').trim().isNotEmpty) conMeta++;
        if ((m['txPgObjetivo'] as String? ?? '').trim().isNotEmpty) {
          conObjetivo++;
        }
      }
    }

    // Score: metas (medibles) pesan más que solo objetivos
    final metaPct = total > 0 ? (conMeta / total * 100).round() : 0;
    final objPct = total > 0 ? (conObjetivo / total * 100).round() : 0;

    // Estimación basada en especificidad
    int pct = ((metaPct * 0.6) + (objPct * 0.3) + (total > 8 ? 10 : 0))
        .round()
        .clamp(5, 75);

    Color color;
    if (pct >= 50) {
      color = AppColors.viable;
    } else if (pct >= 30) {
      color = AppColors.doubtful;
    } else {
      color = AppColors.inviable;
    }

    return _CumplimientoData(
      porcentaje: pct,
      color: color,
      detalle: '$conMeta de $total propuestas tienen metas medibles '
          '($metaPct%).\n'
          '$conObjetivo de $total tienen objetivos claros ($objPct%).\n\n'
          'Estimación: Un plan con metas específicas y medibles tiene mayor '
          'probabilidad de cumplimiento. '
          '${pct >= 50 ? "Este plan presenta buena especificidad." : pct >= 30 ? "Plan con especificidad moderada." : "Plan poco específico — difícil de medir."}',
    );
  }

  _EnfoqueData _calcEnfoque(int social, int econ, int ambient, int instit) {
    final dims = {
      'Social': social,
      'Económico': econ,
      'Ambiental': ambient,
      'Institucional': instit,
    };
    final sorted = dims.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final primario = sorted[0];
    final secundario = sorted[1];
    final debil = sorted.last;

    final total = social + econ + ambient + instit;
    String detalle;
    if (total == 0) {
      detalle = 'No se puede determinar el enfoque por falta de propuestas.';
    } else {
      detalle = 'Enfoque principal: ${primario.key} '
          '(${primario.value} propuestas, ${(primario.value / total * 100).round()}%).\n'
          'Enfoque secundario: ${secundario.key} '
          '(${secundario.value} propuestas).\n';
      if (debil.value == 0) {
        detalle += '\n⚠️ Sin propuestas en Dimensión ${debil.key}.';
      }
    }

    return _EnfoqueData(primario: primario.key, detalle: detalle);
  }

  String _buildEscenario(
      String primer, _EnfoqueData enfoque, int total, int cargos, int sentPen) {
    final buf = StringBuffer();

    if (total == 0) {
      buf.write(
          'No es posible proyectar un escenario sin propuestas de gobierno.');
      return buf.toString();
    }

    buf.write('Si $primer llegara a la presidencia, su gobierno se '
        'enfocaría primarily en la dimensión ${enfoque.primario}. ');

    if (enfoque.primario == 'Social') {
      buf.write('Se esperarían políticas orientadas a salud, educación '
          'y programas sociales. ');
    } else if (enfoque.primario == 'Económico') {
      buf.write('Se priorizarían políticas de inversión, empleo y '
          'crecimiento económico. ');
    } else if (enfoque.primario == 'Institucional') {
      buf.write('Se esperarían reformas en seguridad, justicia y '
          'fortalecimiento institucional. ');
    } else {
      buf.write('Se priorizarían políticas ambientales, recursos '
          'naturales y sostenibilidad. ');
    }

    if (cargos > 0) {
      buf.write('Tiene experiencia previa en cargos públicos ($cargos), '
          'lo que sugiere conocimiento del aparato estatal. ');
    } else {
      buf.write('Sin experiencia previa en cargos de elección, enfrenta '
          'una curva de aprendizaje institucional. ');
    }

    if (sentPen > 0) {
      buf.write('\n\n⚠️ Los antecedentes penales declarados podrían '
          'generar controversia y obstaculizar gobernabilidad.');
    }

    return buf.toString();
  }

  _PresidenteData _presidentePeruano(
      int social, int econ, int ambient, int instit) {
    final total = social + econ + ambient + instit;
    if (total == 0) {
      return const _PresidenteData(
        nombre: 'Sin data',
        detalle: 'No se puede establecer similitud sin propuestas de gobierno.',
      );
    }

    // Determinar perfil dominante
    final max = [social, econ, ambient, instit].reduce((a, b) => a > b ? a : b);

    if (max == instit && instit > 0) {
      return const _PresidenteData(
        nombre: 'Martín Vizcarra',
        detalle: 'Enfoque institucional predominante: reformas anticorrupción, '
            'fortalecimiento del Estado de derecho y seguridad. Vizcarra (2018-2020) '
            'priorizó la reforma judicial y la lucha anticorrupción, disolviendo '
            'el Congreso en 2019 para impulsar cambios institucionales.',
      );
    } else if (max == social && social > 0) {
      return const _PresidenteData(
        nombre: 'Ollanta Humala',
        detalle: 'Enfoque social predominante: programas de inclusión, salud '
            'y educación. Humala (2011-2016) gobernó con énfasis en programas '
            'sociales como Pensión 65, Beca 18 y Qali Warma, ampliando la '
            'cobertura de servicios públicos.',
      );
    } else if (max == econ && econ > 0) {
      return const _PresidenteData(
        nombre: 'Pedro Pablo Kuczynski',
        detalle:
            'Enfoque económico predominante: inversión, empleo y crecimiento. '
            'PPK (2016-2018) impulsó una agenda pro-mercado con destrabe de '
            'inversiones, formalización económica y grandes obras de infraestructura.',
      );
    } else {
      return const _PresidenteData(
        nombre: 'Alejandro Toledo',
        detalle: 'Perfil con énfasis ambiental y desarrollo sostenible. '
            'Toledo (2001-2006) firmó tratados ambientales e impulsó la '
            'descentralización, con un enfoque en el desarrollo regional '
            'y la conservación de recursos naturales.',
      );
    }
  }

  _PresidenteData _presidenteInternacional(
      int social, int econ, int ambient, int instit) {
    final total = social + econ + ambient + instit;
    if (total == 0) {
      return const _PresidenteData(
        nombre: 'Sin data',
        detalle: 'No se puede establecer similitud sin propuestas de gobierno.',
      );
    }

    final max = [social, econ, ambient, instit].reduce((a, b) => a > b ? a : b);

    if (max == instit && instit > 0) {
      return const _PresidenteData(
        nombre: 'Michelle Bachelet (Chile)',
        detalle: 'Enfoque institucional: reformas estructurales al Estado. '
            'Bachelet priorizó reformas constitucionales, educativas y '
            'tributarias. Su agenda buscó fortalecer las instituciones '
            'democráticas y la igualdad ante la ley.',
      );
    } else if (max == social && social > 0) {
      return const _PresidenteData(
        nombre: 'Lula da Silva (Brasil)',
        detalle:
            'Énfasis social: reducción de pobreza y programas de inclusión. '
            'Lula implementó Bolsa Família, amplió el acceso a educación '
            'superior y sacó a millones de brasileños de la pobreza '
            'con políticas sociales a gran escala.',
      );
    } else if (max == econ && econ > 0) {
      return const _PresidenteData(
        nombre: 'Emmanuel Macron (Francia)',
        detalle:
            'Perfil pro-mercado: inversión, competitividad y modernización '
            'económica. Macron impulsó reformas laborales, fiscales y '
            'de pensiones orientadas a dinamizar la economía y atraer inversión.',
      );
    } else {
      return const _PresidenteData(
        nombre: 'José Mujica (Uruguay)',
        detalle: 'Enfoque en sostenibilidad y medioambiente. Mujica promovió '
            'energías renovables (Uruguay llegó a 98% de energía limpia), '
            'políticas ambientales innovadoras y un estilo de gobierno '
            'austero y cercano al pueblo.',
      );
    }
  }
}

class _CollapsibleTile extends StatefulWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String badge;
  final Color badgeColor;
  final String content;

  const _CollapsibleTile({
    required this.icon,
    required this.color,
    required this.title,
    required this.badge,
    required this.badgeColor,
    required this.content,
  });

  @override
  State<_CollapsibleTile> createState() => _CollapsibleTileState();
}

class _CollapsibleTileState extends State<_CollapsibleTile> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        InkWell(
          onTap: () => setState(() => _expanded = !_expanded),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                Icon(widget.icon, size: 18, color: widget.color),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(widget.title,
                      style: const TextStyle(
                          fontSize: 13, fontWeight: FontWeight.w600)),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: widget.badgeColor.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(widget.badge,
                      style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: widget.badgeColor)),
                ),
                const SizedBox(width: 6),
                Icon(
                  _expanded ? Icons.expand_less : Icons.expand_more,
                  size: 18,
                  color: AppColors.textSecondary,
                ),
              ],
            ),
          ),
        ),
        if (_expanded)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(42, 0, 14, 12),
            child: Text(widget.content,
                style: const TextStyle(
                    fontSize: 12, color: AppColors.textSecondary, height: 1.5)),
          ),
      ],
    );
  }
}

// ── Data classes ──

class _RiesgoData {
  final String label;
  final Color color;
  final String detalle;
  const _RiesgoData(
      {required this.label, required this.color, required this.detalle});
}

class _CumplimientoData {
  final int porcentaje;
  final Color color;
  final String detalle;
  const _CumplimientoData(
      {required this.porcentaje, required this.color, required this.detalle});
}

class _EnfoqueData {
  final String primario;
  final String detalle;
  const _EnfoqueData({required this.primario, required this.detalle});
}

class _PresidenteData {
  final String nombre;
  final String detalle;
  const _PresidenteData({required this.nombre, required this.detalle});
}
