# Changelog

Este archivo registra únicamente cambios realmente implementados en **Entre líneas**. Las ideas pendientes permanecen en [`IDEAS.md`](IDEAS.md) y las tareas previstas en [`ROADMAP.md`](ROADMAP.md).

El proyecto utiliza versiones de tres bloques (`x.x.x`). Cada entrega que modifique el proyecto debe incrementar la versión y registrar aquí sus cambios.

## [Unreleased]

### Added

### Changed

### Fixed

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

- El vídeo del monitor de Javi utiliza ahora una homografía calculada desde sus cuatro esquinas para reproducir la perspectiva real del plano.
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
- La carpeta de variantes `assets/generated/` queda excluida de las exportaciones para no aumentar el tamaño del juego.

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
