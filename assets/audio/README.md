# Audio

La demo no contiene todavía música ni ficheros SFX con licencia propia. `AudioManager`
crea los canales Music, SFX y UI y conserva soporte para registrar recursos en esta
carpeta cuando existan.

Para no dejar la demo muda, `strum`, `clonk` y la confirmación de interfaz se generan
de forma procedural en Godot. Es el equivalente al sistema de tonos que utilizaba la
demo HTML anterior y no incorpora audio externo ni material con copyright.

Cuando existan recursos definitivos, añádelos aquí y regístralos en
`scripts/audio_manager.gd`; el diálogo ya puede dispararlos con `"sfx": "nombre"`.

