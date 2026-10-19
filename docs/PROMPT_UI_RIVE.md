# Prompt paso a paso: interfaz animada de "Guardianes de la Chacra" con Rive

Rehacer toda la interfaz (UX/UI) del tower defense en Rive, con animaciones, y conectarla al juego en Flutter. Claude construye el archivo de Rive directamente en el editor a través del MCP de Rive y después lo integra en el código, una fase a la vez y con pausa para tu aprobación, igual que en `prompt-tower-defense.md`.

## Cómo usarlo

1. Abre **Rive desktop**, inicia sesión y renombra el archivo abierto ("Untitled") a `Guardianes UI`. Déjalo como pestaña activa mientras Claude trabaja: el MCP edita el archivo que está al frente.
2. En **Claude desktop**, abre la pestaña **Code** en la carpeta `guardianes_chacra`, para que Claude pueda leer las referencias, editar el código y usar Rive en la misma conversación. El conector de Rive debe estar activo.
3. Pega el **Prompt 0** una sola vez y pídele que lo agregue a `CLAUDE.md` como sección "Interfaz con Rive", para que lo lea en cada sesión.
4. Pega las fases **en orden**. No avances hasta aprobar las capturas de Rive y probar la fase en el Redmi.
5. Mientras Claude edita en Rive, mira pero no edites el mismo artboard: los cambios simultáneos se pisan.
6. Rive guarda los archivos en la nube. El juego usa el `.riv` que Claude exporta a `assets/rive/`. La copia editable `.rev` puede pedir un plan de pago; el `.riv` se exporta en todos los planes.
7. Lo que Claude **no** hace bien en Rive son las ilustraciones detalladas, como los personajes de las referencias. En el Prompt 0 eliges entre versiones vectoriales simplificadas hechas por Claude o PNG/SVG que tú le pases para que los anime.

---

## Prompt 0 — Contexto de la interfaz

