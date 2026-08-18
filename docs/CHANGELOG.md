# Changelog

Este archivo registra únicamente cambios realmente implementados en **Entre líneas**. Las ideas pendientes permanecen en [`IDEAS.md`](IDEAS.md) y las tareas previstas en [`ROADMAP.md`](ROADMAP.md).

El proyecto utiliza versiones de tres bloques (`x.x.x`). Cada entrega que modifique el proyecto debe incrementar la versión y registrar aquí sus cambios.

## [Unreleased]

### Added

### Changed

### Fixed

## [0.9.32] - 2026-08-18

### Changed

- Los textos narrativos inferiores avanzan con clic o toque únicamente sobre el propio panel de diálogo; pulsar el fondo, personajes, hotspots u otras zonas de la pantalla ya no avanza la conversación.
- Al volver a una habitación cuya conversación quedó a medias, la frase de reencuentro se muestra como un bocadillo inferior dentro de la habitación y enlaza después con el checkpoint exacto, en lugar de aparecer sobre una transición negra.

### Fixed

- Los nodos temporales de reencuentro nunca se guardan como checkpoint permanente: guardar o salir al menú mientras están visibles conserva el nodo narrativo real que había quedado pendiente.

## [0.9.31] - 2026-08-18

### Fixed

- El hotspot interactivo de los monitores de Javi queda desactivado mientras hay respuestas visibles, evitando que los botones de la columna izquierda abran accidentalmente el primer plano de las dos pantallas.
- La introducción narrativa del duelo de Javi ya no se considera vista al entrar en la habitación: solo se marca como completada al avanzar desde su última frase al primer insulto.
- Si se sale al mapa, al menú o se carga la partida antes de terminar el relato, se conserva el checkpoint `javi_intro_XX` y se continúa la secuencia narrativa en vez de saltar directamente al bucle de insultos.
- Una vez terminada la introducción, las nuevas entradas eliminan el checkpoint de pregunta y vuelven a pasar por «¿Seguimos con la batalla de insultos?» antes de continuar con los insultos pendientes.

## [0.9.30] - 2026-08-18

### Fixed

- La entrada real desde el mapa a la habitación de Javi en el Día 3 deja de ejecutar el `reroll_javi_question_for_visit()` heredado de 0.9.8, que reconstruía una sola pregunta y podía volver a mostrar el aviso antiguo.
- `Version044VisitTransitions` prepara ahora la batalla persistente antes de abrir la habitación y usa como destino el prólogo narrativo, la pregunta «¿Seguimos con la batalla de insultos?» o el estado de batalla completada según corresponda.
- Se añade una marca nueva por slot para que incluso partidas que pasaron por las rutas defectuosas 0.9.27–0.9.29 vean una vez el prólogo «Hace muchos años, un joven llegó a una isla con un sueño.» tras actualizar.

## [0.9.29] - 2026-08-18

### Fixed

- Los slots guardados dentro de la habitación de Javi en el Día 3 antes de introducir `javi_insult_battle` ya no continúan por el diálogo heredado.
- Al cargar uno de esos guardados se crea el estado de la batalla y, al tratarse de la primera entrada al nuevo sistema, se redirige a «Hace muchos años, un joven llegó a una isla con un sueño.» en vez de saltarse el prólogo.

## [0.9.28] - 2026-08-18

### Fixed

- Eliminado el fallback heredado de Javi que todavía podía reconstruir el aviso «esto es un juego de insultos piratas» en el Día 3.
- La introducción narrativa del duelo se vuelve a instalar explícitamente después de cada reconstrucción de `Story`, garantizando que la primera frase sea «Hace muchos años, un joven llegó a una isla con un sueño.» y que termine en «Allí las peleas se ganaban de otra forma.» antes del primer insulto.

## [0.9.27] - 2026-08-18

### Added

- Nueva introducción narrativa para el duelo de insultos de Javi: un joven llega a una isla con un sueño, consigue una espada y una pala y descubre que allí los combates se ganaban de otra forma.
- La introducción termina en «Allí las peleas se ganaban de otra forma.» y enlaza directamente con el primer insulto y sus cuatro posibles réplicas.
- Estado persistente de la batalla de insultos dentro de cada slot, con registro de insultos completados y pendientes.

### Changed

