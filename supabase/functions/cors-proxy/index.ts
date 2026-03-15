// Supabase Edge Function — cors-proxy
// Proxy genérico para evitar bloqueos CORS en Flutter Web.
// Soporta GET y POST. Reenvía headers y body al URL destino.
//
// Deploy:
//   supabase functions deploy cors-proxy --no-verify-jwt

import { serve } from 'https://deno.land/std@0.208.0/http/server.ts'

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers':
    'authorization, x-client-info, apikey, content-type, x-target-url',
  'Access-Control-Allow-Methods': 'GET, POST, OPTIONS',
}

serve(async (req) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  try {
    // Accept target URL from header (API calls) or query param (images)
    const reqUrl = new URL(req.url)
    const targetUrl = req.headers.get('x-target-url') || reqUrl.searchParams.get('url')
    if (!targetUrl) {
      return new Response(
        JSON.stringify({ error: 'x-target-url header or ?url= param is required' }),
        { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } },
      )
    }

    // Validate target URL
    let parsed: URL
    try {
      parsed = new URL(targetUrl)
    } catch {
      return new Response(
        JSON.stringify({ error: 'Invalid target URL' }),
        { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } },
      )
    }

    // Allow-list: only proxy known domains
    const allowed = [
      'jne.gob.pe',
      'idl-reporteros.pe',
      'wayka.pe',
      'sudaca.pe',
      'rpp.pe',
      'canaln.pe',
      'elcomercio.pe',
      'chequeado.com',
      'gist.githubusercontent.com',
      'peru21.pe',
      'ipsos.com',
    ]
    if (!allowed.some((d) => parsed.hostname === d || parsed.hostname.endsWith('.' + d))) {
      return new Response(
        JSON.stringify({ error: 'Domain not allowed' }),
        { status: 403, headers: { ...corsHeaders, 'Content-Type': 'application/json' } },
      )
    }

    // Forward request
    const headers: Record<string, string> = {}
    const ct = req.headers.get('content-type')
    if (ct) headers['Content-Type'] = ct
    const accept = req.headers.get('accept')
    if (accept) headers['Accept'] = accept

    const fetchOpts: RequestInit = {
      method: req.method,
      headers,
    }

    if (req.method === 'POST') {
      fetchOpts.body = await req.text()
    }

    const upstream = await fetch(targetUrl, fetchOpts)

    const respHeaders = new Headers(corsHeaders)
    const upstreamCt = upstream.headers.get('content-type')
    if (upstreamCt) respHeaders.set('Content-Type', upstreamCt)

    return new Response(await upstream.arrayBuffer(), {
      status: upstream.status,
      headers: respHeaders,
    })
  } catch (e) {
    return new Response(
      JSON.stringify({ error: String(e) }),
      { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } },
    )
  }
})
