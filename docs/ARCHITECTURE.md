# Arquitectura de Entre líneas

Desde 0.10.0 el proyecto deja de usar la versión del juego como mecanismo de herencia para funciones nuevas.

## Puntos de entrada activos

- `scripts/main_current.gd`: coordinación de la escena principal, guardado especial, rutas y batalla de Javi.
- `autoload/data_manager_current.gd`: capa activa de datos, migraciones vigentes y overrides de diálogo.
- `scripts/new_game_manager.gd`: nueva partida y continuación con el jugador fijo `Invitado`.
- `scripts/visit_transition_manager.gd`: entradas, salidas, revisitas y preludio de Nueva partida.
- `data/dialogues/<personaje>/day_<n>.json`: diálogos revisados por personaje y jornada.

Los nombres de nodos históricos de `main.tscn` pueden mantenerse temporalmente como alias de compatibilidad mientras otros sistemas los busquen por nombre. El nombre del nodo no determina ya la versión del código que ejecuta.

## Regla de separación

Un cambio debe tocar el área mínima posible:

- Guion, preguntas, respuestas y feedback: `data/dialogues/`.
- Datos de personajes: `data/characters/`.
- Habitaciones: `data/rooms/`.
- Nueva partida/continuar: `new_game_manager.gd`.
- Entradas y salidas de habitaciones: `visit_transition_manager.gd`.
- Guardados/migraciones: DataManager y gestores de slots.
- Rutas narrativas: datos de rutas y su manager.
- UI: manager específico de la pantalla afectada.

No se crea una subclase nueva para distinguir una entrega. Si una función necesita cambiar, se modifica el módulo estable correspondiente y se registra la versión únicamente en `project.godot` y `docs/CHANGELOG.md`.

## Datos frente a lógica

El contenido que pueda representarse como datos debe permanecer fuera de GDScript. `DataManager` busca primero un override modular en `data/dialogues/<personaje>/day_<n>.json`; si no existe, usa el bundle general de `data/day_dialogues.json`.

Esto permite revisar una conversación frase por frase sin reconstruir la jerarquía runtime.

## Compatibilidad histórica

Los scripts antiguos se consideran legado. Se eliminan cuando ninguna escena, migración, prueba ni clase activa los referencia. Mientras sigan siendo necesarios, no reciben funcionalidades nuevas.

Las migraciones deben mantener compatibilidad de guardados, pero no deben dictar la estructura del runtime actual.

## Validación y producción

- `Validate Game`: importación de Godot, JSON, smoke tests críticos y export Web de prueba.
- `Deploy Godot Web`: solo se ejecuta sobre `main`, genera el artefacto y publica GitHub Pages sin hacer commits automáticos de la exportación.
- `main` solo recibe cambios después de validar la rama de trabajo.