- El duelo de insultos de Javi queda reservado al **Día 3**; los días 1 y 2 recuperan sus preguntas normales definidas en `data/day_dialogues.json`.
- La primera visita del Día 3 muestra la introducción narrativa y después encadena los insultos pendientes; las visitas posteriores empiezan con «¿Seguimos con la batalla de insultos?» y permiten continuar o volver al mapa.
- Los insultos ya respondidos no vuelven a aparecer. En cada nueva entrada se barajan únicamente los que siguen pendientes, de forma que el orden cambia sin introducir repeticiones.
- Guardar o continuar una partida a mitad de la batalla conserva el progreso y reconstruye un punto de reanudación estable antes de los insultos restantes.
- La pista de los monitores del Día 3 se muestra después del último insulto pendiente de la sesión para no interrumpir la presentación del duelo.

## [0.9.26] - 2026-08-18

### Changed

- Retirado del aviso de Portugal el experimento visual de créditos analógicos y la comparativa de diez presets.
- El aviso vuelve a mostrarse una sola vez con **Monocraft**, sin jitter, vibración, aberración cromática, grano, halation, flicker ni shader.
- Se conserva el flujo y los tiempos del preludio 0.9.22, incluido el enlace en negro hacia **El reencuentro** para evitar destellos del mapa.

## [0.9.25] - 2026-08-18

### Added

- Comparativa simultánea de diez configuraciones del efecto de créditos analógicos aplicada al aviso de Portugal, numeradas del 01 al 10 en una cuadrícula 2×5.
- Presets de comparación reutilizables con variantes claramente diferenciadas: limpio, RGB marcado, proyección suave, grano/suciedad, halation, RGB extremo, gate weave, flicker/exposición, archivo gastado y cine marcado.

### Changed

- El cargador de presets permite ahora definir variantes mediante overrides parciales sobre el preset base, facilitando guardar y reutilizar configuraciones sin duplicar todos los parámetros.
- El shader admite valores de aberración cromática de hasta 8 px para poder comparar desregistros RGB mucho más visibles.

## [0.9.24] - 2026-08-18

### Changed

- Reequilibrado el preset `subtle_35mm_titles`: el gate weave pasa a una deriva casi imperceptible, con mucho menos desplazamiento, rotación y variación de escala y con cambios más lentos.
- La aberración cromática, el grano fino, el soft focus, el halation y el color bleed ganan algo de presencia para que el aspecto de película analógica domine sobre el movimiento del texto.
- Reducidos ligeramente el flicker y las variaciones de exposición para evitar que el resultado parezca una animación digital.

## [0.9.23] - 2026-08-18

### Added

- Nuevo sistema reutilizable de créditos con estética de película de 35 mm: shader independiente para grano, aberración cromática, soft focus, halation, flicker, color bleed, polvo, arañazos y variación de exposición.
- Controlador separado para gate weave/jitter, rotación y variación mínima de escala mediante movimientos pseudoaleatorios suaves.
- Preset `subtle_35mm_titles` guardado en `data/film_credit_presets.json`, con parámetros editables y activación individual de cada efecto.
- Documentación de reutilización en `docs/FILM_CREDIT_TEXT_EFFECT.md`.

### Changed

- El aviso de Portugal usa el nuevo preset analógico sobre la fuente local Monocraft, manteniendo efectos deliberadamente sutiles y legibles.

## [0.9.17] - 2026-08-18

### Fixed

- Eliminada la dependencia circular que impedía importar/exportar el proyecto desde 0.9.16: el preludio de Nueva partida deja de heredar del splash de arranque, que precarga `main.tscn`, y pasa a ser un `Control` independiente.
- El flujo conserva el aviso de Portugal en Georgia, los fundidos lentos y el logo de Naranjal Studio a mitad de tamaño sin volver a cargar la escena principal durante su propia importación.

## [0.9.16] - 2026-08-18

### Changed

- El aviso de Portugal y el splash de Naranjal Studio pasan a mostrarse únicamente al iniciar una **Nueva partida**.
- Al abrir la aplicación solo se conserva la pantalla inicial que solicita activar pantalla completa antes de mostrar el menú.
- El logo de Naranjal Studio del preludio de Nueva partida se reduce al 50 % de su tamaño anterior manteniéndose centrado.

## [0.9.15] - 2026-08-17

### Changed

- La franja oscura con el nombre en `Extras → Personajes` se convierte en una etiqueta inferior más fina, con margen respecto a los bordes de la tarjeta.
- El antiguo flujo **Crear personaje** se sustituye por **Invitado al grupo**, que permite entrar directamente sin rellenar nombre, género ni apariencia.

