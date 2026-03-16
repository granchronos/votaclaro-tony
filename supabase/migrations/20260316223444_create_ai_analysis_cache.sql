-- Create ai_analysis_cache table for shared AI analysis caching
CREATE TABLE IF NOT EXISTS ai_analysis_cache (
  candidato_key  TEXT        PRIMARY KEY,
  analysis_data  JSONB       NOT NULL DEFAULT '{}',
  version        INTEGER     NOT NULL DEFAULT 1,
  created_at     TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at     TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_ai_analysis_updated
  ON ai_analysis_cache (updated_at DESC);

-- RLS
ALTER TABLE ai_analysis_cache ENABLE ROW LEVEL SECURITY;

CREATE POLICY "public_read_ai_cache" ON ai_analysis_cache
  FOR SELECT USING (true);

CREATE POLICY "anon_write_ai_cache" ON ai_analysis_cache
  FOR INSERT WITH CHECK (true);

CREATE POLICY "anon_update_ai_cache" ON ai_analysis_cache
  FOR UPDATE USING (true);
