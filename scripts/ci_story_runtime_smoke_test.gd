extends SceneTree

const Story = preload("res://scripts/story.gd")
const EXPECTED_IDS := ["javi", "sue", "smokey", "carmen", "jony", "ana", "argentino", "charlie"]


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var dm := root.get_node_or_null("DataManager")
	if dm == null:
		_fail("DataManager no está disponible")
		return
	dm.call("reload_all")
	var all_ids: Array = dm.call("get_all_character_ids", true)
	if all_ids != EXPECTED_IDS:
		_fail("El reparto actual no contiene los ocho NPC esperados: " + str(all_ids))
		return

	var packed := load("res://scenes/main.tscn") as PackedScene
	if packed == null:
		_fail("No se puede cargar main.tscn")
		return
	var main := packed.instantiate() as Control
	root.add_child(main)
	for _i in range(48):
		await process_frame

	var runtime := main.get_node_or_null("StoryRuntimeManager")
	if runtime == null or not runtime.has_method("apply_story_runtime"):
		main.queue_free()
		_fail("Falta StoryRuntimeManager estable")
		return
	if main.find_child("StoryRosterButton090", true, false) != null or main.find_child("StoryRosterOverlay090", true, false) != null:
		main.queue_free()
		_fail("Sigue apareciendo el selector antiguo de reparto")
		return

	runtime.call("apply_story_runtime", ["javi", "sue"], 1, true)
	await process_frame
	if Story.ENCOUNTER_ORDER != EXPECTED_IDS:
		main.queue_free()
		_fail("El runtime permite todavía reducir el reparto: " + str(Story.ENCOUNTER_ORDER))
		return
	if Story.game_title() != "Entre líneas: La novena silla":
		main.queue_free()
		_fail("El título dinámico no conserva la novena silla")
		return

	var migrated: Dictionary = dm.call("migrate_save_state", {
		"player": {"id": "javi", "display_name": "Javi"},
		"active_characters": ["sue", "smokey"],
		"node_id": "sue_intro_01",
		"affinity": {},
		"expressions": {},
		"history": []
	})
	var player: Dictionary = migrated.get("player", {})
	if str(player.get("id", "")) != "custom" or not bool(player.get("guest", false)):
		main.queue_free()
		_fail("Un guardado antiguo no migra al Invitado fijo")
		return
	if migrated.get("active_characters", []) != EXPECTED_IDS:
		main.queue_free()
		_fail("Un guardado antiguo no recupera a los ocho NPC")
		return

	main.queue_free()
	print("STORY RUNTIME OK: Invitado fijo, ocho NPC, novena silla y ausencia de selector de reparto validados.")
	quit(0)


func _fail(message: String) -> void:
	push_error("STORY RUNTIME FAIL: " + message)
	quit(1)
