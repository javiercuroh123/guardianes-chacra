# Privacidad: qué cambia con los anuncios

> Esto es una guía para preparar la publicación, no asesoría legal. Las declaraciones de Google cambian: revísalas otra vez al llenar Play Console (Fase 11).

## Qué datos maneja el juego

| Quién | Qué | ¿Sale del teléfono? |
|---|---|---|
| El juego | Progreso, estrellas y ajustes (`SharedPreferences`) | No. Se borra al desinstalar o al borrar los datos de la app. |
| La analítica del juego | Nivel empezado, ganado o perdido | Hoy no: solo se escribe en la consola en debug. Con Firebase (Fase 11), sí. |
| El SDK de anuncios de Google (AdMob) | Ver la tabla siguiente | Sí, a Google. |

Según la [declaración de datos de AdMob para Google Play](https://developers.google.com/admob/android/privacy/play-data-disclosure), revisada el 17 de octubre de 2026 (escrita para el SDK de Android 25.5.0; el juego usa la 25.4.0 a través de `google_mobile_ads` 9.1.0), el SDK **recopila y comparte automáticamente** estos datos, **cifrados en tránsito**, con fines de **publicidad, analítica y prevención de fraude**:

| Dato | Ejemplo |
|---|---|
| Dirección IP | Sirve para estimar la ubicación aproximada. |
| Interacciones con la app | Aperturas, toques y anuncios vistos. |
| Diagnóstico | Rendimiento de la app y del SDK. |
| Identificadores del dispositivo | ID de publicidad de Android, App set ID. |

El SDK agrega estos permisos al manifiesto final (comprobado con `aapt2 dump permissions` sobre el APK el 17 de octubre de 2026). Al subir a Play Console conviene saber de dónde salen:

| Permiso | Para qué |
|---|---|
| `INTERNET`, `ACCESS_NETWORK_STATE` | Cargar anuncios. |
| `com.google.android.gms.permission.AD_ID` | Leer el ID de publicidad: obliga a la declaración de "ID de publicidad". |
| `ACCESS_ADSERVICES_AD_ID`, `ACCESS_ADSERVICES_ATTRIBUTION`, `ACCESS_ADSERVICES_TOPICS` | Privacy Sandbox de Android (la nueva forma de medir anuncios). |
| `WAKE_LOCK`, `FOREGROUND_SERVICE` | Tareas en segundo plano del SDK (WorkManager). Si Play Console pregunta por servicios en primer plano, revisarlo en la Fase 11. |

## La política de privacidad

Con anuncios, Google Play exige una política de privacidad publicada en una URL pública. Debe decir, en palabras simples:

1. **Quién eres** y un correo de contacto.
2. **Qué guarda el juego** y que se queda en el teléfono.
3. **Que hay anuncios de Google AdMob** y que Google recopila los datos de la tabla anterior para mostrar anuncios, medirlos y prevenir fraude. Enlaza la página de Google [Cómo usa Google la información de sitios o aplicaciones que utilizan sus servicios](https://policies.google.com/technologies/partner-sites).
4. **El consentimiento:** en Europa y otras regiones se pide al abrir el juego, y se puede cambiar en Ajustes → Opciones de privacidad.
5. **Cómo limitar el ID de publicidad:** Ajustes de Android → Privacidad → Anuncios → Borrar o restablecer el ID de publicidad.
6. **La edad:** el juego está pensado para mayores de 13 años y pide anuncios aptos para todo público.
7. **Cuando conectes Firebase Analytics** (Fase 11), qué eventos se mandan (nivel, estrellas, oleada) y que Google los procesa.
8. **Cómo pedir información o borrado:** por el correo de contacto. Los datos del juego se borran desinstalándolo.

Dónde publicarla gratis lo vemos en la Fase 11 (por ejemplo, GitHub Pages o Google Sites).

## El formulario de Seguridad de los datos (Play Console)

Respuestas que corresponden **por AdMob**. Al conectar Firebase se suman sus datos.

| Pregunta | Respuesta |
|---|---|
| ¿La app recopila o comparte datos del usuario? | Sí. |
| ¿Los datos se cifran en tránsito? | Sí. |
| ¿Los usuarios pueden pedir que se borren? | Puedes responder que sí, por el correo de la política. |
| Ubicación → aproximada | Recopilada y compartida (por la IP). Fines: publicidad, analítica, prevención de fraude. |
| Actividad en la app → interacciones | Recopilada y compartida. Mismos fines. |
| Información y rendimiento de la app → diagnóstico | Recopilada y compartida. Mismos fines. |
| Dispositivo u otros identificadores | Recopilado y compartido. Mismos fines. |
| ¿Es obligatorio u opcional? | Obligatorio para los anuncios. En Europa depende del consentimiento. |

Lo que **no** se marca: nombre, correo, contactos, fotos, ubicación precisa, compras.

## Otras declaraciones en Play Console

- **Anuncios:** "La app contiene anuncios: Sí".
- **ID de publicidad:** la app lo usa; el propósito es "Publicidad o marketing".
- **Público objetivo:** 13 años o más. Si en el futuro se incluyen menores de 13, cambian las reglas: política de Familias, anuncios sin personalizar y el consentimiento se configura distinto. Habría que revisarlo.
- **Clasificación de contenido (IARC):** responder el cuestionario indicando que hay anuncios.
