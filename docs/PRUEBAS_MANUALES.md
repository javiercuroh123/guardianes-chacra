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

- [ ] Título: de fondo el valle (cordillera, lago, andenes con la collca llena, chacra) con nubes que cruzan; el logo cae y sus tres líneas bajan una tras otra, la cinta del lema hace "pop" y las hojas se mecen; Jugar (ancho, de maíz) respira; el hondero hace girar la honda y parpadea, la llama mastica de a ratos y cada tanto un gorgojo se asoma entre las hojas. Con "Quitar animaciones", todo quieto.
- [ ] Título: Jugar, Bestiario y Ajustes abren su pantalla; atrás vuelve al título.
- [ ] Valle (nueva partida): de fondo, el valle del título; solo Chacra del Valle está abierto (verde, flota y lleva el anillo dorado de sugerido); los otros, grises y con candado. Tocar uno cerrado lo sacude y muestra encima un globo con lo que falta, que se va solo a los 3 s o al tocar el mapa.
- [ ] Valle: arriba, Volver (vuelve al título), el cartel "El valle" y las estrellas "N/9"; abajo, la ilustración, el nombre y las estrellas del nivel sugerido y Jugar, que abre su vista previa (igual que tocar el nodo).
- [ ] Valle: al ganar un nivel que abre otro, al volver al valle el camino de piedritas se dibuja hasta el nuevo, su candado salta y suena la estrella; el anillo pasa al nivel sugerido. Con "Quitar animaciones", el camino ya está y nada flota.
- [ ] Preparación: de fondo el valle; arriba las oleadas, el cartel con el nombre del nivel, el maíz inicial y las papas; a la izquierda la ilustración del nivel; a la derecha las tarjetas de las plagas en el orden en que llegan, que entran una tras otra (en Andenes y la Orilla se ven cinco y asoma la sexta; la fila se desliza). Las que no viste llevan "Nueva"; el Rey Gorgojo, marco ciruela, la cinta "Jefe final" y un brillo que late detrás de la corona.
- [ ] Preparación: tocar una plaga muestra un globo con lo que hace; se va solo, al tocar fuera o al deslizar. Volver regresa al valle; Comenzar empieza; "Ver anuncio: +50 de maíz" aparece solo con un anuncio cargado.
- [ ] Victoria que abre un nivel: la tarjeta "Desbloqueado" muestra la escena de ese nivel (postal inclinada) en vez de la bandera.
- [ ] Bestiario: pestañas Plagas y Guardianes (tocándolas o deslizando). Lo no descubierto es una silueta "?" con "???"; su detalle dice cómo conocerlo. Lo recién descubierto queda boca abajo: al tocarlo se da vuelta, suena la estrella y lleva "¡Nuevo!" hasta salir; la próxima vez ya está boca arriba.
- [ ] Bestiario: el detalle de una plaga muestra su retrato, la descripción y sus números (vida, velocidad, maíz, papas, cómo se mueve, armadura y resistencias si tiene); el de un guardián, los niveles I‑II‑III (al tocar uno cambian el costo y el alcance) y sus dos especializaciones.

## Partida

