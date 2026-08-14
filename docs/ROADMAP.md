# Roadmap

Este roadmap contiene únicamente mejoras que tenemos intención real de desarrollar. Las funciones terminadas se documentan en [`CHANGELOG.md`](CHANGELOG.md), las propuestas todavía no decididas en [`IDEAS.md`](IDEAS.md) y los problemas conocidos en [`KNOWN_ISSUES.md`](KNOWN_ISSUES.md).

La versión 0.7.0 ya incorpora 10 slots locales, pantalla de selección y gestión de partidas, creación/carga/borrado de slots, resúmenes de progreso, autoguardado y «Continuar» sobre la partida utilizada más recientemente. Esa base deja de considerarse trabajo pendiente.

## Próximas mejoras

### Partidas

- [ ] Añadir importación y exportación de partidas para poder mover un slot entre equipos.

### Interfaz

- [ ] Mejorar visualmente la pantalla de selección de protagonista manteniendo compatibilidad con ratón, teclado y controles táctiles.

### Arquitectura de datos

- [ ] Reducir progresivamente el hardcode legacy que todavía permanece como capa de compatibilidad en algunos scripts base.
- [ ] Eliminar dependencias específicas restantes para que añadir un personaje estándar mediante JSON + assets no requiera cambios en el flujo principal.

## Siguiente fase

### Cosméticos

- [ ] Permitir elegir qué skin o complemento desbloqueado está equipado para cada personaje.
- [ ] Aplicar las skins y complementos seleccionados durante el gameplay y las conversaciones; no es necesario reflejarlos en mapa ni menús generales.
- [ ] **Fran / Smokey:** preparar variaciones de camisa.
- [ ] **Carmen:** preparar distintos colores de pelo y valorar algunas variantes de ropa.
- [ ] **Jony:** preparar mascotas visuales, por ejemplo distintos gatos que aparezcan junto a él.
- [ ] **Ana:** preparar mascotas visuales, por ejemplo distintos gatos que aparezcan junto a ella.
- [ ] **Javi, Sue y Argentino:** definir primero el concepto de sus cosméticos.

### Mapas

- [ ] Incorporar mapas definitivos para Triana y Monte del Toro cuando existan sus assets.
- [ ] Preparar el sistema para nuevas localizaciones y personajes visitantes cuando el progreso narrativo empiece a necesitarlos.

### Personajes y amistad

- [ ] Ampliar el uso de la amistad para que tenga consecuencias en futuras mecánicas y contenido opcional.
- [ ] Incorporar estados de ánimo o expresiones persistentes cuando se defina cómo afectan las respuestas y el progreso.
- [ ] Añadir un indicador visual de amistad cuando encaje con la interfaz definitiva.

### Economía y contenido

- [ ] Añadir fuentes repetibles pequeñas de MONEDAS mediante favores, actividades o minijuegos opcionales.
- [ ] Ampliar el catálogo con decoraciones, extras y nuevas variantes cosméticas sin bloquear la historia principal.
