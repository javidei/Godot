# Audio

`AudioManager` crea los canales Music, SFX y UI. El menú separa Música de Efectos,
permite regularlos y silenciarlos de forma independiente y guarda las cuatro
preferencias. La música empieza al 30 % y los efectos/UI al 100 %. El 100 % visible
de música equivale al 10 % de la escala lineal anterior; por tanto, el 30 % inicial
equivale al 3 % anterior. Los efectos y la interfaz mantienen su escala completa.
Los botones − y + cambian cada canal en pasos del 10 %.

## Música del menú

`menu.ogg` es el tema exclusivo de la pantalla principal. Su ruta, volumen base y
duración del fundido se declaran en `data/game_config.json`. Cada entrada al menú
reinicia la canción, la hace subir suavemente durante cuatro segundos hasta el 35 %
del ya reducido canal Music y la mantiene en bucle. Al ocultarse `MenuScreen`, el
tema se detiene para no continuar en Extras, Ajustes, la selección de protagonista
o la partida.

## Añadir la música de los escenarios

La forma más sencilla es subir cada canción a `assets/audio/music/` manteniendo uno
de estos nombres:

| Fondo | Estilo propuesto | Fichero esperado |
|---|---|---|
| Casa Asturias | Acústico, cálido y nostálgico | `casa-asturias.ogg` |
| Bosque | Ambiental y misterioso | `bosque-misterioso.ogg` |
| Bar | Nocturno y relajado | `bar-nocturno.ogg` |
| Habitación de Ana | Gótico y vampírico | `ana-vampirica.ogg` |
| Habitación del Argentino | Rock con carácter | `argentino-rock.ogg` |
| Habitación de Fran | Electrónica suave | `fran-electronica.ogg` |
| Habitación de Sue | Fantasía onírica | `sue-fantasia.ogg` |
| Habitación de Jony | Rock relajado | `jony-rock.ogg` |
| Habitación de Javi | Lo-fi rock tecnológico | `javi-lofi-rock.ogg` |

No hace falta modificar escenas ni diálogos. En el siguiente commit Godot importará
los OGG y la música empezará a sonar en bucle cuando aparezca su fondo.

Para usar nombres diferentes, edita `music_id`, `music_path`, `music_volume` y
`music_loop` en el JSON de la habitación correspondiente. El menú utiliza los
campos equivalentes de la sección `menu` de `data/game_config.json`.

Ejemplo:

```gdscript
{
  "music_id": "ana_vampirica",
  "music_path": "res://assets/audio/music/mi-cancion-de-ana.ogg",
  "music_volume": 1.0,
  "music_loop": true
}
```

Se recomienda OGG por su compatibilidad con la exportación web. Utiliza música propia
o con una licencia que te permita incluirla y publicarla en el repositorio.

## Efectos

Mientras no haya SFX definitivos, `strum`, `clonk` y los clics de interfaz se
generan de forma procedural. El diálogo puede reproducir un fichero registrado en
`SFX_FILES` usando `"sfx": "nombre"`.

## Clics de interfaz

`AudioManager` conserva un único `AudioStreamPlayer` en el bus UI y enlaza botones
de forma idempotente. El bus UI reutiliza exactamente el volumen y silencio de
Efectos; no existe un regulador adicional. Los perfiles disponibles son:

- Suave (`soft`)
- Seco (`dry`)
- Digital (`digital`)
- Madera (`wood`)
- Pop (`pop`)
- Desactivado (`off`)

La opción se cambia y previsualiza desde **Ajustes > Sonido de clic**. Se guarda
como `audio.click_sound` en `user://settings.json` y se migra también el antiguo
alias `click_sound_id` si estuviera presente.
