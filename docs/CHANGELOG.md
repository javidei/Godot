# Changelog

Este archivo registra únicamente cambios realmente implementados en **Entre líneas**. Las ideas pendientes permanecen en [`IDEAS.md`](IDEAS.md) y las tareas previstas en [`ROADMAP.md`](ROADMAP.md).

El proyecto utiliza versiones de tres bloques (`x.x.x`). Cada entrega que modifique el proyecto debe incrementar la versión y registrar aquí sus cambios.

El historial anterior a la rama 0.10 se conserva íntegro en [`CHANGELOG_ARCHIVE.md`](CHANGELOG_ARCHIVE.md).

## [Unreleased]

### Added

### Changed

### Fixed

## [0.10.13] - 2026-08-24

### Added

- La Palanca II incorpora los espacios y fracturas espacio-temporales atravesados por Rojo durante el viaje hacia el túnel.
- El instante del láser se bifurca en dos líneas: Carmela rescata a una continuidad de Rojo mientras otra queda atrapada al otro lado de la grieta.
- La Palanca III conecta ambas líneas y convierte la palanca original en una posible llave para reunirlas o destruir una de ellas.

### Changed

- La Palanca I y II se narran íntegramente como sucesos reales dentro del mundo, sin referencias a cámaras, rodaje, películas, espectadores ni entregas audiovisuales.
- Todos los personajes del relato usan exclusivamente sus identidades ficticias: Negro, Rojo, Robot Ninja del Espacio, Carmela y Gaucho Saltarín.
- La presentación y el texto alternativo de «Una trilogía innecesaria» comparten el mismo canon temporal.

### Fixed

- Añadida una validación automática que impide reintroducir nombres reales o lenguaje externo a la ficción en el relato de La Palanca.

## [0.10.12] - 2026-08-24

### Fixed

- Corregido el desplazamiento táctil de **La Palanca III** en móvil: tarjetas, textos y elementos decorativos ya no interceptan el gesto vertical.
- Las páginas del cómic siguen abriéndose con un toque corto, pero permiten deslizar desde la propia imagen sin activar el visor.
- Añadida cobertura de regresión para validar el ScrollContainer y los filtros de entrada de la experiencia narrativa.

## [0.10.11] - 2026-08-24

### Added

- **Una trilogía innecesaria** se convierte en una experiencia dedicada de **La Palanca III**, con el logotipo del PDF como portada, cinco páginas de cómic integradas en orden y tarjetas narrativas diferenciadas.
- Las páginas del cómic se pueden pulsar para abrirlas a pantalla completa; el visor funciona con ratón y toque, conserva la proporción original y se cierra con su botón o con `Esc`.

### Changed

- La historia se reescribe a partir del canon documentado de **La Palanca I** y **La Palanca II**: la palanca activa al RNE a distancia, la investigación conduce al túnel, Negro huye y el final nunca confirma la muerte de Rojo.
- **La Palanca III** desarrolla el salto de quince años, el altar, el monje, su enseñanza, la llegada de Carmen y la reinterpretación del láser como una secuencia continua apoyada por las páginas originales.
- La presentación se carga desde datos estructurados independientes y adapta márgenes, tipografía e imágenes a escritorio y móvil sin modificar **Historia de un asesino**.

### Fixed

- Se eliminan interpretaciones anteriores no respaldadas por los cortos, incluida la apertura inventada de Rojo caminando solo con un mechero y la atribución a Charlie de información fuera de plano no establecida.
- La exportación web valida que el JSON, el logotipo y las cinco páginas de **La Palanca III** estén presentes en el PCK antes de publicar.
- La publicación forzada incorpora el smoke test de portada, capítulos, cómic, ampliación e independencia de **Historia de un asesino**, evitando saltarse la validación nueva cuando un test histórico ajeno bloquea el workflow general.
- El reintento de producción conserva el permiso ejecutable de `prepare_web_export.sh` al publicar mediante la API de GitHub.

## [0.10.10] - 2026-08-24

### Fixed

