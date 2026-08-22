extends "res://scripts/main_v092.gd"


func _ready() -> void:
	super()
	_update_guest_menu_copy_101()


func _go_to(node_id: String, add_to_history: bool = true) -> void:
	super(node_id, add_to_history)
	var routes := get_node_or_null("NarrativeRouteManager")
	if routes == null or current_node.is_empty():
		return
	var route_event := str(current_node.get("route_event", ""))
	if not route_event.is_empty() and routes.has_method("record_scene_event"):
		routes.call("record_scene_event", route_event)
	var easter_egg_id := str(current_node.get("easter_egg_id", ""))
	if not easter_egg_id.is_empty() and routes.has_method("record_easter_egg"):
		routes.call("record_easter_egg", easter_egg_id)


func _choose(choice: Dictionary) -> void:
	var routes := get_node_or_null("NarrativeRouteManager")
	if routes != null and routes.has_method("record_choice"):
		routes.call(
			"record_choice",
			str(state.get("node_id", "")),
			str(choice.get("label", "")),
			str(choice.get("route_event", ""))
		)
	super(choice)


func _update_guest_menu_copy_101() -> void:
	if menu_content == null:
		return
	for node in menu_content.find_children("*", "Label", true, false):
		var label := node as Label
		if label == null:
			continue
		if label.text.begins_with("Elige quién eres"):
			label.text = "Entra como invitado, recorre el grupo y sigue las pistas, decisiones y rutas que se vayan abriendo."
			break
