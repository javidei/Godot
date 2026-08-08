# Entre líneas · Godot

Primera base jugable del proyecto narrativo en **Godot 4**, tomando como referencia la demo `juego-otome`.

## Qué incluye ahora

- Menú principal con **Nueva partida** y **Continuar**.
- Escena narrativa en una cafetería.
- Javi, Sue y Smokey.
- Tres estados visuales por personaje usando los mismos sprite sheets temporales de `juego-otome`.
- Texto con efecto de escritura progresiva.
- Dos momentos de decisión.
- Sistema básico de afinidad.
- Guardado y carga de partida en `user://godot_otome_save.json`.
- Efectos sencillos de zoom, sacudida y onomatopeyas.
- Pantalla final con resumen de afinidad.
- Preset preparado para una futura exportación **Web**.

## Recursos gráficos

Por ahora el proyecto carga los recursos gráficos directamente desde el repositorio público `javidei/juego-otome` mediante `HTTPRequest`. Si la descarga falla, el juego sigue funcionando mostrando placeholders.

Esto es temporal: cuando la base esté asentada podremos mover/copiar los recursos definitivos a este repositorio para que el proyecto sea completamente autónomo y funcione también sin conexión.

## Abrir en Godot

1. Instala Godot 4.
2. Abre Godot y pulsa **Importar**.
3. Selecciona `project.godot`.
4. Ejecuta con **F6/F5**.

## Estructura

```text
Godot/
├── project.godot
├── export_presets.cfg
├── scenes/
│   └── main.tscn
├── scripts/
│   ├── main.gd
│   └── story.gd
└── README.md
```

## Siguiente evolución

La arquitectura ya permite empezar a separar escenas, sistema de diálogos, personajes, rutas, inventario, audio, efectos y minijuegos sin cambiar de motor.
