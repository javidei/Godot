# Godot

Base mínima para empezar un juego con **Godot 4**.

Ahora mismo el proyecto solo muestra una pantalla inicial con el texto **“Aquí va un juego en Godot”**. La idea es usar este repositorio como base e ir añadiendo escenas, personajes, diálogos, animaciones y mecánicas poco a poco.

## Abrir el proyecto

1. Instala Godot 4.
2. Abre Godot y pulsa **Importar**.
3. Selecciona el archivo `project.godot`.
4. Ejecuta el proyecto con **F6/F5**.

## Estructura

```text
Godot/
├── project.godot
├── scenes/
│   └── main.tscn
├── scripts/
│   └── main.gd
└── README.md
```

El proyecto usa el renderizador **Compatibility**, pensado para que más adelante sea sencillo preparar también una exportación web.