```
Actúa como diseñador de UX/UI de juegos móviles, animador de Rive y desarrollador senior de Flutter. Vamos a rehacer, por fases, toda la interfaz de mi tower defense "Guardianes de la Chacra" con Rive, con animaciones, y a conectarla al juego. Sé mi mentor: es mi primera vez con Rive, así que explícame brevemente cada decisión (artboards, componentes, layouts, view models, data binding, state machines).

## Dónde está todo
- Proyecto: esta carpeta (guardianes_chacra). Lee primero CLAUDE.md: arquitectura, reglas de trabajo y decisiones de las Fases 1 a 10. Todo eso sigue vigente.
- Referencias en referencias_ui/2026-10-19/:
  - propuestas/01 a 15 (1870×841, 20:9): la dirección de arte que quiero. Son maquetas generadas con IA: guían la apariencia y la distribución, pero no son assets finales (tienen el texto horneado y baja resolución) y sus cifras son ilustrativas. Recorta zonas con Python si necesitas ver detalles.
  - capturas_actuales/01 a 13: cómo se ve el juego hoy en el Redmi.
  - 00_vista_general.jpg (la colección con nombres), prompts.json (la dirección de arte escrita) y README.md.
- Pantallas actuales: menu/presentation/title_screen.dart, level_select/presentation/ (valle y vista previa), battle/presentation/hud/battle_hud.dart, battle/presentation/menus/ (menú radial), battle/presentation/overlays/battle_overlays.dart, bestiary/presentation/bestiary_screen.dart, settings/presentation/settings_screen.dart, app/app_theme.dart y app/text_scale.dart.
- Rive: tienes el MCP de Rive conectado a Rive desktop. El archivo de trabajo es "Guardianes UI", la pestaña activa.

## Dirección visual (de las referencias)
- Cartoon andino expresivo y legible, para todas las edades, en horizontal.
- Paneles crema con borde marrón oscuro grueso y una guarda tejida andina sutil. Botones principales de maíz dorado con bisel y secundarios crema. Acentos turquesa, terracota, verde hoja y ciruela. Títulos en carteles de madera ocre con hojas.
- Letra redondeada y gruesa, muy legible en español (¡ ¿ á é ñ).
- El maíz es la única moneda, las papas son las vidas y las estrellas marcan el avance. No agregues gemas, tienda, energía, misiones ni nada que el juego no tenga.

## Qué va en Rive y qué no
- En Rive va la "piel" animada de la interfaz: botones, contadores del HUD, barra de oleadas, menú de construcción, mejora y especialización, paneles de pausa, victoria y derrota, logo y mascotas del título, nodos del valle, bestiario, ajustes y transiciones.
- Flutter sigue a cargo de la navegación, los toques, la semántica para TalkBack, las claves de los tests, los textos traducidos y el estado (Riverpod).
- Flame sigue dibujando el campo de batalla. El arte del mapa y los sprites de plagas y guardianes en batalla no entran en este plan.

## Requisitos (obligatorios)
1. Data binding: cada artboard expone un view model; no uses los inputs heredados de las state machines. Los estados son enums, las acciones son triggers y los números y textos son propiedades. Flutter escribe una propiedad solo cuando su valor cambia (el HUD ya se actualiza por eventos, no en cada frame).
2. Ningún texto horneado: todo texto visible es una propiedad string ligada al Text Run, que Flutter llena desde los ARB o desde assets/content/i18n (español e inglés). Los números los formatea Dart. Prueba cada componente con el texto más largo de los dos idiomas.
3. Los toques los maneja Flutter. Cada control de Rive va dentro de un widget de Flutter que tiene la Key, la Semantics, el onTap, el sonido y la vibración, y que le pasa a Rive "pressed" y "enabled". Conserva todas las claves de los tests: hud-next-wave, hud-speed, hud-pause, hud-dev, build-<id>, menu-upgrade, menu-branch-<id>, menu-sell, menu-targeting, pause-resume, victory-next, battle-retry, battle-exit, preview-rewarded, battle-revive, settings-privacy. Si en algún caso conviene que el toque lo detecte Rive (un listener que dispara un trigger que Flutter escucha), propónlo y justifícalo.
4. Rive no reproduce sonido: el audio sigue en AudioService con su SoundLimiter. Si un sonido debe ir sincronizado con una animación (por ejemplo, cada estrella de la victoria), Rive dispara un trigger del view model y Flutter toca el sonido y la vibración.
5. Accesibilidad: respeta TextScaleLimits (HUD y menú radial hasta 1,3×, lo demás hasta 2×; text_scale_test.dart no debe fallar), el contraste AA de app_theme_test.dart y una propiedad reduceMotion (desde MediaQuery.disableAnimations) que apague los bucles y los movimientos grandes.
6. Responsive: diseña los artboards de pantalla a 853×384 (los dp del Redmi en horizontal, con ~39 dp de SafeArea por la cámara) y pruébalos también a 1280×800 y 1024×768. Usa los Layouts de Rive para que paneles y barras se reacomoden en lugar de estirarse.
7. Rendimiento: el juego debe mantener 60 FPS con más de 100 plagas en el Redmi (hoy da 73–77 FPS en x2 con 167 plagas; ver docs/RENDIMIENTO.md). Las animaciones en bucle se detienen cuando no se ven. Mide cuánto peso agrega Rive al APK.
8. Respaldo: si el .riv no carga, el widget muestra el aspecto actual de Flutter, igual que los sprites que caen a su forma de reserva.
9. Un solo archivo de Rive, exportado a assets/rive/guardianes_ui.riv y versionado en git. Los nombres dentro del archivo (artboards, view models, propiedades, enums y state machines) van en inglés y con el estilo del código Dart, porque Dart los busca como texto. Un test de contrato, como real_content_test.dart, carga el .riv y comprueba que todos existen.
10. Documenta el contrato en docs/UI_RIVE.md: para cada artboard, su view model, cada propiedad, quién la escribe y qué animación dispara.

## Principios de animación
- Micro (presionar, cambiar un número): 80–150 ms. Entradas de elementos: 200–350 ms con ease-out o un rebote leve. Paneles: 350–500 ms. Celebraciones: hasta 1,5 s, y un toque las salta al final.
- Rebote y squash & stretch de caricatura, pero sutiles: los bucles de reposo no pasan del 5 % de escala.
- En batalla, la interfaz no le roba atención al mapa, salvo para avisar peligro (pocas papas, jefe).
- Ninguna animación bloquea la entrada más de 300 ms.
- Si un elemento tiene a la vez un estado (habilitado o deshabilitado) y efectos (pulso, brillo), usa capas separadas en su state machine.

## Cómo trabajas con Rive
- Antes de construir una pantalla, revisa su referencia y dime en 3 a 5 líneas qué vas a hacer.
- Aprovecha el timeline y la state machine que trae cada artboard nuevo, como indica la herramienta, y ponle nombre a todo.
- Usa componentes reutilizables (artboards marcados como componente) para botones, paneles, contadores, etc., y Component Lists ligadas a listas del view model para las grillas (bestiario, plagas de la preparación).
- Verifica todo: después de cada componente, toma una captura con capture_artboard y compárala con la referencia; corre simulateStateMachine con cambios de propiedades para comprobar que se alcanza cada estado y cada transición. Corrige antes de mostrármelo.
- Usa el scripting de Rive solo si algo no se puede hacer con state machines (por ejemplo, tiempos al azar o confeti), y explícame por qué.
- Al cerrar cada fase: exporta el .riv a assets/rive/, intégralo en Flutter, corre dart format lib test tool, flutter analyze y flutter test, y pruébalo en el Redmi siguiendo docs/PRUEBAS_MANUALES.md. Muéstrame las capturas de Rive y del teléfono.
- El Redmi lo uso mientras trabajas: antes de cada toque por adb comprueba que el juego esté al frente, y nunca abras el juego encima de lo que tenga en pantalla sin preguntarme.

## Reglas de trabajo
- UNA fase a la vez. Antes de tocar Rive o el código, muéstrame un plan breve; al terminar, resume qué hiciste y cómo probarlo, y espera mi confirmación.
- Las diferencias entre las referencias y el juego actual no las decides tú solo. Por ejemplo: la mejora en una tarjeta lateral en lugar del menú radial, el botón de siguiente oleada abajo a la derecha y sin los segundos, o las papas como "20/20". Enuméralas y pregúntame. No se puede perder ninguna función existente: el doble toque para confirmar, la cuenta regresiva de la oleada, el botón 🐞 en debug y los anuncios condicionales.
- Anota las decisiones en CLAUDE.md, en la sección "Interfaz con Rive", como en las fases anteriores.
- Usa la versión estable actual del paquete rive (verifícala en pub.dev) y lee su documentación de data binding para Flutter antes de escribir código.
- Al cerrar cada fase, haz un commit con un mensaje en formato Conventional Commits.

Si entendiste, no construyas nada todavía. Responde con:
1. la comprobación de la conexión con Rive (qué archivo está abierto);
2. qué entendiste de la dirección visual, con la paleta que extraes de las referencias (muestrea los colores y dámelos en hex) comparada con AppTheme y GameColors;
3. el inventario de pantallas y estados (referencias 01 a 15 frente al código actual), con las diferencias de UX que debo decidir;
4. la estructura del archivo de Rive que propones (artboards, componentes y view models principales);
5. qué ilustraciones necesitamos (logo, llama, hondero, fondos, retratos de guardianes y plagas) y cómo propones hacerlas: vectoriales simplificadas hechas por ti en Rive, o PNG/SVG que yo te pase y tú animas con mallas y huesos;
6. los riesgos que ves (rendimiento, tests con rive_native, tamaño del APK, textos y escala de letra, límites del plan de Rive).
```