## [0.9.14] - 2026-08-17

### Changed

- El aviso sobre Portugal usa únicamente la fuente **Georgia**, retirando la comparación con DejaVu Serif Bold y Courier New.
- El fundido de entrada del aviso aumenta a 4 segundos y el de salida a 4,5 segundos, más del doble que los tiempos anteriores.

## [0.9.13] - 2026-08-17

### Changed

- Las tarjetas de Apariencia reservan espacio vertical según la altura real de la ventana y eliminan el texto auxiliar inferior redundante, evitando que el contenido quede cortado en determinadas resoluciones.
- La apariencia seleccionada se identifica mediante una insignia flotante **EN USO** dentro de la propia tarjeta, manteniendo toda la tarjeta como superficie de selección.
- La franja oscura de nombre en `Extras → Personajes` se reduce a una etiqueta inferior de aproximadamente el 14,5 % de la tarjeta, con menor opacidad y tipografía más compacta.

### Fixed

- Corregido el recorte del texto inferior en las tarjetas de Apariencia cuando el alto disponible era insuficiente.
- Corregido el bloque negro excesivamente alto del listado de Personajes, que ocupaba demasiado espacio visual bajo las ilustraciones.

## [0.9.12] - 2026-08-17

### Added

- Nuevo preludio antes del logo de Naranjal Studio con pantalla negra y mensaje parpadeante de estilo Commodore que recomienda jugar a pantalla completa.
- La primera interacción por clic, toque, teclado o mando solicita el modo de pantalla completa antes de continuar el arranque.
- Segunda pantalla negra con el aviso sobre los hechos acontecidos en Portugal mostrado simultáneamente en tres propuestas tipográficas: **DejaVu Serif Bold**, **Georgia** y **Courier New**, identificadas en pantalla para poder escoger una más adelante.

### Changed

- El aviso de Portugal entra y sale mediante fundidos lentos y automáticos para darle un tono más dramático antes de iniciar el splash de Naranjal Studio.
- El logo de Naranjal conserva su animación y transición posterior al menú una vez finalizado el nuevo preludio.

## [0.9.11] - 2026-08-17

### Added

- La apariencia alternativa `jony_alternativo.png` queda registrada para Jony con el nombre **Adam Driver**.

### Changed

- La pestaña activa de las fichas de personaje se conserva al navegar con **Anterior** y **Siguiente**: Ficha, Cosméticos o Apariencia permanecen seleccionadas al pasar a otro personaje.
- Las tarjetas de Apariencia son ahora completamente clicables; desaparece el botón interior de selección y la apariencia activa se identifica visualmente con borde destacado y estado `EN USO`.
- Las tarjetas de Apariencia se compactan y distribuyen en más columnas para que, en escritorio, no sea necesario hacer scroll mientras haya menos de cinco apariencias.

### Fixed

- Las franjas oscuras con los nombres en el listado de Personajes comienzan debajo de la ilustración y dejan de tapar la parte inferior del personaje.

## [0.9.10] - 2026-08-17

### Fixed

- Eliminado el destello de unas milésimas del logo de Naranjal Studio al terminar el splash: una vez alcanzado el negro total, el logo se oculta y el menú se revela desvaneciendo únicamente la capa negra.

## [0.9.9] - 2026-08-17

### Added

- Sistema global de **Apariencias** por personaje, separado de los cosméticos comprables de la tienda.
- Nueva pestaña **Apariencia** dentro de `Extras → Personajes → ficha del personaje`, con previsualización y selección del aspecto activo.
- Registro data-driven `data/character_skins.json` para asociar skins a cada personaje sin tocar su lógica narrativa.
- Primeras asociaciones preparadas para Javi (`javi-lapalanca`), Jony (`jony-lapalanca`), Smokey (`smokey-lapalanca`) y Ana (`ana(2)`).

### Changed

- Todas las apariencias registradas en esta pestaña están disponibles desde el principio: no cuestan MONEDAS ni requieren desbloqueo.
- La apariencia elegida se guarda en el perfil global y puede cambiarse en cualquier momento desde Extras, afectando a partidas actuales y futuras.
- El aspecto original permanece siempre como opción y conserva el sistema de poses y expresiones existente.
- Una skin alternativa sustituye la ilustración completa del personaje mientras está seleccionada, sin alterar preguntas, afinidad, habitación o progreso.

## [0.9.8] - 2026-08-17

