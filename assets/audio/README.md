# Audio

`AudioManager` crea los canales Music, SFX y UI. El menú separa Música de Efectos,
permite regularlos y silenciarlos de forma independiente y guarda las cuatro
preferencias. La música empieza al 30 % y los efectos/UI al 100 %.

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

Para usar nombres diferentes, edita solo las dos tablas del principio de
`scripts/audio_manager.gd`: `MUSIC_FILES` guarda las rutas y `BACKGROUND_MUSIC`
relaciona cada fondo con una canción.

Ejemplo:

```gdscript
const MUSIC_FILES := {
    "ana_vampirica": "res://assets/audio/music/mi-cancion-de-ana.ogg"
}

const BACKGROUND_MUSIC := {
    "habitacion_ana": "ana_vampirica"
}
```

Se recomienda OGG por su compatibilidad con la exportación web. Utiliza música propia
o con una licencia que te permita incluirla y publicarla en el repositorio.

## Efectos

Mientras no haya SFX definitivos, `strum`, `clonk` y la confirmación de interfaz se
generan de forma procedural. El diálogo puede reproducir un fichero registrado en
`SFX_FILES` usando `"sfx": "nombre"`.
