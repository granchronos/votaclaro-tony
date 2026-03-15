// Supabase Edge Function — scrape-encuestas
// Serves latest poll data. Strategy:
//   1. Try to discover and extract from accessible news articles (RPP, etc.)
//   2. Return structured JSON compatible with the Encuesta model
//   3. Falls back gracefully — the Flutter app merges this with Gist + local data
//
// Sources: Google News RSS → article titles/dates → accessible article pages
//
// Note: Peru21 and Ipsos use Cloudflare bot protection, so direct scraping
// isn't possible. Most poll data lives in infographics, not text. This function
// extracts what it can and the app merges with the local asset + GitHub Gist.
//
// Deploy:
//   supabase functions deploy scrape-encuestas --no-verify-jwt

import { serve } from 'https://deno.land/std@0.208.0/http/server.ts'

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
  'Access-Control-Allow-Methods': 'GET, OPTIONS',
}

// ─── Candidate ID mapping ────────────────────────────────────────────────────

const CANDIDATE_MAP: Record<string, { id: string; partido: string; nombre: string }> = {
  'lopez aliaga': { id: 'lopez_aliaga', partido: 'Renovación Popular', nombre: 'Rafael López Aliaga' },
  'fujimori': { id: 'fujimori', partido: 'Fuerza Popular', nombre: 'Keiko Fujimori' },
  'keiko': { id: 'fujimori', partido: 'Fuerza Popular', nombre: 'Keiko Fujimori' },
  'alvarez': { id: 'alvarez', partido: 'País para Todos', nombre: 'Carlos Álvarez' },
  'acuna': { id: 'acuna', partido: 'Alianza para el Progreso', nombre: 'César Acuña' },
  'lopez chau': { id: 'lopez_chau', partido: 'Ahora Nación', nombre: 'Alfonso López-Chau' },
  'lopez-chau': { id: 'lopez_chau', partido: 'Ahora Nación', nombre: 'Alfonso López-Chau' },
  'grozo': { id: 'grozo', partido: 'Primero la Gente', nombre: 'Wolfgang Grozo' },
  'forsyth': { id: 'forsyth', partido: 'Somos Perú', nombre: 'George Forsyth' },
  'vizcarra': { id: 'vizcarra', partido: 'Perú Primero', nombre: 'Mario Vizcarra' },
  'belmont': { id: 'belmont', partido: 'Partido Cívico OBRAS', nombre: 'Ricardo Belmont' },
  'luna': { id: 'luna', partido: 'Podemos Perú', nombre: 'José Luna Gálvez' },
  'lescano': { id: 'lescano', partido: 'Cooperación Popular', nombre: 'Yonhy Lescano' },
  'nieto': { id: 'nieto', partido: 'Juntos por el Perú', nombre: 'Martín Nieto' },
  'sanchez': { id: 'sanchez', partido: 'Perú Libre', nombre: 'Roberto Sánchez' },
  'williams': { id: 'williams', partido: 'Partido Morado', nombre: 'Flor Pablo Williams' },
  'flor pablo': { id: 'williams', partido: 'Partido Morado', nombre: 'Flor Pablo Williams' },
}

function normalize(s: string): string {
  return s.toLowerCase().normalize('NFD').replace(/[\u0300-\u036f]/g, '').replace(/[^a-z0-9 -]/g, '').trim()
}

function matchCandidate(name: string): { id: string; partido: string; nombre: string } | null {
  const norm = normalize(name)
  if (CANDIDATE_MAP[norm]) return CANDIDATE_MAP[norm]
  for (const [key, val] of Object.entries(CANDIDATE_MAP)) {
    if (norm.includes(key) || key.includes(norm)) return val
  }
  return null
}

// ─── Types ───────────────────────────────────────────────────────────────────

interface EncuestaResult {
  candidatoId: string
  nombreCandidato: string
  partido: string
  porcentaje: number
}

interface Encuesta {
  id: string
  empresa: string
  metodologia: string
  muestreo: number
  margenError: number
  fechaPublicacion: string
  urlFuente: string
  esCertificada: boolean
  resultados: EncuestaResult[]
}

// ─── Extraction helpers ──────────────────────────────────────────────────────