### Added

- Antes de la pregunta de Javi se avisa explícitamente de que comienza un juego de insultos piratas y que las réplicas forman parte del juego.

### Changed

- Cada entrada en la habitación de Javi vuelve a elegir aleatoriamente una de las 16 preguntas del pool, en lugar de fijar la secuencia únicamente al crear la partida.
- Las revisitas evitan repetir inmediatamente el mismo insulto cuando existen alternativas, manteniendo una sola pregunta durante toda la estancia actual.
- Entrar de nuevo en la habitación de Javi reinicia su minijuego desde la introducción, descarta el checkpoint parcial de Javi y sortea un insulto nuevo antes de mostrar el aviso.

## [0.9.7] - 2026-08-17

### Added

- Pool de 16 preguntas de combate verbal para Javi, inspirado en los duelos de insultos piratas y adaptado a un tono andaluz suave y natural.

### Changed

- Javi mantiene una sola pregunta por jornada en los tres días actuales, pero cada partida selecciona sus preguntas desde el nuevo pool mediante una semilla aleatoria persistente.
- Los días 1, 2 y 3 avanzan cinco posiciones dentro del pool, evitando repetir la misma pregunta de Javi durante esos tres días de una misma partida.
- La semilla se guarda en el slot y se restaura antes de reconstruir el diálogo, por lo que cargar una partida conserva las preguntas que le correspondían; los guardados antiguos reciben una semilla al continuar por primera vez.

## [0.8.1] - 2026-08-15

### Added

- La habitación de Javi incorpora una zona interactiva sobre sus monitores que abre un primer plano usando `assets/backgrounds/pantalla-javi-naranjal.png`.
- En el primer plano, la pantalla derecha funciona como acceso directo a `https://javidei.github.io/pixel-adventure/` desde Web, escritorio y móvil.
- Smoke test específico de 0.8.1 para validar el fondo, el único botón visible de retorno y el destino de Pixel Adventure.

### Changed

- El primer plano de los monitores cubre completamente la escena normal: no muestra personajes, diálogo, HUD ni controles de habitación; únicamente deja el botón **Volver** y la zona clicable de la pantalla derecha.
- Las áreas interactivas se calculan sobre coordenadas normalizadas de la imagen y respetan el recorte `cover` del fondo en distintas relaciones de aspecto.
- Abrir los monitores no avanza la conversación ni altera la música o el checkpoint narrativo de la habitación.

## [0.8.0] - 2026-08-14

### Added

- Sistema **data-driven de jornadas narrativas** con tres primeros días, títulos, aperturas, cierres y objetivos distintos por jornada.
- **Diario de jornada** accesible desde el mapa con progreso del día, visitas obligatorias, pistas encontradas y pistas todavía pendientes.
- Primer puzle narrativo, **El código de la octava silla**, con cuatro pistas repartidas entre personajes y una solución final introducida manualmente por el jugador.
- Pistas indirectas que describen a quién visitar sin mostrar siempre su nombre, con selección de destinos adaptada al protagonista para no pedir al jugador que se visite a sí mismo.
- Persistencia por slot del día actual, jornadas completadas, visitas de cada día, pistas recogidas, intentos de código y resolución del puzle.
- Indicador de `DÍA N · X/Y` integrado en el mapa para consultar rápidamente el estado de la jornada.
- Smoke test específico de 0.8 para validar migración, objetivos diarios variables, cuatro pistas únicas, código incorrecto/correcto, avance entre días y final del primer arco.

### Changed

- El **Día 1** funciona como reencuentro y requiere visitar a todo el grupo salvo al protagonista; el **Día 2** demuestra la nueva estructura exigiendo solo varias conversaciones concretas; el **Día 3** gira alrededor de una investigación y un código.
- El porcentaje de progreso de una partida se calcula sobre los objetivos narrativos de los días disponibles, en lugar de depender únicamente de la primera ronda global de visitas.
- Los marcadores del mapa distinguen entre objetivo obligatorio, pista pendiente/completada y visita opcional, y se refrescan al regresar de una habitación.
- Los slots ocupados muestran el día actual, nombre de la jornada y objetivos completados además del tiempo y las MONEDAS.
- Resolver el puzle se registra como evento especial del sistema de progresión y economía existente, manteniendo las recompensas únicas por partida.
- El antiguo resumen de fin de visitas deja de representar el final de la progresión tras la primera ronda; el arco narrativo disponible termina después de completar las jornadas y el puzle.

