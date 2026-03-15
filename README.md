# 🗳️ VotaClaro — App Electoral Perú 2026

> **Tu voto, bien informado.** — Datos verificados del JNE, ONPE, Datum e Ipsos. Sin sesgos. Sin publicidad partidaria.

---

## ¿Qué es VotaClaro?

**VotaClaro** es una aplicación Flutter de código abierto para las **Elecciones Generales del Perú 2026**. Integra el agente de inteligencia artificial **ELECTORAL_PE_2026** (vía Claude API o GPT-4o) para ofrecer información electoral verificable, neutral y accesible a todos los ciudadanos peruanos.

---

## Pantallas principales

| # | Pantalla | Descripción |
|---|---------|-------------|
| 1 | **🏠 Home** | Resumen electoral: candidatos top, encuestas, acceso rápido |
| 2 | **👥 Candidatos** | Lista con buscador y filtros (partido, región, % encuesta) |
| 3 | **📋 Perfil** | Detalle completo: patrimonio JNE, propuestas con semáforo, análisis predictivo |
| 4 | **⚖️ Comparar** | Comparador cara a cara en 8 dimensiones con IA |
| 5 | **🎯 Mi Voto** | Simulador personalizado: elige 5 prioridades → candidato ideal |
| 6 | **📊 Encuestas** | Gráficas certificadas: Datum · Ipsos · CPI · GfK |
| 7 | **📰 Noticias** | Feed fact-checked: Ojo Público · IDL-Reporteros · Convoca.pe |

---

## Stack técnico

```
Frontend:   Flutter 3.27.4 (iOS + Android + Web PWA)
Estado:     Flutter Riverpod 2.x (StateNotifier + FutureProvider)
Navegación: go_router 13.x (StatefulShellRoute — 6 branches)
IA:         Gemini Flash (gemini-flash-latest) — principal, gratis
            Claude 3 Haiku (claude-3-haiku-20240307) — fallback
Noticias:   RSS real (8 fuentes) + CORS proxy (allorigins.win)
Cache:      L1 in-memory (TTL 5 min) + L2 SharedPreferences (TTL 1 h)
JNE/ONPE:   INFOGOB · Voto Informado 2026 · Declara · Consulta Multa
Backend:    Firebase (Firestore + Cloud Functions) — opcional
Encuestas:  JNE API + mock Datum/Ipsos
Auth:       Anónimo (sin registro obligatorio)
Idiomas:    Español + Quechua Ayacucho-Chanka (quy)
```

---

## Configuración rápida

### 1. Clona el proyecto
```bash
git clone https://github.com/tu-usuario/votaclaro.git
cd votaclaro
flutter pub get
```

### 2. Configura tu API key
Edita el archivo `.env` en la raíz:
```env
CLAUDE_API_KEY=tu_clave_aqui
# o si prefieres GPT-4o:
OPENAI_API_KEY=tu_clave_aqui
```

### 3. Corre la aplicación
```bash
flutter run
```

---

## El agente ELECTORAL_PE_2026

El corazón de VotaClaro es el agente IA con acceso a:

- **JNE** — candidaturas, hojas de vida, patrimonio declarado
- **ONPE** — resultados históricos, simulacros
- **Datum, Ipsos, CPI, GfK** — encuestas certificadas
- **Ojo Público, IDL-Reporteros, Convoca.pe** — fact-checkers

### Módulos del agente

| Módulo | Función |
|--------|---------|
| **M1 — Presidencial** | Perfil, patrimonio, propuestas, predictivo |
| **M2 — Congreso** | Historial legislativo, asistencia, votos polémicos |
| **M3 — Parl. Andino** | Posición regional, historial diplomático |
| **M4 — Comparador** | 8 dimensiones: Economía · Seguridad · Salud · Educación · Corrupción · Medio Ambiente · Descentralización · RR.EE. |
| **M5 — Mi Voto** | Match % por prioridades ciudadanas |

### Semáforo de viabilidad
| Ícono | Significado |
|-------|-------------|
| 🟢 | Viabilidad Alta |
| 🟡 | Viabilidad Media |
| 🔴 | Viabilidad Baja |
| 🔄 | Propuesta reciclada (ya fue prometida antes) |

---

## Reglas de oro

1. **NEUTRALIDAD** — Ningún partido favorecido. Datos = argumentos.
2. **FUENTE SIEMPRE** — Cada dato lleva su fuente y fecha.
3. **BREVEDAD** — Si puedes decirlo en 5 palabras, no uses 10.
4. **PRIVACIDAD** — Tu preferencia de voto no es almacenada ni compartida.
5. **Sin publicidad partidaria** — Ningún partido puede pagar por visibilidad.

