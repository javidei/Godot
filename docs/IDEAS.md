# Ideas y mejoras futuras

Este archivo reúne únicamente propuestas para **Entre líneas** que todavía no están decididas ni planificadas.

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

Las funcionalidades terminadas no se conservan aquí. Las tareas que ya tenemos intención real de desarrollar están en [`ROADMAP.md`](ROADMAP.md) y los errores o revisiones técnicas conocidas en [`KNOWN_ISSUES.md`](KNOWN_ISSUES.md).

## Partidas y comodidad

El sistema de 10 slots, la pantalla de gestión, el borrado, la carga de cualquier slot, el resumen de progreso y «Continuar» sobre la partida más reciente ya forman parte de la versión 0.7.0.

- [ ] Valorar una captura o imagen representativa de cada partida dentro de la pantalla de slots.

## Progresión narrativa por días

La base data-driven de jornadas ya forma parte de la versión 0.8.0: días numerados, objetivos variables, transición de jornada, Diario, persistencia por slot y eventos de apertura. El Día 1 exige recorrer al grupo, el Día 2 reduce las visitas obligatorias y el Día 3 introduce el primer puzle narrativo.

Quedan como posibles ampliaciones:

- [ ] Permitir que determinados días arranquen directamente dentro de una habitación con una visita obligatoria y guionizada, no solo con un evento de apertura.
- [ ] Añadir variantes de diálogos, escenas y disponibilidad de localizaciones condicionadas por el día actual.
- [ ] Permitir objetivos diarios distintos de visitar personajes o resolver puzles: objetos, decisiones, afinidad o eventos de mapa.

## Puzles narrativos y minijuegos de pistas

La infraestructura base también está implementada en 0.8.0: pistas data-driven, destinos indirectos, adaptación al protagonista, fragmentos persistentes, Diario de pistas, introducción manual de la solución, reintentos y recompensa por resolver el evento especial.

Quedan como posibles ampliaciones:

- [ ] Crear puzles con símbolos, palabras, orden variable, objetos o combinaciones distintas de un código numérico.
- [ ] Añadir consecuencias narrativas más profundas al fallar o resolver un puzle de formas diferentes, sin convertirlos necesariamente en bloqueos de la historia principal.
- [ ] Permitir pistas opcionales, señuelos y rutas alternativas para llegar a una misma solución.

## Narrativa y personajes

- [ ] Valorar estados de ánimo o expresiones que evolucionen y persistan según respuestas, amistad y progreso.
- [ ] Valorar encuentros especiales entre varios personajes fuera de las visitas individuales.
- [ ] Valorar reacciones, diálogos o pequeñas escenas opcionales desbloqueadas por determinados hitos de amistad.

## Economía y contenido opcional

La base de MONEDAS, recompensas únicas, tienda, coleccionables y cosméticos ya está implementada. Las siguientes propuestas ampliarían el contenido, no la infraestructura básica.

- [ ] Pequeñas actividades o minijuegos opcionales integrados con personajes.
- [ ] Favores puntuales: llevar algo, encontrar un objeto, visitar una localización o ayudar en una situación.
- [ ] Regalos para personajes que puedan provocar reacciones, diálogos o escenas especiales.
- [ ] Objetos decorativos para habitaciones.
- [ ] Música, galería, ilustraciones, recuerdos y otros extras desbloqueables.
- [ ] Más coleccionables relacionados con gustos y anécdotas de los personajes.
- [ ] Recompensas por encuentros especiales, descubrimientos y determinados hitos de exploración.
- [ ] Eventos especiales del mapa que puedan otorgar monedas, objetos o contenido narrativo.
- [ ] Valorar objetos que permitan iniciar actividades o eventos concretos sin bloquear la historia principal.

La economía debe seguir premiando principalmente explorar y descubrir contenido, evitando convertir el juego en un sistema de grindeo.

## Mapa y mundo

- [ ] Valorar localizaciones bloqueables y desbloqueables según el progreso.
- [ ] Valorar eventos visibles sobre el mapa.
- [ ] Valorar cambios ambientales o animaciones del mapa según avance la historia.
- [ ] Valorar personajes visitantes en localizaciones distintas de su residencia habitual.
- [ ] Ampliar en el futuro el mundo con otras ciudades, viajes y localizaciones especiales cuando la historia lo necesite.

## Interfaz y presentación

- [ ] Valorar transiciones visuales más elaboradas entre algunas pantallas y escenas, más allá de los fundidos ya existentes.

Cuando una de estas propuestas deje de ser hipotética y decidamos desarrollarla, debe salir de este archivo y pasar al roadmap.