- [ ] Tocar un espacio vacío abre el menú de construir: las tarjetas (retrato, nombre, costo) salen en abanico una tras otra. El primer toque levanta la tarjeta con brillo de maíz, muestra el alcance (círculo turquesa punteado) y abajo "Nombre · a qué ataca / Toca otra vez para confirmar"; el segundo hace un "pop" y construye.
- [ ] Lo que no alcanza el maíz se ve gris con el costo en rojo: tocarlo lo sacude y abajo dice "No alcanza el maíz". Los guardianes bloqueados se ven con candado: tocarlos los sacude y abajo dice qué falta ("Se abre al ganar…"). Intentar algo inválido muestra un aviso breve.
- [ ] Tocar un guardián abre su ficha del lado contrario: retrato, "Nombre · Nivel N", a qué ataca y dos filas "actual → siguiente" donde el valor nuevo late. Mejorar y Vender (terracota) piden dos toques; Objetivo cambia con uno; la X cierra.
- [ ] En el último nivel, "Especializar" abre la ventana: el juego se detiene, las dos tarjetas entran girando, tocar una la levanta y muestra su alcance en el mapa, "Elegir" la hace estallar y se cierra; la X vuelve a la ficha y el juego sigue.
- [ ] Tocar fuera cierra el menú.
- [ ] "Siguiente oleada" (abajo a la derecha): el anillo verde se vacía con la cuenta regresiva; tocarlo rebota el anillo y el bono, llama la oleada y el maíz suma ese bono con su "+N".
- [ ] Al empezar cada oleada cae el cartel "Oleada N" y se va solo; si trae al jefe, el cartel es rojo con la cinta "¡Llega el jefe!" y la barra de oleadas se pone roja.
- [ ] Las papas se ven "N/máx"; al perder una, el número destella en rojo y tiembla; con pocas (30 % o menos) la pastilla late en rojo.
- [ ] El contador de maíz (hecho en Rive) muestra el número; al ganar maíz el ícono rebota, el número destella en verde y flota un "+N" debajo; al gastarlo destella en rojo. Con "Quitar animaciones" de Android solo cambia el número.
- [ ] Los botones de Rive (título, preparación, pausa, victoria y derrota): se hunden al apoyar el dedo, rebotan al soltar, suenan y vibran (si la vibración está encendida en Ajustes). El principal tiene un brillo que lo cruza cada ~4 s; con "Quitar animaciones", no. Con letra al 200 % crecen sin cortarse.
- [ ] Panel 🐞 → "Catálogo de la interfaz": arriba todos los estados quietos; abajo, cada componente responde ("Mejorar" se sacude y avisa que no alcanza el maíz, las estrellas se llenan una por una, el interruptor cruza con squash, la pastilla del selector se desliza, el tooltip y el panel entran y salen).
- [ ] x1 / x2 cambia la velocidad: la cara del botón da una vuelta, a x2 se pinta de maíz y dos flechitas avanzan; con "Quitar animaciones", sin vuelta ni flechas moviéndose.
- [ ] Las marcas de efectos se distinguen por la forma: lento = anillo punteado, quemadura = corona de puntas, aturdido = puntos girando sobre la cabeza.
- [ ] Al aparecer el jefe: sonido propio, vibración fuerte y una sacudida corta de la cámara.
- [ ] Cuando una plaga llega a la collca: sonido y vibración suave (espaciada, no continua).
- [ ] Pausa detiene todo (también la música): el mapa se oscurece, cae el panel con el cartel "Pausa" y el sol con espiral gira despacio; debajo "La chacra puede esperar", Continuar (grande, de maíz) y Reintentar y Salir del nivel (terracota). Continuar sigue donde estaba.
- [ ] El botón de inicio de Android pausa la partida; al volver sigue pausada hasta tocar Continuar.

## Fin de partida y progreso

- [ ] Victoria: cae el cartel "¡Cosecha a salvo!" con el sol que sonríe; las estrellas se llenan una a una, cada una con su sonido y una vibración; "Papas restantes" y "Maíz cosechado" cuentan desde 0 y hacen "pop"; entran las tarjetas de lo desbloqueado (un guardián con su retrato, un nivel con la bandera) con su destello; al final llueve maíz y la llama salta. Los botones se pueden tocar enseguida (antes de 0,3 s).
- [ ] Un toque fuera de los botones durante la victoria lleva al final de una vez, sin más sonidos de estrella. Con "Quitar animaciones" se ve el final directamente, sin lluvia ni salto.
- [ ] Derrota: el panel entra temblando con "La collca se quedó sin papas" (sin sol), la llama triste junto a la collca vacía, "Papas restantes 0/20", "Prueba otra combinación de guardianes.", Reintentar (de maíz) y Volver al valle; "Ver anuncio…" abajo, solo si hay un anuncio cargado.
- [ ] "Siguiente nivel" lleva a la vista previa del nivel siguiente.
- [ ] Derrota: Reintentar empieza de nuevo con el maíz y las papas iniciales.
- [ ] Cerrar la app desde recientes y abrirla otra vez: siguen las estrellas, los niveles abiertos y el Bestiario.
- [ ] Orilla del Lago pide haber ganado Andenes y tener 4 estrellas en total.

## Ajustes

- [ ] Pantalla: el valle de fondo y la llama a la izquierda; dos columnas (Sonido y respuesta / Pantalla e idioma) con un ícono por fila e interruptores de Rive; el idioma con Sistema / Español / English; Volver arriba a la izquierda.
- [ ] Música y Efectos se apagan y prenden al momento; la música retoma la pista correcta.
- [ ] Vibración apagada: el jefe, la collca y los botones ya no vibran.
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