---

## Fase 1 — Prueba técnica

```
Fase 1: Prueba técnica de Rive dentro del juego, antes de diseñar nada grande.
- Agrega el paquete rive (versión estable actual de pub.dev) y explícame qué trae: rive_native y los renderers Factory.rive y Factory.flutter.
- En Rive, crea un artboard de prueba con un botón (estados normal, presionado y deshabilitado, con la etiqueta ligada a una propiedad) y el contador de maíz (número ligado y un ícono que rebota al cambiar).
- Expórtalo a assets/rive/ y úsalo en el HUD de la partida en lugar del contador actual, con respaldo si no carga.
- Mide en el Redmi, en modo profile y con la prueba de estrés: FPS y tiempos de UI y raster, con Factory.rive y con Factory.flutter. Mide también cuánto crece el APK (o el App Bundle por ABI).
- Haz que flutter test funcione: decide si los tests cargan Rive (dart run rive_native:setup --platform windows en mi PC y linux en el CI) o si usan el respaldo, y justifícalo. Agrega el test de contrato.
- Documenta los resultados en docs/UI_RIVE.md y recomiéndame qué renderer usar, cuántos RiveWidget por pantalla son razonables y si conviene un artboard por control o uno por panel. Esas decisiones guían las fases siguientes.
Al final quiero ver el contador animado funcionando en el teléfono.
```

