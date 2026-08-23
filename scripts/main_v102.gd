extends "res://scripts/main_v101.gd"

const DataAccess102 = preload("res://scripts/data_access.gd")


func _ready() -> void:
	super()
	if not character_slots.has("charlie"):
		_create_character("charlie", "center")
		var slot := character_slots.get("charlie") as Control
		if slot != null:
			slot.name = "Charlie"


func _chapter_for_node(node_id: String, node: Dictionary) -> String:
	var character_id: String = Story.character_for_node(node_id)
	var encounter_order: Array[String] = Story.encounter_order_for_player(_player_character_id())
	var encounter_index := encounter_order.find(character_id)
	if encounter_index < 0:
		return str(node.get("chapter", "ENCUENTRO"))
	var chapter := "ENCUENTRO %d/%d · %s" % [
		encounter_index + 1,
		encounter_order.size(),
		_character_display_name_102(character_id).to_upper()
	]
	if node.has("question_number"):
		chapter += " · PREGUNTA %d/%d" % [
			int(node.get("question_number", 1)),
			maxi(1, int(node.get("question_count", 1)))
		]
	return chapter


func _choose(choice: Dictionary) -> void:
	var routes := get_node_or_null("NarrativeRouteManager")
	if routes != null and routes.has_method("record_choice"):
		routes.call(
			"record_choice",
			str(state.get("node_id", "")),
			str(choice.get("label", "")),
			str(choice.get("route_event", ""))
		)

	var affinity: Dictionary = choice.get("affinity", {})
	for character in affinity.keys():
		var character_id := str(character)
		var amount := int(affinity[character])
		state["affinity"][character_id] = int(state["affinity"].get(character_id, 0)) + amount
		_show_toast(_character_display_name_102(character_id) + " +" + str(amount) + " afinidad")
	state["history"].append({"choice": str(choice.get("label", ""))})
	_go_to(str(choice.get("next", "__END__")))


func _character_display_name_102(character_id: String) -> String:
	var dm: Variant = DataAccess102.dm()
	if dm != null and dm.has_method("get_character"):
		var data: Variant = dm.call("get_character", character_id)
		if typeof(data) == TYPE_DICTIONARY:
			var display_name := str((data as Dictionary).get("display_name", ""))
			if not display_name.is_empty():
				return display_name
	return character_id.capitalize()
