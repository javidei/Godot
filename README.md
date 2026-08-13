# Entre líneas

Novela visual en **Godot 4.7.1**, actualmente en **Early Access** y versión **0.6.1**, con Javi, Sue, Smokey, Carmen, Jony, Ana y El Argentino.

El subtítulo se calcula automáticamente con el número de personajes más una silla: los siete personajes actuales producen **«La octava silla»** y trece producirían **«La decimocuarta silla»**.

## Base actual

- Recursos gráficos locales: no depende de `raw.githubusercontent.com` para fondos o personajes.
- Fondos narrativos locales, varias poses/expresiones y recursos por personaje configurables mediante datos.
- Poses seleccionables desde los datos del diálogo y posiciones `left`, `center` y `right`.
- Carga bajo demanda con caché acotada y precarga ligera de la siguiente escena.
- Composición de novela visual sin `ColorRect` ni placeholders detrás de los personajes.
- Foco sutil del personaje que habla, zoom, sacudida y onomatopeyas animadas.
- Interfaz para ratón/táctil y composición alternativa en orientación vertical.
- Guardado offline por partida en `user://savegame.json`, preferencias en `user://settings.json` y perfil acumulado en `user://profile.json`, con migración compatible desde archivos locales anteriores.
- `DataManager` como Autoload para centralizar personajes, preguntas, habitaciones, mapas, economía, tienda, logros, configuración y persistencia.
- AudioManager con canales separados para música y efectos/UI, volúmenes y silencios independientes, música de menú con entrada gradual y temas en bucle asociados mediante datos.
- La nueva partida presenta brevemente el año 2026 antes de elegir protagonista.
- Mapa interactivo de Naranjal del Río como centro del recorrido, con accesos temporales a Triana y Monte del Toro, tienda y retorno después de cada conversación.
- Recorrido libre por el resto del grupo: el personaje elegido representa al jugador, no aparece como encuentro y los marcadores conservan el estado visitado.
- MONEDAS y recompensas únicas por partida; coleccionables, cosméticos, estadísticas y logros en un perfil global local.
- Ajuste global con cinco perfiles procedurales de clic más la opción desactivada, todos en el bus de Efectos/UI.
- Cuatro respuestas por pregunta en una cuadrícula táctil de dos columnas.
- Afinidad independiente por personaje y puntuaciones configurables desde los datos de preguntas.
- Menú **Extras** con fichas —cada una con pestañas de datos y cosméticos—, lugares, logros, estadísticas acumuladas, colección y créditos.

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
├── maps/
│   └── naranjal_del_rio.png
└── ui/
    ├── fonts/
    └── icons/
```

Los datos operativos están separados del código en `data/` y se consumen a través de `DataManager`. `scripts/asset_manager.gd` continúa siendo la capa encargada de cargar y cachear recursos visuales, pero las rutas configurables proceden de los JSON en lugar de estar dispersas por los scripts.

Los PNG de personajes conservan su resolución original y transparencia. Los `TextureRect` usan filtrado lineal y `KEEP_ASPECT_CENTERED`: las imágenes grandes se reducen visualmente sin recomprimirlas ni sustituirlas por copias pequeñas. Para este rango de escala 2D no se fuerzan mipmaps, evitando crear copias innecesarias de la textura.

El título usa `DejaVuSerif-Bold.ttf`, incluido en el proyecto para conservar la misma tipografía narrativa en web, móvil y escritorio. Su licencia se encuentra junto al archivo de fuente.

## Datos y diálogo

La versión 0.6.1 permite elegir a Javi, Sue, Smokey, Carmen, Jony, Ana o El Argentino como protagonista. La persona elegida representa al jugador, queda fuera de las visitas y el mapa se adapta al resto del grupo. Cada encuentro contiene una presentación, preguntas con cuatro opciones, puntuaciones configurables y una réplica inmediata.

Los datos estáticos se organizan principalmente en:

```text
data/
├── achievements.json
├── characters/
├── economy.json
├── questions/
├── rooms/
├── shop_catalog.json
├── world_maps.json
└── game_config.json
```

`DataManager` centraliza el acceso a estos JSON. Los scripts históricos como `story.gd` y los gestores de versiones conservan capas de compatibilidad para mantener escenas y partidas existentes mientras el origen de los datos permanece separado del código.

Todas las fichas de personaje incluyen una pestaña **Cosméticos**, incluso cuando todavía no tienen contenido. Las skins, mascotas y variantes asociadas desde la tienda aparecen allí y reflejan los desbloqueos del perfil global.

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

El tema `assets/audio/music/menu.ogg` comienza desde el principio cada vez que se entra al menú, sube suavemente durante cuatro segundos hasta un volumen deliberadamente bajo y permanece en bucle al navegar por el menú, Extras y Ajustes. Se detiene al comenzar la selección de protagonista o la partida.

Las habitaciones/personajes pueden configurar fondo, tema musical y volumen base desde sus JSON. Al cambiar de fondo, el tema correspondiente se carga y continúa en bucle. Si un fichero de audio configurado no existe, el juego continúa en silencio sin bloquear la ejecución.

Los tonos `strum`, `clonk` y los perfiles de clic **Suave**, **Seco**, **Digital**, **Madera** y **Pop** se generan de forma procedural y no incorporan audio externo ni material con copyright. **Desactivado** silencia solo los clics. La selección se previsualiza en Ajustes, se conserva globalmente y respeta el volumen/silencio de Efectos.

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
