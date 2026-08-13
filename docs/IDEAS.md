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

Se quiere incorporar una **moneda interna obtenible únicamente jugando**, sin conexión ni compras con dinero real, para poder adquirir objetos y extras dentro de la partida.

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

### Propuesta técnica inicial

- [ ] Guardar el saldo dentro de la partida local (`state`) para que cada save pueda tener su propia economía.
- [ ] Crear un inventario local con identificadores de objetos comprados/desbloqueados.
- [ ] Definir catálogo, precios y recompensas mediante JSON para poder balancearlos sin tocar código.
- [ ] Registrar recompensas únicas ya cobradas mediante identificadores para evitar duplicados.
- [ ] Crear más adelante una pantalla de tienda/inventario integrada con el mapa o con alguna localización/personaje.
- [ ] Mostrar el saldo de forma discreta en la interfaz cuando exista una mecánica que permita gastarlo.

**Dirección recomendada:** empezar con una sola moneda y una economía sencilla. Primero recompensas por contenido narrativo + una tienda pequeña de extras; después añadir minijuegos, favores e inventario si realmente aportan al flujo del juego.

## Habitaciones y navegación

- [x] Mantener regulador individual del volumen de música de cada habitación.
- [x] Poder configurar fondo, canción y volumen de cada habitación mediante datos.

### ⭐ MAPA INTERACTIVO — evolución principal de navegación

Esta es una de las mejoras de navegación más importantes previstas a largo plazo.

Actualmente el flujo se basa principalmente en elegir a quién visitar y entrar en la habitación correspondiente. La intención es evolucionarlo hacia una **pantalla de mapa visual e interactiva** desde la que el jugador pueda decidir dónde ir.

Ejemplo puramente conceptual:

```text
                         MAPA

        [ Casa de Sue ]        [ Casa Smokey ]

              [ Casa Jony ]      [ Tu casa ]

        [ Casa Carmen ]        [ Casa Ana ]

              [ Casa Argentino ]

                         [ SALIR ]
```

La distribución final no tiene por qué parecerse a este esquema. El mapa deberá integrarse visualmente con el estilo gráfico de **Entre líneas**.

Características a estudiar:

- [ ] Localizaciones clicables.
- [ ] Mostrar qué personaje vive en cada ubicación.
- [ ] Entrar en la casa/habitación seleccionando su localización.
- [ ] Indicar visualmente personajes ya visitados.
- [ ] Indicar personajes pendientes.
- [ ] Poder volver al mapa después de terminar las preguntas de un personaje.
- [ ] Elegir libremente a quién visitar después.
- [ ] Posibilidad de abandonar las visitas y volver al menú.
- [ ] Poder bloquear/desbloquear localizaciones según progreso en el futuro.
- [ ] Posibles localizaciones que no pertenezcan a un personaje.
- [ ] Eventos especiales que puedan aparecer en determinadas zonas del mapa.
- [ ] Cambios visuales del mapa según avance la partida.
- [ ] Valorar animaciones sencillas al desplazarse o seleccionar una ubicación.
- [ ] Mantener el sistema compatible con ratón y pantallas táctiles.

Evolución conceptual del flujo:

```text
ACTUAL / BASE

Seleccionar personaje jugador
        ↓
Seleccionar visita
        ↓
Habitación
        ↓
Conversación + preguntas
        ↓
Seleccionar siguiente visita
```

```text
OBJETIVO FUTURO

Seleccionar personaje jugador
        ↓
MAPA
        ↓
Elegir destino
        ↓
Casa / habitación del personaje
        ↓
Conversación + preguntas
        ↓
MAPA
        ↓
Elegir siguiente destino
```

**No implementar todavía el mapa únicamente por estar documentado aquí.** Debe pasar primero al roadmap cuando se decida comenzar su desarrollo y la migración deberá conservar el flujo actual mientras se construye.

## Interfaz

- [ ] Mejorar visualmente la selección de personaje.
- [ ] Mejorar transiciones entre pantallas.
- [ ] Añadir transiciones entre mapa y habitación cuando exista el mapa.
- [ ] Valorar un indicador visual de amistad.
- [ ] Revisar interfaz para resoluciones pequeñas.
- [ ] Mantener buena compatibilidad móvil, web y táctil.