### Fixed

- Los guardados 0.7 se migran al nuevo schema narrativo conservando las visitas ya completadas para que actualizar a 0.8 no obligue a repetir artificialmente el Día 1.
- La lógica automática de jornadas se aísla durante los smoke tests heredados para no competir con las transiciones narrativas históricas que estos validan.
- Los tests heredados de slots y mapa/progreso aceptan la rama 0.8 sin rebajar los contratos que protegen de versiones anteriores.

## [0.7.0] - 2026-08-14

### Added

- Sistema de hasta diez slots locales independientes bajo `user://save_slots/`, con índice del último slot utilizado.
- Pantalla **Partidas** para revisar, cargar y borrar partidas guardadas, con confirmación explícita antes de eliminar un slot.
- Selección de un slot vacío antes de iniciar una nueva partida, evitando sobrescrituras accidentales.
- Resumen por slot con protagonista, porcentaje de progreso narrativo, localidad, visitas completadas, tiempo jugado, MONEDAS, fecha y versión del guardado.
- Tiempo jugado específico por partida y autoguardado periódico de la partida activa.
- Smoke test específico de 0.7 para validar diez slots, aislamiento entre partidas, carga, borrado y flujo de interfaz.

### Changed

- **Continuar** carga automáticamente el slot utilizado más recientemente.
- El progreso narrativo, las MONEDAS, afinidad, checkpoints y posición permanecen separados por partida, mientras colección, cosméticos, logros y estadísticas siguen perteneciendo al perfil global.
- Los guardados incorporan metadatos de versión y schema para facilitar futuras migraciones.

### Fixed

- Crear una nueva partida deja de reemplazar implícitamente el progreso de la partida anterior.
- El antiguo guardado único `user://savegame.json` se migra automáticamente al Slot 1 cuando procede, sin borrar el archivo original de respaldo.

## [0.6.10] - 2026-08-14

### Changed

- El marcador de Fran pasa a mostrar `Visitar a Fran` y el del Argentino `Visitar al Argentino`, evitando tarjetas innecesariamente largas.
- Los iconos de estado visitado/pendiente de las tarjetas del mapa pasan a una esquina superior izquierda para no competir visualmente con el texto.

### Fixed

- Los estados de visita dejan de descentrar o apretar el texto en tarjetas con nombres largos.

## [0.6.9] - 2026-08-14

### Changed

- El retorno desde **Triana** a Naranjal del Río se mantiene abajo a la derecha y muestra una flecha SVG hacia la derecha.
- El retorno desde **Monte del Toro** a Naranjal del Río pasa abajo a la izquierda y muestra una flecha SVG hacia la izquierda.
- Las etiquetas de estas conexiones dejan de incluir flechas Unicode; la dirección se representa únicamente mediante iconos SVG.

## [0.6.8] - 2026-08-14

### Added

- Nuevo icono SVG específico de mapa para el botón de retorno desde las habitaciones.

### Fixed

- El botón `Mapa` de las habitaciones deja de reutilizar la flecha de navegación izquierda.
- Corregida la alineación del icono del botón `Mapa` para que quede a la izquierda del texto y no se superponga visualmente sobre la palabra.

## [0.6.7] - 2026-08-14

### Added

- Nuevo icono SVG local para la tienda del mapa.

### Changed

- Los marcadores de personajes, las conexiones entre localidades y el acceso a la tienda usan iconos SVG reales en lugar de símbolos tipográficos.
- Las flechas de viaje se alinean a izquierda o derecha según la dirección de la conexión, y los personajes muestran iconos distintos para pendiente y visitado.

### Fixed

- Eliminados del mapa los glifos Unicode que podían aparecer como cuadrados o caracteres extraños en Web y Android.
- Los botones de retorno a Naranjal y a Mapa usan ahora la flecha SVG existente en vez del carácter `←`.

## [0.6.6] - 2026-08-14

### Changed

- La portada de **Extras** distribuye sus accesos en una cuadrícula responsive de hasta cuatro columnas y reduce la altura de las tarjetas para mostrar más opciones sin tanto desplazamiento.
- La página **Extras → Logros** pasa de una lista vertical de tarjetas a una cuadrícula responsive: hasta cuatro columnas en pantallas muy anchas, tres en escritorio estándar, dos en anchos intermedios y una en pantallas estrechas.
- Las tarjetas de logros usan iconos, tipografías, márgenes y barras de progreso más compactas, manteniendo el scroll táctil y la legibilidad en móvil.

