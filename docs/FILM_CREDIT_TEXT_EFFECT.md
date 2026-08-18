# Efecto reutilizable de créditos analógicos

El preset principal está en `data/film_credit_presets.json` con el nombre `subtle_35mm_titles`.

Para aplicarlo a cualquier `Label` o `CanvasItem` textual:

```gdscript
const FilmCreditTextEffect = preload("res://scripts/film_credit_text_effect.gd")

var effect := FilmCreditTextEffect.attach(mi_label, "subtle_35mm_titles")
```

La implementación separa dos capas:

- `assets/shaders/film_credit_35mm.gdshader`: grano, aberración cromática, soft focus, halation, flicker, color bleed, polvo, arañazos y variación de exposición.
- `scripts/film_credit_text_effect.gd`: gate weave/jitter, rotación y variación mínima de escala mediante objetivos pseudoaleatorios suavizados.

Todos los parámetros del preset son editables desde JSON y cada efecto visual puede activarse o desactivarse con su campo `*_enabled`. Los valores por defecto están deliberadamente bajos para mantener legibilidad y evitar cualquier apariencia VHS, glitch o vibración fuerte.
