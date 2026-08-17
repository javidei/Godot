extends "res://scripts/version_090_character_select_manager.gd"

var _pending_javi_question_seed := 0


func _new_javi_question_seed() -> int:
	return randi_range(1, 2147483646)


func _set_javi_question_seed(seed: int) -> void:
	var dm := get_node_or_null("/root/DataManager")
	if dm != null and dm.has_method("set_runtime_javi_question_seed"):
		dm.call("set_runtime_javi_question_seed", seed)


# La pregunta diaria de Javi se fija al crear la partida. De este modo la
# selección es aleatoria entre partidas, pero estable al guardar y continuar.
func _start_game() -> void:
	_pending_javi_question_seed = _new_javi_question_seed()
	_set_javi_question_seed(_pending_javi_question_seed)
	super()
	if main == null:
		return
	var raw_state: Variant = main.get("state")
	if typeof(raw_state) != TYPE_DICTIONARY:
		return
	var current_state := raw_state as Dictionary
	if current_state.is_empty() or typeof(current_state.get("player", null)) != TYPE_DICTIONARY:
		return
	current_state["javi_question_seed"] = _pending_javi_question_seed
	main.set("state", current_state)
	main.call("_save_game", false)


# Al continuar, restauramos la misma semilla antes de que Story reconstruya
# los nodos del día; los guardados antiguos reciben una al cargarse por primera vez.
func _continue_with_migration() -> void:
	var dm := get_node_or_null("/root/DataManager")
	var seed := 0
	if dm != null:
		var loaded: Variant = dm.call("load_game")
		if typeof(loaded) == TYPE_DICTIONARY:
			var loaded_state := loaded as Dictionary
			if loaded_state.has("javi_question_seed"):
				seed = int(loaded_state.get("javi_question_seed", 0))
	if seed <= 0:
		seed = _new_javi_question_seed()
	_set_javi_question_seed(seed)
	_pending_javi_question_seed = seed

	super()

	if main == null:
		return
	var raw_state: Variant = main.get("state")
	if typeof(raw_state) != TYPE_DICTIONARY:
		return
	var current_state := raw_state as Dictionary
	if current_state.is_empty():
		return
	if not current_state.has("javi_question_seed"):
		current_state["javi_question_seed"] = seed
		main.set("state", current_state)
		main.call("_save_game", false)
