extends "res://scripts/version_095_unified_audio_visual.gd"

const DataStory099 = preload("res://scripts/story.gd")
const DataAccess099 = preload("res://scripts/data_access.gd")

const JAVI_PIRATE_DAY_ID_0927 := 3
const JAVI_BATTLE_RESUME_NODE_0927 := "javi_battle_resume_0927"
const JAVI_BATTLE_COMPLETE_NODE_0927 := "javi_battle_complete_0927"
const JAVI_BATTLE_STORY_INTRO_FLAG_0930 := "javi_battle_story_intro_seen_0930"


func _select_visit(character_id: String) -> void:
	if character_id != "javi":
		super(character_id)
		return

	var state: Dictionary = main.get("state") if main != null else {}
	if state.is_empty() or _current_day_0927(state) != JAVI_PIRATE_DAY_ID_0927:
		super(character_id)
		return

	var entry_node := prepare_javi_battle_for_transition(state)
	if entry_node.is_empty():
		super(character_id)
		return
	_hide_selector()
	main.call("_go_to", entry_node, false)


# Punto único de preparación para la ruta real mapa -> transición -> habitación.
# No navega por sí mismo: devuelve el nodo que debe abrir la transición activa.
func prepare_javi_battle_for_transition(state: Dictionary) -> String:
	if state.is_empty() or _current_day_0927(state) != JAVI_PIRATE_DAY_ID_0927:
		return ""
	var dm: Variant = DataAccess099.dm()
	if dm == null:
		return ""

	_ensure_visit_state(state)
	var raw_checkpoints: Variant = state.get("conversation_checkpoints", {})
	if typeof(raw_checkpoints) == TYPE_DICTIONARY:
		var checkpoints := (raw_checkpoints as Dictionary).duplicate(true)
		checkpoints.erase("javi")
		state["conversation_checkpoints"] = checkpoints

	var show_story_intro := not bool(state.get(JAVI_BATTLE_STORY_INTRO_FLAG_0930, false))
	var battle: Dictionary = dm.call("prepare_javi_insult_battle_visit", state)
	dm.call("mark_javi_insult_battle_entered", state)
	dm.call("set_runtime_javi_insult_battle_state", state)
	_rebuild_javi_battle_story_0927(state)

	# La marca 0.9.30 es deliberadamente nueva. Los slots que pasaron por las
	# rutas defectuosas 0.9.27-0.9.29 no la tienen y verán el prólogo una vez.
	if show_story_intro:
		state[JAVI_BATTLE_STORY_INTRO_FLAG_0930] = true
	main.set("state", state)
	main.call("_save_game", false)

	if bool(battle.get("complete", false)):
		return JAVI_BATTLE_COMPLETE_NODE_0927
	return "javi_intro_01" if show_story_intro else JAVI_BATTLE_RESUME_NODE_0927


# Continuar una partida guardada dentro de Javi usa exactamente la misma
# preparación que una entrada desde el mapa, evitando dos contratos distintos.
func prepare_javi_battle_resume_from_save(state: Dictionary) -> String:
	return prepare_javi_battle_for_transition(state)


func _rebuild_javi_battle_story_0927(state: Dictionary) -> void:
	var dm: Variant = DataAccess099.dm()
	if dm != null:
		if dm.has_method("set_runtime_narrative_day"):
			dm.call("set_runtime_narrative_day", _current_day_0927(state))
		var raw_active: Variant = state.get("active_characters", [])
		if dm.has_method("set_runtime_active_characters") and typeof(raw_active) == TYPE_ARRAY and not (raw_active as Array).is_empty():
			dm.call("set_runtime_active_characters", raw_active as Array)
		if dm.has_method("set_runtime_javi_insult_battle_state"):
			dm.call("set_runtime_javi_insult_battle_state", state)

	DataStory099.refresh()
	_patch_story()
	_force_javi_day3_intro_0928()
	_install_javi_battle_nodes_0927()
	var transitions := main.get_node_or_null("Version044VisitTransitions") if main != null else null
	if transitions != null and transitions.has_method("_ensure_story_patches"):
		transitions.call("_ensure_story_patches")
	# Algunos parches de transición pueden reconstruir enlaces finales. Volvemos a
	# instalar los nodos propios y la introducción al final para mantener el flujo.
	_force_javi_day3_intro_0928()
	_install_javi_battle_nodes_0927()


func _force_javi_day3_intro_0928() -> void:
	var dm: Variant = DataAccess099.dm()
	if dm == null or not dm.has_method("get_question_bundle"):
		return
	var bundle: Variant = dm.call("get_question_bundle", "javi")
	if typeof(bundle) != TYPE_DICTIONARY:
		return
	var raw_intro: Variant = (bundle as Dictionary).get("intro", [])
	if typeof(raw_intro) != TYPE_ARRAY or (raw_intro as Array).is_empty():
		return

	var intro := raw_intro as Array
	var background_id := _background_for_character("javi")
	for index in range(intro.size()):
		var raw_line: Variant = intro[index]
		if typeof(raw_line) != TYPE_DICTIONARY:
			continue
		var line := raw_line as Dictionary
		var node_id := "javi_intro_%02d" % [index + 1]
		var next_id := "javi_intro_%02d" % [index + 2] if index + 1 < intro.size() else "javi_q1"
		DataStory099.NODES[node_id] = {
			"speaker": str(line.get("speaker", "Narrador")),
			"text": str(line.get("text", "")),
			"background": background_id,
			"show": ["javi"],
			"positions": {"javi": "center"},
			"focus": "javi",
			"chapter": "JAVI · BATALLA DE INSULTOS",
			"next": next_id
		}


func _install_javi_battle_nodes_0927() -> void:
	var background_id := _background_for_character("javi")
	DataStory099.NODES[JAVI_BATTLE_RESUME_NODE_0927] = {
		"speaker": "Javi",
		"text": "¿Seguimos con la batalla de insultos?",
		"background": background_id,
		"show": ["javi"],
		"focus": "javi",
		"chapter": "JAVI · BATALLA DE INSULTOS",
		"choices": [
			{"label": "Venga, dispara.", "next": "javi_q1"},
			{"label": "Ahora no.", "next": VISIT_NODE}
		]
	}
	DataStory099.NODES[JAVI_BATTLE_COMPLETE_NODE_0927] = {
		"speaker": "Javi",
		"text": "Ya no me quedan insultos nuevos. Te los has comido todos.",
		"background": background_id,
		"show": ["javi"],
		"focus": "javi",
		"chapter": "JAVI · BATALLA DE INSULTOS COMPLETADA",
		"next": VISIT_NODE
	}


func _current_day_0927(state: Dictionary) -> int:
	var progress: Variant = state.get("narrative_progress", {})
	if typeof(progress) == TYPE_DICTIONARY:
		return int((progress as Dictionary).get("current_day", 1))
	var dm: Variant = DataAccess099.dm()
	if dm != null and dm.has_method("get_runtime_narrative_day"):
		return int(dm.call("get_runtime_narrative_day"))
	return 1
