# Ideas y mejoras futuras

Este archivo reúne ideas para **Entre líneas** aunque todavía no tengan fecha ni prioridad definida.

Flujo de trabajo esperado:

```text
IDEA
  ↓
IDEAS.md
  ↓
Decidimos desarrollarla
  ↓
ROADMAP.md
  ↓
Se implementa
  ↓
CHANGELOG.md
```

Los errores conocidos se registran de forma independiente en [`KNOWN_ISSUES.md`](KNOWN_ISSUES.md).

> **Nota sobre el inventario inicial:** algunas ideas solicitadas al crear este documento ya estaban implementadas en el proyecto. Se conservan aquí marcadas con `[x]` para reflejar correctamente su estado inicial; las funcionalidades terminadas quedan registradas de forma definitiva en el changelog.

## Sistema de guardado

Los saves deben ser completamente locales, funcionar sin conexión a Internet y almacenarse bajo `user://`.

- [x] Sistema de partidas guardadas locales mediante un único `user://savegame.json`.
- [ ] Varias ranuras/slots de guardado.
- [ ] Pantalla de selección de partida.
- [x] Botón «Continuar» que carga la partida local existente; cuando haya slots deberá cargar la utilizada más recientemente.
- [ ] Nueva partida permitiendo seleccionar slot.
- [x] Cargar la partida local actual.
- [ ] Borrar partida.
- [x] Autoguardado durante el progreso.
- [ ] Importar/exportar partidas para poder llevar un save a otro ordenador.
- [ ] Posibilidad futura de mostrar información resumida de cada partida en la pantalla de carga.
- [ ] Posibilidad futura de mostrar una captura o imagen representativa de la partida.

## Datos del juego

La base de esta arquitectura ya fue materializada en la migración a DataManager/JSON. Se mantiene aquí como referencia del inventario inicial.

- [x] Migrar datos de personajes a JSON.
- [x] Migrar preguntas y respuestas a JSON.
- [x] Migrar puntuaciones de respuestas a datos configurables.
- [x] Migrar habitaciones a datos configurables.
- [x] Migrar música y volumen individual de cada habitación/personaje.
- [x] Crear un `DataManager` centralizado.
- [x] Intentar que añadir un personaje nuevo requiera el mínimo código posible.
- [x] Permitir activar/desactivar personajes mediante datos.
- [x] Separar completamente datos originales del juego y datos de la partida.

## Personajes

- [x] Permitir varias poses/expresiones por personaje mediante datos y assets.
- [x] Poder añadir personajes estándar principalmente mediante datos y assets.
- [ ] Valorar estados de ánimo o expresiones que evolucionen según respuestas y progreso.
- [ ] Ampliar el sistema de amistad y aprovecharlo para futuras mecánicas.

## Economía, monedas y compras

La base 0.6 ya incorpora una **moneda interna obtenible únicamente jugando**, sin conexión ni compras con dinero real, para adquirir objetos y extras dentro de la partida. Las ideas siguientes amplían esa base.

La economía debería premiar sobre todo **explorar, conocer a los personajes y descubrir contenido**, evitando convertir el juego en un sistema de grindeo.

### Cómo podría ganarse moneda

- [ ] Recompensa pequeña al completar por primera vez una visita o conversación.
- [ ] Recompensas por descubrir diálogos, eventos o escenas nuevas al volver a una habitación.
- [ ] Recompensas por completar encuentros especiales entre varios personajes.
- [ ] Bonificaciones por determinados hitos de amistad, sin obligar a escoger siempre una única respuesta «correcta».
- [ ] Pequeñas actividades o minijuegos opcionales integrados con los personajes.
- [ ] Objetivos o favores puntuales: llevar algo a alguien, encontrar un objeto, visitar una localización, ayudar en una situación, etc.
- [ ] Logros o hitos de exploración: visitar todas las habitaciones, encontrar escenas ocultas, completar determinadas combinaciones de encuentros, etc.
- [ ] Eventos especiales del mapa que puedan otorgar monedas u objetos.
- [ ] Valorar recompensas únicas vinculadas a recuerdos/anécdotas del grupo para incentivar descubrir contenido narrativo.

Las recompensas importantes deberían ser **de una sola vez** cuando correspondan a contenido único, para impedir que entrar y salir repetidamente de una habitación genere dinero infinito.

### En qué podrían gastarse

