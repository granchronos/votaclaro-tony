import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../core/services/ai_electoral_service.dart';
import '../../core/services/settings_provider.dart';

/// Botón compacto para el AppBar que alterna entre Gemini y Claude
class ModelSwitcherButton extends ConsumerWidget {
  const ModelSwitcherButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final active = ref.watch(aiProviderSettingsNotifier);
    final isGemini = active == AiProvider.gemini;

    return GestureDetector(
      onTap: () => _showSwitcherSheet(context, ref, active),
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: isGemini
              ? const Color(0xFF1A73E8).withOpacity(0.1)
              : const Color(0xFFD97706).withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isGemini
                ? const Color(0xFF1A73E8).withOpacity(0.4)
                : const Color(0xFFD97706).withOpacity(0.4),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              isGemini ? '✨' : '🔶',
              style: const TextStyle(fontSize: 12),
            ),
            const SizedBox(width: 4),
            Text(
              isGemini ? 'Gemini' : 'Claude',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isGemini
                    ? const Color(0xFF1A73E8)
                    : const Color(0xFFD97706),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showSwitcherSheet(
      BuildContext context, WidgetRef ref, AiProvider current) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _ModelSwitcherSheet(current: current, ref: ref),
    );
  }
}

class _ModelSwitcherSheet extends StatelessWidget {
  final AiProvider current;
  final WidgetRef ref;

  const _ModelSwitcherSheet({required this.current, required this.ref});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Modelo de IA',
              style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 4),
          const Text(
            'Elige el proveedor para el agente ELECTORAL_PE_2026',
            style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 16),
          _ModelTile(
            provider: AiProvider.gemini,
            current: current,
            emoji: '✨',
            title: 'Gemini Flash',
            subtitle: 'Google · Free tier · gemini-flash-latest',
            color: const Color(0xFF1A73E8),
            onTap: () {
              ref
                  .read(aiProviderSettingsNotifier.notifier)
                  .switchTo(AiProvider.gemini);
              Navigator.pop(context);
            },
          ),
          const SizedBox(height: 10),
          _ModelTile(
            provider: AiProvider.claude,
            current: current,
            emoji: '🔶',
            title: 'Claude Haiku',
            subtitle: 'Anthropic · Free tier · claude-3-haiku-20240307',
            color: const Color(0xFFD97706),
            onTap: () {
              ref
                  .read(aiProviderSettingsNotifier.notifier)
                  .switchTo(AiProvider.claude);
              Navigator.pop(context);
            },
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.surfaceVariant,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Text(
              'Ambos modelos usan el mismo prompt maestro ELECTORAL_PE_2026. '
              'Si uno falla por rate limit, la app cambia al otro automáticamente.',
              style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

class _ModelTile extends StatelessWidget {
  final AiProvider provider;
  final AiProvider current;
  final String emoji;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _ModelTile({
    required this.provider,
    required this.current,
    required this.emoji,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isSelected = provider == current;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color:
              isSelected ? color.withOpacity(0.08) : AppColors.surfaceVariant,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? color.withOpacity(0.5) : AppColors.border,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Center(
                  child: Text(emoji, style: const TextStyle(fontSize: 22))),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: TextStyle(
                          fontWeight: FontWeight.w700,
                          color: isSelected ? color : AppColors.textPrimary)),
                  Text(subtitle,
                      style: const TextStyle(
                          fontSize: 12, color: AppColors.textSecondary)),
                ],
              ),
            ),
            if (isSelected)
              Icon(Icons.check_circle_rounded, color: color, size: 22),
          ],
        ),
      ),
    );
  }
}
