extends SceneTree

class DummyMain:
	extends Control
	var state: Dictionary = {}
	var saved_count := 0
	var last_toast := ""

	func _save_game(_show_feedback: bool = false) -> bool:
		saved_count += 1
		return true

	func _show_toast(message: String) -> void:
		last_toast = message


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var dm := get_root().get_node_or_null("DataManager")
	if dm == null:
		_fail("DataManager no está disponible")
		return
	dm.call("reload_all")
	if not dm.has_method("get_narrative_day_ids"):
		_fail("El DataManager no expone la progresión por días")
		return
	var day_ids: Array = dm.call("get_narrative_day_ids")
	if day_ids != [1, 2, 3]:
		_fail("Se esperaban los días 1, 2 y 3")
		return
	var day_three: Dictionary = dm.call("get_narrative_day", 3)
	if typeof(day_three.get("puzzle", null)) != TYPE_DICTIONARY:
		_fail("El Día 3 no contiene el puzle data-driven")
		return

	var state := {
		"node_id": "__VISIT_SELECT__",
		"player": {"id": "javi", "name": "Javi", "display_name": "Javi"},
		"affinity": {},
		"expressions": {},
		"history": [],
		"completed_characters": [],
		"visit_order": [],
		"visit_mode": true,
		"coins": 0
	}
	state = dm.call("migrate_save_state", state) as Dictionary
	if int(state.get("schema_version", 0)) < 5:
		_fail("El guardado no se migra al esquema narrativo 0.8")
		return
	var progress: Dictionary = state.get("narrative_progress", {})
	if int(progress.get("current_day", 0)) != 1:
		_fail("Una partida nueva no empieza en el Día 1")
		return

	var dummy := DummyMain.new()
	dummy.state = state
	var manager_script := load("res://scripts/narrative_day_manager.gd") as Script
	if manager_script == null:
		_fail("No se puede cargar NarrativeDayManager")
		return
	var manager: Node = manager_script.new() as Node
	if manager == null:
		_fail("No se puede instanciar NarrativeDayManager")
		return
	manager.set("main", dummy)
	manager.set("data_manager", dm)
	manager.set("transition_manager", null)
	manager.set("progress_manager", null)

	for character_id in ["sue", "smokey", "carmen", "jony", "ana", "argentino"]:
		manager.call("on_character_visit_completed", character_id)
	var day_one_progress: Dictionary = manager.call("get_current_day_progress")
	if int(day_one_progress.get("completed", 0)) != 6 or not bool(day_one_progress.get("ready", false)):
		_fail("El Día 1 no se completa al visitar al grupo salvo al protagonista")
		return
	manager.call("_commit_day_advance", 1, 2)
	if int(manager.call("get_current_day_id")) != 2:
		_fail("La progresión no avanza al Día 2")
		return

	for character_id in ["ana", "jony", "carmen"]:
		manager.call("on_character_visit_completed", character_id)
	var day_two_progress: Dictionary = manager.call("get_current_day_progress")
	if int(day_two_progress.get("completed", 0)) != 3 or not bool(day_two_progress.get("ready", false)):
		_fail("El Día 2 no respeta su lista reducida de visitas")
		return
	manager.call("_commit_day_advance", 2, 3)

	var targets: Dictionary = manager.call("get_puzzle_clue_targets")
	if targets.size() != 4:
		_fail("El puzle no resuelve cuatro destinos de pista")
		return
	var unique_targets: Dictionary = {}
	for clue_id in targets.keys():
		var target := str(targets[clue_id])
		if target == "javi":
			_fail("Una pista ha apuntado al propio protagonista")
			return
		unique_targets[target] = true
	if unique_targets.size() != 4:
		_fail("Las cuatro pistas deberían repartirse entre cuatro visitas distintas")
		return
	for target in targets.values():
		manager.call("on_character_visit_completed", str(target))
	var before_solution: Dictionary = manager.call("get_current_day_progress")
	if int(before_solution.get("completed", 0)) != 4 or bool(before_solution.get("ready", false)):
		_fail("Recoger pistas no debe resolver automáticamente el código")
		return
	if bool(manager.call("submit_puzzle_solution", "1234")):
		_fail("Un código incorrecto ha sido aceptado")
		return
	if not bool(manager.call("submit_puzzle_solution", "2026")):
		_fail("El código correcto no resuelve el puzle")
		return
	var solved_progress: Dictionary = manager.call("get_current_day_progress")
	if int(solved_progress.get("completed", 0)) != 5 or not bool(solved_progress.get("ready", false)):
		_fail("El Día 3 no queda listo tras resolver las cuatro pistas y el código")
		return
	manager.call("_begin_arc_completion")
	if not bool(manager.call("is_arc_complete")):
		_fail("El primer arco no queda marcado como completado")
		return

	var story_progress: Dictionary = dm.call("_story_progress", dummy.state, "javi")
	if int(story_progress.get("percent", 0)) != 100:
		_fail("El progreso global no alcanza el 100% al completar el arco disponible")
		return

	print("V080 NARRATIVE DAYS OK: 3 días, objetivos variables, pistas, código, migración y progreso persistente validados.")
	quit(0)


func _fail(message: String) -> void:
	push_error("V080 NARRATIVE DAYS FAIL: " + message)
	quit(1)
