# Changelog

Este archivo registra únicamente cambios realmente implementados en **Entre líneas**. Las ideas pendientes permanecen en [`IDEAS.md`](IDEAS.md) y las tareas previstas en [`ROADMAP.md`](ROADMAP.md).

El proyecto utiliza versiones de tres bloques (`x.x.x`). Cada entrega que modifique el proyecto debe incrementar la versión y registrar aquí sus cambios.

El historial anterior a la rama 0.10 se conserva íntegro en [`CHANGELOG_ARCHIVE.md`](CHANGELOG_ARCHIVE.md).

## [Unreleased]

### Added

### Changed

### Fixed

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