## Fase 2 — Sistema visual: paleta, letra e íconos

```
Fase 2: Sistema visual en Rive, todavía sin pantallas.
- Un artboard "StyleGuide" con la paleta aprobada, el uso de cada color (fondos, bordes, texto, éxito, peligro, deshabilitado) y el contraste de cada combinación de texto.
- Letra: propón 1 o 2 fuentes redondeadas con licencia que permita uso comercial (OFL o similar), una para títulos y otra para texto. Verifica la licencia, súbelas al archivo de Rive y anótalas en docs/ASSETS.md. Deben tener todos los caracteres del español.
- Formas base: panel crema con borde y guarda tejida, cartel de madera para títulos, bisel de los botones dorado y crema, y sombras suaves.
- Íconos vectoriales con un mismo estilo: maíz, papa, estrella (llena y vacía), play, pausa, x1/x2, siguiente oleada, engranaje, libro, casa, reintentar, flecha atrás, cerrar, candado, mejorar, vender, objetivo, tierra/aire, música, efectos, vibración, idioma y anuncio. Reúnelos en un "IconSet" donde una propiedad elige el ícono.
- Ajusta AppTheme y GameColors de Flutter a la paleta, para que las pantallas que aún no cambian combinen con las nuevas.
Muéstrame capturas del StyleGuide y del IconSet al tamaño real del teléfono.
```

## Fase 3 — Kit de componentes animados

```
Fase 3: Kit de componentes animados, cada uno con su view model, su state machine y su respaldo en Flutter.
- PrimaryButton y SecondaryButton (ícono + texto): en reposo, un brillo cruza el botón cada ~4 s (solo el principal); presionado (escala 0,94 y bisel hundido, ~80 ms); al soltar, rebote; deshabilitado; y "no alcanza el maíz" (sacudida corta).
- IconButton redondo (pausa, velocidad, atrás, cerrar).
- Counter (pastilla con ícono y número): al subir, el ícono rebota y flota un "+N"; al bajar, un destello; y una variante de peligro con pulso.
- WaveBar: "Oleada 3/10" con segmentos que se llenan y un aviso especial en la oleada del jefe.
- Star (vacía → llena con estallido), Toggle (perilla con squash), SegmentedControl (Sistema / Español / English), Tab, Panel (entrada y salida), Tooltip y Badge ("¡Nuevo!").
- Un artboard "Catalog" con todos los componentes en todos sus estados, para revisarlos de un vistazo.
- En Flutter, un widget envoltorio por componente (por ejemplo RivePrimaryButton) con Key, Semantics, onTap, sonido y vibración, que reemplace poco a poco a los botones del tema. Tests de widgets de los envoltorios.
Verifica cada state machine con simulateStateMachine y muéstrame el Catalog.
```