function stripHtml(html: string): string {
  return html
    .replace(/<script[^>]*>[\s\S]*?<\/script>/gi, '')
    .replace(/<style[^>]*>[\s\S]*?<\/style>/gi, '')
    .replace(/<[^>]+>/g, ' ')
    .replace(/&nbsp;/g, ' ').replace(/&amp;/g, '&')
    .replace(/&lt;/g, '<').replace(/&gt;/g, '>')
    .replace(/&#(\d+);/g, (_, n) => String.fromCharCode(parseInt(n)))
    .replace(/\s+/g, ' ').trim()
}

function extractPollData(text: string): EncuestaResult[] {
  const results: EncuestaResult[] = []
  const seen = new Set<string>()

  const patterns = [
    /([A-ZÁÉÍÓÚÑ][a-záéíóúñA-ZÁÉÍÓÚÑ\s\-]{2,30}?)[\s:,]+(\d{1,2}(?:\.\d)?)\s*%/g,
    /([A-ZÁÉÍÓÚÑ][a-záéíóúñA-ZÁÉÍÓÚÑ\s\-]{2,30}?)\s*\((\d{1,2}(?:\.\d)?)\s*%\)/g,
    /([A-ZÁÉÍÓÚÑ][a-záéíóúñA-ZÁÉÍÓÚÑ\s\-]{2,30}?)\s+(?:con|tiene|obtuvo|alcanza|registra)\s+(?:el\s+)?(\d{1,2}(?:\.\d)?)\s*%/gi,
  ]

  for (const pattern of patterns) {
    let match
    while ((match = pattern.exec(text)) !== null) {
      const rawName = match[1].trim()
      const pct = parseFloat(match[2])
      if (pct < 1 || pct > 60) continue
      const candidate = matchCandidate(rawName)
      if (candidate && !seen.has(candidate.id)) {
        seen.add(candidate.id)
        results.push({
          candidatoId: candidate.id,
          nombreCandidato: candidate.nombre,
          partido: candidate.partido,
          porcentaje: pct,
        })
      }
    }
  }

  results.sort((a, b) => b.porcentaje - a.porcentaje)
  return results
}

function extractDate(html: string): string | null {
  const jsonLd = html.match(/"datePublished"\s*:\s*"([^"]+)"/)
  if (jsonLd) {
    const d = new Date(jsonLd[1])
    if (!isNaN(d.getTime())) return d.toISOString().split('T')[0]
  }
  const meta = html.match(/<meta[^>]+(?:property="article:published_time"|name="date")[^>]+content="([^"]+)"/i)
  if (meta) {
    const d = new Date(meta[1])
    if (!isNaN(d.getTime())) return d.toISOString().split('T')[0]
  }
  return null
}

function detectEmpresa(text: string): string {
  const lower = text.toLowerCase()
  if (lower.includes('ipsos')) return 'Ipsos Perú'
  if (lower.includes('cpi')) return 'CPI'
  if (lower.includes('datum')) return 'Datum'
  if (lower.includes('iep')) return 'IEP'
  return 'Encuestadora'
}

// ─── Google News RSS ─────────────────────────────────────────────────────────

interface RssItem { title: string; link: string; pubDate: string; source: string; sourceUrl: string }

function parseRssItems(xml: string): RssItem[] {
  const items: RssItem[] = []
  const itemRegex = /<item>([\s\S]*?)<\/item>/g
  let match
  while ((match = itemRegex.exec(xml)) !== null) {
    const block = match[1]
    const title = block.match(/<title>([^<]+)<\/title>/)?.[1] ?? ''
    const link = block.match(/<link>(https?:[^<]+)<\/link>/)?.[1] ?? ''
    const pubDate = block.match(/<pubDate>([^<]+)<\/pubDate>/)?.[1] ?? ''
    const source = block.match(/<source[^>]*>([^<]+)<\/source>/)?.[1] ?? ''
    const sourceUrl = block.match(/<source[^>]+url="([^"]+)"/)?.[1] ?? ''
    if (title && link) items.push({ title, link, pubDate, source, sourceUrl })
  }
  return items
}

// Domains that don't block server-side fetch
const ACCESSIBLE_DOMAINS = ['rpp.pe', 'larepublica.pe', 'gestion.pe', 'elperuano.pe', 'andina.pe', 'infobae.com']

function isAccessible(url: string): boolean {
  try {
    const hostname = new URL(url).hostname
    return ACCESSIBLE_DOMAINS.some(d => hostname === d || hostname.endsWith('.' + d))
  } catch {
    return false
  }
}

// ─── Main ────────────────────────────────────────────────────────────────────

