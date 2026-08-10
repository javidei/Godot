# Entre líneas: La octava silla

Novela visual en **Godot 4.7.1**, actualmente en **Early Access**, con Javi, Sue, Smokey, Carmen, Jony, Ana y El Argentino.

## Base actual

- Recursos gráficos locales: no depende de `raw.githubusercontent.com` para fondos o personajes.
- 3 fondos, 5 poses de cada protagonista y una pose inicial de cada personaje secundario.
- Poses seleccionables desde los datos del diálogo y posiciones `left`, `center` y `right`.
- Carga bajo demanda con caché acotada y precarga ligera de la siguiente escena.
- Composición de novela visual sin `ColorRect` ni placeholders detrás de los personajes.
- Foco sutil del personaje que habla, zoom, sacudida y onomatopeyas animadas.
- Interfaz para ratón/táctil y composición alternativa en orientación vertical.
- Guardado compatible en `user://godot_otome_save.json`.
- AudioManager con canales Music/SFX/UI. La demo genera tonos `strum`, `clonk` y UI sin usar audio externo.
- Recorrido individual por los siete personajes: solo aparece una persona cada vez, se presenta sin revelar las respuestas y plantea tres preguntas.
- Cuatro respuestas por pregunta en una cuadrícula táctil de dos columnas.
- Afinidad independiente de `0/3` por personaje y resumen final completo de `0/21` puntos.

## Recursos

```text
assets/
├── backgrounds/
├── characters/
│   ├── javi/
│   ├── sue/
│   ├── smokey/
│   ├── carmen/
│   ├── jony/
│   ├── ana/
│   └── argentino/
├── audio/
└── ui/fonts/
```

`scripts/asset_manager.gd` es el único catálogo de rutas de imágenes. Si más adelante se migra el almacenamiento a Supabase, el resto del motor no necesita conocer las rutas físicas.

Los PNG de personajes conservan su resolución original y transparencia. Los `TextureRect` usan filtrado lineal y `KEEP_ASPECT_CENTERED`: las imágenes grandes se reducen visualmente sin recomprimirlas ni sustituirlas por copias pequeñas. Para este rango de escala 2D no se fuerzan mipmaps, evitando crear copias innecesarias de la textura.

El título usa `DejaVuSerif-Bold.ttf`, incluido en el proyecto para conservar la misma tipografía narrativa en web, móvil y escritorio. Su licencia se encuentra junto al archivo de fuente.

## Diálogo

La versión Early Access `0.3.1` recorre a Javi, Sue, Smokey, Carmen, Jony, Ana y El Argentino de uno en uno. Cada encuentro contiene una presentación sin pistas directas, tres preguntas con cuatro opciones y una única respuesta correcta, además de una réplica inmediata del personaje. Los datos están centralizados en `scripts/story.gd` para poder sustituir preguntas o ampliar las presentaciones sin modificar la interfaz.

Una escena puede indicar recursos y composición sin crear escenas Godot nuevas:

```gdscript
{
    "background": "cafeteria",
    "positions": {"sue": "center"},
    "expressions": {"sue": "chocolate"},
    "effect": {"type": "shake", "text": "CLONK!", "sfx": "clonk"}
}
```

Los nombres de expresiones antiguos (`embarrassed`, `teasing`, `annoyed`, etc.) siguen mapeados para no romper partidas guardadas existentes.

## Audio

No se encontraron ficheros de audio válidos en el Godot actual ni en la demo HTML previa. Aquella demo generaba los tonos en el navegador; Godot replica ese comportamiento de forma procedural. `assets/audio/` queda preparado para música/SFX definitivos y `AudioManager` puede reproducir archivos registrados sin cambiar los datos del diálogo.

## Web y estabilidad

La exportación Web usa `export_presets.cfg`. El workflow de GitHub Actions mantiene la validación que impide publicar si aparecen `SCRIPT ERROR`, `Parse Error` o `Failed to load script`, y comprueba `index.html`, `index.wasm` e `index.pck` antes de guardar la build.

La versión jugable se sincroniza después en `javidei/cvitae/godot/`.
