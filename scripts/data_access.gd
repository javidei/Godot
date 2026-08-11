extends RefCounted

# Evita depender del identificador global `DataManager` al compilar scripts que
# también se ejecutan directamente con `godot --script` en CI. En el juego
# normal siempre devuelve el Autoload real configurado en project.godot.
static func dm() -> Variant:
	var main_loop := Engine.get_main_loop()
	if main_loop is SceneTree:
		var tree := main_loop as SceneTree
		var singleton := tree.root.get_node_or_null("DataManager")
		if singleton != null:
			return singleton
	push_error("DataAccess: el Autoload DataManager no está disponible")
	return null