## [0.6.5] - 2026-08-14

### Added

- `eclipse-menu.ogv` se reproduce como fondo animado del menú principal, en bucle y sin interferir con la música del menú.

### Changed

- El vídeo del menú conserva su proporción 16:9 mediante un contenedor en modo `cover`, con el fondo estático anterior como respaldo.
- La capa oscura del menú se suaviza para dejar visible el eclipse sin perder legibilidad en los controles.

## [0.6.4] - 2026-08-14

### Changed

- Los siete personajes actuales pasan a tener rol `principal` tanto en sus JSON operativos como en `detalles-juego.json`.
- Eliminada la distinción de personajes secundarios para el reparto actual; todos pueden ser protagonistas y personajes relevantes de la historia.

## [0.6.3] - 2026-08-14

### Added

- Iconos SVG locales para estados de colección, logros conseguidos/pendientes/secretos y selección de sonido de clic.
- Smoke test específico para validar la experiencia táctil de Extras y evitar regresiones de iconos tipográficos en Android.

### Changed

- Los `ScrollContainer` de Extras priorizan el gesto táctil inmediato y permiten que los botones internos propaguen el arrastre sin perder su pulsación normal.
- Los controles puramente visuales dentro de páginas desplazables dejan de interceptar eventos táctiles.

### Fixed

- Corregido el desplazamiento con el dedo en Extras, que podía responder con mucho retardo al iniciar el gesto sobre textos, paneles o tarjetas.
- Sustituidos los símbolos Unicode usados como iconos de colección, logros y selección de sonido de clic, evitando glifos ausentes o caracteres extraños en Android.

## [0.6.2] - 2026-08-13

### Added

- Pestaña permanente de Cosméticos en todas las fichas de personaje, conectada al perfil global, con skins y mascotas iniciales para Ana y Jony.
- Botón `Mapa` dentro de las habitaciones y checkpoints independientes para pausar y retomar cada conversación.

### Changed

- Al volver a una habitación a medias, una frase de reencuentro configurable espera una pulsación y continúa exactamente donde se dejó.
- Los coleccionables comprados con asset visual, incluido el Retrato del grupo, muestran su imagen en `Extras → Colección` y permiten abrirla en una vista grande.
- El desbloqueo Retratos del grupo sustituye la alineación parcial del menú por dos artes completos incluidos en el repositorio: ilustración nocturna y pixel art.
- La Colección distribuye complementos en tarjetas compactas de varias columnas y coloca los diseños de cada pack lado a lado cuando hay espacio.

### Fixed

- Las tarjetas de selección de protagonista ya no reproducen dos sonidos de clic en una sola pulsación.
- Los regresos desde Triana y Monte del Toro se integran abajo a la derecha de cada panel temporal y desaparecen de la cabecera para evitar duplicados.
- La introducción temporal deja de repetir «2026» y las pantallas negras esperan una interacción real por clic, toque o teclado, incluso si se realiza durante el fundido.
- La música del menú usa un reproductor y bus independientes, por lo que puede sonar mientras la pista de habitación continúa avanzando silenciada y se recupera al continuar.
- El mapa data-driven oculta diálogo y HUD al abrirse y los restaura al entrar en una habitación, conservando la corrección de interfaz de la rama remota.
- La integración conserva los perfiles narrativos ampliados y añade únicamente residencia y zona a los personajes de la versión 0.6.
- El smoke 0.6 abre realmente Extras antes de medir su cuadrícula, evitando un falso fallo headless causado por contenedores ocultos sin geometría calculada.

## [0.6.1] - 2026-08-13

### Added

- Tema `menu.ogg` para la pantalla principal, reproducido en bucle a volumen bajo.

### Changed

- La música del menú entra mediante un fundido de cuatro segundos, continúa sin cortes por Extras/Ajustes y se detiene al comenzar la selección o la partida.

## [0.6.0] - 2026-08-13

### Added

