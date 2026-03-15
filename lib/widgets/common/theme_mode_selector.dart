import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../core/services/providers.dart';

/// Widget para selección del theme mode
class ThemeModeSelector extends ConsumerWidget {
  const ThemeModeSelector({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentMode = ref.watch(themeModeProvider);

    return PopupMenuButton<ThemeMode>(
      icon: Icon(_getIconForMode(currentMode)),
      tooltip: 'Cambiar tema',
      onSelected: (mode) {
        ref.read(themeModeProvider.notifier).state = mode;
      },
      itemBuilder: (context) => [
        PopupMenuItem(
          value: ThemeMode.light,
          child: Row(
            children: [
              Icon(
                Icons.light_mode,
                color: currentMode == ThemeMode.light
                    ? AppColors.primary
                    : AppColors.textSecondary,
                size: 20,
              ),
              const SizedBox(width: 12),
              Text(
                'Claro',
                style: TextStyle(
                  fontWeight: currentMode == ThemeMode.light
                      ? FontWeight.w700
                      : FontWeight.normal,
                ),
              ),
            ],
          ),
        ),
        PopupMenuItem(
          value: ThemeMode.dark,
          child: Row(
            children: [
              Icon(
                Icons.dark_mode,
                color: currentMode == ThemeMode.dark
                    ? AppColors.primary
                    : AppColors.textSecondary,
                size: 20,
              ),
              const SizedBox(width: 12),
              Text(
                'Oscuro',
                style: TextStyle(
                  fontWeight: currentMode == ThemeMode.dark
                      ? FontWeight.w700
                      : FontWeight.normal,
                ),
              ),
            ],
          ),
        ),
        PopupMenuItem(
          value: ThemeMode.system,
          child: Row(
            children: [
              Icon(
                Icons.brightness_auto,
                color: currentMode == ThemeMode.system
                    ? AppColors.primary
                    : AppColors.textSecondary,
                size: 20,
              ),
              const SizedBox(width: 12),
              Text(
                'Sistema',
                style: TextStyle(
                  fontWeight: currentMode == ThemeMode.system
                      ? FontWeight.w700
                      : FontWeight.normal,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  IconData _getIconForMode(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.light:
        return Icons.light_mode;
      case ThemeMode.dark:
        return Icons.dark_mode;
      case ThemeMode.system:
        return Icons.brightness_auto;
    }
  }
}
