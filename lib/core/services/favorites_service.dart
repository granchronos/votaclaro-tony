import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Categories for favorite candidates.
enum FavoriteCategory { presidente, diputado, senador, andino }

/// Manages favorite candidates persisted in SharedPreferences.
class FavoritesNotifier
    extends StateNotifier<Map<FavoriteCategory, Set<String>>> {
  static const _key = 'vc_favorites';

  FavoritesNotifier()
      : super({
          for (final c in FavoriteCategory.values) c: <String>{},
        }) {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null) return;
    try {
      final map = jsonDecode(raw) as Map<String, dynamic>;
      final loaded = <FavoriteCategory, Set<String>>{};
      for (final c in FavoriteCategory.values) {
        final list = map[c.name] as List<dynamic>? ?? [];
        loaded[c] = list.cast<String>().toSet();
      }
      state = loaded;
    } catch (_) {}
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    final map = <String, List<String>>{};
    for (final c in FavoriteCategory.values) {
      map[c.name] = state[c]?.toList() ?? [];
    }
    await prefs.setString(_key, jsonEncode(map));
  }

  bool isFavorite(String candidatoId) {
    return state.values.any((set) => set.contains(candidatoId));
  }

  bool isFavoriteIn(FavoriteCategory category, String candidatoId) {
    return state[category]?.contains(candidatoId) ?? false;
  }

  void toggle(FavoriteCategory category, String candidatoId) {
    final current = Set<String>.from(state[category] ?? {});
    if (current.contains(candidatoId)) {
      current.remove(candidatoId);
    } else {
      current.add(candidatoId);
    }
    state = {...state, category: current};
    _save();
  }

  int countFor(FavoriteCategory category) => state[category]?.length ?? 0;

  int get totalCount => state.values.fold(0, (sum, s) => sum + s.length);
}

final favoritesProvider = StateNotifierProvider<FavoritesNotifier,
    Map<FavoriteCategory, Set<String>>>((ref) => FavoritesNotifier());
