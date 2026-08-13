# Datos offline de Entre líneas

Toda la información de esta carpeta forma parte del juego exportado y se lee desde `res://`. No necesita Internet ni una base de datos externa.

El acceso en tiempo de ejecución está centralizado en `DataManager` (`res://autoload/data_manager.gd`). Los demás sistemas no deberían abrir estos JSON directamente.

## Estructura

- `game_config.json`: orden de personajes, ajustes generales, música del menú, rutas de guardado y localizaciones globales.
- `characters/<id>.json`: identidad, estado habilitado, habitación, imagen/poses, música, volumen inicial, afinidad inicial y textos de transición.
- `questions/<id>.json`: presentación, preguntas, cuatro respuestas, posición izquierda/derecha, puntuación y diálogo de reacción.
- `rooms/<id>.json`: fondo, canción, volumen base, propietarios, nombre y descripción visual de la habitación.
- `world_maps.json`: localidades, fondo de mapa, residentes, marcadores normalizados, conexiones y excusas de mapas temporales.
- `economy.json`: moneda, intervalos del contador de actividad y reglas configurables de recompensas únicas/repetibles.
- `shop_catalog.json`: coleccionables y cosméticos, con nombre, descripción, categoría, precio, recurso opcional y estado `enabled`.
- `achievements.json`: logros globales y sus condiciones data-driven sobre estadísticas.
- `detalles-juego.json`: información ampliada usada por Extras/códice. `DataManager` la combina con los datos operativos de `characters/`.

La sección `menu` de `game_config.json` registra `menu.ogg`, su volumen bajo, el
fundido de entrada y el bucle. `AudioManager` inicia y detiene ese tema siguiendo
la visibilidad real de `MenuScreen`.

## Mapas y localidades

`world_maps.json` tiene un `default_zone_id` y un diccionario `zones`. Un mapa real declara `map_asset`; una zona sin arte definitivo usa `temporary: true` y el mismo renderer genérico. Cambiar Triana o Monte del Toro a un mapa real no requiere crear un flujo paralelo.

Las localizaciones sobre el PNG se colocan con coordenadas normalizadas entre 0 y 1:

```json
{
  "id": "home_sue",
  "type": "character",
  "character_id": "sue",
  "position": {"x": 0.53, "y": 0.34}
}
```

Los controles son independientes de la imagen y se recalculan dentro del rectángulo que conserva su proporción. `current_residence` y `current_zone_id` en cada ficha describen la residencia actual; los datos biográficos de procedencia se conservan aparte.

## Economía, tienda y logros

Las reglas de `economy.json` resuelven un evento a un identificador de recompensa. Por ejemplo, `character_visited` produce `first_visit_<character_id>` y +15 MONEDAS una sola vez por partida. El saldo y `claimed_rewards` viven en el save; los valores antiguos ausentes migran a saldo 0 y diccionario vacío.

La tienda solo admite las categorías `collectible` y `cosmetic`. Los precios se leen de `shop_catalog.json`; la historia principal no consulta compras ni introduce bloqueos narrativos. Los objetos comprados se escriben en el perfil global.

Cada logro de `achievements.json` declara una o varias condiciones `{metric, operator, value}`. Varias definiciones pueden leer la misma métrica sin necesitar una función GDScript por logro.

## Modificar un personaje

Edita `data/characters/<id>.json`. Los campos operativos principales son:

```json
{
  "id": "sue",
  "name": "Sue",
  "real_name": "Susana",
  "display_name": "Sue",
  "room": "room_sue",
  "image": "res://assets/characters/sue/sue_a.png",
  "music": "sue_fantasia",
  "music_volume": 1.0,
  "initial_friendship": 0,
  "enabled": true
}
```

`enabled: false` lo retira de la selección y del recorrido jugable sin borrar sus datos.

## Modificar preguntas y conversaciones

Edita `data/questions/<id>.json`. Cada personaje contiene `intro` y `questions`. Cada pregunta debe seguir teniendo exactamente cuatro respuestas, pero las reacciones ya no están limitadas a `correct` y `wrong`: cada respuesta puede apuntar a su propia clave de `feedback`.

El formato clásico continúa siendo válido:

```json
{
  "id": "q1",
  "text": "Pregunta...",
  "answers": [
    {"text": "Respuesta A", "side": "left", "score": 1, "feedback": "correct"},
    {"text": "Respuesta B", "side": "right", "score": 0, "feedback": "wrong"},
    {"text": "Respuesta C", "side": "left", "score": 0, "feedback": "wrong"},
    {"text": "Respuesta D", "side": "right", "score": 0, "feedback": "wrong"}
  ],
  "feedback": {
    "correct": {"text": "...", "expression": "happy"},
    "wrong": {"text": "...", "expression": "thoughtful"}
  }
}
```

