# Anuncios y analítica

## Qué hay en el juego

| Anuncio | Dónde | Recompensa o regla |
|---|---|---|
| Recompensado | Vista previa de un nivel: "Ver anuncio: +50 de maíz" | Empieza la partida con ese maíz extra. Al reintentar ya no se suma. |
| Recompensado | Derrota: "Ver anuncio: seguir con 5 papas" | La partida sigue con esas papas y sin las plagas que había en pantalla (sin dar maíz por ellas). Una vez por partida. |
| Intersticial | Al salir del resultado (ganar o perder) | Como máximo uno cada 3 partidas terminadas, y nunca si en esa partida se vio un recompensado. |

- **Los botones solo aparecen si hay un anuncio cargado.** Sin internet, sin consentimiento o en una compilación sin IDs, el juego se ve igual que antes.
- **Recompensa solo si se ve entero.** Si el jugador cierra el recompensado antes de tiempo, no se le da y aparece un aviso.
- **Valores en los datos:** los tres números están en `assets/content/ads.json` (ver `docs/CONTENIDO.md`). Un 0 apaga esa parte.
- **Contenido de los anuncios:** se piden aptos para todo público (clasificación G de AdMob), aunque el juego se declare para mayores de 13 años.

## Cómo está armado

- **`AdsService`** (`lib/core/services/ads_service.dart`): la interfaz. El juego pide "un recompensado" o "un intersticial" sin saber de AdMob.
  - **`NoAdsService`:** la implementación por defecto (tests, y release sin IDs).
  - **`GoogleAdsService`:** la real, con `google_mobile_ads` 9.1.0.
- **`AdPolicy`** (`lib/features/ads/domain/`, Dart puro): cuenta las partidas y decide cuándo toca el intersticial.
- **`AdUnitIds`:** elige los IDs (ver abajo).
- **`AnalyticsService`** (`lib/core/services/analytics_service.dart`): la interfaz de analítica.
  - **`BattleAnalytics`** escucha la partida y anota `level_start`, `level_complete` y `level_fail` (con la oleada en que se perdió).
  - **Hoy no sale del teléfono:** en debug y profile los eventos se escriben en la consola (`DebugAnalyticsService`); en release no se anota nada. Firebase Analytics se conecta en la Fase 11 con otra implementación de la misma interfaz.

## IDs de prueba e IDs reales

**En debug y profile se usan siempre los IDs de prueba de Google**, aunque existan los reales. Tocar anuncios reales en tu propio teléfono es "tráfico no válido" y puede hacer que AdMob suspenda la cuenta.

| Qué | Prueba | Dónde va el real |
|---|---|---|
| App ID | `ca-app-pub-3940256099942544~3347511713` | `android/admob.properties` (fuera de git) |
| Bloque recompensado | `ca-app-pub-3940256099942544/5224354917` | `admob.json` → `ADMOB_REWARDED_ID` |
| Bloque intersticial | `ca-app-pub-3940256099942544/1033173712` | `admob.json` → `ADMOB_INTERSTITIAL_ID` |

**Para pasar a los reales** (cuando la app esté en Google Play, Fase 11):

1. Crea una cuenta en [AdMob](https://admob.google.com) y agrega la app. Lo ideal es vincularla a su ficha de Play.
2. Crea dos bloques de anuncios: uno **recompensado** y uno **intersticial**.
3. Copia `android/admob.properties.example` como `android/admob.properties` y pon el App ID.
4. Copia `admob.example.json` como `admob.json` (en la raíz del proyecto) y pon los IDs de los bloques.
5. Compila el release con esos IDs:

   ```powershell
   flutter build appbundle --release --dart-define-from-file=admob.json
   ```

Sin `admob.json`, el release sale **sin anuncios**: nunca con los de prueba. Los dos archivos reales están en `.gitignore`; los `.example` sí se suben.

## Probar en el teléfono

```powershell
flutter run
```

Con los IDs de prueba los anuncios llevan la etiqueta "Anuncio de prueba". Se pueden tocar sin problema.

Los anuncios de prueba son de Google y **no siguen el filtro de contenido G**: en el Redmi salió uno con una escena romántica. El filtro se aplica a los anuncios reales. Si con los reales aparece algo inapropiado, se puede bloquear por categoría en AdMob (Controles de bloqueo).

- **Recompensado:** entra a la vista previa de un nivel. El botón aparece en unos segundos, cuando el anuncio terminó de cargar.
- **Revivir:** pierde una partida (con el panel 🐞 no hace falta jugarla entera: "Saltar oleada" acelera).
- **Intersticial:** termina 3 partidas sin ver recompensados y sal del resultado.
- **Si algo no carga:** en la consola aparece `Anuncios: falló …` con el motivo. Un anuncio que no carga no rompe nada: se reintenta a los 30 s.

### El formulario de consentimiento (como si estuvieras en Europa)

En Perú el formulario normalmente no aparece. Para verlo:

1. Corre la app una vez con `flutter run` y busca en la consola la línea `UserMessagingPlatform` que sugiere `addTestDeviceHashedId("…")`. Ese texto entre comillas es el id de prueba de tu teléfono.
2. Córrela así:

   ```powershell
   flutter run --dart-define=UMP_TEST_DEVICE=EL_ID_DE_TU_TELEFONO
   ```

Al abrir aparece el formulario ("Publisher Test Ads", porque usa el App ID de prueba) y, en Ajustes, "Opciones de privacidad". Para que el formulario vuelva a salir al abrir después de responderlo, borra los datos de la app (Ajustes de Android → Apps → Guardianes de la Chacra → Almacenamiento → Borrar datos; ojo, también borra el progreso). Esto solo funciona fuera de release.

Probado en el Redmi el 17 de octubre de 2026: el formulario apareció sin borrar datos, y "Opciones de privacidad" lo vuelve a abrir.

## Reglas de AdMob que conviene recordar

- No toques tus propios anuncios reales ni pidas a nadie que lo haga.
- El recompensado siempre es opcional y la recompensa se describe antes de verlo ("+50 de maíz").
- Nada de intersticiales en medio de la partida ni al abrir la app: solo en pausas naturales, que aquí es la salida del resultado.
- Lo que cambia en la política de privacidad y en Play Console: `docs/PRIVACIDAD.md`.
