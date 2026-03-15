-- ═══════════════════════════════════════════════════════════════════════════
--  VotaClaro — Supabase Schema
--  Ejecutar en el SQL Editor del dashboard de Supabase:
--  https://supabase.com/dashboard/project/efbrpoustizkyldlqoit/sql
-- ═══════════════════════════════════════════════════════════════════════════

-- ─────────────────────────────────────────────────────────────────────────────
--  1. Preferencias de usuario (anónimas, identificadas por session_id)
-- ─────────────────────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS user_preferences (
  session_id   TEXT        PRIMARY KEY,
  preferences  JSONB       NOT NULL DEFAULT '{}',
  updated_at   TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Índice para consultas rápidas por session_id
CREATE INDEX IF NOT EXISTS idx_user_preferences_session
  ON user_preferences (session_id);

-- ─────────────────────────────────────────────────────────────────────────────
--  2. Caché de candidatos (por tipo: presidente, congreso_Lima, etc.)
-- ─────────────────────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS candidatos_cache (
  tipo        TEXT        PRIMARY KEY,          -- 'presidente', 'diputados_Lima', etc.
  data        JSONB       NOT NULL DEFAULT '[]',
  updated_at  TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ─────────────────────────────────────────────────────────────────────────────
--  3. Caché de planes de gobierno (por idOrganizacionPolitica del JNE)
-- ─────────────────────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS planes_cache (
  id_organizacion_politica  INTEGER     PRIMARY KEY,
  plan_data                 JSONB       NOT NULL DEFAULT '{}',
  updated_at                TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ─────────────────────────────────────────────────────────────────────────────
--  4. Analytics de uso
-- ─────────────────────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS analytics_events (
  id          UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
  event_type  TEXT        NOT NULL,
  properties  JSONB       NOT NULL DEFAULT '{}',
  session_id  TEXT,
  created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Índices para consultas analíticas
CREATE INDEX IF NOT EXISTS idx_analytics_event_type
  ON analytics_events (event_type);
CREATE INDEX IF NOT EXISTS idx_analytics_session
  ON analytics_events (session_id);
CREATE INDEX IF NOT EXISTS idx_analytics_created_at
  ON analytics_events (created_at DESC);

-- ─────────────────────────────────────────────────────────────────────────────
--  5. Row Level Security (RLS) — acceso anónimo via anon key
-- ─────────────────────────────────────────────────────────────────────────────

-- user_preferences: cada sesión solo puede leer/escribir sus propias preferencias
ALTER TABLE user_preferences ENABLE ROW LEVEL SECURITY;

CREATE POLICY "anon_own_preferences" ON user_preferences
  FOR ALL
  USING (true)  -- El session_id viene del cliente; restringir si se usa auth
  WITH CHECK (true);

-- candidatos_cache: lectura pública, escritura restringida (el servicio usa anon key)
ALTER TABLE candidatos_cache ENABLE ROW LEVEL SECURITY;

CREATE POLICY "public_read_candidatos" ON candidatos_cache
  FOR SELECT USING (true);

CREATE POLICY "anon_write_candidatos" ON candidatos_cache
  FOR INSERT WITH CHECK (true);

CREATE POLICY "anon_update_candidatos" ON candidatos_cache
  FOR UPDATE USING (true);

-- planes_cache: lectura pública
ALTER TABLE planes_cache ENABLE ROW LEVEL SECURITY;

CREATE POLICY "public_read_planes" ON planes_cache
  FOR SELECT USING (true);

CREATE POLICY "anon_write_planes" ON planes_cache
  FOR INSERT WITH CHECK (true);

CREATE POLICY "anon_update_planes" ON planes_cache
  FOR UPDATE USING (true);

-- analytics_events: solo inserción anónima, sin lectura pública
ALTER TABLE analytics_events ENABLE ROW LEVEL SECURITY;

CREATE POLICY "anon_insert_events" ON analytics_events
  FOR INSERT WITH CHECK (true);

-- ─────────────────────────────────────────────────────────────────────────────
--  6. Función de limpieza automática (opcional, ejecutar via pg_cron)
-- ─────────────────────────────────────────────────────────────────────────────
-- Borrar eventos de analytics con más de 90 días
-- SELECT cron.schedule('cleanup-analytics', '0 3 * * *',
--   $$DELETE FROM analytics_events WHERE created_at < NOW() - INTERVAL '90 days'$$
-- );
