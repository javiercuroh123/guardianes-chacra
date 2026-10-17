# Simulador de balance

```bash
dart run tool/balance.dart
```

Juega cada nivel sin gráficos con la misma simulación que el juego y el contenido real de `assets/`, y escribe `build/balance/balance.csv` (más un resumen en la terminal). Corre con `dart` (sin Flutter) porque el dominio es Dart puro: las 12 partidas tardan menos de medio segundo.

## Estrategias

Están en `lib/dev/balance/autoplay.dart` y son genéricas: no nombran espacios, los eligen por cuánto camino cubren. Con varios caminos se turnan el mejor espacio de cada uno (sus tramos propios primero; los compartidos, cerca de la collca, después).

| Estrategia | Qué hace | Qué esperamos |
|---|---|---|
| `minima` | 3 Honderos sin mejoras | Pierde (si gana, el nivel no tiene reto). |
| `honderos` | Solo Honderos, construyendo y mejorando | Gana: es una defensa razonable. |
| `mixta` | Todos los guardianes disponibles, por turnos (incluido el Pututu, que no ataca) | Una defensa "de jugador nuevo". |
| `mejoras` | Pocos guardianes, mejorados al máximo antes de seguir | Riesgosa a propósito. |

Cada nivel se juega con los guardianes que el jugador tendría al llegar (los niveles anteriores ganados con 3 estrellas). Las estrategias esperan a tener el maíz de lo que decidieron; no llaman oleadas antes de tiempo.

El CSV tiene: nivel, estrategia, resultado, oleada en que se perdió, oleadas del nivel, papas, papas iniciales, maíz sobrante, maíz gastado, guardianes construidos y segundos de partida.

## Resultados actuales (17 de octubre de 2026)

| Nivel | minima | honderos | mixta | mejoras |
|---|---|---|---|---|
| Chacra del Valle | pierde (oleada 10/10) | gana 20/20 | gana 18/20 | gana 20/20 |
| Andenes | pierde (7/12) | gana 20/20 | pierde (5/12) | pierde (9/12) |
| Orilla del Lago | pierde (10/15) | gana 20/20 | gana 20/20 | gana 11/20 |

Lectura:

- **Chacra del Valle** está bien como primer nivel: se gana con cualquier defensa razonable y la mínima solo cae ante el jefe.
- **Andenes** exige cubrir los dos caminos. `mixta` pierde porque el camino sur queda solo con la Llama (ralentiza, casi no daña) y su cuarta compra es un Pututu (apoyo): en la oleada 3 se le escapan las langostas y polillas de la oleada 2 (14 papas). `honderos`, con daño en ambos caminos, no pierde ninguna. Cambiar el maíz inicial (280–320) o repartir los gorgojos de las oleadas 3 y 5 entre caminos no cambió nada: no es un problema de economía.
- **Orilla del Lago** (el último nivel) resulta **más fácil que Andenes**: tres de las cuatro estrategias ganan. La curva de dificultad está invertida entre los niveles 2 y 3.

## Propuestas (pendientes de aprobación)

Medidas con variantes en memoria, sin tocar los JSON:

| Propuesta | Efecto medido |
|---|---|
| **Orilla del Lago: maíz inicial 300 → 260 y cada grupo de plagas ×1,3 (redondeado; el jefe igual).** | `minima` pierde antes (oleada 8), `mejoras` pierde (oleada 8); `honderos` y `mixta` siguen ganando con 20 papas. Queda al menos tan exigente como Andenes, con más guardianes disponibles. |
| Orilla del Lago: solo maíz 300 → 260 | Más suave: `mejoras` gana con 7 papas en lugar de 11. |
| Andenes: sin cambios | Su dificultad viene de defender dos caminos, que es su idea. |

Variantes que se probaron y no cambian nada: Andenes con 280, 300 o 320 de maíz; Andenes con las oleadas 2–7 al 80 %; Orilla con las oleadas 8–15 ×1,25.

## Límites

Las estrategias son simples: no venden, no cambian la estrategia de apuntado ni llaman oleadas antes. Sirven para comparar niveles entre sí y detectar cambios bruscos, no para decir si un nivel es divertido: eso solo lo dicen las pruebas con jugadores.