También se puede dar una reacción diferente a cada opción y encadenar varias líneas:

```json
{
  "id": "q1",
  "text": "¿Qué haces?",
  "answers": [
    {"text": "Opción A", "side": "left", "score": 1, "feedback": "respuesta_a"},
    {"text": "Opción B", "side": "right", "score": 0, "feedback": "respuesta_b"},
    {"text": "Opción C", "side": "left", "score": 0, "feedback": "respuesta_c"},
    {"text": "Opción D", "side": "right", "score": 0, "feedback": "respuesta_d"}
  ],
  "feedback": {
    "respuesta_a": [
      {"speaker_id": "jony", "text": "Primera línea."},
      {"speaker": "Narrador", "speaker_id": "", "text": "Una pausa o acción narrativa."}
    ],
    "respuesta_b": {"speaker_id": "jony", "text": "Otra reacción."},
    "respuesta_c": {"speaker_id": "jony", "text": "Otra reacción."},
    "respuesta_d": {"speaker_id": "jony", "text": "Otra reacción."}
  },
  "after": [
    {"speaker_id": "jony", "text": "Este diálogo ocurre después de cualquiera de las cuatro respuestas."}
  ]
}
```

Las líneas de `intro`, `feedback` y `after` admiten metadatos narrativos opcionales:

- `speaker_id`: id del personaje que habla. Si se omite, habla el personaje visitado.
- `speaker`: nombre literal que se mostrará; sirve también para `Narrador`.
- `show`: personajes visibles en la escena.
- `positions`: posiciones de los personajes visibles (`left`, `center`, `right`).
- `focus`: personaje que recibe el foco visual o `all`.
- `expression`: pose/expresión del personaje que habla.
- `expressions`: cambios de expresión para varios personajes.
- `exclude_players`: protagonistas para los que esa línea se omite; útil para que un personaje no aparezca como NPC cuando lo controla el jugador.
- `include_players`: limita la línea a protagonistas concretos.
- `effect`: efecto narrativo compatible con el sistema de escenas.

`after` permite introducir pausas, remates, monólogos o pequeños diálogos comunes antes de pasar a la siguiente pregunta. La puntuación máxima se calcula a partir del mayor `score` disponible en cada pregunta, por lo que no está fijada a tres puntos de forma interna.

## Modificar una habitación o canción

Edita `data/rooms/<id>.json`:

```json
{
  "id": "room_sue",
  "display_name": "Habitación de Sue",
  "description": "Descripción visual que aparece en Extras > Lugares.",
  "codex_visible": true,
  "owners": ["sue"],
  "background_id": "habitacion_sue",
  "background_path": "res://assets/backgrounds/fondo-habitacion-sue.png",
  "music_id": "sue_fantasia",
  "music_path": "res://assets/audio/music/sue-fantasia.ogg",
  "music_volume": 1.0
}
```

`display_name` y `description` alimentan directamente la galería de **Extras > Lugares**. La galería muestra las habitaciones asociadas a personajes activos y con propietarios; `codex_visible: false` permite ocultar una habitación del códice sin desactivarla en el juego.

El volumen base también puede especificarse en el personaje con `music_volume`. Durante las pruebas, el regulador de la habitación crea una preferencia del usuario que se guarda en `user://settings.json`; los JSON originales de `res://` nunca se modifican.

## Añadir un personaje nuevo

Para un personaje estándar no debería ser necesario añadir lógica específica en GDScript:

1. Añade sus PNG/OGG y fondo en `assets/`.
2. Crea `data/characters/nuevo_id.json`.
3. Crea `data/questions/nuevo_id.json`.
4. Crea o reutiliza un archivo de `data/rooms/` y referencia su id con `room`.
5. Añade `nuevo_id` a `character_order` en `data/game_config.json` si quieres controlar su posición exacta; si no aparece allí, `DataManager` lo añade después de los ids configurados.
6. Opcionalmente añade su información ampliada a `data/detalles-juego.json` para el códice.

`main_data_driven.gd` crea automáticamente un slot visual para ids nuevos y Story genera introducciones, preguntas, reacciones y secuencias posteriores a partir de los datos.

## Datos del usuario

- Partida: `user://savegame.json`
- Preferencias: `user://settings.json`
- Perfil global: `user://profile.json`

La partida contiene el protagonista, nodo narrativo, afinidad, expresiones, historial, zona actual, MONEDAS y recompensas cobradas. El perfil global, independiente de cualquier partida, contiene desbloqueos, logros y estadísticas acumuladas. Las preferencias contienen audio, pantalla completa y el perfil de sonido de clic.

La primera ejecución de esta arquitectura intenta migrar automáticamente:

- `user://godot_otome_save.json`
- `user://audio_settings.cfg`
- `user://music_track_settings.cfg`

Los archivos antiguos no se borran durante la migración.
