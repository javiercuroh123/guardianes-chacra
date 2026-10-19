# Pruebas manuales en un teléfono

Los tests automáticos (`flutter test`) cubren la lógica y las pantallas, pero no pueden oír el audio, sentir la vibración ni ver si algo se entiende de un vistazo. Esta lista se repasa en un teléfono real antes de cerrar una fase o de publicar una versión.

Copia la lista en el reporte de la fase y marca cada punto: `[x]` bien, `[ ]` pendiente, `[!]` falla (con una nota).

## Preparar

```powershell
flutter devices
flutter run --release
```

- Usa **release** para probar el juego como lo verá el jugador, **profile** para medir rendimiento (ver `RENDIMIENTO.md`) y **debug** solo para el panel de desarrollo con recarga en caliente.
- Para empezar desde cero, borra los datos de la app: Ajustes de Android → Apps → Guardianes de la Chacra → Almacenamiento → Borrar datos.

## Arranque y pantalla

- [ ] La app abre directamente en horizontal y en pantalla completa (sin barras del sistema).
- [ ] Al girar el teléfono 180° la imagen gira; nunca pasa a vertical.
- [ ] Al deslizar desde un borde aparecen las barras del sistema y se vuelven a ocultar solas.
- [ ] Suena la música del menú.

## Menús

- [ ] Título: Jugar, Bestiario y Ajustes abren su pantalla; atrás vuelve al título.
- [ ] Valle (nueva partida): solo Chacra del Valle está abierto; tocar un nivel cerrado dice qué falta para abrirlo.
- [ ] Vista previa: muestra oleadas, plagas en orden de llegada y guardianes disponibles.
- [ ] Bestiario: lo no descubierto aparece como "Sin descubrir"; después de jugar, con su ficha.

## Partida

- [ ] Tocar un espacio vacío abre el menú de construir; el primer toque muestra el alcance y el segundo construye.
- [ ] Lo que no alcanza el maíz se ve gris y no responde; intentar algo inválido muestra un aviso breve.
- [ ] Tocar un guardián abre su menú: mejorar, vender, cambiar a quién apunta; en el último nivel ofrece las dos ramas.
- [ ] Tocar fuera cierra el menú.
- [ ] "⏭ … s +N" llama la oleada antes y suma ese maíz.
- [ ] El contador de maíz (hecho en Rive) muestra el número; al ganar maíz el ícono rebota y el número destella en verde, al gastarlo destella en rojo. Con "Quitar animaciones" de Android solo cambia el número.
- [ ] x1 / x2 cambia la velocidad; a x2 el botón se pinta de amarillo.
- [ ] Las marcas de efectos se distinguen por la forma: lento = anillo punteado, quemadura = corona de puntas, aturdido = puntos girando sobre la cabeza.
- [ ] Al aparecer el jefe: sonido propio, vibración fuerte y una sacudida corta de la cámara.
- [ ] Cuando una plaga llega a la collca: sonido y vibración suave (espaciada, no continua).
- [ ] Pausa detiene todo (también la música); Continuar sigue donde estaba.
- [ ] El botón de inicio de Android pausa la partida; al volver sigue pausada hasta tocar Continuar.

## Fin de partida y progreso

- [ ] Victoria: estrellas según las papas que quedan, resumen y lo que se desbloqueó.
- [ ] "Siguiente nivel" lleva a la vista previa del nivel siguiente.
- [ ] Derrota: Reintentar empieza de nuevo con el maíz y las papas iniciales.
- [ ] Cerrar la app desde recientes y abrirla otra vez: siguen las estrellas, los niveles abiertos y el Bestiario.
- [ ] Orilla del Lago pide haber ganado Andenes y tener 4 estrellas en total.

## Ajustes

- [ ] Música y Efectos se apagan y prenden al momento; la música retoma la pista correcta.
- [ ] Vibración apagada: el jefe y la collca ya no vibran.
- [ ] Números de daño (apagados por defecto): al prenderlos, los números se leen sobre el pasto, la tierra y el agua.
- [ ] Idioma: español / inglés cambia todos los textos, también los del contenido (nombres de plagas y guardianes).
- [ ] Los ajustes siguen igual después de cerrar y abrir la app.

## Anuncios (con los IDs de prueba; ver `MONETIZACION.md`)

- [ ] Con internet, en la vista previa aparece "Ver anuncio: +50 de maíz" a los pocos segundos; visto entero, la partida empieza con 50 de maíz más.
- [ ] Cerrar el recompensado antes de tiempo muestra el aviso y no da la recompensa.
- [ ] Al perder aparece "Ver anuncio: seguir con 5 papas"; la partida sigue con 5 papas, sin las plagas que había y con la música del nivel. Si se pierde otra vez, ya no se ofrece.
- [ ] Al salir del resultado de la tercera partida (sin recompensados) aparece un intersticial; al cerrarlo, sigue lo que se tocó.
- [ ] Sin internet: no aparecen botones de anuncios y el juego funciona igual.
- [ ] Con `UMP_TEST_DEVICE` (como en Europa): aparece el formulario de consentimiento y, en Ajustes, "Opciones de privacidad".

## Accesibilidad

- [ ] **Letra grande**: Ajustes de Android → Pantalla → Tamaño de fuente al máximo. Los menús crecen hasta el doble sin cortarse; el HUD y los menús de la partida crecen un poco (hasta 1,3) y no tapan el mapa.
- [ ] **Quitar animaciones**: Ajustes de Android → Accesibilidad → Quitar animaciones. Al aparecer el jefe ya no se sacude la cámara.
- [ ] **TalkBack**: el HUD se lee completo ("Maíz: 220", "Papas en la collca: 20"…) y los botones del menú dicen qué hacen y cuánto cuestan.
- [ ] **Escala de grises** (Opciones de desarrollador → Simular espacio de color → Monocromía): los efectos de estado se distinguen igual por su forma.
- [ ] Todos los botones se tocan cómodos con el pulgar.

## Herramientas de desarrollo (debug y profile)

- [ ] En la partida aparece el botón 🐞; en Ajustes, "Desarrollo: todo desbloqueado".
- [ ] Maíz infinito, Invencible y Saltar oleada funcionan.
- [ ] "Caminos, alcances, FPS y conteos" muestra caminos, alcances, FPS y conteos.
- [ ] En **profile**, la prueba de estrés (150 plagas) a x2 se mantiene cerca de 60 FPS (ver `RENDIMIENTO.md`).
- [ ] En **release** no aparece el botón 🐞 ni el interruptor de desarrollo.