## Fase 4 — HUD y acciones de batalla (referencias 04 a 09)

```
Fase 4: La interfaz de la partida en Rive (referencias 04, 05, 06, 07, 08 y 09).
- HUD: maíz, papas (con el máximo del nivel si lo aprobé), barra de oleadas, velocidad x1/x2 (cambia con un giro; en x2 se mueven unas flechitas), pausa y siguiente oleada con un anillo de cuenta regresiva (trim path) y el "+bono" flotando. Animaciones: el maíz sube al derrotar plagas; las papas tiemblan y destellan en rojo al perder vidas; pulso de peligro con pocas papas; cartel "Oleada N" al empezar cada oleada; aviso del jefe.
- Menú de construcción: los botones salen del centro en abanico y escalonados. El elegido brilla en dorado y se eleva; sin maíz suficiente se ve gris con el precio en rojo; bloqueado lleva candado; al confirmar hace "pop" y se cierra. Abajo, una etiqueta con el nombre, a qué ataca y "Toca otra vez para confirmar".
- Guardián construido: alcance, mejora con las estadísticas "8 → 12" que pulsan, objetivo, vender y nivel, respetando lo que decidí entre menú radial o tarjeta lateral.
- Especialización: dos tarjetas que entran girando, con ilustración, descripción y costo; al elegir una, estallido.
- Retratos de los 5 guardianes según lo que decidimos en el Prompt 0.
- Conserva el doble toque para confirmar, las claves de los tests y el botón 🐞 en debug.
- Vuelve a medir el rendimiento con la prueba de estrés y compáralo con la Fase 1.
```

## Fase 5 — Pausa, victoria y derrota (referencias 10 a 12)

```
Fase 5: Overlays de la partida (referencias 10, 11 y 12).
- Pausa: un velo oscurece el mapa, el panel cae con rebote y el sol del adorno gira lento. Botones: Continuar, Reintentar y Salir del nivel.
- Victoria "¡Cosecha a salvo!": el cartel cae; las estrellas aparecen una por una según las ganadas (cada una con un trigger para que Flutter toque el sonido y vibre); las papas restantes y el maíz cosechado cuentan hacia arriba; el desbloqueo brilla; llueven granos de maíz y la llama celebra. Un toque salta la coreografía al final.
- Derrota "La collca se quedó sin papas": el panel entra temblando, la llama está triste y la collca vacía. Botones: Reintentar, Volver al valle y el de anuncio para recuperar papas, solo si está disponible.
- Los botones aparecen cuando termina la entrada del panel, sin bloquear más de 300 ms.
- Los datos salen de lo que el juego ya calcula: estrellas, BattleStats, Unlocked y AdsStatus.
```

## Fase 6 — Título, valle y preparación (referencias 01 a 03)

```
Fase 6: Pantallas de menú (referencias 01, 02 y 03).
- Título: fondo del valle en capas (montañas, nubes que se desplazan, andenes, collca) con parallax suave. El logo se arma (letras que caen escalonadas, hojas que se mecen) y Jugar "respira". Las mascotas están en reposo (la llama parpadea y mastica, el hondero gira la honda) y de vez en cuando un gorgojo se asoma entre las plantas.
- Valle: los 3 nodos del mapa con sus estados: bloqueado (candado; al tocarlo, se sacude y aparece el aviso con la regla), disponible (flota) y elegido (anillo brillante). Estrellas por nivel, contador de estrellas totales y barra inferior con el nivel elegido y Jugar. Al desbloquear un nivel nuevo, un camino de puntos se dibuja hasta él.
- Preparación: tarjetas de las plagas que entran escalonadas (el jefe con una corona que brilla), número de oleadas, maíz y papas iniciales, el botón de anuncio "+50 de maíz" solo si está disponible, Volver y Comenzar.
```

