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

### Economía, monedas y compras

La primera versión deberá ser sencilla: una única moneda local por partida obtenida jugando.

- [ ] Añadir saldo de moneda al estado de la partida y al sistema de guardado.
- [ ] Definir recompensas mediante datos y registrar cuáles ya se han cobrado para evitar repetir recompensas únicas.
- [ ] Empezar premiando contenido narrativo: primeras visitas, escenas nuevas, eventos especiales e hitos de exploración.
- [ ] Diseñar un catálogo pequeño de objetos y extras comprables mediante JSON.
- [ ] Añadir inventario de objetos comprados o desbloqueados.
- [ ] Crear una primera interfaz de compra e inventario.
- [ ] Incorporar posteriormente favores, actividades y minijuegos opcionales como nuevas fuentes de moneda.
- [ ] Evitar que la historia principal dependa de tener monedas; la economía debe ampliar contenido, personalización y exploración.

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
