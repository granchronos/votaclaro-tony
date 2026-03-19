import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../core/l10n/app_l10n.dart';
import '../../core/services/providers.dart';
import '../../widgets/common/widgets.dart';

class CompararScreen extends ConsumerStatefulWidget {
  const CompararScreen({super.key});

  @override
  ConsumerState<CompararScreen> createState() => _CompararScreenState();
}

class _CompararScreenState extends ConsumerState<CompararScreen> {
  String? _candidatoA;
  String? _candidatoB;
  bool _isQuerying = false;
  Map<String, dynamic>? _resultado;
  String? _error;

  @override
  Widget build(BuildContext context) {
    final t = ref.watch(translationsProvider);
    final candidatosAsync = ref.watch(candidatosPresidenteProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(t.compararTitle),
        actions: const [FontSizeAdjuster(), LanguageSelectorButton()],
      ),
      body: candidatosAsync.when(
        data: (candidatos) {
          final nombres = candidatos
              .map((c) => '${c['nombreCompleto']} — ${c['partido']}')
              .toList();

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              const NeutralidadBanner(),
              const SizedBox(height: 16),

              // Selector A
              _SelectorCard(
                label: '🔴 Candidato A',
                value: _candidatoA,
                opciones: nombres.where((c) => c != _candidatoB).toList(),
                onChanged: (v) => setState(() => _candidatoA = v),
                color: AppColors.primary,
              ),

              // VS divider
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Row(
                  children: [
                    const Expanded(child: Divider()),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [AppColors.primary, AppColors.accent],
                        ),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text(
                        'VS',
                        style: TextStyle(
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                            fontSize: 16),
                      ),
                    ),
                    const Expanded(child: Divider()),
                  ],
                ),
              ),

              // Selector B
              _SelectorCard(
                label: '🔵 Candidato B',
                value: _candidatoB,
                opciones: nombres.where((c) => c != _candidatoA).toList(),
                onChanged: (v) => setState(() => _candidatoB = v),
                color: AppColors.accent,
              ),

              const SizedBox(height: 20),

