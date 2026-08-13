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

La primera versión deberá ser sencilla: una única moneda llamada **Monedas**, representada mediante un icono de moneda. El saldo será propio de cada partida, mientras que los coleccionables, extras y cosméticos comprados serán desbloqueos globales que se conservarán al empezar partidas nuevas.

- [ ] Añadir saldo de monedas al estado de cada partida y al sistema de guardado.
- [ ] Mantener desbloqueos globales en un perfil persistente separado del save.
- [ ] Definir recompensas mediante datos y registrar cuáles ya se han cobrado para evitar repetir recompensas únicas.
- [ ] Empezar premiando contenido narrativo: primeras visitas, escenas nuevas, eventos especiales e hitos de exploración.
- [ ] Añadir una fuente repetible sencilla de pocas monedas para evitar bloqueos económicos, con recompensa mucho menor que el contenido nuevo.
- [ ] Diseñar un catálogo pequeño de coleccionables, extras, decoraciones y cosméticos mediante JSON.
- [ ] Añadir inventario global de objetos comprados o desbloqueados.
- [ ] Crear una primera interfaz de compra e inventario.
- [ ] Incorporar posteriormente favores, actividades y minijuegos opcionales como nuevas fuentes de moneda.
- [ ] Evitar que la historia principal dependa de tener monedas; la economía debe ampliar contenido, personalización y exploración.

### Logros y estadísticas del jugador

Crear un sistema local de progreso que registre acciones del jugador y permita desbloquear logros automáticamente a partir de estadísticas acumuladas.

- [ ] Crear un registro persistente de estadísticas del jugador.
- [ ] Contabilizar tiempo jugado evitando, cuando sea posible, sumar periodos largos con la pestaña/aplicación inactiva.
- [ ] Registrar sesiones iniciadas y formato/plataforma utilizada, por ejemplo escritorio/PC y móvil/táctil cuando pueda detectarse de forma fiable.
- [ ] Registrar visitas por personaje y por habitación/localización.
- [ ] Registrar protagonistas utilizados y número de partidas con cada personaje.
- [ ] Registrar conversaciones, decisiones, escenas/eventos únicos, monedas ganadas/gastadas y desbloqueos obtenidos.
- [ ] Crear una pantalla de «Cosas que ha hecho el jugador» con estadísticas y curiosidades como personaje más visitado o ubicación favorita.
- [ ] Crear logros por tiempo jugado, visitas, exploración, coleccionables, economía y otros hitos.
- [ ] Mostrar una notificación al desbloquear un logro.
- [ ] Crear una pantalla de logros con desbloqueados, pendientes y posibilidad de logros secretos.
- [ ] Definir logros y umbrales mediante JSON para poder ampliarlos sin añadir lógica específica por cada logro.
- [ ] Permitir que una misma estadística alimente varios logros, por ejemplo horas jugadas o número de visitas a un personaje.

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
