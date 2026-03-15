# VotaClaro — Project Instructions

## Overview
VotaClaro is a Flutter civic information app for Peru's 2026 General Elections. It provides verified, neutral, and accessible data about candidates, government plans, polls, and news. The app runs on iOS, Android, and Web (Cloudflare Pages).

## Tech Stack
- **Flutter 3.27+** with Material 3, Dart 3.6+
- **State management**: `flutter_riverpod` (providers in `lib/core/services/providers.dart`)
- **Navigation**: `go_router` with `StatefulShellRoute` (routes in `lib/core/services/app_router.dart`)
- **Backend**: Supabase (auth, cache, user preferences, edge functions)
- **APIs**: JNE Voto Informado 2026, JNE Plataforma Electoral, JNE IA API
- **CORS Proxy**: Supabase Edge Function `cors-proxy` at `supabase/functions/cors-proxy/index.ts` — all web API calls and images go through it via `lib/core/services/cors_proxy.dart`
- **PDF parsing**: `syncfusion_flutter_pdf` via `lib/core/services/pdf_service.dart`
- **Image caching**: `cached_network_image` (always use `CachedNetworkImage` instead of `Image.network`)
- **Fonts**: Inter family from `assets/fonts/`
- **Theme**: Light default (`ThemeMode.light`), dark available. Colors in `lib/core/constants/app_colors.dart`, themes in `lib/core/theme/app_theme.dart`

## Project Structure
```
lib/
├── main.dart              # Entry point (Supabase init, orientation lock)
├── app.dart               # MaterialApp.router (theme, router, text scaling)
├── core/
│   ├── constants/         # AppColors, strings
│   ├── l10n/              # Localization (Spanish-first, Quechua support)
│   ├── models/            # Data models (Candidato, Encuesta, Noticia, etc.)
│   ├── services/          # API services, providers, cache, Supabase, CORS proxy
│   └── theme/             # AppTheme.light / AppTheme.dark
├── features/
│   ├── candidates/        # Candidate listing and filtering
│   ├── como_votar/        # "How to vote" guide
│   ├── compare/           # Compare candidates side by side
│   ├── home/              # Home screen with top candidates, search, filters
│   ├── mi_voto/           # "My vote" priority matching
│   ├── news/              # RSS news aggregator
│   ├── polls/             # Poll data visualization
│   └── profile/           # Candidate profile (HV, plan de gobierno, AI analysis)
└── widgets/
    ├── common/            # Shared widgets (CandidatoCard, badges, etc.)
    └── navigation/        # Bottom nav, app bar
```

## Cache Architecture
- **L1**: In-memory cache (CandidatosCacheService, 5min TTL)
- **L2**: SharedPreferences (CandidatosCacheService, 1hr TTL)
- **L3**: Supabase remote cache (SupabaseService, plans de gobierno)

## Key APIs
- **JNE Working**: `https://votoinformadoia.jne.gob.pe/ServiciosWeb/api/v1`
- **JNE Legacy (may 404)**: `https://web.jne.gob.pe/serviciovotoinformado/api/votoinf`
- **Supabase**: `https://efbrpoustizkyldlqoit.supabase.co`

## Web Deployment
- **Hosting**: Cloudflare Pages (project: `votaclaro`)
- **Build**: `flutter build web --release --dart-define-from-file=env.web.json`
- **CI/CD**: `.github/workflows/deploy.yml` — auto-deploys on push to `main`
- **CORS**: All external API calls on web go through the Supabase Edge Function `cors-proxy` (supports GET/POST via `x-target-url` header, images via `?url=` query param)
- **Env vars**: `env.web.json` has `SUPABASE_URL` and `SUPABASE_ANON_KEY` (injected via `--dart-define-from-file`)

## Development Rules

### ALWAYS
- Use `CachedNetworkImage` for all network images (never `Image.network`)
- Use `CorsProxy.imageUrl(url)` for any image URL displayed on web (JNE photos, logos)
- Use `CorsProxy.get()` / `CorsProxy.post()` for API calls on web (`kIsWeb` guard)
- Pull colors from `AppColors`, text styles from theme
- Use `ConsumerWidget` / `ConsumerStatefulWidget` for Riverpod
- Add `const` constructors where applicable
- Keep all user-facing strings in Spanish
- Use `ref.keepAlive()` for providers that should persist across navigation
- Run `flutter analyze` after edits

### NEVER
- Hardcode colors, font sizes, or spacing
- Use `setState` for shared/global state (use Riverpod providers)
- Expose API keys in client-side code (use Supabase Edge Functions)
- Use `allorigins.win` or similar third-party CORS proxies (use our own `cors-proxy`)
- Skip error handling on API calls (always return empty/fallback gracefully)
- Create landscape-specific layouts (portrait only)

### CORS Proxy Usage
```dart
// API calls (GET/POST):
if (kIsWeb) {
  res = await CorsProxy.post(uri, headers: headers, body: body);
} else {
  res = await http.post(uri, headers: headers, body: body);
}

// Image URLs:
final imageUrl = CorsProxy.imageUrl('https://mpesije.jne.gob.pe/apidocs/photo.jpg');
// Returns proxied URL on web, original on native

// Edge Function allow-list (supabase/functions/cors-proxy/index.ts):
// *.jne.gob.pe, RSS feeds, gist.githubusercontent.com
```

### PDF Plan de Gobierno
- Always parse `rutaCompleto` (full version) first, fallback to `rutaResumen`
- Display order: Full version first, then summary
- PDF download goes through CORS proxy on web
- Parsed via `parsedPdfProvider` in `providers.dart`

## Build & Run
```bash
# Local web (dev)
cd votaclaro
flutter run -d chrome --web-port 8080 --dart-define-from-file=env.web.json

# iOS
flutter run -d <device_id>

# Production web build
flutter build web --release --dart-define-from-file=env.web.json

# Deploy CORS proxy
supabase functions deploy cors-proxy --no-verify-jwt

# Deploy to Cloudflare (manual)
npx wrangler pages deploy build/web --project-name=votaclaro
```