## Fase 7 — Bestiario y ajustes (referencias 13 a 15)

```
Fase 7: Bestiario y ajustes (referencias 13, 14 y 15).
- Bestiario: pestañas Plagas y Guardianes que se deslizan; grilla hecha con Component List; las fichas bloqueadas son una silueta con "?"; la primera vez que se abre una ficha recién descubierta, se voltea y muestra "¡Nuevo!". El detalle muestra las estadísticas y, en los guardianes, las mejoras y las ramas.
- Ajustes: Música, Efectos de sonido, Vibración y Números de daño (Toggles), Idioma (Sistema / Español / English), Opciones de privacidad solo si la ley lo pide y "Desarrollo: todo desbloqueado" solo en debug.
- Los textos largos del bestiario pueden quedarse en Flutter si en Rive no respetan la escala de letra: decide y explícame por qué.
```

## Fase 8 — Transiciones, pulido y cierre

```
Fase 8: Pulido y cierre.
- Una transición entre pantallas hecha en Rive (por ejemplo, una cortina de hojas o de tejido andino), corta (400 ms como máximo) y que se apague con reduceMotion.
- Revisión completa frente a las 15 referencias: una tabla con lo que coincide, lo que cambió y por qué.
- Accesibilidad: TalkBack recorre cada pantalla con etiquetas correctas, la letra a 1,3× y 2× no desborda, el contraste se cumple y reduceMotion funciona.
- Rendimiento final en el Redmi (FPS con estrés, memoria y tiempo de arranque) y peso del App Bundle.
- Borra el código de interfaz viejo que ya no se use, salvo los respaldos que decidimos mantener.
- Actualiza docs/UI_RIVE.md, docs/ASSETS.md, docs/PRUEBAS_MANUALES.md y CLAUDE.md.
- Dame la lista de pendientes y tus propuestas para después.
```

---

## Plantillas para seguir después

**Agregar un componente o una pantalla**

```
Quiero agregar [componente o pantalla]: [qué muestra, sus estados y sus animaciones]. Reutiliza el kit de componentes y el sistema visual. Antes de construir, dime qué view model y qué propiedades vas a agregar al contrato. Verifica con capture_artboard y simulateStateMachine, exporta, intégralo con su respaldo y actualiza docs/UI_RIVE.md.
```

**Ajustar una animación**

```
La animación de [elemento] [qué no me gusta: muy lenta, poco rebote, distrae]. Propón 2 variantes con duraciones y curvas concretas, muéstramelas y aplica la que elija.
```

**Agregar un guardián o una plaga a la interfaz**

```
Agregué [guardián o plaga] al contenido. Crea su retrato y su ficha en Rive con el mismo estilo, agrégalo al menú de construcción o al bestiario sin tocar el motor y actualiza el test de contrato.
```

**Cuando algo falla con Rive**

```
Tengo este problema: [qué pasa: no carga el .riv, no cambia de estado, se ve distinto en el teléfono, o el error completo]. Antes de cambiar nada, revisa el contrato en docs/UI_RIVE.md y usa queryStateMachine, listDataBinds y simulateStateMachine para encontrar la causa; explícamela y luego propón la corrección mínima.
```

**Retomar en una conversación nueva**

```
Ya completamos hasta la Fase [X] de la interfaz con Rive. Lee CLAUDE.md (sección "Interfaz con Rive") y docs/UI_RIVE.md, revisa con el MCP qué tiene el archivo "Guardianes UI", resúmeme el estado y sigamos con la Fase [X+1].
```

## Ideas para después

- Pantalla de carga animada (una mata de maíz que crece).
- Ícono de la app y gráfico destacado de Play Store con el mismo estilo de Rive.
- Un tutorial guiado por la llama en el primer nivel.
