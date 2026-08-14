# Changelog

Este archivo registra únicamente cambios realmente implementados en **Entre líneas**. Las ideas pendientes permanecen en [`IDEAS.md`](IDEAS.md) y las tareas previstas en [`ROADMAP.md`](ROADMAP.md).

El proyecto utiliza versiones de tres bloques (`x.x.x`). Cada entrega que modifique el proyecto debe incrementar la versión y registrar aquí sus cambios.

## [Unreleased]

### Added

### Changed

### Fixed

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
- Las tarjetas de logros usan iconos, tipografías, márgenes y barras de progreso más compactos, manteniendo el scroll táctil y la legibilidad en móvil.

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