- [ ] Objetos decorativos para habitaciones.
- [ ] Ropa, poses, expresiones o variantes cosméticas de personajes cuando tenga sentido.
- [ ] Regalos para personajes que puedan desbloquear reacciones, diálogos o pequeñas escenas especiales.
- [ ] Música, galería, ilustraciones, recuerdos o contenido extra desbloqueable.
- [ ] Objetos coleccionables relacionados con los gustos y anécdotas de cada personaje.
- [ ] Mejoras puramente visuales del mapa o de la interfaz del jugador.
- [ ] Valorar objetos que permitan iniciar actividades o eventos concretos, evitando que la historia principal dependa de tener dinero.

### Skins y complementos visuales de personajes

La tienda podrá incluir **skins y complementos puramente visuales** que modifiquen la apariencia del personaje durante sus escenas dentro del juego.

- [ ] Las skins compradas/desbloqueadas deberán conservarse como progreso global y poder aplicarse al personaje correspondiente.
- [ ] El cambio visual se mostrará en la representación del personaje durante el gameplay y sus conversaciones; no es necesario replicarlo en el mapa, selectores u otros menús generales.
- [ ] Añadir en la pantalla de información de cada personaje una pestaña **Skins** con las apariencias conseguidas y una previsualización grande.
- [ ] Mantener las skins y sus assets configurables mediante datos para poder ampliar el catálogo sin lógica específica por cada variante.

Primeras propuestas de catálogo:

- **Fran / Smokey:** variaciones de sus camisas, manteniendo al personaje igual y cambiando principalmente el diseño/color de la camisa.
- **Carmen:** distintos colores de pelo, inspirados en que ha llevado el pelo teñido de varios colores; se podrán valorar también algunas variaciones de ropa.
- **Jony:** complementos visuales en forma de mascotas, por ejemplo distintos gatos que puedan aparecer junto a él.
- **Ana:** complementos visuales en forma de mascotas, por ejemplo distintos gatos que puedan aparecer junto a ella.
- **Javi:** skins pendientes de definir.
- **Sue:** skins pendientes de definir.
- **Argentino:** skins pendientes de definir.

El comportamiento exacto para elegir entre varias skins desbloqueadas podrá concretarse cuando se implemente el sistema; como mínimo deberán poder consultarse en la ficha del personaje y aplicarse visualmente en sus escenas.

### Base técnica implementada

- [x] Guardar el saldo dentro de la partida local (`state`) para que cada save pueda tener su propia economía.
- [x] Mantener los objetos, coleccionables y cosméticos comprados como desbloqueos globales persistentes separados del saldo de cada partida.
- [x] Definir catálogo, precios y recompensas mediante JSON para poder balancearlos sin tocar código.
- [x] Registrar recompensas únicas ya cobradas mediante identificadores para evitar duplicados.
- [x] Crear una pantalla de tienda/inventario integrada con una localización del mapa.
- [x] Mostrar el saldo de forma discreta en la interfaz de la tienda.

**Dirección recomendada:** empezar con una sola moneda y una economía sencilla. Primero recompensas por contenido narrativo + una tienda pequeña de extras; después añadir minijuegos, favores e inventario si realmente aportan al flujo del juego.

## Habitaciones y navegación

- [x] Mantener regulador individual del volumen de música de cada habitación.
- [x] Poder configurar fondo, canción y volumen de cada habitación mediante datos.

### ⭐ MAPA INTERACTIVO — implementado en 0.6.0

La evolución principal de navegación ya está implementada sobre el mapa de Naranjal del Río:

- [x] Localizaciones clicables con ratón y touch.
- [x] Casas/personajes y tienda descritos por datos y coordenadas normalizadas.
- [x] Estado visual visitado/pendiente y exclusión del protagonista.
- [x] Retorno al mapa después de cada conversación y elección libre de la siguiente visita.
- [x] Salida al menú sin dejar al jugador atrapado.
- [x] Conexiones a Triana y Monte del Toro mediante pantallas temporales reutilizables.
- [x] Compatibilidad responsive con ratón y controles táctiles.
- [x] Localización no residencial: tienda de coleccionables y cosméticos.
- [ ] Valorar localizaciones bloqueables/desbloqueables para historias futuras.
- [ ] Valorar eventos especiales visibles sobre el mapa.
- [ ] Valorar cambios ambientales o animaciones según avance la partida.

## Interfaz

- [ ] Mejorar visualmente la selección de personaje.
- [ ] Mejorar transiciones entre pantallas.
- [ ] Añadir transiciones entre mapa y habitación cuando exista el mapa.
- [ ] Valorar un indicador visual de amistad.
- [ ] Revisar interfaz para resoluciones pequeñas.
- [ ] Mantener buena compatibilidad móvil, web y táctil.