- El botón **Volver** del lector de historias utiliza el icono SVG de flecha izquierda en lugar del carácter Unicode que Monocraft mostraba como un cuadrado.
- Se fuerza una exportación web limpia de la 0.10.10 para evitar que una comprobación histórica desactualizada de Charlie mantenga publicada la compilación anterior.

## [0.10.9] - 2026-08-24

### Fixed

- El separador que precede a la atribución de las frases iniciales usa ahora un carácter incluido en Monocraft, evitando el cuadrado de glifo ausente que aparecía antes de textos como **Mensaje eliminado del grupo de WhatsApp**.

## [0.10.8] - 2026-08-24

### Changed

- El pie del menú principal muestra únicamente la nomenclatura `v0.10.8 · EARLY ACCESS`; desaparece el texto descriptivo adicional.
- La versión sale del bloque de botones y queda anclada en la esquina inferior izquierda de la pantalla, por lo que mantiene su posición al cambiar el tamaño de la ventana.

## [0.10.7] - 2026-08-24

### Changed

- **Personajes de la historia** vuelve a estar disponible dentro de **Ajustes**, junto a volumen, pantalla completa y partidas guardadas.
- La pantalla conserva la selección del reparto para la próxima partida y sigue arrancando por defecto con Javi y Fran/Smokey.

### Fixed

- Se recupera el acceso al selector que permite decidir qué personajes aparecen en el juego; **Extras → Personajes** continúa reservado para las fichas y cosméticos del grupo.
- La nueva partida mantiene al protagonista fijo como **Invitado**, sin reintroducir la selección de personaje jugable.

## [0.10.6] - 2026-08-24

### Changed

- El menú principal adopta la composición visual simplificada: **Nueva partida** y **Continuar partida** comparten la primera fila; las dos historias y **Extras** ocupan filas completas; **Ajustes** y **Salir** cierran el bloque inferior.
- **Pantalla completa** deja de ocupar el menú principal y pasa a **Ajustes**.
- El control real de **Volumen general** se mueve a **Ajustes**, conservando sus botones de bajar, subir y silenciar.
- **Partidas guardadas** se conserva accesible dentro de **Ajustes** para mantener la gestión de slots sin recargar el menú principal.
- Se elimina del menú principal el acceso redundante **Personajes de la historia**; las fichas de personajes siguen disponibles desde **Extras**.

### Fixed

- La reorganización reutiliza los botones y callbacks existentes de nueva partida, continuación, historias, Extras, guardados, audio y pantalla completa, evitando duplicar lógica de navegación o persistencia.

## [0.10.5] - 2026-08-24

### Fixed

- El lector de **Historia de un asesino** y **Una trilogía innecesaria** desactiva la selección del `RichTextLabel`, evitando que al arrastrar para hacer scroll en móvil se marque el texto.
- El gesto táctil sigue propagándose al `ScrollContainer`, por lo que se puede desplazar la historia empezando el arrastre directamente sobre cualquier párrafo.

## [0.10.4] - 2026-08-23

### Changed

- El menú principal deja de estar contenido en un `ScrollContainer`: todas las opciones vuelven a mostrarse de forma fija, sin barra ni desplazamiento.
- Las acciones se reorganizan en un orden más claro: **Nueva partida / Continuar**, las dos historias, utilidades (**Pantalla completa / Extras / Ajustes**), volumen, **Salir** y versión.
- Se reducen de forma moderada alturas, tipografías y separaciones del menú para mantener una composición limpia sin sacrificar legibilidad.

### Fixed

- **Salir** recupera una fila propia aunque alguna capa heredada lo hubiera dejado dentro de las utilidades.
- Los smoke tests históricos conservan la anchura de menú que esperan, mientras la versión actual gana algo de espacio horizontal para las nuevas opciones.

## [0.10.3] - 2026-08-23

### Changed

- El preset Web incluye explícitamente `data/stories/*.txt`, de modo que **Historia de un asesino** y **Una trilogía innecesaria** se empaquetan dentro de `index.pck` y pueden leerse en la versión publicada.

### Fixed