              SizedBox(
                height: 48,
                child: ElevatedButton.icon(
                  onPressed: (_candidatoA != null && _candidatoB != null)
                      ? _ejecutarComparacion
                      : null,
                  icon: _isQuerying
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.compare_arrows),
                  label: Text(_isQuerying ? t.analizandoIA : t.compararBtn),
                ),
              ),

              if (_error != null)
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Text(_error!,
                      style: const TextStyle(color: AppColors.inviable)),
                ),

              if (_resultado != null) ...[
                const SizedBox(height: 24),
                _ResultadoComparacion(
                  resultado: _resultado!,
                  nombreA:
                      (_candidatoA?.split(' — ').first ?? '').split(' ').first,
                  nombreB:
                      (_candidatoB?.split(' — ').first ?? '').split(' ').first,
                ),
              ],
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => Center(child: Text(t.errorGeneral)),
      ),
    );
  }

  /// Las 4 dimensiones reales del Plan de Gobierno JNE.
  static const List<MapEntry<String, String>> _jneDimensiones = [
    MapEntry('dimensionInstitucional', 'Institucional / Seguridad'),
    MapEntry('dimensionSocial', 'Social'),
    MapEntry('dimensionEconomica', 'Económica'),
    MapEntry('dimensionAmbiental', 'Ambiental'),
  ];

  Future<void> _ejecutarComparacion() async {
    setState(() {
      _isQuerying = true;
      _error = null;
      _resultado = null;
    });

    try {
      final jne = ref.read(jneApiServiceProvider);
      final supa = ref.read(supabaseServiceProvider);
      final candidatos = await ref.read(candidatosPresidenteProvider.future);

      final nameA = _candidatoA!.split(' — ').first;
      final nameB = _candidatoB!.split(' — ').first;

      final candA = candidatos.firstWhere((c) => c['nombreCompleto'] == nameA,
          orElse: () => <String, dynamic>{});
      final candB = candidatos.firstWhere((c) => c['nombreCompleto'] == nameB,
          orElse: () => <String, dynamic>{});

      final idOpA = candA['idOrganizacionPolitica'] as int? ?? 0;
      final idOpB = candB['idOrganizacionPolitica'] as int? ?? 0;

      // Edad
      final edadA = (candA['edad'] as num?)?.toInt() ?? 0;
      final edadB = (candB['edad'] as num?)?.toInt() ?? 0;

      // ── Fetch plans: Supabase cache first, then JNE API ──
      Future<Map<String, dynamic>> _fetchPlanDetalle(int idOP) async {
        if (idOP <= 0) return {};

        // L1: Supabase cache
        final cached = await supa.getCachedPlan(idOP);
        if (cached != null && cached.isNotEmpty) return cached;

        // L2: API call
        final planMeta =
            await jne.getPlanGobierno(idOP).catchError((_) => null);
        final idPlan = (planMeta?['idPlanGobierno'] as int?) ?? 0;
        if (idPlan <= 0) return {};

        final detalle = await jne
            .getPlanGobiernoDetalle(idPlan)
            .catchError((_) => <String, dynamic>{});

        // Persistir en Supabase para futuras consultas
        if (detalle.isNotEmpty) {
          supa.cachePlan(idOP, detalle);
        }
        return detalle;
      }

      final detalles = await Future.wait([
        _fetchPlanDetalle(idOpA),
        _fetchPlanDetalle(idOpB),
      ]);

      final detalleA = detalles[0];
      final detalleB = detalles[1];

      // ── Fetch enriched profile data for patrimony ──
      Future<Map<String, dynamic>> _fetchHojaVida(
          Map<String, dynamic> cand) async {
        final dni = cand['dni'] as String? ?? '';
        final idOP = cand['idOrganizacionPolitica'] as int? ?? 0;
        if (dni.isEmpty || idOP <= 0) return {};
        try {
          final hv = await jne.getHojaVida(dni, idOP);
          return hv['data'] as Map<String, dynamic>? ?? {};
        } catch (_) {
          return {};
        }
      }

      final hojas = await Future.wait([
        _fetchHojaVida(candA),
        _fetchHojaVida(candB),
      ]);
      final hvA = hojas[0];
      final hvB = hojas[1];

      // Patrimonio
      final patrimonioA = _calcPatrimonio(hvA);
      final patrimonioB = _calcPatrimonio(hvB);

      // Antecedentes
      final sentPenA = (hvA['lSentenciaPenal'] as List?)?.length ?? 0;
      final sentPenB = (hvB['lSentenciaPenal'] as List?)?.length ?? 0;
      final sentOblA = (hvA['lSentenciaObliga'] as List?)?.length ?? 0;
      final sentOblB = (hvB['lSentenciaObliga'] as List?)?.length ?? 0;
      final renunciasA = (hvA['lRenunciaOP'] as List?)?.length ?? 0;
      final renunciasB = (hvB['lRenunciaOP'] as List?)?.length ?? 0;

      // Track comparison analytics
      supa.trackComparison(nameA, nameB);

      // Build per-dimension comparison with actual proposal data
      final dimensiones = <String, dynamic>{};
      int totalA = 0, totalB = 0;
      final strongA = <String>[];
      final strongB = <String>[];

      for (final dim in _jneDimensiones) {
        final listA = (detalleA[dim.key] as List?) ?? [];
        final listB = (detalleB[dim.key] as List?) ?? [];
        totalA += listA.length;
        totalB += listB.length;

        final propsA = listA
            .map((p) => {
                  'problema': (p['txPgProblema'] ?? '').toString().trim(),
                  'objetivo': (p['txPgObjetivo'] ?? '').toString().trim(),
                  'meta': (p['txPgMeta'] ?? '').toString().trim(),
                })
            .toList();
        final propsB = listB
            .map((p) => {
                  'problema': (p['txPgProblema'] ?? '').toString().trim(),
                  'objetivo': (p['txPgObjetivo'] ?? '').toString().trim(),
                  'meta': (p['txPgMeta'] ?? '').toString().trim(),
                })
            .toList();

        dimensiones[dim.value] = {
          'propuestasA': propsA,
          'propuestasB': propsB,
          'countA': listA.length,
          'countB': listB.length,
        };

        if (listA.length - listB.length >= 2) strongA.add(dim.value);
        if (listB.length - listA.length >= 2) strongB.add(dim.value);
      }

      // Generate analytical summary with extensive analysis
      final nombreCortoA = nameA.split(' ').first;
      final nombreCortoB = nameB.split(' ').first;

      // Keyword analysis per dimension
      final keywordThemes = <String, Map<String, List<String>>>{};
      for (final dim in _jneDimensiones) {
        final listA = (detalleA[dim.key] as List?) ?? [];
        final listB = (detalleB[dim.key] as List?) ?? [];
        final themesA = _extractThemes(listA);
        final themesB = _extractThemes(listB);
        keywordThemes[dim.value] = {'A': themesA, 'B': themesB};
      }

      // Determine enfoque
      final enfoqueA = _getEnfoque(detalleA);
      final enfoqueB = _getEnfoque(detalleB);

      // Ventajas / Desventajas
      final ventajasA = <String>[];
      final ventajasB = <String>[];
      final desventajasA = <String>[];
      final desventajasB = <String>[];

      for (final dim in _jneDimensiones) {
        final listA = (detalleA[dim.key] as List?) ?? [];
        final listB = (detalleB[dim.key] as List?) ?? [];
        if (listA.length >= listB.length + 2) {
          ventajasA.add(
              'Más propuestas en ${dim.value} (${listA.length} vs ${listB.length})');
        }
        if (listB.length >= listA.length + 2) {
          ventajasB.add(
              'Más propuestas en ${dim.value} (${listB.length} vs ${listA.length})');
        }
        if (listA.isEmpty && listB.isNotEmpty) {
          desventajasA.add('Sin propuestas en ${dim.value}');
        }
        if (listB.isEmpty && listA.isNotEmpty) {
          desventajasB.add('Sin propuestas en ${dim.value}');
        }
      }

      // Specificity analysis: how many proposals have measurable goals
      int metasA = 0, metasB = 0;
      for (final dim in _jneDimensiones) {
        for (final p in (detalleA[dim.key] as List?) ?? []) {
          if ((p['txPgMeta'] ?? '').toString().trim().isNotEmpty) metasA++;
        }
        for (final p in (detalleB[dim.key] as List?) ?? []) {
          if ((p['txPgMeta'] ?? '').toString().trim().isNotEmpty) metasB++;
        }
      }

      // Build richer analytical summary
      final buf = StringBuffer();
      buf.writeln('📊 RESUMEN COMPARATIVO');
      buf.writeln('');
      if (edadA > 0 || edadB > 0) {
        buf.writeln('👤 PERFIL');
        if (edadA > 0) buf.writeln('▸ $nombreCortoA: $edadA años');
        if (edadB > 0) buf.writeln('▸ $nombreCortoB: $edadB años');
        buf.writeln('');
      }
      buf.writeln(
          '▸ $nombreCortoA presenta $totalA propuestas con enfoque $enfoqueA.');
      buf.writeln(
          '▸ $nombreCortoB presenta $totalB propuestas con enfoque $enfoqueB.');
      buf.writeln('');

      if (strongA.isNotEmpty) {
        buf.writeln('✅ $nombreCortoA destaca en: ${strongA.join(", ")}.');
      }
      if (strongB.isNotEmpty) {
        buf.writeln('✅ $nombreCortoB destaca en: ${strongB.join(", ")}.');
      }

      buf.writeln('');
      buf.writeln('📏 ESPECIFICIDAD DE PROPUESTAS');
      if (totalA > 0) {
        buf.writeln(
            '▸ $nombreCortoA: $metasA de $totalA con metas medibles (${totalA > 0 ? (metasA * 100 ~/ totalA) : 0}%)');
      }
      if (totalB > 0) {
        buf.writeln(
            '▸ $nombreCortoB: $metasB de $totalB con metas medibles (${totalB > 0 ? (metasB * 100 ~/ totalB) : 0}%)');
      }

      // Patrimonio
      if (patrimonioA.total > 0 || patrimonioB.total > 0) {
        buf.writeln('');
        buf.writeln('💰 PATRIMONIO DECLARADO');
        if (patrimonioA.total > 0) {
          buf.writeln(
              '▸ $nombreCortoA: S/ ${_fmtMoney(patrimonioA.total)} (Ing: S/ ${_fmtMoney(patrimonioA.ingresos)}, Bienes: S/ ${_fmtMoney(patrimonioA.bienes)})');
        }
        if (patrimonioB.total > 0) {
          buf.writeln(
              '▸ $nombreCortoB: S/ ${_fmtMoney(patrimonioB.total)} (Ing: S/ ${_fmtMoney(patrimonioB.ingresos)}, Bienes: S/ ${_fmtMoney(patrimonioB.bienes)})');
        }
      }

      // Antecedentes comparison
      if (sentPenA > 0 || sentPenB > 0 || sentOblA > 0 || sentOblB > 0) {
        buf.writeln('');
        buf.writeln('⚖️ ANTECEDENTES');
        if (sentPenA > 0) {
          buf.writeln('▸ $nombreCortoA: $sentPenA sentencia(s) penal(es)');
        }
        if (sentPenB > 0) {
          buf.writeln('▸ $nombreCortoB: $sentPenB sentencia(s) penal(es)');
        }
      }

      if (ventajasA.isNotEmpty || ventajasB.isNotEmpty) {
        buf.writeln('');
        buf.writeln('💪 VENTAJAS COMPARATIVAS');
        for (final v in ventajasA) {
          buf.writeln('▸ $nombreCortoA: $v');
        }
        for (final v in ventajasB) {
          buf.writeln('▸ $nombreCortoB: $v');
        }
      }

      if (desventajasA.isNotEmpty || desventajasB.isNotEmpty) {
        buf.writeln('');
        buf.writeln('⚠️ ÁREAS SIN COBERTURA');
        for (final d in desventajasA) {
          buf.writeln('▸ $nombreCortoA: $d');
        }
        for (final d in desventajasB) {
          buf.writeln('▸ $nombreCortoB: $d');
        }
      }

      buf.writeln('');
      buf.write('[Fuente: Plan de Gobierno JNE 2026]');

      setState(() {
        _resultado = {
          'dimensiones': dimensiones,
          'totalA': totalA,
          'totalB': totalB,
          'resumenComparacion': buf.toString(),
          'enfoqueA': enfoqueA,
          'enfoqueB': enfoqueB,
          'metasA': metasA,
          'metasB': metasB,
          'ventajasA': ventajasA,
          'ventajasB': ventajasB,
          'desventajasA': desventajasA,
          'desventajasB': desventajasB,
          'keywordThemes': keywordThemes,
          'edadA': edadA,
          'edadB': edadB,
          'patrimonioA': patrimonioA,
          'patrimonioB': patrimonioB,
          'sentPenA': sentPenA,
          'sentPenB': sentPenB,
          'sentOblA': sentOblA,
          'sentOblB': sentOblB,
          'renunciasA': renunciasA,
          'renunciasB': renunciasB,
        };
        _isQuerying = false;
      });
    } catch (e) {
      setState(() {
        _error = ref.read(translationsProvider).errorGeneral;
        _isQuerying = false;
      });
    }
  }

  /// Extract key themes from a list of proposals
  List<String> _extractThemes(List proposals) {
    final themes = <String>{};
    final keywords = {
      'seguridad': 'Seguridad',
      'salud': 'Salud',
      'educac': 'Educación',
      'empleo': 'Empleo',
      'econom': 'Economía',
      'corrupc': 'Anticorrupción',
      'ambient': 'Medio ambiente',
      'infraestruct': 'Infraestructura',
      'tecnolog': 'Tecnología',
      'agr': 'Agricultura',
      'mujer': 'Género',
      'descentraliz': 'Descentralización',
      'justicia': 'Justicia',
      'transport': 'Transporte',
      'vivienda': 'Vivienda',
      'turismo': 'Turismo',
      'agua': 'Recursos hídricos',
      'miner': 'Minería',
      'digital': 'Digitalización',
    };
    for (final p in proposals) {
      final text = [
        (p['txPgProblema'] ?? '').toString(),
        (p['txPgObjetivo'] ?? '').toString(),
      ].join(' ').toLowerCase();
      for (final entry in keywords.entries) {
        if (text.contains(entry.key)) themes.add(entry.value);
      }
    }
    return themes.take(5).toList();
  }

  /// Determine the main enfoque from plan data
  String _getEnfoque(Map<String, dynamic> detalle) {
    final counts = {
      'Social': ((detalle['dimensionSocial'] as List?) ?? []).length,
      'Económico': ((detalle['dimensionEconomica'] as List?) ?? []).length,
      'Ambiental': ((detalle['dimensionAmbiental'] as List?) ?? []).length,
      'Institucional':
          ((detalle['dimensionInstitucional'] as List?) ?? []).length,
    };
    final sorted = counts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    if (sorted.first.value == 0) return 'indefinido';
    return sorted.first.key;
  }

  _PatrimonioData _calcPatrimonio(Map<String, dynamic> hv) {
    double ingresos = 0;
    double bienes = 0;
    final ing = hv['oIngresos'] as Map<String, dynamic>? ?? {};
    ingresos += (ing['decRemuBrutaPublico'] as num?)?.toDouble() ?? 0;
    ingresos += (ing['decRemuBrutaPrivado'] as num?)?.toDouble() ?? 0;
    for (final b in (hv['lBienMueble'] as List? ?? [])) {
      bienes += ((b as Map)['decValor'] as num?)?.toDouble() ?? 0;
    }
    for (final b in (hv['lBienInmueble'] as List? ?? [])) {
      bienes += ((b as Map)['decAutoavaluo'] as num?)?.toDouble() ?? 0;
    }
    return _PatrimonioData(ingresos: ingresos, bienes: bienes);
  }

  String _fmtMoney(double amount) {
    if (amount >= 1e6) return '${(amount / 1e6).toStringAsFixed(1)}M';
    if (amount >= 1e3) return '${(amount / 1e3).toStringAsFixed(0)}K';
    return amount.toStringAsFixed(0);
  }
}

