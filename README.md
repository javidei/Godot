# Entre líneas

Novela visual en **Godot 4.7.1**, actualmente en **Early Access**, con Javi, Sue, Smokey, Carmen, Jony, Ana y El Argentino.

El subtítulo se calcula automáticamente con el número de personajes más una silla: los siete personajes actuales producen **«La octava silla»** y trece producirían **«La decimocuarta silla»**.

## Base actual

- Recursos gráficos locales: no depende de `raw.githubusercontent.com` para fondos o personajes.
- 8 fondos, 5 poses de cada protagonista y una pose inicial de cada personaje secundario.
- Poses seleccionables desde los datos del diálogo y posiciones `left`, `center` y `right`.
- Carga bajo demanda con caché acotada y precarga ligera de la siguiente escena.
- Composición de novela visual sin `ColorRect` ni placeholders detrás de los personajes.
- Foco sutil del personaje que habla, zoom, sacudida y onomatopeyas animadas.
- Interfaz para ratón/táctil y composición alternativa en orientación vertical.
- Guardado compatible en `user://godot_otome_save.json`.
- AudioManager con canales Music/SFX/UI, volumen general persistente, silencio y música en bucle asociada automáticamente a cada fondo.
- La nueva partida empieza eligiendo protagonista, sin una selección de escenario intermedia.
- Recorrido individual por el resto del grupo: el personaje elegido representa al jugador y no aparece como encuentro.
- Cuatro respuestas por pregunta en una cuadrícula táctil de dos columnas.
- Afinidad independiente de `0/3` por personaje y resumen final de `0/18` puntos al elegir a alguien del grupo (`0/21` con un personaje personalizado).

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

La versión Early Access `0.3.7` permite elegir a Javi, Sue, Smokey, Carmen, Jony, Ana o El Argentino como protagonista. La persona elegida representa al jugador, queda fuera de la historia y el recorrido se adapta a los otros seis; si se crea un personaje nuevo, aparecen los siete. Cada encuentro contiene una presentación sin pistas directas, tres preguntas con cuatro opciones y una única respuesta correcta, además de una réplica inmediata. Ya no se elige escenario al comenzar: cada personaje carga directamente su fondo asociado. Javi, Sue, Jony, Ana y El Argentino usan sus habitaciones; Smokey y Carmen comparten la habitación de Fran. La pantalla principal conserva Casa Asturias. Los datos están centralizados en `scripts/story.gd` para poder sustituir preguntas o ampliar las presentaciones sin modificar la interfaz.

Una escena puede indicar recursos y composición sin crear escenas Godot nuevas:

```gdscript
{
    "background": "habitacion_fran",
    "positions": {"smokey": "center"},
    "expressions": {"smokey": "vaping"},
    "effect": {"type": "shake", "text": "CLONK!", "sfx": "clonk"}
}
```

Los nombres de expresiones antiguos (`embarrassed`, `teasing`, `annoyed`, etc.) siguen mapeados para no romper partidas guardadas existentes.

## Audio

El menú permite bajar o subir el volumen general en pasos del 10 % y silenciar o volver a activar todo el sonido. Ambas preferencias se guardan en `user://audio_settings.cfg`, por lo que se conservan al volver a abrir el juego.

Cada uno de los nueve fondos registrados tiene un tema musical asignado en `scripts/audio_manager.gd`. Al cambiar el fondo, el tema correspondiente se carga una vez y continúa en bucle. Las rutas están preparadas para ficheros OGG dentro de `assets/audio/music/`; mientras un fichero no exista, el juego continúa en silencio sin errores. La guía y los nombres esperados están en `assets/audio/README.md`.

Los tonos `strum`, `clonk` y la confirmación de interfaz continúan generándose de forma procedural y no incorporan audio externo ni material con copyright.

## Web y estabilidad

La exportación Web usa `export_presets.cfg`. El workflow de GitHub Actions mantiene la validación que impide publicar si aparecen `SCRIPT ERROR`, `Parse Error` o `Failed to load script`, y comprueba `index.html`, `index.wasm` e `index.pck` antes de guardar la build.

Cada cambio en `main` se valida, exporta y publica directamente mediante GitHub Pages en:

<https://javidei.github.io/Godot/>

Para actualizar la aplicación basta con guardar los cambios en `Godot/main` y esperar a que termine en verde la acción **Export Godot Web**; no es necesario sincronizar ni modificar `cvitae`.

`cvitae` conserva únicamente la tarjeta y los enlaces al juego y al repositorio; no almacena una segunda copia de la build.