- Mapa interactivo de Naranjal del Río basado en el PNG original incluido en `assets/maps/`, con marcadores normalizados, estado visitado y exclusión del protagonista.
- Navegación data-driven a Triana y Monte del Toro mediante pantallas temporales reutilizables, transiciones negras y diez excusas aleatorias sin repetición inmediata.
- Introducción breve de 2026 antes de seleccionar protagonista en una nueva partida.
- Sistema de MONEDAS y recompensas únicas por partida, con reglas configurables e infraestructura para escenas, eventos, descubrimientos y actividades repetibles.
- Tienda como localización del mapa, catálogo JSON de coleccionables/cosméticos y desbloqueos globales sin bloqueos narrativos.
- Perfil global local con estadísticas, tiempo activo, plataforma/touch, desbloqueos y logros data-driven.
- Páginas de Logros, Estadísticas y Colección dentro de Extras, además de notificaciones no bloqueantes.
- Cinco sonidos de clic procedurales y opción desactivada, seleccionables y persistentes desde Ajustes.
- Smoke test 0.6 para mapas, migraciones, economía, perfil, tienda, logros, estadísticas y sonidos.

### Changed

- El selector de visitas pasa a ser el mapa principal dentro del mismo flujo protagonista → destino → conversación → mapa.
- Los datos de personajes distinguen residencia actual en Naranjal del Río, Triana o Monte del Toro de su procedencia biográfica.
- El guardado y las preferencias incorporan schemas retrocompatibles; el progreso global se separa en `user://profile.json`.
- Las antiguas escrituras de versión de los parches 0.4.x respetan ahora la versión actual del proyecto.

### Fixed
- Las recompensas únicas ya no pueden repetirse entrando y saliendo de una visita.
- La alineación de marcadores se calcula sobre el rectángulo real del PNG sin deformarlo.
- La reproducción de clic está centralizada para evitar listeners y sonidos duplicados.

## [0.5.12]

### Added

- Soporte data-driven para que cada una de las cuatro respuestas pueda tener una réplica diferente, incluyendo secuencias de varias líneas.
- Bloques `after` para añadir pausas, remates, monólogos y pequeños diálogos después de una respuesta antes de continuar con la siguiente pregunta.
- Metadatos narrativos opcionales para identificar hablante, personajes visibles, foco, posiciones y líneas excluidas según el protagonista.

### Changed

- Reescrita la visita de Jony como una conversación más natural con situaciones sobre los favores para ir a la estación, la reforma de su casa con Ana, su postura sobre el uso de IA en la empresa y su tendencia a alargarse cuando domina un tema.
- Añadidos el humor seco y los juegos de palabras de Jony, junto con pausas y reacciones específicas para cada respuesta.
- Actualizados el resumen y los textos de entrada y despedida de Jony.
- Documentado el nuevo formato narrativo en `data/README.md` manteniendo compatibilidad con el esquema clásico `correct`/`wrong`.

## [0.5.11]

### Changed

- Sustituida la restauración de la posición mediante `seek` por continuidad real: al volver al menú la canción de la habitación sigue reproduciéndose silenciada y recupera su volumen al continuar la partida.

### Fixed

- El control de volumen específico de cada habitación respeta el silencio temporal del menú y no puede reactivar la música mientras este permanece visible.

## [0.5.10]

### Fixed

- Al volver desde una habitación al menú principal, la partida guarda la canción y su posición exacta para que **Continuar** reanude la reproducción desde ese punto en lugar de empezar desde el principio.

## [0.5.9]

### Changed

- Restaurado el fondo original de la habitación de Javi, incluido el contenido original de su monitor secundario.

### Removed

- Retirados la pantalla verde, el vídeo integrado, la homografía, los efectos de iluminación y toda su configuración y lógica asociadas.
- Eliminados del proyecto el archivo de vídeo y el respaldo temporal, que dejó de ser necesario tras restaurar el fondo.

## [0.5.8]

### Added

- Respaldo verificable del fondo original de la habitación de Javi previo a la edición de pantalla verde.

### Changed

- Sustituido exclusivamente el contenido del monitor secundario del fondo de Javi por verde puro `#00FF00`, conservando sin cambios todos los píxeles exteriores.
- El vídeo se proyecta directamente sobre la superficie verde y usa coordenadas normalizadas derivadas de los vértices exactos de la máscara en píxeles.
- Los respaldos quedan excluidos de la exportación del juego para no aumentar su tamaño.

### Fixed

- Alineadas las cuatro esquinas del vídeo con la misma máscara usada para preparar el fondo, evitando diferencias entre el área editada y la superficie proyectada.

## [0.5.7]
### Changed

- El vídeo de la habitación de Javi utiliza ahora una homografía calculada desde sus cuatro esquinas para reproducir la perspectiva real del plano.
- El fotograma completo se adapta al trapecio sin recortar los laterales; la deformación de perspectiva sustituye al anterior modo de relleno `cover`.

