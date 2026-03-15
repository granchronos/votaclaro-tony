// Supabase Edge Function — ai-proxy
// Actúa como proxy seguro entre la app Flutter Web y los proveedores de IA.
// Las API keys (Gemini, Claude) viven en Supabase Vault y NUNCA se exponen al cliente.
//
// Subir keys al Vault antes de deploy:
//   supabase secrets set GEMINI_API_KEY=AIza...
//   supabase secrets set CLAUDE_API_KEY=sk-ant-...
//   supabase secrets set GEMINI_MODEL=gemini-2.0-flash-exp
//   supabase secrets set CLAUDE_MODEL=claude-3-haiku-20240307

import { serve } from 'https://deno.land/std@0.208.0/http/server.ts'

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
  'Access-Control-Allow-Methods': 'POST, OPTIONS',
}

serve(async (req) => {
  // CORS preflight
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  try {
    const { prompt, systemPrompt } = await req.json()

    if (!prompt) {
      return new Response(
        JSON.stringify({ error: 'prompt_required' }),
        { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } },
      )
    }

    // ── Intento 1: Gemini ─────────────────────────────────────────────────────
    const geminiKey = Deno.env.get('GEMINI_API_KEY') ?? ''
    const geminiModel = Deno.env.get('GEMINI_MODEL') ?? 'gemini-2.0-flash-exp'

    if (geminiKey) {
      const geminiRes = await fetch(
        `https://generativelanguage.googleapis.com/v1beta/models/${geminiModel}:generateContent`,
        {
          method: 'POST',
          headers: {
            'Content-Type': 'application/json',
            'X-goog-api-key': geminiKey,
          },
          body: JSON.stringify({
            system_instruction: { parts: [{ text: systemPrompt ?? '' }] },
            contents: [{ parts: [{ text: prompt }] }],
            generationConfig: { temperature: 0.1, maxOutputTokens: 4096 },
          }),
        },
      )

      if (geminiRes.ok) {
        const data = await geminiRes.json()
        const text: string = data?.candidates?.[0]?.content?.parts?.[0]?.text ?? ''
        if (text) {
          return new Response(
            JSON.stringify({ text }),
            { headers: { ...corsHeaders, 'Content-Type': 'application/json' } },
          )
        }
      }
    }

    // ── Intento 2: Claude ─────────────────────────────────────────────────────
    const claudeKey = Deno.env.get('CLAUDE_API_KEY') ?? ''
    const claudeModel = Deno.env.get('CLAUDE_MODEL') ?? 'claude-3-haiku-20240307'

    if (claudeKey) {
      const claudeRes = await fetch('https://api.anthropic.com/v1/messages', {
        method: 'POST',
        headers: {
          'x-api-key': claudeKey,
          'anthropic-version': '2023-06-01',
          'content-type': 'application/json',
        },
        body: JSON.stringify({
          model: claudeModel,
          max_tokens: 4096,
          system: systemPrompt ?? '',
          messages: [{ role: 'user', content: prompt }],
        }),
      })

      if (claudeRes.ok) {
        const data = await claudeRes.json()
        const text: string = data?.content?.[0]?.text ?? ''
        if (text) {
          return new Response(
            JSON.stringify({ text }),
            { headers: { ...corsHeaders, 'Content-Type': 'application/json' } },
          )
        }
      }
    }

    return new Response(
      JSON.stringify({ error: 'no_provider_available' }),
      { status: 503, headers: { ...corsHeaders, 'Content-Type': 'application/json' } },
    )
  } catch (err) {
    return new Response(
      JSON.stringify({ error: (err as Error).message }),
      { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } },
    )
  }
})