class _PatrimonioData {
  final double ingresos;
  final double bienes;
  double get total => ingresos + bienes;
  const _PatrimonioData({this.ingresos = 0, this.bienes = 0});
}

class _SelectorCard extends StatelessWidget {
  final String label;
  final String? value;
  final List<String> opciones;
  final ValueChanged<String?> onChanged;
  final Color color;

  const _SelectorCard({
    required this.label,
    required this.value,
    required this.opciones,
    required this.onChanged,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    // Sort options alphabetically
    final sortedOpciones = List<String>.from(opciones)..sort();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.06),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              ),
              const SizedBox(width: 8),
              Text(label,
                  style: TextStyle(
                      color: color, fontWeight: FontWeight.w700, fontSize: 14)),
            ],
          ),
          const SizedBox(height: 12),
          GestureDetector(
            onTap: () => _showSearchableSelector(context, sortedOpciones),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: color.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  Icon(Icons.person_search, color: color, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: value != null
                        ? Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                value!.split(' — ').first,
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: color,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                              if (value!.contains(' — '))
                                Text(
                                  value!.split(' — ').last,
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                            ],
                          )
                        : Text(
                            'Buscar y seleccionar candidato',
                            style: TextStyle(
                              fontSize: 14,
                              color: AppColors.textHint,
                            ),
                          ),
                  ),
                  Icon(Icons.arrow_drop_down, color: color),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showSearchableSelector(BuildContext context, List<String> opciones) {
    String searchText = '';
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => StatefulBuilder(
        builder: (ctx, setSheetState) {
          final filtered = searchText.isEmpty
              ? opciones
              : opciones
                  .where(
                      (o) => o.toLowerCase().contains(searchText.toLowerCase()))
                  .toList();

          return DraggableScrollableSheet(
            initialChildSize: 0.6,
            minChildSize: 0.3,
            maxChildSize: 0.8,
            expand: false,
            builder: (_, scrollCtrl) => Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
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
                  const SizedBox(height: 12),
                  Text(label,
                      style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: color)),
                  const SizedBox(height: 12),
                  TextField(
                    autofocus: true,
                    onChanged: (v) => setSheetState(() => searchText = v),
                    decoration: InputDecoration(
                      hintText: 'Buscar candidato o partido...',
                      prefixIcon: const Icon(Icons.search, size: 18),
                      suffixIcon: searchText.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.close, size: 16),
                              onPressed: () =>
                                  setSheetState(() => searchText = ''),
                            )
                          : null,
                      contentPadding: const EdgeInsets.symmetric(vertical: 8),
                      filled: true,
                      fillColor: AppColors.surfaceVariant,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Expanded(
                    child: ListView.builder(
                      controller: scrollCtrl,
                      itemCount: filtered.length,
                      itemBuilder: (_, i) {
                        final o = filtered[i];
                        final nombre = o.split(' — ').first;
                        final partido =
                            o.contains(' — ') ? o.split(' — ').last : '';
                        final isSelected = value == o;
                        return ListTile(
                          dense: true,
                          selected: isSelected,
                          selectedColor: color,
                          leading: CircleAvatar(
                            radius: 14,
                            backgroundColor: color.withOpacity(0.15),
                            child: Text(
                              nombre.isNotEmpty ? nombre[0] : '?',
                              style: TextStyle(
                                color: color,
                                fontWeight: FontWeight.w700,
                                fontSize: 12,
                              ),
                            ),
                          ),
                          title: Text(nombre,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: isSelected
                                    ? FontWeight.w700
                                    : FontWeight.w500,
                              )),
                          subtitle: partido.isNotEmpty
                              ? Text(partido,
                                  style: const TextStyle(
                                      fontSize: 11,
                                      color: AppColors.textSecondary))
                              : null,
                          trailing: isSelected
                              ? Icon(Icons.check_circle, color: color, size: 20)
                              : null,
                          onTap: () {
                            onChanged(o);
                            Navigator.pop(context);
                          },
                        );
                      },
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

class _ResultadoComparacion extends StatelessWidget {
  final Map<String, dynamic> resultado;
  final String nombreA;
  final String nombreB;

  const _ResultadoComparacion({
    required this.resultado,
    required this.nombreA,
    required this.nombreB,
  });

  static const _dimIcons = {
    'Institucional / Seguridad': '🛡️',
    'Social': '🏥',
    'Económica': '💰',
    'Ambiental': '🌿',
  };

  static const _dimColors = {
    'Institucional / Seguridad': Color(0xFFE53935),
    'Social': Color(0xFFE91E63),
    'Económica': Color(0xFF2196F3),
    'Ambiental': Color(0xFF4CAF50),
  };

  @override
  Widget build(BuildContext context) {
    final dimensiones = resultado['dimensiones'] as Map<String, dynamic>? ?? {};
    final totalA = (resultado['totalA'] as num?)?.toInt() ?? 0;
    final totalB = (resultado['totalB'] as num?)?.toInt() ?? 0;
    final resumen = resultado['resumenComparacion'] as String? ?? '';
    final edadA = (resultado['edadA'] as num?)?.toInt() ?? 0;
    final edadB = (resultado['edadB'] as num?)?.toInt() ?? 0;
    final patrimonioA =
        resultado['patrimonioA'] as _PatrimonioData? ?? const _PatrimonioData();
    final patrimonioB =
        resultado['patrimonioB'] as _PatrimonioData? ?? const _PatrimonioData();
    final sentPenA = (resultado['sentPenA'] as num?)?.toInt() ?? 0;
    final sentPenB = (resultado['sentPenB'] as num?)?.toInt() ?? 0;
    final sentOblA = (resultado['sentOblA'] as num?)?.toInt() ?? 0;
    final sentOblB = (resultado['sentOblB'] as num?)?.toInt() ?? 0;
    final renunciasA = (resultado['renunciasA'] as num?)?.toInt() ?? 0;
    final renunciasB = (resultado['renunciasB'] as num?)?.toInt() ?? 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Summary header
        Card(
          color: AppColors.surfaceVariant,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        children: [
                          Text(
                            '$totalA',
                            style: const TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.w800,
                                color: AppColors.primary),
                          ),
                          Text(
                            nombreA.split(' ').first,
                            style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.primary,
                                fontWeight: FontWeight.w600),
                            textAlign: TextAlign.center,
                          ),
                          if (edadA > 0)
                            Text(
                              '$edadA años',
                              style: const TextStyle(
                                  fontSize: 11, color: AppColors.textSecondary),
                            ),
                        ],
                      ),
                    ),
                    const Text(
                      'propuestas',
                      style: TextStyle(
                          fontSize: 11, color: AppColors.textSecondary),
                    ),
                    Expanded(
                      child: Column(
                        children: [
                          Text(
                            '$totalB',
                            style: const TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.w800,
                                color: AppColors.accent),
                          ),
                          Text(
                            nombreB.split(' ').first,
                            style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.accent,
                                fontWeight: FontWeight.w600),
                            textAlign: TextAlign.center,
                          ),
                          if (edadB > 0)
                            Text(
                              '$edadB años',
                              style: const TextStyle(
                                  fontSize: 11, color: AppColors.textSecondary),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),

        // Patrimony & risk card
        if (patrimonioA.total > 0 ||
            patrimonioB.total > 0 ||
            sentPenA > 0 ||
            sentPenB > 0) ...[
          const SizedBox(height: 8),
          _TransparenciaCard(
            nombreA: nombreA,
            nombreB: nombreB,
            patrimonioA: patrimonioA,
            patrimonioB: patrimonioB,
            sentPenA: sentPenA,
            sentPenB: sentPenB,
            sentOblA: sentOblA,
            sentOblB: sentOblB,
            renunciasA: renunciasA,
            renunciasB: renunciasB,
          ),
        ],

        const SizedBox(height: 12),

        // Per-dimension expandable cards
        ...dimensiones.entries.map((entry) {
          final dimName = entry.key;
          final data = entry.value as Map<String, dynamic>;
          final countA = (data['countA'] as num?)?.toInt() ?? 0;
          final countB = (data['countB'] as num?)?.toInt() ?? 0;
          final propsA = (data['propuestasA'] as List?) ?? [];
          final propsB = (data['propuestasB'] as List?) ?? [];
          final icon = _dimIcons[dimName] ?? '📋';
          final color = _dimColors[dimName] ?? AppColors.textSecondary;

          return _DimensionCard(
            dimName: dimName,
            icon: icon,
            color: color,
            countA: countA,
            countB: countB,
            propsA: propsA,
            propsB: propsB,
            nombreA: nombreA,
            nombreB: nombreB,
          );
        }),

        // Analysis summary — now much more detailed
        if (resumen.isNotEmpty) ...[
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.analytics, size: 18, color: AppColors.accent),
                      SizedBox(width: 8),
                      Text('Análisis comparativo exhaustivo',
                          style: TextStyle(fontWeight: FontWeight.w700)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // Enfoque badges
                  Row(
                    children: [
                      Expanded(
                        child: _EnfoqueBadge(
                          nombre: nombreA,
                          enfoque: resultado['enfoqueA'] as String? ?? '',
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _EnfoqueBadge(
                          nombre: nombreB,
                          enfoque: resultado['enfoqueB'] as String? ?? '',
                          color: AppColors.accent,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // Specificity bars
                  _MetricBar(
                    label: 'Metas medibles',
                    valueA: (resultado['metasA'] as num?)?.toInt() ?? 0,
                    valueB: (resultado['metasB'] as num?)?.toInt() ?? 0,
                    totalA: totalA,
                    totalB: totalB,
                    nombreA: nombreA,
                    nombreB: nombreB,
                  ),
                  const SizedBox(height: 12),
                  // Full text analysis
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceVariant,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(resumen,
                        style: const TextStyle(
                            fontSize: 12,
                            height: 1.6,
                            fontFamily: 'monospace')),
                  ),
                  const SizedBox(height: 8),
                  const SourceTag(fuente: 'JNE Voto Informado 2026'),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _DimensionCard extends StatefulWidget {
  final String dimName;
  final String icon;
  final Color color;
  final int countA;
  final int countB;
  final List propsA;
  final List propsB;
  final String nombreA;
  final String nombreB;

  const _DimensionCard({
    required this.dimName,
    required this.icon,
    required this.color,
    required this.countA,
    required this.countB,
    required this.propsA,
    required this.propsB,
    required this.nombreA,
    required this.nombreB,
  });

  @override
  State<_DimensionCard> createState() => _DimensionCardState();
}

class _DimensionCardState extends State<_DimensionCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final total = widget.countA + widget.countB;
    final ratioA = total > 0 ? widget.countA / total : 0.5;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          // Header - always visible
          InkWell(
            onTap: () => setState(() => _expanded = !_expanded),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                children: [
                  Row(
                    children: [
                      Text(widget.icon, style: const TextStyle(fontSize: 18)),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Dimensión ${widget.dimName}',
                          style: const TextStyle(
                              fontWeight: FontWeight.w700, fontSize: 14),
                        ),
                      ),
                      Text(
                        '${widget.countA}',
                        style: const TextStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w800,
                            fontSize: 16),
                      ),
                      const Text(' vs ',
                          style: TextStyle(
                              color: AppColors.textSecondary, fontSize: 12)),
                      Text(
                        '${widget.countB}',
                        style: const TextStyle(
                            color: AppColors.accent,
                            fontWeight: FontWeight.w800,
                            fontSize: 16),
                      ),
                      const SizedBox(width: 8),
                      Icon(
                        _expanded ? Icons.expand_less : Icons.expand_more,
                        size: 20,
                        color: AppColors.textSecondary,
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  // Proportional bar
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: SizedBox(
                      height: 6,
                      child: Row(
                        children: [
                          Flexible(
                            flex: (ratioA * 100).round().clamp(1, 99),
                            child: Container(color: AppColors.primary),
                          ),
                          Flexible(
                            flex: ((1 - ratioA) * 100).round().clamp(1, 99),
                            child: Container(color: AppColors.accent),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Expanded detail
          if (_expanded)
            Container(
              color: widget.color.withOpacity(0.04),
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Divider(),
                  // Candidate A proposals
                  _ProposalList(
                    label: widget.nombreA.split(' ').first,
                    color: AppColors.primary,
                    proposals: widget.propsA,
                  ),
                  if (widget.propsA.isNotEmpty && widget.propsB.isNotEmpty)
                    const Divider(height: 20),
                  // Candidate B proposals
                  _ProposalList(
                    label: widget.nombreB.split(' ').first,
                    color: AppColors.accent,
                    proposals: widget.propsB,
                  ),
                  if (widget.propsA.isEmpty && widget.propsB.isEmpty)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.all(12),
                        child: Text('Sin propuestas registradas',
                            style: TextStyle(
                                color: AppColors.textSecondary,
                                fontStyle: FontStyle.italic)),
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

class _ProposalList extends StatelessWidget {
  final String label;
  final Color color;
  final List proposals;

  const _ProposalList({
    required this.label,
    required this.color,
    required this.proposals,
  });

  @override
  Widget build(BuildContext context) {
    if (proposals.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Text('$label: Sin propuestas',
            style: TextStyle(
                color: color, fontStyle: FontStyle.italic, fontSize: 12)),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
            const SizedBox(width: 6),
            Text(label,
                style: TextStyle(
                    color: color, fontWeight: FontWeight.w700, fontSize: 13)),
          ],
        ),
        const SizedBox(height: 6),
        ...proposals.asMap().entries.map((entry) {
          final i = entry.key;
          final p = entry.value as Map;
          final problema = p['problema'] ?? '';
          final objetivo = p['objetivo'] ?? '';
          final meta = p['meta'] ?? '';

          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border(left: BorderSide(color: color, width: 3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Propuesta ${i + 1}',
                    style: TextStyle(
                        fontSize: 10,
                        color: color,
                        fontWeight: FontWeight.w600)),
                if (problema.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text.rich(TextSpan(children: [
                    const TextSpan(
                        text: 'Problema: ',
                        style: TextStyle(
                            fontWeight: FontWeight.w600, fontSize: 12)),
                    TextSpan(
                        text: problema, style: const TextStyle(fontSize: 12)),
                  ])),
                ],
                if (objetivo.isNotEmpty) ...[
                  const SizedBox(height: 3),
                  Text.rich(TextSpan(children: [
                    const TextSpan(
                        text: 'Objetivo: ',
                        style: TextStyle(
                            fontWeight: FontWeight.w600, fontSize: 12)),
                    TextSpan(
                        text: objetivo, style: const TextStyle(fontSize: 12)),
                  ])),
                ],
                if (meta.isNotEmpty) ...[
                  const SizedBox(height: 3),
                  Text.rich(TextSpan(children: [
                    const TextSpan(
                        text: 'Meta: ',
                        style: TextStyle(
                            fontWeight: FontWeight.w600, fontSize: 12)),
                    TextSpan(text: meta, style: const TextStyle(fontSize: 12)),
                  ])),
                ],
              ],
            ),
          );
        }),
      ],
    );
  }
}

class _EnfoqueBadge extends StatelessWidget {
  final String nombre;
  final String enfoque;
  final Color color;

  const _EnfoqueBadge({
    required this.nombre,
    required this.enfoque,
    required this.color,
  });

  static const _enfoqueIcons = {
    'Social': '🏥',
    'Económico': '💰',
    'Ambiental': '🌿',
    'Institucional': '🛡️',
    'indefinido': '❓',
  };

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          Text(
            _enfoqueIcons[enfoque] ?? '📋',
            style: const TextStyle(fontSize: 18),
          ),
          const SizedBox(height: 4),
          Text(
            nombre.split(' ').first,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
          Text(
            'Enfoque $enfoque',
            style: const TextStyle(
              fontSize: 10,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _MetricBar extends StatelessWidget {
  final String label;
  final int valueA;
  final int valueB;
  final int totalA;
  final int totalB;
  final String nombreA;
  final String nombreB;

  const _MetricBar({
    required this.label,
    required this.valueA,
    required this.valueB,
    required this.totalA,
    required this.totalB,
    required this.nombreA,
    required this.nombreB,
  });

  @override
  Widget build(BuildContext context) {
    final pctA = totalA > 0 ? valueA / totalA : 0.0;
    final pctB = totalB > 0 ? valueB / totalB : 0.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary)),
        const SizedBox(height: 6),
        Row(
          children: [
            Text('${nombreA.split(' ').first} ${(pctA * 100).round()}%',
                style: const TextStyle(
                    fontSize: 10,
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600)),
            const SizedBox(width: 8),
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(3),
                child: SizedBox(
                  height: 6,
                  child: Row(
                    children: [
                      Flexible(
                        flex: (pctA * 100).round().clamp(1, 99),
                        child: Container(color: AppColors.primary),
                      ),
                      Flexible(
                        flex: ((1 - pctA) * 100).round().clamp(1, 99),
                        child: Container(color: AppColors.border),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 4),
            const Text('|', style: TextStyle(color: AppColors.border)),
            const SizedBox(width: 4),
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(3),
                child: SizedBox(
                  height: 6,
                  child: Row(
                    children: [
                      Flexible(
                        flex: (pctB * 100).round().clamp(1, 99),
                        child: Container(color: AppColors.accent),
                      ),
                      Flexible(
                        flex: ((1 - pctB) * 100).round().clamp(1, 99),
                        child: Container(color: AppColors.border),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Text('${(pctB * 100).round()}% ${nombreB.split(' ').first}',
                style: const TextStyle(
                    fontSize: 10,
                    color: AppColors.accent,
                    fontWeight: FontWeight.w600)),
          ],
        ),
      ],
    );
  }
}

/// Transparencia & riesgo card — shows patrimony and antecedentes side by side.
class _TransparenciaCard extends StatefulWidget {
  final String nombreA;
  final String nombreB;
  final _PatrimonioData patrimonioA;
  final _PatrimonioData patrimonioB;
  final int sentPenA, sentPenB;
  final int sentOblA, sentOblB;
  final int renunciasA, renunciasB;

  const _TransparenciaCard({
    required this.nombreA,
    required this.nombreB,
    required this.patrimonioA,
    required this.patrimonioB,
    required this.sentPenA,
    required this.sentPenB,
    required this.sentOblA,
    required this.sentOblB,
    required this.renunciasA,
    required this.renunciasB,
  });

  @override
  State<_TransparenciaCard> createState() => _TransparenciaCardState();
}

class _TransparenciaCardState extends State<_TransparenciaCard> {
  bool _expanded = false;

  int _calcRisk(_PatrimonioData pat, int sentPen, int sentObl, int renuncias) {
    // 0 = sin datos, 1 = bajo, 2 = moderado, 3 = alto
    // Basado ÚNICAMENTE en datos verificables del JNE
    int score = 0;
    if (sentPen > 0) score += 2;
    if (sentObl > 0) score += 1;
    if (renuncias >= 3) score += 1;
    return score.clamp(0, 3);
  }

  Widget _riskBadge(String nombre, int risk, Color color) {
    final labels = ['Sin datos', 'Bajo', 'Moderado', 'Alto'];
    final colors = [
      AppColors.textSecondary,
      const Color(0xFF4CAF50),
      const Color(0xFFFFA726),
      const Color(0xFFE53935),
    ];
    final icons = [
      Icons.help_outline,
      Icons.check_circle,
      Icons.warning,
      Icons.error
    ];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: colors[risk].withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: colors[risk].withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icons[risk], size: 14, color: colors[risk]),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              '${nombre.split(' ').first}: ${labels[risk]}',
              style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: colors[risk]),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  String _fmtMoney(double amount) {
    if (amount >= 1e6) return '${(amount / 1e6).toStringAsFixed(1)}M';
    if (amount >= 1e3) return '${(amount / 1e3).toStringAsFixed(0)}K';
    return amount.toStringAsFixed(0);
  }

  @override
  Widget build(BuildContext context) {
    final riskA = _calcRisk(widget.patrimonioA, widget.sentPenA,
        widget.sentOblA, widget.renunciasA);
    final riskB = _calcRisk(widget.patrimonioB, widget.sentPenB,
        widget.sentOblB, widget.renunciasB);

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          InkWell(
            onTap: () => setState(() => _expanded = !_expanded),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Text('🔍', style: TextStyle(fontSize: 18)),
                      const SizedBox(width: 10),
                      const Expanded(
                        child: Text(
                          'Transparencia y Riesgo',
                          style: TextStyle(
                              fontWeight: FontWeight.w700, fontSize: 14),
                        ),
                      ),
                      Icon(
                        _expanded ? Icons.expand_less : Icons.expand_more,
                        size: 20,
                        color: AppColors.textSecondary,
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                          child: _riskBadge(
                              widget.nombreA, riskA, AppColors.primary)),
                      const SizedBox(width: 8),
                      Expanded(
                          child: _riskBadge(
                              widget.nombreB, riskB, AppColors.accent)),
                    ],
                  ),
                ],
              ),
            ),
          ),
          if (_expanded)
            Container(
              color: const Color(0xFFFAFAFA),
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Divider(),
                  if (widget.patrimonioA.total > 0 ||
                      widget.patrimonioB.total > 0) ...[
                    const Text('💰 Patrimonio declarado',
                        style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textSecondary)),
                    const SizedBox(height: 6),
                    _patrimonioRow(
                        widget.nombreA, widget.patrimonioA, AppColors.primary),
                    const SizedBox(height: 4),
                    _patrimonioRow(
                        widget.nombreB, widget.patrimonioB, AppColors.accent),
                    const SizedBox(height: 12),
                  ],
                  if (widget.sentPenA > 0 ||
                      widget.sentPenB > 0 ||
                      widget.sentOblA > 0 ||
                      widget.sentOblB > 0 ||
                      widget.renunciasA > 0 ||
                      widget.renunciasB > 0) ...[
                    const Text('⚖️ Antecedentes JNE',
                        style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textSecondary)),
                    const SizedBox(height: 6),
                    _antecedentesRow(
                      widget.nombreA,
                      widget.sentPenA,
                      widget.sentOblA,
                      widget.renunciasA,
                      AppColors.primary,
                    ),
                    const SizedBox(height: 4),
                    _antecedentesRow(
                      widget.nombreB,
                      widget.sentPenB,
                      widget.sentOblB,
                      widget.renunciasB,
                      AppColors.accent,
                    ),
                  ],
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF8E1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.info_outline,
                            size: 14, color: Color(0xFFF57F17)),
                        SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            'Indicador basado exclusivamente en datos públicos del JNE. No constituye acusación.',
                            style: TextStyle(
                                fontSize: 10, color: Color(0xFFF57F17)),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _patrimonioRow(String nombre, _PatrimonioData pat, Color color) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            '${nombre.split(' ').first}: S/ ${_fmtMoney(pat.total)} (Ingresos: S/ ${_fmtMoney(pat.ingresos)}, Bienes: S/ ${_fmtMoney(pat.bienes)})',
            style: const TextStyle(fontSize: 11),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _antecedentesRow(
      String nombre, int sentPen, int sentObl, int renuncias, Color color) {
    final items = <String>[];
    if (sentPen > 0) items.add('$sentPen sent. penal(es)');
    if (sentObl > 0) items.add('$sentObl sent. obligación');
    if (renuncias > 0) items.add('$renuncias renuncia(s)');
    if (items.isEmpty) items.add('Sin antecedentes');

    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            '${nombre.split(' ').first}: ${items.join(', ')}',
            style: const TextStyle(fontSize: 11),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
