# Roadmap

Este roadmap contiene únicamente mejoras que tenemos intención real de desarrollar. Puede reorganizarse conforme evolucione **Entre líneas** y no fija versiones ni fechas mientras no estén decididas.

La base de `DataManager`, los JSON de personajes/preguntas/habitaciones y el guardado local único con autoguardado ya están implementados, por lo que no se mantienen aquí como tareas pendientes.

## Próximas mejoras

### Sistema de guardado

- [ ] Diseñar soporte para varias ranuras/slots locales.
- [ ] Crear pantalla de selección y gestión de partidas.
- [ ] Permitir iniciar una nueva partida seleccionando slot.
- [ ] Permitir cargar un slot concreto.
- [ ] Permitir borrar un slot.
- [ ] Adaptar «Continuar» para cargar automáticamente el slot utilizado más recientemente.
- [ ] Añadir importación/exportación de saves para mover una partida entre equipos.

### Sistema de datos

- [ ] Reducir progresivamente el hardcode legacy que todavía permanece en scripts base como capa de compatibilidad.
- [ ] Seguir comprobando que añadir un personaje estándar mediante JSON + assets no requiera cambios específicos en el flujo principal.

### Interfaz y compatibilidad

- [ ] Revisar el escalado completo de la interfaz en resoluciones pequeñas y relaciones de aspecto distintas.
- [ ] Revisar experiencia táctil/móvil de las pantallas principales y Extras.
- [ ] Revisar comportamiento de pantalla completa en los entornos soportados.
- [ ] Mejorar visualmente la selección de personaje.
- [ ] Toda nueva pantalla o mecánica deberá diseñarse desde el principio para funcionar tanto en PC como en Android, incluyendo ratón, teclado y controles táctiles.

## Implementado en 0.6.0

### Prólogo e inicio narrativo

- [x] Crear una introducción breve antes de la selección de protagonista que sitúa la historia desde 2026.
- [x] Permitir continuar el prólogo mediante clic, toque o teclado con diseño adaptable a PC y Android.

### Mapa y progreso local

- [x] Evolucionar el selector de visitas al mapa visual de Naranjal del Río.
- [x] Definir casas, tienda y conexiones con coordenadas normalizadas en JSON.
- [x] Navegar `mapa → casa/habitación → conversación → mapa`.
- [x] Permitir salir de una conversación, visitar otra habitación y retomarla desde un checkpoint por personaje.
- [x] Representar estado visitado/no visitado sin ocultar revisitas.
- [x] Añadir Triana y Monte del Toro mediante una vista temporal sustituible por futuros PNG.
- [x] Separar MONEDAS/recompensas por partida de colección, logros y estadísticas globales.
- [x] Añadir tienda en el mapa y progreso global consultable desde Extras.
- [x] Centralizar sonidos de clic configurables en el sistema de audio existente.

## Más adelante

### Ampliaciones de economía, tienda y cosméticos

- [ ] Añadir fuentes repetibles pequeñas de monedas mediante favores, actividades o minijuegos opcionales.
- [ ] Ampliar el catálogo con decoraciones, extras y nuevas variantes cosméticas sin bloquear la historia principal.
- [ ] Aplicar durante el gameplay las skins adquiridas, manteniendo su consulta en las fichas de personaje.

#### Skins previstas para la tienda

- [ ] **Fran / Smokey:** variaciones de camisa.
- [ ] **Carmen:** distintos colores de pelo y posibilidad de algunas variantes de ropa.
- [ ] **Jony:** mascotas visuales, por ejemplo distintos gatos que aparezcan junto a él.
- [ ] **Ana:** mascotas visuales, por ejemplo distintos gatos que aparezcan junto a ella.
- [ ] **Javi, Sue y Argentino:** concepto pendiente de definir.
- [ ] Mostrar la skin durante las escenas del personaje dentro del gameplay; no es necesario reflejarla en mapa ni menús generales.
### Ampliaciones del mapa

- [ ] Incorporar mapas definitivos para Triana y Monte del Toro cuando existan sus assets.
- [ ] Valorar localizaciones bloqueables/desbloqueables según progreso futuro.
- [ ] Valorar eventos visuales y cambios ambientales del mapa según avance la historia.
- [ ] Permitir personajes visitantes y nuevas localizaciones según el progreso.
- [ ] Ampliar posteriormente el mundo con otras ciudades, viajes y localizaciones especiales.

### Personajes y amistad

- [ ] Ampliar el uso de la amistad para futuras mecánicas.
- [ ] Valorar estados de ánimo/expresiones persistentes según respuestas y progreso.
- [ ] Valorar un indicador visual de amistad en la interfaz.
