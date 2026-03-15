import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'ai_electoral_service.dart';
import 'providers.dart';

/// Provider del switcher de modelo IA — persiste en sesión
final aiProviderSettingsNotifier =
    StateNotifierProvider<AiProviderNotifier, AiProvider>((ref) {
  return AiProviderNotifier(ref.read(aiServiceProvider));
});

class AiProviderNotifier extends StateNotifier<AiProvider> {
  AiProviderNotifier(this._service) : super(AiProvider.gemini);

  final AiElectoralService _service;

  void switchTo(AiProvider provider) {
    state = provider;
    _service.activeProvider = provider;
  }

  void toggle() => switchTo(
      state == AiProvider.gemini ? AiProvider.claude : AiProvider.gemini);
}
