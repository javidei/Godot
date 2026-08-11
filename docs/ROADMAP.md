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

## Más adelante

### Mapa interactivo

El mapa será una evolución del actual selector de visitas, no una reescritura inmediata del juego. Su desarrollo deberá permitir mantener funcional el flujo actual durante la transición.

- [ ] Diseñar el concepto visual del mapa.
- [ ] Definir las localizaciones iniciales.
- [ ] Diseñar la navegación `mapa → casa/habitación`.
- [ ] Representar estado visitado/no visitado.
- [ ] Volver al mapa después de finalizar la visita de cada personaje.
- [ ] Mantener elección libre del siguiente destino.
- [ ] Permitir abandonar las visitas y regresar al menú.
- [ ] Preparar el sistema para localizaciones bloqueables/desbloqueables.

### Personajes y amistad

- [ ] Ampliar el uso de la amistad para futuras mecánicas.
- [ ] Valorar estados de ánimo/expresiones persistentes según respuestas y progreso.
- [ ] Valorar un indicador visual de amistad en la interfaz.