---

## Monetización ética

```
✅ Donaciones ciudadanas (modelo Wikipedia)
✅ Patrocinio de ONGs / observadores electorales
❌ Partidos políticos — PROHIBIDO pagar por visibilidad
❌ Publicidad comercial relacionada con candidatos
```

---

## Checklist de lanzamiento

### Infraestructura y configuración
- [x] Configurar API keys en `.env` (Gemini + Claude configurados)
- [ ] Configurar Firebase (`google-services.json` / `GoogleService-Info.plist`)

### Datos electorales JNE / ONPE
- [x] Conectar JNE API real (INFOGOB · Voto Informado 2026 · Declara)
- [x] Candidatos en tiempo real con caché L1/L2 + pull-to-refresh + infinite scroll
- [ ] Alianza con Datum/Ipsos para datos de encuestas oficiales

### Noticias y fact-checking
- [x] Feed RSS de IDL-Reporteros · Ojo Público · Convoca.pe · Epicentro TV · Sudaca.pe · RPP · Canal N · El Comercio
- [x] 5 categorías: investigación · fact-check · minuto a minuto · análisis · perfiles

### Funcionalidades cívicas
- [x] Tutorial "Cómo votar" (7 pasos) + simulador de cédula con marca X
- [x] Soporte básico en quechua (Ayacucho-Chanka) con toggle de idioma
- [x] Comparador cara a cara en 8 dimensiones con IA
- [x] Simulador "Mi Voto Ideal" por prioridades ciudadanas

### Neutralidad y transparencia
- [ ] Revisión de neutralidad por panel independiente
- [ ] Política de privacidad publicada

### Lanzamiento
- [ ] Registro JNE como aplicación observadora (opcional)
- [ ] **Meta:** 90 días antes de primera vuelta — 12 de abril de 2026 ⌚ 38 días restantes
  - Primera vuelta: 12 abr 2026
  - Segunda vuelta: 7 jun 2026

---

## Estructura del proyecto

```
lib/
├── main.dart                         # Punto de entrada
├── app.dart                          # MaterialApp + tema + router
├── core/
│   ├── constants/
│   │   ├── app_colors.dart           # Paleta de colores
│   │   ├── app_strings.dart          # Textos en español peruano
│   │   └── app_strings_qu.dart       # Textos en quechua (Ayacucho-Chanka)
│   ├── models/
│   │   ├── candidato.dart            # Modelo candidato + patrimonio + propuestas
│   │   └── electoral_models.dart     # Encuestas, noticias, comparación, Mi Voto
│   ├── services/
│   │   ├── ai_electoral_service.dart # Agente ELECTORAL_PE_2026 (Gemini / Claude)
│   │   ├── candidatos_cache_service.dart # Caché L1 (in-memory) + L2 (SharedPrefs)
│   │   ├── jne_api_service.dart      # INFOGOB · Voto Informado 2026 · Declara
│   │   ├── rss_news_service.dart     # Agregador RSS (8 fuentes, CORS proxy)
│   │   ├── providers.dart            # Riverpod providers (caché + paginación)
│   │   └── app_router.dart           # go_router con 6 branches
│   └── theme/
│       └── app_theme.dart            # Tema claro + oscuro
├── features/
│   ├── home/                         # Pantalla principal + toggle quechua
│   ├── candidates/                   # Lista tiempo real + caché + scroll infinito
│   ├── profile/                      # Perfil detallado del candidato
│   ├── compare/                      # Comparador cara a cara con IA
│   ├── como_votar/                   # Tutorial 7 pasos + simulador de cédula
│   ├── mi_voto/                      # Simulador Mi Voto Ideal
│   ├── polls/                        # Encuestas certificadas
│   └── news/                         # Feed RSS verificado por categorías
└── widgets/
    ├── common/                       # ViabilidadBadge, CandidatoCard, etc.
    └── navigation/                   # BottomNav con 6 tabs
```

---

## Contribuir

Este proyecto es de **código abierto y ciudadano**. Para contribuir:

1. Haz fork del repositorio
2. Crea un branch: `git checkout -b feat/mi-mejora`
3. Commit: `git commit -m 'feat: agrego módulo de parlamento andino'`
4. PR con descripción clara de los cambios

**Áreas prioritarias:**
- Integración real con API JNE (scraping oficial)
- Soporte en quechua (i18n)
- Tests unitarios de los providers
- PWA (Web) para mayor alcance

---

## Licencia

MIT — Uso libre para fines ciudadanos y educativos. Prohibido el uso comercial sin autorización y el uso por partidos políticos con fines de campaña.

---

*Hecho con ❤️ por y para ciudadanos peruanos.*