- El postprocesado de la exportación comprueba que ambos relatos existan, no estén vacíos y que sus nombres aparezcan dentro del paquete PCK; si falta cualquiera, la publicación falla en lugar de generar un lector sin texto.

## [0.10.2] - 2026-08-23

### Added

- La exportación Web genera el alias opaco `a7f3c9e2b6d4.html`, que carga exactamente la misma build que `index.html` sin redirección, por lo que la barra del navegador conserva la URL aleatoria.

### Changed

- El alias se recrea automáticamente en cada exportación Web para que no desaparezca al regenerar la carpeta `web`.

## [0.10.1] - 2026-08-23

### Added

- Nueva fila de historias en el menú principal con **Historia de un asesino** y **Una trilogía innecesaria**.
- Lector narrativo a pantalla completa con fondo negro, cabecera fija, botón **Volver**, lectura mediante scroll y adaptación a escritorio/móvil.
- `Historia de un asesino`: relato largo en catorce capítulos sobre un investigador externo al grupo que reconstruye el asesinato de Darío Luna, descubre que el sospechoso Elías Vela era su propio alias y termina afrontando que él mismo cometió el crimen antes de perder parte de su memoria.
- El misterio utiliza de forma diferenciada a los ocho miembros del grupo —Javi, Sue, Smokey/Fran, Carmen, Jony, Ana, el Argentino y Charlie— como testigos y piezas de la reconstrucción, con explicación explícita de la cinta, la amnesia, el silencio del grupo y el origen de la pista inicial.
- `Una trilogía innecesaria`: crónica corta de **La Palanca**, **La Palanca II** y el planteamiento actual de **La Palanca III**, incluyendo a Rojo/Fran, Negro/Javi, RNE/Jony, Charlie como cámara, el túnel, el salto de quince años, el monje y la reinterpretación del láser.
- La crónica de La Palanca reutiliza las tres apariencias ya existentes de Javi, Smokey y Jony como material visual, sin añadir un logo ficticio que no exista en los assets.

### Changed

- El bloque principal del menú queda alojado en un `ScrollContainer`, por lo que puede crecer con nuevas opciones sin cortar **Salir**, la versión ni los controles de audio en pantallas bajas.
- Las nuevas historias se cargan desde `data/story_library.json` y ficheros de texto independientes en `data/stories/`, dejando el contenido separado de la lógica de interfaz y preparado para futuras ampliaciones.

### Fixed

- La versión actual del misterio evita la contradicción de mostrar simultáneamente al protagonista y a la persona desaparecida como dos individuos distintos: Elías Vela es un alias previo del protagonista y Darío Luna es la víctima independiente del asesinato.

## [0.10.0] - 2026-08-23

### Changed

- Las nuevas partidas arrancan por defecto con **Javi** y **Smokey / Fran** como únicos personajes activos de la historia.
- El reparto predeterminado pasa a declararse en `data/game_config.json`, de modo que Sue, Carmen, Jony, Ana, el Argentino y Charlie siguen existiendo en datos, habitaciones y contenido, pero no aparecen en una run nueva salvo que se activen expresamente.
- El selector de reparto sigue permitiendo ampliar o cambiar manualmente los personajes antes de iniciar una partida.
- Los guardados que ya tenían un reparto explícito conservan su selección al continuar; el nuevo valor por defecto se aplica cuando una partida todavía no tiene roster propio.
- `DataManager` incorpora una nueva capa `data_manager_v104.gd` para aislar esta política sin eliminar la compatibilidad de las capas anteriores.
- Los smoke tests históricos de roster y guardado aceptan la rama `0.10.x`; el test de roster valida además que el arranque predeterminado sea Javi + Smokey.

## [0.9.42] - 2026-08-23

### Fixed

- Restauradas las constantes heredadas necesarias para compilar la cadena de transiciones sin recuperar el texto retirado de 2026.

## Historial anterior

Las entradas de **0.5.0 a 0.9.41** se mantienen sin modificaciones en [`CHANGELOG_ARCHIVE.md`](CHANGELOG_ARCHIVE.md).
