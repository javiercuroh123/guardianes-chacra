# Guardianes de la Chacra — referencias de interfaz

15 imágenes conceptuales generadas con la herramienta integrada `image_gen.imagegen`, a partir de 13 capturas reales del juego instalado en el Android conectado por USB y de la lectura de las pantallas del proyecto. No se modificó el código ni se integraron recursos al juego.

Abre `00_vista_general.jpg` para recorrer la colección. Las imágenes individuales están en `propuestas/`; las capturas del juego actual, en `capturas_actuales/`. El conjunto de prompts y los tres retoques finales están en `prompts.json`.

| Imagen | Pantalla o estado |
| --- | --- |
| 01_inicio.png | Menú principal |
| 02_mapa_del_valle.png | Selección de nivel |
| 03_preparacion.png | Preparación: plagas, recursos y comenzar |
| 04_batalla_valle.png | Batalla en Chacra del Valle |
| 05_construccion.png | Construcción de guardianes |
| 06_mejoras.png | Alcance, mejora, objetivo y venta |
| 07_especializacion.png | Piedra pesada u Honda veloz |
| 08_batalla_andenes.png | Batalla en Andenes, con dos entradas |
| 09_batalla_lago.png | Batalla en Orilla del Lago |
| 10_pausa.png | Continuar, reintentar y salir |
| 11_victoria.png | Estrellas, cosecha y desbloqueo |
| 12_derrota.png | Reintentar y recuperación opcional |
| 13_bestiario_plagas.png | Enciclopedia de plagas |
| 14_bestiario_guardianes.png | Enciclopedia de guardianes |
| 15_ajustes.png | Sonido, respuesta, pantalla e idioma |

La dirección visual combina cartoon expresivo, identidad andina, paneles crema, botones de maíz dorado y acentos turquesa. Se conservaron el maíz como moneda, las papas como vidas, los cinco guardianes y los tres escenarios. Las pantallas de victoria y derrota se guiaron por las ventanas y opciones existentes en `lib/features/battle/presentation/overlays/battle_overlays.dart`; no son capturas de partidas completadas en el teléfono.

Son referencias de apariencia y distribución. Los diseños de mapa y las cifras visibles ilustran estados de juego; las posiciones exactas de los espacios y el escalado se resolverían al implementar. Los anuncios recompensados y las opciones de privacidad se muestran como estados condicionales, según las funciones ya presentes en el proyecto.

Los PNG individuales conservan su resolución original de generación y una proporción horizontal aproximada de 20:9. La lámina general es únicamente un catálogo de miniaturas rotuladas; los originales permanecen completos.
