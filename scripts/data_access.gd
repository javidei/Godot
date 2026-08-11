extends RefCounted

const DATA_MANAGER_SCRIPT := preload("res://autoload/data_manager.gd")

static var _fallback: Node


# En el juego normal devuelve siempre /root/DataManager. Algunos tests headless
# precargan Story/GameData antes de que Godot haya insertado los Autoloads en el
# árbol; en ese instante se usa una instancia temporal de solo datos para que
# las fachadas estáticas se construyan con el mismo JSON y no con valores vacíos.
static func dm() -> Variant:
	var main_loop := Engine.get_main_loop()
	if main_loop is SceneTree:
		var tree := main_loop as SceneTree
		var singleton := tree.root.get_node_or_null("DataManager")
		if singleton != null:
			return singleton
	if _fallback == null:
		_fallback = DATA_MANAGER_SCRIPT.new()
		_fallback.call("ensure_loaded")
	return _fallback
