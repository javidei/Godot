extends "res://scripts/main_v091.gd"

const Story092 = preload("res://scripts/story.gd")


func _choose(choice: Dictionary) -> void:
	# Cada insulto respondido se consume antes de navegar al feedback. Así el
	# ProgressManager guarda ya el progreso actualizado junto con la decisión.
	if _is_javi_battle_question_0927():
		var dm: Variant = _dm()
		if dm != null and dm.has_method("record_javi_insult_answer"):
			dm.call("record_javi_insult_answer", state, int(current_node.get("question_number", 0)))
	super(choice)


func _read_save() -> bool:
	# Guardamos el nodo real antes de que la compatibilidad histórica intente
	# resolverlo contra un Story todavía no sincronizado con la batalla del Día 3.
	var dm: Variant = _dm()
	var saved_node := ""
	var saved_day := 0
	if dm != null:
		var preview: Dictionary = dm.call("load_game")
		if not preview.is_empty():
			saved_node = str(preview.get("node_id", ""))
			saved_day = _state_day_0927(preview)

	if not super():
		return false

	if saved_day != 3 or not saved_node.begins_with("javi_"):
		return true
	if typeof(state.get("javi_insult_battle", null)) != TYPE_DICTIONARY:
		return true

	var battle_manager := get_node_or_null("Version040Manager")
	if battle_manager == null or not battle_manager.has_method("prepare_javi_battle_resume_from_save"):
		return true
	var resume_node := str(battle_manager.call("prepare_javi_battle_resume_from_save", state))
	if not resume_node.is_empty():
		state["node_id"] = resume_node
	return true


func _is_javi_battle_question_0927() -> bool:
	if state.is_empty() or _state_day_0927(state) != 3:
		return false
	if str(state.get("node_id", "")).begins_with("javi_q") == false:
		return false
	return str(current_node.get("question_character", "")) == "javi" and int(current_node.get("question_number", 0)) > 0


func _state_day_0927(source: Dictionary) -> int:
	var progress: Variant = source.get("narrative_progress", {})
	return int((progress as Dictionary).get("current_day", 1)) if typeof(progress) == TYPE_DICTIONARY else 1
