extends "res://scripts/version_080_visit_transitions.gd"

const DataStory098 = preload("res://scripts/story.gd")
const DataAccess098 = preload("res://scripts/data_access.gd")


func begin_character_visit(character_id: String) -> void:
	if character_id == "javi" and not transition_active:
		_prepare_random_javi_visit()
	super(character_id)


func _prepare_random_javi_visit() -> void:
	var dm: Variant = DataAccess098.dm()
	if dm == null or not dm.has_method("reroll_javi_question_for_visit"):
		return

	# Javi funciona como minijuego independiente: cada entrada desde el mapa
	# empieza de nuevo, muestra el aviso y sortea un insulto distinto.
	var state := _state()
	var raw_checkpoints: Variant = state.get("conversation_checkpoints", {})
	if typeof(raw_checkpoints) == TYPE_DICTIONARY:
		var checkpoints := (raw_checkpoints as Dictionary).duplicate(true)
		checkpoints.erase("javi")
		state["conversation_checkpoints"] = checkpoints

	dm.call("reroll_javi_question_for_visit")
	if dm.has_method("get_runtime_javi_question_seed"):
		state["javi_question_seed"] = int(dm.call("get_runtime_javi_question_seed"))
	main.set("state", state)
	main.call("_save_game", false)

	# La historia se reconstruye antes de abrir la habitación para que tanto la
	# introducción como la única pregunta de esta visita usen el nuevo sorteo.
	DataStory098.refresh()
	if version_manager != null and version_manager.has_method("_patch_story"):
		version_manager.call("_patch_story")
	_ensure_story_patches()
