# Changelog

Este archivo registra únicamente cambios realmente implementados en **Entre líneas**. Las ideas pendientes permanecen en [`IDEAS.md`](IDEAS.md) y las tareas previstas en [`ROADMAP.md`](ROADMAP.md).

## [Unreleased]

### Added

### Changed

### Fixed

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
