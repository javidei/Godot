# Datos offline de Entre líneas

Toda la información de esta carpeta forma parte del juego exportado y se lee desde `res://`. No necesita Internet ni una base de datos externa.

El acceso en tiempo de ejecución está centralizado en `DataManager` (`res://autoload/data_manager.gd`). Los demás sistemas no deberían abrir estos JSON directamente.

## Estructura

- `game_config.json`: orden de personajes, ajustes generales, rutas de guardado y localizaciones globales.
- `characters/<id>.json`: identidad, estado habilitado, habitación, imagen/poses, música, volumen inicial, afinidad inicial y textos de transición.
- `questions/<id>.json`: presentación, preguntas, cuatro respuestas, posición izquierda/derecha, puntuación y feedback.
- `rooms/<id>.json`: fondo, canción, volumen base, propietarios, nombre y descripción visual de la habitación.
- `detalles-juego.json`: información ampliada usada por Extras/códice. `DataManager` la combina con los datos operativos de `characters/`.

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

## Modificar preguntas

Edita `data/questions/<id>.json`. Cada personaje contiene `intro` y `questions`. Cada pregunta debe tener cuatro respuestas:

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

La puntuación máxima ya no está fijada a 3 en el nuevo resumen: se calcula a partir de los valores `score` de los JSON.

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
  "screen_video": {
    "path": "res://assets/video/video-pantalla.ogv",
    "quad": [[0.15, 0.38], [0.27, 0.38], [0.27, 0.51], [0.15, 0.51]],
    "source_size": [320, 180],
    "fit_mode": "perspective",
    "brightness": 0.58,
    "saturation": 0.72,
    "warmth": 0.16,
    "vignette": 0.22,
    "scanlines": 0.025,
    "glow": 0.07,
    "loop": true,
    "muted": true
  },
  "music_id": "sue_fantasia",
  "music_path": "res://assets/audio/music/sue-fantasia.ogg",
  "music_volume": 1.0
}
```

`display_name` y `description` alimentan directamente la galería de **Extras > Lugares**. La galería muestra las habitaciones asociadas a personajes activos y con propietarios; `codex_visible: false` permite ocultar una habitación del códice sin desactivarla en el juego.

`screen_video` es opcional. `path` debe apuntar a un vídeo Ogg Theora (`.ogv`) y `quad` define las cuatro esquinas de la pantalla —superior izquierda, superior derecha, inferior derecha e inferior izquierda— normalizadas respecto al fondo. `source_size` conserva la proporción de origen y `fit_mode` permite proyectar el fotograma completo sobre el plano del monitor (`perspective`), rellenarlo con un recorte centrado (`cover`) o mostrarlo completo con bandas (`contain`). `brightness`, `saturation`, `warmth`, `vignette`, `scanlines` y `glow` integran visualmente la emisión del monitor con la habitación. La superficie se adapta al recorte de `STRETCH_KEEP_ASPECT_COVERED`, se activa solo en esa habitación y respeta `loop` y `muted`.

El volumen base también puede especificarse en el personaje con `music_volume`. Durante las pruebas, el regulador de la habitación crea una preferencia del usuario que se guarda en `user://settings.json`; los JSON originales de `res://` nunca se modifican.

## Añadir un personaje nuevo

Para un personaje estándar no debería ser necesario añadir lógica específica en GDScript:

1. Añade sus PNG/OGG y fondo en `assets/`.
2. Crea `data/characters/nuevo_id.json`.
3. Crea `data/questions/nuevo_id.json`.
4. Crea o reutiliza un archivo de `data/rooms/` y referencia su id con `room`.
5. Añade `nuevo_id` a `character_order` en `data/game_config.json` si quieres controlar su posición exacta; si no aparece allí, `DataManager` lo añade después de los ids configurados.
6. Opcionalmente añade su información ampliada a `data/detalles-juego.json` para el códice.

`main_data_driven.gd` crea automáticamente un slot visual para ids nuevos y Story genera introducciones, preguntas y nodos de feedback a partir de los datos.

## Datos del usuario

- Partida: `user://savegame.json`
- Preferencias: `user://settings.json`

La primera ejecución de esta arquitectura intenta migrar automáticamente:

- `user://godot_otome_save.json`
- `user://audio_settings.cfg`
- `user://music_track_settings.cfg`

Los archivos antiguos no se borran durante la migración.
