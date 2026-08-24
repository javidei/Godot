# Changelog

Este archivo registra únicamente cambios realmente implementados en **Entre líneas**. Las ideas pendientes permanecen en [`IDEAS.md`](IDEAS.md) y las tareas previstas en [`ROADMAP.md`](ROADMAP.md).

El proyecto utiliza versiones de tres bloques (`x.x.x`). Cada entrega que modifique el proyecto debe incrementar la versión y registrar aquí sus cambios.

El historial anterior a la rama 0.10 se conserva íntegro en [`CHANGELOG_ARCHIVE.md`](CHANGELOG_ARCHIVE.md).

## [Unreleased]

### Added

### Changed

### Fixed

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