### Fixed

- Eliminado el recorte visual que afeaba la integración del vídeo en el monitor inclinado.

## [0.5.6]

### Changed

- El vídeo de la habitación de Javi rellena el trapecio completo marcado por el marco del monitor mediante un recorte centrado que conserva su proporción.
- Reducidos el brillo y la saturación del vídeo, con una gradación cálida, viñeta, líneas de pantalla y parpadeo casi imperceptibles para integrarlo con la estética nocturna de la habitación.
- Añadido un halo cálido y tenue alrededor del monitor para simular la luz que proyecta sobre el entorno.

### Fixed

- Reajustadas manualmente las cuatro esquinas del vídeo al contorno completo del monitor.

## [0.5.5]

### Changed

- La pantalla de vídeo de la habitación de Javi usa ahora cuatro esquinas normalizadas para seguir manualmente la perspectiva del monitor y mantener el encaje al cambiar de resolución.
- El fotograma 16:9 se muestra completo sobre una base negra, con bandas mínimas calculadas automáticamente en vez de deformarse o recortarse.

### Fixed

- Corregidos la inclinación, el encuadre y la cobertura del vídeo integrado en el monitor de Javi.

## [0.5.4]

### Added

- Carpeta `assets/generated/` como destino persistente de las imágenes generadas para el proyecto.
- Reproducción opcional de vídeos integrados en zonas concretas de los fondos de habitación mediante configuración JSON.
- Vídeo **La Leyenda del Hombre Gato** integrado, en bucle y sin audio, en el monitor de la habitación de Javi.
- Pruebas de carga, visibilidad, silencio, bucle y desactivación del vídeo al abandonar la habitación.

### Changed

- El flujo de generación copia sus resultados finales a `assets/generated/` con nombres descriptivos.
- El MP4 original se convierte a Ogg Theora de `320x180`, `20 FPS` y aproximadamente `1,7 MB` para reducir el coste de reproducción.
- La carpeta de variantes `assets/generated/` queda excluida de las exportaciones para no aumentar su tamaño.

## [0.5.3]

### Changed

- Sustituido el versionado de cuatro bloques por el formato `x.x.x`; la versión `0.5.2.2` pasa a ser `0.5.3`.
- Añadida al changelog y a `AGENTS.md` la norma persistente de incrementar la versión y mantener una traza con cada entrega de cambios.

### Fixed

- Ocultados el panel de diálogo y el HUD inferior mientras se muestra el selector de visitas; ambos reaparecen al comenzar una visita.

## [0.5.2]

### Added

- Metadatos de códice para habitaciones (`display_name`, `description` y `codex_visible`) dentro de los JSON de `data/rooms/`.
- Iconos SVG reales para la navegación anterior/siguiente de Extras.

### Changed

- La pantalla **Lugares** de Extras pasa a mostrar las habitaciones asociadas a personajes activos desde `DataManager`.
- Las habitaciones se presentan con imagen y descripción en una composición alterna izquierda/derecha en escritorio y apilada en pantallas estrechas.

### Fixed

- Sustituidas las flechas Unicode de `Volver`, `Anterior` y `Siguiente`, que podían mostrarse como caracteres extraños.
- Corregido el desbordamiento vertical de las fichas de personaje para mantener la navegación dentro de la pantalla.

## [0.5.1]

### Added

- `DataManager` centralizado como Autoload para acceder a los datos del juego.
- Datos estáticos offline separados en JSON para personajes, preguntas, habitaciones y configuración general.
- Guardado principal en `user://savegame.json` y preferencias en `user://settings.json`.
- Migración compatible desde los antiguos archivos locales de guardado/configuración sin eliminarlos.

### Changed

- Personajes, preguntas, puntuaciones, habitaciones, música, volúmenes y activación de personajes pasan a obtenerse mediante la nueva capa de datos.
- Los sistemas existentes conservan capas de compatibilidad para evitar reconstruir el juego o romper escenas y flujo actual.
- La exportación Web incluye explícitamente los archivos JSON necesarios para funcionar completamente offline.

## [0.5.0]

### Added

- Opción **Extras** en el menú principal.
- Códice de personajes con ficha individual, retrato y datos ampliados.
- Pantallas de **Información del juego**, **Lugares** y **Créditos**.
- Créditos del proyecto con Javi Díaz como creador, diseñador y programador.