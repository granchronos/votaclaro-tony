import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

/// Two-tier cache for candidato lists.
///
/// L1 — in-memory  (TTL: 5 min) — zero-latency within the same session.
/// L2 — SharedPreferences (TTL: 1 h) — survives page reloads / app restarts.
///
/// No external server required: works entirely on-device / in-browser (web
/// uses localStorage via shared_preferences).
class CandidatosCacheService {
  static const Duration _ttlMemory = Duration(minutes: 5);
  static const Duration _ttlPersist = Duration(hours: 1);
  static const String _prefix = 'vc_cache_';

  final Map<String, _Entry> _mem = {};

  // ── Read ─────────────────────────────────────────────────────────────────

  /// Returns the cached list for [key], or `null` if missing or expired.
  /// Serves from L1 first, then hydrates L1 from L2 on a cache hit there.
  Future<({List<Map<String, dynamic>> data, DateTime ts})?> get(
      String key) async {
    // L1: in-memory
    final m = _mem[key];
    if (m != null && _fresh(m.ts, _ttlMemory)) {
      return (data: m.data, ts: m.ts);
    }

    // L2: persistent (SharedPreferences / localStorage)
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString('$_prefix$key');
      if (raw != null) {
        final j = jsonDecode(raw) as Map<String, dynamic>;
        final ts = DateTime.fromMillisecondsSinceEpoch(j['ts'] as int);
        if (_fresh(ts, _ttlPersist)) {
          final data = (j['data'] as List)
              .map((e) => Map<String, dynamic>.from(e as Map))
              .toList();
          _mem[key] = _Entry(data, ts); // warm L1
          return (data: data, ts: ts);
        }
      }
    } catch (_) {}
    return null;
  }

  // ── Write ────────────────────────────────────────────────────────────────

  /// Stores [data] for [key] in both tiers.
  Future<void> set(String key, List<Map<String, dynamic>> data) async {
    final ts = DateTime.now();
    _mem[key] = _Entry(data, ts);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        '$_prefix$key',
        jsonEncode({'ts': ts.millisecondsSinceEpoch, 'data': data}),
      );
    } catch (_) {}
  }

  // ── Invalidate ───────────────────────────────────────────────────────────

  /// Evicts [key] from both tiers (forces a fresh fetch on next [get]).
  Future<void> invalidate(String key) async {
    _mem.remove(key);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('$_prefix$key');
    } catch (_) {}
  }

  // ── Helper ───────────────────────────────────────────────────────────────

  bool _fresh(DateTime ts, Duration ttl) => DateTime.now().difference(ts) < ttl;
}

class _Entry {
  final List<Map<String, dynamic>> data;
  final DateTime ts;
  _Entry(this.data, this.ts);
}