serve(async (req) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  try {
    const encuestas: Encuesta[] = []
    const seenIds = new Set<string>()
    let articlesChecked = 0

    // Step 1: Discover poll articles via Google News RSS
    const queries = [
      'encuesta+ipsos+peru+2026+presidencial',
      'encuesta+CPI+datum+peru+2026+intencion+voto',
    ]

    const rssItems: RssItem[] = []
    for (const q of queries) {
      try {
        const rssUrl = `https://news.google.com/rss/search?q=${q}&hl=es-419&gl=PE&ceid=PE:es-419`
        const res = await fetch(rssUrl, {
          headers: { 'User-Agent': 'Mozilla/5.0 (compatible; VotaClaroBot/1.0)' },
        })
        if (res.ok) {
          rssItems.push(...parseRssItems(await res.text()))
        }
      } catch { /* ignore */ }
    }

    // Filter to poll-related items
    const pollKeywords = /encuesta|sondeo|intenci[oó]n de voto|simulacro|preferencia presidencial/i
    const pollItems = rssItems.filter(item => pollKeywords.test(item.title)).slice(0, 10)

    // Step 2: Try to find and fetch accessible article pages
    for (const item of pollItems) {
      // Build potential direct URLs from source info
      const sourceHost = item.sourceUrl ? new URL(item.sourceUrl).hostname : ''
      
      // Only try accessible domains
      if (!ACCESSIBLE_DOMAINS.some(d => sourceHost === d || sourceHost.endsWith('.' + d))) continue

      // Try to find the article on the accessible source site
      // Google News links can't be easily resolved, so we search for the article
      // by constructing a search URL on the source site
      const slug = item.title
        .toLowerCase()
        .normalize('NFD').replace(/[\u0300-\u036f]/g, '')
        .replace(/[^a-z0-9\s]/g, '')
        .split(/\s+/)
        .filter(w => w.length > 3)
        .slice(0, 6)
        .join('+')

      // Try fetching the Google News link directly (some resolve)
      let articleHtml = ''
      let articleUrl = item.link
      
      try {
        const res = await fetch(item.link, {
          headers: { 'User-Agent': 'Mozilla/5.0 (compatible; VotaClaroBot/1.0)' },
          redirect: 'follow',
        })
        articlesChecked++
        if (res.ok) {
          const finalUrl = res.url
          articleHtml = await res.text()
          
          // Check if we got Cloudflare or Google's page
          if (articleHtml.includes('Just a moment') || !articleHtml.includes('</article')) {
            articleHtml = '' // Not a real article
          } else {
            articleUrl = finalUrl
          }
        }
      } catch { /* ignore */ }

      if (!articleHtml) continue

      const articleText = stripHtml(articleHtml)
      const resultados = extractPollData(articleText)
      if (resultados.length < 3) continue

      const date = extractDate(articleHtml) || (item.pubDate ? new Date(item.pubDate).toISOString().split('T')[0] : null)
      if (!date) continue

      const empresa = detectEmpresa(item.title + ' ' + articleText)
      const id = `${empresa.toLowerCase().replace(/\s+/g, '_')}_${date.replace(/-/g, '_')}`
      if (seenIds.has(id)) continue
      seenIds.add(id)

      let muestreo = 1300
      const sampleMatch = articleText.match(/(?:muestra|encuestados?|personas)[:\s]+de?\s*(\d[\d.,]*)/i)
      if (sampleMatch) {
        const n = parseInt(sampleMatch[1].replace(/[.,]/g, ''))
        if (n >= 300 && n <= 50000) muestreo = n
      }

      let margenError = 2.7
      const marginMatch = articleText.match(/(?:margen|error)[^.]{0,30}?(\d+[.,]\d+)\s*%/i)
      if (marginMatch) {
        const m = parseFloat(marginMatch[1].replace(',', '.'))
        if (m >= 0.5 && m <= 10) margenError = m
      }

      encuestas.push({
        id, empresa, metodologia: 'Encuesta urbano-rural',
        muestreo, margenError, fechaPublicacion: date,
        urlFuente: articleUrl, esCertificada: true, resultados,
      })
    }

    encuestas.sort((a, b) => b.fechaPublicacion.localeCompare(a.fechaPublicacion))

    return new Response(
      JSON.stringify({
        encuestas,
        scraped: new Date().toISOString(),
        rssItemsTotal: rssItems.length,
        pollArticlesFound: pollItems.length,
        articlesChecked,
      }),
      {
        status: 200,
        headers: {
          ...corsHeaders,
          'Content-Type': 'application/json',
          'Cache-Control': 'public, max-age=3600',
        },
      },
    )
  } catch (e) {
    return new Response(
      JSON.stringify({ error: String(e), encuestas: [] }),
      { status: 200, headers: { ...corsHeaders, 'Content-Type': 'application/json' } },
    )
  }
})
