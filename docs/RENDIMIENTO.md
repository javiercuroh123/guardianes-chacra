# Rendimiento

El juego debe ir a 60 cuadros por segundo en un teléfono de gama media, incluso con 150 plagas en pantalla. A 60 fps cada cuadro tiene **16,7 ms** para todo: correr la simulación (uno o dos ticks, según la velocidad) y dibujar.

Se mide en dos partes, porque son dos problemas distintos:

| Qué | Con qué | Dónde |
|---|---|---|
| La lógica (simulación) | `dart run tool/stress.dart` | En la computadora, sin gráficos |
| El dibujo y la app completa | Modo profile + DevTools | En el teléfono |

## 1. La lógica: `tool/stress.dart`

```powershell
dart run tool/stress.dart
```

Toma el nivel con más espacios (si no alcanzan, agrega espacios junto al camino hasta tener 15), construye 15 guardianes de todos los tipos (mejorados y especializados, para que haya ralentizar, quemar y aturdir a la vez), lanza 150 plagas y corre 30 segundos de juego con maíz infinito y la collca invencible. Mide cada tick por separado.

**Presupuesto:** a x2 se corren dos ticks por cuadro. Si el p95 (el tick más lento de cada 20) queda bajo **2 ms**, la simulación usa menos de un cuarto del cuadro y el resto queda para dibujar.

Último resultado (17 de octubre de 2026, en la computadora de desarrollo):

| Guardianes | Plagas vivas a la vez | Promedio | p95 | Máximo |
|---|---|---|---|---|
| 15 | 119 | 0,13 ms | 0,45 ms | 2,0 ms |

No llegan a 150 plagas vivas a la vez porque los guardianes van derrotando a las primeras mientras aparecen las últimas. El máximo aislado suele ser el recolector de basura de Dart: importa el p95, no un pico suelto.

`dart run` compila con JIT; en el teléfono el código va compilado AOT y el procesador es otro, así que los números no se comparan directamente. Sirve para **comparar antes y después** de un cambio en la simulación.

## 2. En el teléfono: modo profile

El modo debug (el de `flutter run` normal) es lento a propósito: compila sobre la marcha y agrega comprobaciones. **Nunca midas rendimiento en debug.** El modo profile se compila como el de lanzamiento pero deja conectar las herramientas de medición. El modo release no las tiene.

Con el teléfono conectado por USB y la depuración USB activada:

```powershell
flutter run --profile
```

En profile siguen estando el botón 🐞 y el panel de desarrollo (no existen en release; ver `lib/dev/dev_options.dart`).

### La prueba en el juego

1. Entra a un nivel y toca 🐞.
2. Activa **Caminos, alcances, FPS y conteos**: arriba a la izquierda aparecen los FPS y cuántas plagas, proyectiles y componentes hay.
3. Toca **Prueba de estrés (150 plagas)** y pon la velocidad en x2.
4. Mira los FPS mientras las plagas cruzan el mapa. Deberían quedar cerca de 60 (o de la frecuencia de la pantalla).

Último resultado (17 de octubre de 2026, Redmi Note 14 Pro, pantalla de 120 Hz, modo profile, Andenes con 12 guardianes):

| Situación | Plagas vivas | FPS |
|---|---|---|
| Partida normal, x1 | 14–20 | 102–119 |
| Prueba de estrés, x2 | 118 | 108 |
| Prueba de estrés, x2 | 167 | 77 |
| Prueba de estrés, x2 (plagas derrotándose) | 67 | 73 |

Con 167 plagas sigue por encima de 60 FPS. El contador de FPS promedia los últimos cuadros, por eso tarda en volver a subir cuando quedan menos plagas.

Con la interfaz de Rive terminada (21 de octubre de 2026, el mismo teléfono, Chacra del Valle sin guardianes, medido con SurfaceFlinger en vez del contador): **117 FPS** en una partida normal a x1 y **113 FPS** con la prueba de estrés a x2 (2 % de cuadros de más de 16,7 ms). La memoria en el estrés: 365 MB. El arranque en frío hasta el primer cuadro: alrededor de 0,9 s. Detalle, comparación sin Rive y peso del App Bundle: `UI_RIVE.md` ("Mediciones de la Fase 8 (parte C)").

Para medir el arranque sin tocar el juego a mano:

```powershell
flutter build apk --profile --target-platform android-arm64
flutter run --use-application-binary build\app\outputs\flutter-apk\app-profile.apk --profile --trace-startup
```

Deja `build/start_up_info.json` con `timeToFirstFrameRasterizedMicros` (cuánto tardó en aparecer el primer cuadro). Repetirlo varias veces: cambia bastante de una a otra.

### El gráfico de cuadros

En la terminal donde corre `flutter run --profile`, presiona `P` para mostrar u ocultar el *performance overlay*: dos gráficos encima del juego.

- **Arriba, raster**: el tiempo de la GPU para dibujar cada cuadro.
- **Abajo, UI**: el tiempo de Dart (simulación, componentes de Flame, widgets).

Cada barra es un cuadro; la línea verde horizontal marca 16 ms. Las barras rojas son cuadros que se pasaron (*jank*): el jugador nota un tirón.

### DevTools

`flutter run --profile` imprime una línea como:

```
The Flutter DevTools debugger and profiler on ... is available at: http://127.0.0.1:9100?uri=...
```

Ábrela en el navegador.

- **Performance**: el gráfico de cuadros con más detalle. Toca un cuadro rojo para ver qué tardó: *Build* y *Layout* son widgets de Flutter (el HUD, los menús); *Paint* y *Raster*, el dibujo.
- **CPU Profiler**: presiona *Record*, haz la prueba de estrés unos segundos y *Stop*. La vista *Bottom Up* ordena las funciones por tiempo propio. Si arriba aparece `Simulation.step` o `_attackable`, el problema es la lógica (vuelve a la parte 1); si aparece `render` de algún componente, es el dibujo.
- **Memory**: si la memoria sube sin parar durante la partida, algo se está creando en cada cuadro y no se libera.

## Lo que ya se hizo para que rinda

- **Simulación de paso fijo** (30 ticks por segundo): su costo no depende de los FPS del teléfono.
- **Pools de componentes** para proyectiles, pulsos y números de daño (`ComponentPool`): se reutilizan en lugar de crearse y destruirse.
- **Nada se crea al dibujar**: los `Paint`, los `Path` de las marcas de efectos y los rectángulos se preparan al crear cada componente.
- **Topes**: hasta 24 números de daño a la vez (sumados por plaga cada 0,3 s), 10 explosiones de partículas y 6 sonidos cada 250 ms.
- **El HUD solo se reconstruye cuando cambia**: Riverpod compara el estado nuevo con el anterior (`BattleHudState` define `==`) y, si son iguales, no avisa a nadie.

## Si algo va lento

1. Repite la medición en profile para confirmar que no es el modo debug.
2. Mira en DevTools si el tiempo se va en UI o en raster.
3. Si es la lógica, reproduce con `tool/stress.dart` y compara antes y después de cada cambio.
4. Si es el dibujo, busca componentes que creen objetos en `render` o `update`, o efectos con transparencias grandes (son caros en la GPU).
