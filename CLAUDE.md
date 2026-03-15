# CLAUDE.md — VotaClaro

This file provides guidance to Claude when working on this codebase.

## What is VotaClaro?
A Flutter app for Peru's 2026 General Elections. Provides verified JNE candidate data, government plans, polls, and news. Runs on iOS, Android, and Web (Cloudflare Pages).

## Quick Reference

| Area | Location |
|------|----------|
| Entry point | `lib/main.dart` |
| App config | `lib/app.dart` |
| All providers | `lib/core/services/providers.dart` |
| Routes | `lib/core/services/app_router.dart` |
| API service | `lib/core/services/jne_api_service.dart` |
| CORS proxy helper | `lib/core/services/cors_proxy.dart` |
| CORS Edge Function | `supabase/functions/cors-proxy/index.ts` |
| Supabase service | `lib/core/services/supabase_service.dart` |
| Cache service | `lib/core/services/candidatos_cache_service.dart` |
| PDF parser | `lib/core/services/pdf_service.dart` |
| Colors | `lib/core/constants/app_colors.dart` |
| Theme | `lib/core/theme/app_theme.dart` |
| Web env | `env.web.json` |
| CI/CD | `.github/workflows/deploy.yml` |
| DB schema | `supabase_schema.sql` |

## Critical Rules

1. **CORS on Web**: All network calls on web MUST go through `CorsProxy` (`lib/core/services/cors_proxy.dart`). The proxy is a Supabase Edge Function with a domain allow-list.
2. **Images**: Always use `CachedNetworkImage` + `CorsProxy.imageUrl(url)` for network images.
3. **Theme**: Default is `ThemeMode.light`. Never hardcode colors — use `AppColors`.
4. **Spanish**: All UI strings are in Spanish. Tone: neutral, informative, civic.
5. **Error handling**: All API calls fail gracefully — return empty lists/maps, never crash.
6. **PDF parsing**: Prefer `rutaCompleto` (full plan) over `rutaResumen`. Display full version first.
7. **No third-party CORS proxies**: We use our own `cors-proxy` Edge Function. Never use allorigins.win or similar.

## Build Commands
```bash
flutter run -d chrome --web-port 8080 --dart-define-from-file=env.web.json  # dev web
flutter build web --release --dart-define-from-file=env.web.json            # prod web
supabase functions deploy cors-proxy --no-verify-jwt                        # deploy proxy
```

## Deployment
- Push to `main` → GitHub Actions builds Flutter web → deploys to Cloudflare Pages
- Supabase Edge Functions deployed manually via `supabase functions deploy`
