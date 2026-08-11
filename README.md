# Entre líneas

Novela visual en **Godot 4.7.1**, actualmente en **Early Access**, con Javi, Sue, Smokey, Carmen, Jony, Ana y El Argentino.

El subtítulo se calcula automáticamente con el número de personajes más una silla: los siete personajes actuales producen **«La octava silla»** y trece producirían **«La decimocuarta silla»**.

## Base actual

- Recursos gráficos locales: no depende de `raw.githubusercontent.com` para fondos o personajes.
- 8 fondos, varias poses/expresiones de protagonistas y recursos por personaje configurables mediante datos.
- Poses seleccionables desde los datos del diálogo y posiciones `left`, `center` y `right`.
- Carga bajo demanda con caché acotada y precarga ligera de la siguiente escena.
- Composición de novela visual sin `ColorRect` ni placeholders detrás de los personajes.
- Foco sutil del personaje que habla, zoom, sacudida y onomatopeyas animadas.
- Interfaz para ratón/táctil y composición alternativa en orientación vertical.
- Guardado offline en `user://savegame.json` y preferencias en `user://settings.json`, con migración compatible desde archivos locales anteriores.
- `DataManager` como Autoload para centralizar personajes, preguntas, habitaciones, música, configuración y acceso al progreso.
- AudioManager con canales separados para música y efectos/UI, volúmenes y silencios independientes y música en bucle asociada a fondos/habitaciones mediante datos.
- La nueva partida empieza eligiendo protagonista.
- Recorrido libre por el resto del grupo: el personaje elegido representa al jugador y no aparece como encuentro.
- Cuatro respuestas por pregunta en una cuadrícula táctil de dos columnas.
- Afinidad independiente por personaje y puntuaciones configurables desde los datos de preguntas.
- Menú **Extras** con fichas de personajes, información del juego, habitaciones y créditos.

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

Los datos operativos están separados del código en `data/` y se consumen a través de `DataManager`. `scripts/asset_manager.gd` continúa siendo la capa encargada de cargar y cachear recursos visuales, pero las rutas configurables proceden de los JSON en lugar de estar dispersas por los scripts.

Los PNG de personajes conservan su resolución original y transparencia. Los `TextureRect` usan filtrado lineal y `KEEP_ASPECT_CENTERED`: las imágenes grandes se reducen visualmente sin recomprimirlas ni sustituirlas por copias pequeñas. Para este rango de escala 2D no se fuerzan mipmaps, evitando crear copias innecesarias de la textura.

El título usa `DejaVuSerif-Bold.ttf`, incluido en el proyecto para conservar la misma tipografía narrativa en web, móvil y escritorio. Su licencia se encuentra junto al archivo de fuente.

## Datos y diálogo

La rama 0.5.x permite elegir a Javi, Sue, Smokey, Carmen, Jony, Ana o El Argentino como protagonista. La persona elegida representa al jugador, queda fuera de las visitas y el recorrido se adapta al resto del grupo. Cada encuentro contiene una presentación, preguntas con cuatro opciones, puntuaciones configurables y una réplica inmediata.

Los datos estáticos se organizan principalmente en:

```text
data/
├── characters/
├── questions/
├── rooms/
└── game_config.json
```

`DataManager` centraliza el acceso a estos JSON. Los scripts históricos como `story.gd` y los gestores de versiones conservan capas de compatibilidad para mantener escenas y partidas existentes mientras el origen de los datos permanece separado del código.

Una escena puede seguir indicando recursos y composición sin crear escenas Godot nuevas:

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

El menú separa los ajustes de **Música** y **Efectos de sonido**. Ambos pueden regularse y silenciarse de forma independiente. Las preferencias persistentes se guardan en `user://settings.json`; al migrar desde versiones anteriores se conservan los antiguos archivos locales como respaldo.

Las habitaciones/personajes pueden configurar fondo, tema musical y volumen base desde sus JSON. Al cambiar de fondo, el tema correspondiente se carga y continúa en bucle. Si un fichero de audio configurado no existe, el juego continúa en silencio sin bloquear la ejecución.

Los tonos `strum`, `clonk` y la confirmación de interfaz continúan generándose de forma procedural y no incorporan audio externo ni material con copyright.

## Documentación del proyecto

La planificación y seguimiento del proyecto se mantienen fuera del juego:

- [Ideas y mejoras futuras](docs/IDEAS.md)
- [Roadmap](docs/ROADMAP.md)
- [Problemas conocidos](docs/KNOWN_ISSUES.md)
- [Changelog](docs/CHANGELOG.md)

La filosofía es mover una propuesta de **Ideas → Roadmap → Changelog** cuando pasa de concepto a tarea decidida y finalmente a funcionalidad implementada. Los errores se gestionan de forma independiente en `KNOWN_ISSUES.md`.

## Web y estabilidad

La exportación Web usa `export_presets.cfg`. El workflow de GitHub Actions mantiene la validación que impide publicar si aparecen `SCRIPT ERROR`, `Parse Error` o `Failed to load script`, y comprueba `index.html`, `index.wasm` e `index.pck` antes de guardar la build.

Cada cambio en `main` se valida, exporta y publica directamente mediante GitHub Pages en:

<https://javidei.github.io/Godot/>

Para actualizar la aplicación basta con guardar los cambios en `Godot/main` y esperar a que termine en verde la acción **Export Godot Web**; no es necesario sincronizar ni modificar `cvitae`.

`cvitae` conserva únicamente la tarjeta y los enlaces al juego y al repositorio; no almacena una segunda copia de la build.
