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

### Prólogo e inicio narrativo

Antes de comenzar una nueva partida deberá mostrarse una introducción breve de tono narrativo que sitúe temporalmente la historia.

- [ ] Crear una pantalla/secuencia de prólogo antes de la selección o inicio efectivo de la partida.
- [ ] Usar como punto de partida el texto/idea: **«Los hechos acontecieron desde 2026...»**, pendiente de redactar su versión narrativa definitiva.
- [ ] Permitir continuar el prólogo mediante clic, toque o teclado.
- [ ] Mantener el prólogo adaptable a PC y Android.
- [ ] Valorar animaciones o transiciones suaves de texto sin ralentizar excesivamente el inicio de nuevas partidas.

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
- [ ] Situar la tienda como una localización del futuro mapa, en lugar de añadirla como botón independiente del menú principal.
- [ ] Incorporar posteriormente favores, actividades y minijuegos opcionales como nuevas fuentes de moneda.
- [ ] Evitar que la historia principal dependa de tener monedas; la economía debe ampliar contenido, personalización y exploración.

### Logros y estadísticas del jugador

Crear un sistema local de progreso que registre acciones del jugador y permita desbloquear logros automáticamente a partir de estadísticas acumuladas.

Los **logros, estadísticas, coleccionables y cosméticos serán globales al juego** y persistirán entre partidas. Las **monedas, afinidad y progreso narrativo serán propios de cada partida**.

- [ ] Crear un perfil global persistente separado de las partidas guardadas.
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

El mapa será una evolución completa del actual selector de visitas y deberá convertirse en una **zona de mapa real e interactiva**, no en una simple colección de botones con fondos de habitaciones. Su desarrollo deberá permitir mantener funcional el flujo actual durante la transición.

#### Geografía narrativa

El mundo utilizará localizaciones ficticias inspiradas en lugares reales, evitando mostrar literalmente los nombres reales dentro de la historia.

- [ ] Crear el **pueblo principal ficticio**, inspirado geográficamente en Palma del Río, como núcleo del mapa donde vive la mayor parte del grupo.
- [ ] El nombre del pueblo principal deberá evocar elementos reconocibles de su inspiración, especialmente **las naranjas** y, de forma secundaria, referencias rurales como las ovejas.
- [ ] Crear una **ciudad ficticia inspirada en Sevilla**, donde viven actualmente Jony y Ana.
- [ ] Crear un **municipio ficticio inspirado en Montoro**, donde vive Carmen.
- [ ] Mantener relaciones de distancia y desplazamiento narrativamente coherentes entre las tres zonas sin necesidad de reproducir kilómetros o cartografía real de forma exacta.
- [ ] Permitir ampliar posteriormente el mundo con otras ciudades, viajes y localizaciones especiales.

#### Navegación

- [ ] Diseñar el concepto visual del mapa principal.
- [ ] Definir las localizaciones iniciales dentro del pueblo principal.
- [ ] Diseñar la navegación `mapa → casa/habitación`.
- [ ] Representar estado visitado/no visitado.
- [ ] Volver al mapa después de finalizar la visita de cada personaje.
- [ ] Permitir regresar a una habitación ya visitada para descubrir nuevas escenas, personajes visitantes o eventos según el progreso.
- [ ] Permitir que personajes puedan aparecer temporalmente en habitaciones/localizaciones de otros personajes.
- [ ] Mantener elección libre del siguiente destino.
- [ ] Permitir abandonar las visitas y regresar al menú.
- [ ] Preparar el sistema para localizaciones bloqueables/desbloqueables.
- [ ] Incluir localizaciones funcionales que no sean viviendas, empezando por la futura tienda.
- [ ] Diseñar el mapa, zonas clicables y controles para funcionar correctamente con ratón en PC y mediante toque en Android.
- [ ] Evitar objetivos clicables demasiado pequeños y contemplar layouts distintos para horizontal y vertical.

### Personajes y amistad

- [ ] Ampliar el uso de la amistad para futuras mecánicas.
- [ ] Valorar estados de ánimo/expresiones persistentes según respuestas y progreso.
- [ ] Valorar un indicador visual de amistad en la interfaz.
