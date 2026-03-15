import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/theme/app_theme.dart';
import 'core/services/app_router.dart';
import 'core/services/providers.dart';

class VotaClaro extends ConsumerStatefulWidget {
  const VotaClaro({super.key});

  @override
  ConsumerState<VotaClaro> createState() => _VotaClaroState();
}

class _VotaClaroState extends ConsumerState<VotaClaro> {
  @override
  void initState() {
    super.initState();
    _initSupabase();
    _loadSavedTheme();
    _startBackgroundSync();
  }

  /// Verifica conexión con Supabase al arrancar.
  Future<void> _initSupabase() async {
    final supabase = ref.read(supabaseServiceProvider);
    await supabase.healthCheck();
  }

  /// Carga el tema guardado desde Supabase/SharedPreferences al arrancar.
  Future<void> _loadSavedTheme() async {
    try {
      final supabase = ref.read(supabaseServiceProvider);
      final saved = await supabase.getUserPreference('theme_mode');
      if (saved != null && mounted) {
        final mode = ThemeMode.values.firstWhere(
          (m) => m.name == saved,
          orElse: () => ThemeMode.light,
        );
        ref.read(themeModeProvider.notifier).state = mode;
      }
    } catch (_) {
      // Sin conexión — usar valor por defecto (light)
    }
  }

  /// Sincronización en segundo plano: refresca candidatos y planes.
  void _startBackgroundSync() {
    try {
      final supabase = ref.read(supabaseServiceProvider);
      supabase.scheduleBgSync(() async {
        // Pre-warm: fetch presidential candidates to populate cache
        await ref.read(candidatosPresidenteProvider.future);
      });
    } catch (_) {
      // Sync failed silently — app works offline with local cache
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeMode = ref.watch(themeModeProvider);

    // Persistir cambio de tema automáticamente
    ref.listen<ThemeMode>(themeModeProvider, (previous, next) {
      if (previous != next) {
        ref
            .read(supabaseServiceProvider)
            .saveUserPreference('theme_mode', next.name);
      }
    });

    // Barra de estado transparente
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
      ),
    );

    return MaterialApp.router(
      title: 'VotaClaro',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: themeMode,
      routerConfig: appRouter,
      builder: (context, child) {
        // Escala de texto limitada para evitar overflow en texto grande
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaler: TextScaler.linear(
              MediaQuery.of(context).textScaler.scale(1.0).clamp(0.8, 1.3),
            ),
          ),
          child: child!,
        );
      },
    );
  }
}
