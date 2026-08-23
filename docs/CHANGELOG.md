# Changelog

Este archivo registra únicamente cambios realmente implementados en **Entre líneas**. Las ideas pendientes permanecen en [`IDEAS.md`](IDEAS.md) y las tareas previstas en [`ROADMAP.md`](ROADMAP.md).

El proyecto utiliza versiones de tres bloques (`x.x.x`). Cada entrega que modifique el proyecto debe incrementar la versión y registrar aquí sus cambios.

El historial anterior a la rama 0.10 se conserva íntegro en [`CHANGELOG_ARCHIVE.md`](CHANGELOG_ARCHIVE.md).

## [Unreleased]

### Added

### Changed

### Fixed

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
