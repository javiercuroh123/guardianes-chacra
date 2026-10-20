# La interfaz en Rive

La interfaz del juego se dibuja y anima con [Rive](https://rive.app). El plan por fases está en [PROMPT_UI_RIVE.md](PROMPT_UI_RIVE.md) y las decisiones, en la sección "Interfaz con Rive" de [CLAUDE.md](../CLAUDE.md). Este documento es el **contrato** entre el archivo de Rive y el código, y guarda lo que se midió.

## Cómo funciona

- **Un solo archivo**, "Guardianes UI" en el editor de Rive (vive en la nube de Rive). El juego usa su exportación para runtime: `assets/rive/guardianes_ui.riv`, versionada en git.
- **Flutter manda y Rive dibuja.** Cada pieza de Rive va dentro de un widget de Flutter que tiene la `Key` de los tests, la `Semantics` para TalkBack, los toques, el sonido y la vibración. El widget le escribe datos a Rive (el número, si está presionado) y Rive decide cómo se ve y cómo se anima.
- **Data binding.** Cada artboard tiene un *view model* (sus datos) y una state machine llamada `Main` que reacciona a esos datos. No se usan los *inputs* viejos de las state machines.
- **Respaldo.** `main.dart` carga el archivo antes del primer cuadro (`RiveUi.load`). Si no se puede (faltan las librerías nativas, el archivo está roto), `riveFileProvider` queda en `null` y cada widget muestra su aspecto de Flutter. Así también corren los tests que no prueban Rive.

### Vocabulario de Rive

| Rive | Qué es | En Flutter se parece a |
|---|---|---|
| Artboard | Un lienzo con su contenido: un botón, un panel, una pantalla | Un widget |
| Componente | Un artboard reutilizable dentro de otro | Un widget dentro de otro |
| Layout | Cajas flex dentro del artboard (fila, columna, relleno, separación) | `Row`, `Column`, `Padding` |
| Timeline | Una animación con keyframes | Un `AnimationController` con su `Tween` |
| State machine | Estados (cada uno con su timeline) y transiciones con condiciones | Una máquina de estados escrita a mano |
| View model | Los datos del artboard: textos, números, booleanos, enums y triggers | El estado de un widget |
| Data bind | "Este texto muestra la propiedad `value`" | Pasarle un parámetro a un widget |
| Trigger | Una propiedad que no guarda un valor: solo "dispara" | Llamar a un método (`animar()`) |

## El contrato

Los nombres van en inglés, como el código, porque Dart los busca como texto. `test/app/rive/rive_contract_test.dart` carga el `.riv` real y falla si falta algo.

### `Counter` (Fases 1 y 3)

Pastilla del HUD con ícono y número. 104 × 60: la pastilla ocupa los 35 de arriba y el "+N" flota en el resto, por debajo, sin empujar lo que haya alrededor (el widget mide solo la pastilla y deja que el dibujo se salga hacia abajo). Widget: `RiveCounter` (`lib/app/rive/rive_counter.dart`), hoy en el contador de maíz del HUD (clave `hud-corn`).

| Propiedad | Tipo | La escribe | Qué hace |
|---|---|---|---|
| `value` | string | `RiveCounter`, con el número formateado por Dart | El texto del número |
| `icon` | view model `IconSet` | `RiveCounter` (`icon`, por defecto `corn`) | El ícono de la pastilla |
| `gain` | trigger | `RiveCounter`, cuando el número sube | El ícono rebota (escala 135 %, rebote elástico), el número destella en verde `#117D16` (0,4 s) y flota `delta` (0,9 s) |
| `delta` | string | `RiveCounter`, antes de `gain` ("+25") | La etiqueta verde que sube y se desvanece |
| `loss` | trigger | `RiveCounter`, cuando el número baja | El número y el borde destellan en rojo `#C43403` y el ícono tiembla: 0,4 s |
| `danger` | boolean | `RiveCounter` (`danger`; pocas papas en la Fase 4) | Un anillo rojo late sobre la pastilla (1 s, en bucle) |
| `reduceMotion` | boolean | `RiveBindingState`, desde `MediaQuery.disableAnimations` | El aviso de peligro queda fijo, sin latir |

State machine `Main`, tres capas: `Layer 1` (`Idle` ← cualquier estado → `Gain` o `Loss` con su trigger → vuelven a `Idle`), `Delta` (`DeltaHidden` → `DeltaFloat` con `gain` → vuelve al terminar) y `Danger` (`Calm`, `Pulse` y `Steady`). Con "quitar animaciones" del teléfono solo cambia el número.

### `PrimaryButton`, `SecondaryButton` y `RoundButton` (Fase 3)

Los botones del juego. Los tres comparten el view model `Button`. Widget: `RiveButton` (`lib/app/rive/rive_button.dart`); `RiveButton.round` para el redondo.

- `PrimaryButton`: maíz con degradado y bisel, 200 × 56 de diseño. Un brillo lo cruza cada ~4 s.
- `SecondaryButton`: crema `#FBD7A5`, sin brillo.
- `RoundButton`: 56 × 56, solo con ícono (pausa, velocidad, atrás, cerrar). Con `danger`, la cara pasa a roja.

Los de texto se estiran con `Fit.layout`: Flutter mide el texto con la misma letra (Fredoka 20, peso 700) y le pasa el ancho (`RiveButton.widthFor`, mínimo 140); con letra grande, todo crece con `layoutScaleFactor`.

| Propiedad | Tipo | La escribe | Qué hace |
|---|---|---|---|
| `label` | string | `RiveButton`, desde los ARB | El texto (el redondo no lo muestra: es su tooltip y lo que lee TalkBack) |
| `icon` | view model `IconSet` | `RiveButton` | El ícono a la izquierda del texto |
| `hasIcon` | boolean | `RiveButton` | Sin ícono, su lugar desaparece (`display` ligado con el convertidor `HiddenUnless`) |
| `pressed` | boolean | `RiveButton`, al apoyar y levantar el dedo | Se hunde: escala 0,94 y bisel bajo en ~80 ms; al soltar, rebote (0,3 s) |
| `enabled` | boolean | `RiveButton` (`onPressed` no nulo) | Apagado: grises y no reacciona a `pressed` |
| `deny` | trigger | `RiveButton`, al tocarlo deshabilitado si tiene `onDenied` | "No se puede" (no alcanza el maíz): una sacudida corta de 0,3 s |
| `danger` | boolean | `RiveButton.round` | Cara roja (opacidad de `RedFace` ligada con `BoolToNumber`) |
| `reduceMotion` | boolean | `RiveBindingState` | Apaga el brillo del principal |

State machine `Main`: capa `Layer 1` con `Idle`, `Pressed`, `Release`, `Disabled` y `Deny`; el principal tiene además la capa `Shine` (`ShineLoop` y `ShineOff`), separada para que el brillo no se mezcle con el estado.

### `IconSet` (Fase 2)

Los 29 íconos de la interfaz en un solo artboard de 48 × 48, todos con el mismo estilo: contorno `#4A1302` de 2,2 dp con puntas redondeadas y los colores de la paleta. Dart: `RiveIcon` (`lib/app/rive/rive_icons.dart`).

| Propiedad | Tipo | La escribe | Qué hace |
|---|---|---|---|
| `icon` | enum `IconName` | El componente que lo usa, con un valor de `RiveIcon` (su `name`) | Muestra ese ícono |

Valores, en este orden: `corn`, `potato`, `star`, `starEmpty`, `play`, `pause`, `fastForward`, `nextWave`, `gear`, `book`, `home`, `retry`, `back`, `close`, `lock`, `upgrade`, `sell`, `target`, `ground`, `air`, `music`, `sound`, `vibration`, `language`, `ad`, `check`, `flag`, `shield`, `damage`.

Cómo está hecho: cada ícono es un grupo (`icon_<nombre>`) cuya opacidad se liga a `icon` con un convertidor de grupo: `EnumToIndex` (enum → número) y una fórmula `max(0, 1 - pow({Input} - k, 2))`, que da 1 solo cuando el índice es `k`. **El orden importa**: un ícono nuevo va al final del enum (y de `RiveIcon`), con su grupo y su convertidor `IsIconNN`. Un valor que no está en el enum no se aplica y queda el que había (el primero, `corn`). `rive_contract_test.dart` compara el enum con `RiveIcon`, y `rive_icons_test.dart` dibuja los 29 y comprueba que cada uno pinte algo.

### `TitleSign` (Fase 2)

Cartel de madera para los títulos: tabla con degradado, vetas, borde claro interior y hojas a los lados. 360 × 96. El título va en Lilita One crema con contorno oscuro de 5 dp y se achica solo si no cabe (*fit font size*).

| Propiedad | Tipo | La escribe | Qué hace |
|---|---|---|---|
| `title` | string | La pantalla, desde los ARB | El texto del cartel |

### `Panel` (Fases 2 y 3)

Marco de los paneles y tarjetas: borde terracota `#AF5212` con contorno oscuro, interior crema, guarda naranja `#F59950` y un rombo tejido en cada esquina. Hecho con layouts, así que se estira a cualquier tamaño (`Fit.layout`). El contenido lo pone Flutter encima. Widget: `RivePanel` (`lib/app/rive/rive_panel.dart`), que mueve el contenido junto con el marco.

| Propiedad | Tipo | La escribe | Qué hace |
|---|---|---|---|
| `visible` | boolean | `RivePanel` | `true`: el marco cae 40 dp con rebote y aparece (0,42 s). `false`: baja 24 dp y se desvanece (0,2 s) |
| `reduceMotion` | boolean | `RiveBindingState` | Entra solo desvaneciéndose (`EnterCalm`, 0,15 s) |

State machine `Main`: `Hidden`, `Enter`, `EnterCalm`, `Shown` y `Exit`. Los overlays (pausa, victoria, derrota) lo usarán en la Fase 5.

### `PortraitHondero` (Fase 2, prueba de estilo)

Retrato *sticker* del Hondero, 120 × 120: chullo rojo con guarda en zigzag y pompón, orejeras con borlas, poncho con franjas turquesa y amarilla. Es la prueba de estilo de los retratos; en las fases siguientes se hacen los otros guardianes y las plagas, y se juntan en un `Portrait` con un enum (como `IconSet`).

### `StyleGuide` (Fase 2, solo para revisar)

La guía de estilo en el editor: los 19 colores con su uso, el contraste de cada combinación de texto, las dos fuentes y una fila con las formas base (panel, cartel, botones dorado y crema, retrato). No va en el `.riv`: la exportación solo incluye los artboards marcados como componente (el `Catalog` lo está para poder dibujarlo en los tests y en el teléfono). La exportación también trae tres artboards de Rive (`Watermark`, `NuRiveBrandmark01`, `NuRiveWordmark01`), por el plan de la cuenta: el juego no los dibuja.

### `WaveBar` (Fase 3)

"Oleada 3/10" con una bandera y una barra que se llena. 200 × 44 de diseño, `Fit.layout`. Widget: `RiveWaveBar` (`lib/app/rive/rive_wave_bar.dart`); el HUD la usa en la Fase 4. Es una barra continua y no por segmentos: los niveles tienen hasta 15 oleadas y los segmentos quedarían muy finos en un teléfono.

| Propiedad | Tipo | La escribe | Qué hace |
|---|---|---|---|
| `label` | string | `RiveWaveBar`, desde los ARB | El texto |
| `progress` | number (0–1) | `RiveWaveBar` (oleada / total) | El ancho del relleno (`ProgressToPercent`); el layout lo anima en 0,45 s |
| `boss` | boolean | `RiveWaveBar` | La barra pasa a terracota y aparece un círculo ciruela con "!" que late (0,8 s, en bucle) |
| `waveStarted` | trigger | `RiveWaveBar`, al subir la oleada | El texto rebota y la pastilla destella (0,5 s) |
| `icon` | view model `IconSet` | `RiveWaveBar` (siempre `flag`) | El ícono |
| `reduceMotion` | boolean | `RiveBindingState` | El aviso del jefe queda fijo |

State machine `Main`: `Layer 1` (`Idle`, `WaveStart`) y `Boss` (`Normal`, `BossAlert`, `BossSteady`).

### `Star` (Fase 3)

Estrella de puntuación, 56 × 56: vacía `#E7D9BD` con contorno `#8A6A4A`; llena `#FECE18` con contorno oscuro. Widget: `RiveStar` (`lib/app/rive/rive_star.dart`); la victoria la usa en la Fase 5 (quien cambia `filled` toca el sonido de cada estrella).

| Propiedad | Tipo | La escribe | Qué hace |
|---|---|---|---|
| `filled` | boolean | `RiveStar` | `true`: la estrella llena crece girando hasta 125 % y se asienta, con un anillo que se abre y seis chispas (0,6 s). `false`: se encoge (0,15 s) |
| `reduceMotion` | boolean | `RiveBindingState` | Se llena de golpe, sin estallido |

State machine `Main`: `Empty`, `Fill`, `Filled` y `Unfill`.

### `Toggle` (Fase 3)

Interruptor, 68 × 40: riel gris `#D8DBCF` (apagado) o verde `#36901D` (encendido) y perilla crema. Widget: `RiveToggle` (`lib/app/rive/rive_toggle.dart`), con Semantics de interruptor; Ajustes lo usará en la Fase 7.

| Propiedad | Tipo | La escribe | Qué hace |
|---|---|---|---|
| `on` | boolean | `RiveToggle` | La perilla cruza con squash (128 % × 82 %) y rebote, y el riel cambia de color (0,25 s) |
| `enabled` | boolean | `RiveToggle` (`onChanged` no nulo) | Apagado: 45 % de opacidad |
| `reduceMotion` | boolean | `RiveBindingState` | Sin uso todavía (el movimiento es corto) |

State machine `Main`: `Layer 1` (`Off`, `TurnOn`, `On`, `TurnOff`) y `Enabled` (`Enabled`, `Disabled`).

### `Segmented` (Fase 3)

Tres opciones con una pastilla de maíz que se desliza hasta la elegida (Sistema / Español / English). 300 × 44 de diseño, `Fit.layout`. Widget: `RiveSegmented` (`lib/app/rive/rive_segmented.dart`): Flutter pone tres zonas tocables, cada una con su Semantics y su Key (`optionKeys`).

| Propiedad | Tipo | La escribe | Qué hace |
|---|---|---|---|
| `label0`, `label1`, `label2` | string | `RiveSegmented`, desde los ARB | Los textos |
| `selected` | number (0–2) | `RiveSegmented` | La posición de la pastilla (`positionLeft` en %, con el convertidor `ThirdToPercent`); el layout la desliza en 0,25 s |

No tiene animaciones propias: el deslizamiento es una animación de layout.

### `Tab` (Fase 3)

Pestaña con esquinas de arriba redondeadas, 140 × 46 de diseño, `Fit.layout` (Flutter mide el texto: Fredoka 15, peso 700). Widget: `RiveTab` (`lib/app/rive/rive_tab.dart`); el bestiario la usará en la Fase 7.

| Propiedad | Tipo | La escribe | Qué hace |
|---|---|---|---|
| `label` | string | `RiveTab`, desde los ARB | El texto |
| `selected` | boolean | `RiveTab` | Sube 6 dp con rebote y pasa de crema a maíz (0,25 s) |
| `icon`, `hasIcon` | view model `IconSet`, boolean | `RiveTab` | El ícono opcional |

State machine `Main`: `Unselected`, `Select`, `Selected` y `Deselect`.

### `Tooltip` (Fase 3)

Globo crema con borde terracota y flecha abajo. 220 × 64 de diseño, `Fit.layout`: Flutter mide el texto (Fredoka 14, peso 600, en varias líneas si hace falta) y le da el tamaño (`RiveTooltip.sizeFor`). Widget: `RiveTooltip` (`lib/app/rive/rive_tooltip.dart`), que no tapa toques y TalkBack anuncia al aparecer. El "Toca otra vez para confirmar" del menú de construcción lo usará en la Fase 4.

| Propiedad | Tipo | La escribe | Qué hace |
|---|---|---|---|
| `text` | string | `RiveTooltip`, desde los ARB | El texto |
| `visible` | boolean | `RiveTooltip` | Aparece subiendo 6 dp (0,22 s) y se va bajando y desvaneciéndose (0,15 s) |
| `reduceMotion` | boolean | `RiveBindingState` | Sin uso todavía |

State machine `Main`: `Hidden`, `Show`, `Shown` y `Hide`.

### `Badge` (Fase 3)

Etiqueta ciruela `#8B2055` con texto crema, 84 × 32. Widget: `RiveBadge` (`lib/app/rive/rive_badge.dart`); la preparación del nivel la usará en la Fase 6.

| Propiedad | Tipo | La escribe | Qué hace |
|---|---|---|---|
| `label` | string | `RiveBadge`, desde los ARB ("¡Nuevo!") | El texto (centrado en una caja fija: "New!" también cabe) |
| `reduceMotion` | boolean | `RiveBindingState` | Quieta (`Still`) en vez de menearse |

State machine `Main`: `Wiggle` (3 s en bucle: quieta 2 s, después se menea ±8° y crece 10 %) y `Still`.

### `Catalog` (Fase 3, para revisar)

Todos los componentes en todos sus estados, 1000 × 640: botones (normal, presionado, deshabilitado, secundario, redondo, redondo en peligro), contadores (maíz y papas en peligro), barras de oleadas (normal y jefe), estrellas, interruptores (apagado, encendido, deshabilitado), la etiqueta, el selector, las pestañas, el tooltip y el panel. Su view model `Catalog` tiene una propiedad por componente que apunta a una instancia con los datos de ese estado (`PrimaryPressed`, `WaveBoss`, `IcoFlagBoss`…). Una instancia anidada solo puede estar en un lugar a la vez: cada uno tiene la suya, también los íconos.

`MCP capture_artboard` lo muestra sin datos (los textos de diseño); con datos lo dibuja `test/app/rive/rive_catalog_test.dart`, que busca el color de cada estado y guarda la imagen con `--dart-define=CATALOG_PNG=build/catalog.png`. En el teléfono está en el panel de desarrollo (🐞 → "Catálogo de la interfaz"), con cada componente para tocarlo debajo.

## El kit en Flutter (Fase 3)

- `RiveBinding` (`lib/app/rive/rive_binding.dart`) crea el controlador de un artboard con la state machine `Main` y ata su view model por defecto (`DataBind.auto()`: cada widget tiene su propia instancia, también la del ícono anidado). Pide las propiedades por nombre y lanza `RiveContractException` si falta alguna.
- `RiveBindingState` es la base de cada envoltorio: crea el binding si el archivo está cargado, le pone los valores iniciales (`bind`), llena `reduceMotion` desde `MediaQuery.disableAnimations` y lo libera al final. Sin archivo, o si falta una propiedad, el widget dibuja su respaldo del tema.
- Los toques los recibe Flutter: cada envoltorio tiene su `GestureDetector`, su `Semantics` (botón, interruptor, opción elegida) y la Key que le pase la pantalla. Rive dibuja con `RiveHitTestBehavior.none`.
- `UiFeedback` (`lib/app/ui_feedback.dart`) toca `Sfx.uiTap` o `Sfx.uiDeny` (sonidos sintetizados por `tool/generate_placeholder_audio.py`) y vibra `Haptic.tap` (`selectionClick`) o `Haptic.deny` (`lightImpact`), respetando los interruptores de Efectos y Vibración.
- Dónde se usa ya: los botones del título (`menu-play`, `menu-bestiary`, `menu-settings`), de la preparación (`preview-start`, `preview-rewarded`) y de los overlays de la partida (`pause-resume`, `victory-next`, `battle-retry`, `battle-exit`, `battle-revive`). Los demás componentes esperan su fase (HUD en la 4, overlays en la 5, menús en la 6, bestiario y ajustes en la 7).

## Paleta

La misma de CLAUDE.md ("Decisiones (UI)") y de `AppTheme` en Flutter. Combinaciones de texto (WCAG):

| Texto sobre | Contraste | Uso |
|---|---|---|
| `#4A1302` sobre crema `#FEF3D7` | 13,7:1 | Texto normal |
| `#4A1302` sobre maíz `#FDB119` | 8,3:1 | Botón principal |
| Crema sobre madera `#9E430B` | 5,8:1 | Carteles, barra de arriba |
| Crema sobre terracota `#B5452A` | 4,9:1 | Vender |
| Verde `#117D16` sobre crema | 4,8:1 | Números que suben |
| Verde `#0E6B12` sobre crema HUD `#FDEAC5` | 5,7:1 | Bono del HUD |
| Crema sobre ciruela `#8B2055` | 7,8:1 | Jefe |
| Crema sobre turquesa `#0B889F` | 3,8:1 | Solo texto grande o íconos |
| Crema sobre verde `#36901D` | 3,7:1 | Solo íconos (el visto del interruptor) |

La estrella amarilla `#FECE18` sobre crema da 1,35:1: siempre lleva su contorno oscuro (10:1).

## Fuentes

| Fuente | Para qué | En Rive | En Flutter |
|---|---|---|---|
| Lilita One | Títulos y carteles | Completa (28 KB): no se recorta porque su licencia reserva el nombre "Lilita" para versiones modificadas | `AppTheme.titleFont`: `displayMedium`, `headlineSmall` y la barra de arriba |
| Fredoka (variable, 300–700) | Todo lo demás | Recortada a los caracteres del español y el inglés | `AppTheme.bodyFont`, la fuente por defecto; `FontWeight` elige el peso sin `fontVariations` |

Las dos tienen licencia SIL OFL 1.1 y están en `assets/fonts/` con su `OFL.txt` (que `main.dart` suma a la pantalla de licencias). En el editor de Rive no se pueden subir fuentes por el MCP (no permite `.ttf`): se agregaron desde el selector de fuentes del editor (catálogo de Google Fonts) y después se asignaron a cada texto con `fontassetid`.

El recorte de Fredoka se escribe en su asset ("caracteres incluidos" en modo personalizado) como **rangos Unicode**, no como los caracteres sueltos (ver "El error de la fuente" más abajo):

```
U+0020-007E,U+00A1,U+00BF,U+00C1,U+00C9,U+00CD,U+00D1,U+00D3,U+00DA,U+00DC,U+00E1,U+00E9,U+00ED,U+00F1,U+00F3,U+00FA,U+00FC,U+00B7,U+00D7,U+2013-2014,U+2018-2019,U+201C-201D,U+2026,U+2192,U+2265
```

Es ASCII más `¡ ¿ Á É Í Ñ Ó Ú Ü á é í ñ ó ú ü · × – — ‘ ’ “ ” … → ≥`. Si un texto nuevo usa otro carácter, hay que sumarlo a la lista. Con Inter (Fase 1) el `.riv` pesaba 199 KB; con Lilita One completa y Fredoka recortada, 144 KB.

## Tests y librerías nativas

Rive usa código nativo (`rive_native`). Para compilar la app no hay que hacer nada: el build lo descarga. Para `flutter test` (los tests de `test/app/rive/` y el del catálogo de desarrollo cargan el archivo real) hay que bajarlo una vez por PC:

```powershell
dart run tool/setup_rive_native.dart
```

En Windows, los tests cargan la DLL de depuración de Rive, que pide el runtime de depuración de C++ (`MSVCP140D.dll`, `ucrtbased.dll`): solo viene con Visual Studio y sin él falla con "error code 126". El script copia encima la DLL de lanzamiento, que usa el runtime normal que ya trae Windows. El CI (Linux) corre el mismo script antes de los tests.

## Mediciones de la Fase 1

19 de octubre de 2026, Redmi Note 14 Pro (pantalla de 120 Hz), APK de profile, Chacra del Valle sin guardianes, collca invencible. "Estrés" = la prueba de 150 plagas del panel de desarrollo, a x2. Los cuadros se midieron con SurfaceFlinger (`dumpsys SurfaceFlinger --latency` sobre la capa del juego): cinco muestras de los últimos ~128 cuadros presentados. A 120 Hz, un cuadro a tiempo dura 8,3 ms; uno de más de 16,7 ms ya baja de 60 FPS.

Las pruebas con varios contadores usan el panel de desarrollo ("Prueba de Rive", `lib/dev/rive_bench.dart`): contadores que cambian cada 250 ms (más seguido que su animación de 0,4 s, así que no paran de animarse).

| Situación | Sin Rive (respaldo) | Renderer de Flutter | Renderer de Rive | Renderer de Rive + `RivePanel` |
|---|---|---|---|---|
| Partida normal, contador del HUD | 118 FPS | 119 FPS | 118 FPS | — |
| Estrés, contador del HUD | 118 FPS | 118 FPS | 117 FPS | — |
| Estrés + 6 contadores, 2 animándose (como el HUD de la Fase 4) | — | **114 FPS** (4 % de cuadros > 16,7 ms) | 59 FPS (80 %) | 75 FPS (46 %) |
| Estrés + 12 contadores animándose (peor caso) | — | 80–81 FPS (35 %) | 29–30 FPS (100 %) | 62 FPS (75 %) |

`RivePanel` no funciona con el renderer de Flutter: `RiveWidget` muestra un error en lugar del dibujo. `RiveCounter` ya no pide la textura compartida con ese renderer.

### Qué decidimos

- **Renderer: el de Flutter** (`Factory.flutter`, el valor por defecto de `RiveUi.renderer`). Dentro del juego, con Flame dibujando al mismo tiempo, cada widget con el renderer de Rive tiene su propia textura y eso cuesta mucho; el de Flutter dibuja en el mismo lienzo que el resto de la app. Lo que se pierde: el *vector feathering* (bordes difuminados) del editor solo existe con el renderer de Rive, así que los brillos y sombras suaves se hacen con degradados y trazos. `--dart-define=RIVE_RENDERER=rive` sigue disponible para volver a comparar.
- **Cuántos widgets de Rive por pantalla**: en batalla, hasta unos 6 controles con pocas animaciones a la vez (el HUD) cuesta unos 4 FPS de 118. Doce animándose sin parar ya baja a 80: en batalla no se animan muchas cosas a la vez ni se dejan bucles de reposo corriendo. En los menús y en los overlays (la partida en pausa o terminada) hay más margen.
- **Un artboard por control o por panel**: un artboard por control tocable (lo que acordamos en el Prompt 0) aguanta el rendimiento con el renderer de Flutter. Los paneles y escenas sin toques (victoria, título) van en un solo artboard grande, que además permite coordinar sus animaciones.
- **Las máquinas que se asientan no cuestan**: un contador quieto no hace repintar nada (fila "Partida normal"). Por eso los estados de reposo de cada state machine terminan en una animación de un solo disparo, no en un bucle, salvo que el bucle sea parte del diseño (y entonces se apaga con `reduceMotion` y en batalla).

### Peso

`rive` agrega `librive_native.so`: en arm64 son 7,7 MB instalados y unos 2,8 MB comprimidos, que es más o menos lo que se descarga desde Google Play con un App Bundle (cada teléfono baja solo su arquitectura). En el APK universal hay tres copias (arm64, armeabi-v7a y x86_64: 22,5 MB sin comprimir). El `.riv` pesaba 199 KB en la Fase 1 (casi todo era la fuente Inter); con Lilita One y Fredoka recortada y el kit de la Fase 3 completo, pesa 164 KB. El código Dart de Rive, unos 70 KB.

### El error de la fuente

La primera exportación recortó la fuente escribiendo los caracteres tal cual en "caracteres incluidos": el editor no lo entendió, el `.riv` quedó en 16 KB y **el número no se dibujaba** (la pastilla salía vacía en el teléfono). El campo espera rangos Unicode (`U+0020-007E,U+00A1,…`). `rive_counter_test.dart` ahora cuenta los píxeles del texto para que no vuelva a pasar sin que nadie lo note.
