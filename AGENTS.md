# Reglas del repositorio

## Versionado y traza de cambios

- El proyecto usa exclusivamente versiones de tres bloques (`x.x.x`).
- Cada entrega que modifique código, contenido o configuración debe incrementar `application/config/version` en `project.godot`. Si no se indica otro nivel, se incrementa el tercer bloque.
- La misma entrega debe añadir una sección para esa versión en `docs/CHANGELOG.md` y describir todos los cambios realizados.
- La actualización de versión y changelog forma parte obligatoria de la implementación, no es un paso opcional posterior.

## Imágenes generadas

- Las imágenes generadas para este proyecto deben copiarse a `assets/generated/` con un nombre descriptivo.
- Se conserva el archivo original creado por la herramienta y no se reemplazan recursos existentes salvo petición expresa del usuario.
