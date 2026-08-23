# Reglas del repositorio

## Versionado y traza de cambios

- El proyecto usa exclusivamente versiones de tres bloques (`x.x.x`).
- Cada entrega que modifique código, contenido o configuración debe incrementar `application/config/version` en `project.godot`. Si no se indica otro nivel, se incrementa el tercer bloque.
- La misma entrega debe añadir una sección para esa versión en `docs/CHANGELOG.md` y describir todos los cambios realizados.
- La actualización de versión y changelog forma parte obligatoria de la implementación, no es un paso opcional posterior.

## Arquitectura desde 0.10.0

- No crear nuevos scripts runtime con nombres `version_*`, `main_v*` ni `data_manager_v*`. Las versiones pertenecen al changelog, no a la jerarquía de clases.
- Los puntos de entrada activos deben tener nombres estables (`main_current.gd`, `data_manager_current.gd`, `new_game_manager.gd`, `visit_transition_manager.gd`, etc.).
- Los scripts históricos solo se conservan mientras una compatibilidad, migración o prueba vigente los necesite. No se deben extender para implementar funciones nuevas.
- Los cambios de texto y contenido deben ir en `data/` siempre que no requieran lógica. Los diálogos revisados se separan por personaje y jornada en `data/dialogues/<personaje>/day_<n>.json`.
- Una modificación de guion no debe crear una nueva clase GDScript ni una capa de herencia.
- `main` representa producción. Los refactors o cambios amplios se validan primero en una rama y pasan por importación de Godot, smoke tests y export Web antes de fusionarse.
- Los workflows de despliegue no deben modificar ni hacer commits automáticos de código fuente en `main`.

## Imágenes generadas

- Las imágenes generadas para este proyecto deben copiarse a `assets/generated/` con un nombre descriptivo.
- Se conserva el archivo original creado por la herramienta y no se reemplazan recursos existentes salvo petición expresa del usuario.
