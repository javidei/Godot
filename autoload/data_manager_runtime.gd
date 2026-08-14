extends "res://autoload/data_manager.gd"

const SAVE_SLOTS_DIR := "user://save_slots"
const SAVE_SLOTS_INDEX_PATH := "user://save_slots/index.json"
const SAVE_SLOTS_SCHEMA_VERSION := 1
const SAVE_STATE_SLOTS_SCHEMA_VERSION := 4
const MAX_SAVE_SLOTS := 10

var _slots_ready := false
var _active_save_slot := 0
var _slot_index: Dictionary = {}


func reload_all() -> void:
	_slots_ready = false
	super.reload_all()
	_ensure_save_slots_ready()


# La validación base distingue recursos opcionales y valida también los datos
# nuevos. Este punto queda disponible para futuras comprobaciones de runtime.
func _validate_data() -> void:
	super._validate_data()


func migrate_save_state(state: Dictionary) -> Dictionary:
	var result: Dictionary = super(state)
	result["schema_version"] = maxi(int(result.get("schema_version", 0)), SAVE_STATE_SLOTS_SCHEMA_VERSION)
	result["slot_play_seconds"] = maxf(0.0, float(result.get("slot_play_seconds", 0.0)))
	var slot_id := int(result.get("slot_id", 0))
	if slot_id < 1 or slot_id > MAX_SAVE_SLOTS:
		result.erase("slot_id")
	return result


func get_max_save_slots() -> int:
	_ensure_save_slots_ready()
	return MAX_SAVE_SLOTS


func get_active_save_slot() -> int:
	_ensure_save_slots_ready()
	return _active_save_slot


func set_active_save_slot(slot_id: int) -> bool:
	_ensure_save_slots_ready()
	if not _valid_slot(slot_id):
		return false
	_active_save_slot = slot_id
	return true


func clear_active_save_slot() -> void:
	_active_save_slot = 0


func get_last_used_save_slot() -> int:
	_ensure_save_slots_ready()
	var configured := int(_slot_index.get("last_used_slot", 0))
	if _valid_slot(configured) and save_slot_exists(configured):
		return configured
	return _most_recent_occupied_slot()


func get_save_slot_path(slot_id: int) -> String:
	if not _valid_slot(slot_id):
		return ""
	return "%s/slot_%02d.json" % [SAVE_SLOTS_DIR, slot_id]


func save_slot_exists(slot_id: int) -> bool:
	_ensure_save_slots_ready()
	var path := get_save_slot_path(slot_id)
	return not path.is_empty() and FileAccess.file_exists(path)


func has_save() -> bool:
	_ensure_save_slots_ready()
	return _first_occupied_slot() > 0


func save_game(state: Dictionary) -> bool:
	_ensure_save_slots_ready()
	if state.is_empty():
		return false
	var slot_id := _resolve_slot_for_write()
	if not _valid_slot(slot_id):
		return false
	var path := get_save_slot_path(slot_id)
	var previous := _load_json_object(path, {}) if FileAccess.file_exists(path) else {}
	var now := int(Time.get_unix_time_from_system())
	var migrated := migrate_save_state(state)
	migrated["slot_id"] = slot_id
	migrated["save_version"] = str(ProjectSettings.get_setting("application/config/version", "0.7.0"))
	migrated["slot_created_at_unix"] = int(previous.get("slot_created_at_unix", migrated.get("slot_created_at_unix", now)))
	migrated["slot_updated_at_unix"] = now
	migrated["slot_play_seconds"] = maxf(0.0, float(migrated.get("slot_play_seconds", 0.0)))
	state.clear()
	state.merge(migrated, true)
	if not _write_json(path, state):
		return false
	_active_save_slot = slot_id
	_touch_slot_index(slot_id, int(state["slot_created_at_unix"]), now)
	return true


func load_game() -> Dictionary:
	_ensure_save_slots_ready()
	var slot_id := _resolve_slot_for_read()
	if not _valid_slot(slot_id):
		return {}
	return load_save_slot(slot_id)


func create_save_slot(slot_id: int, state: Dictionary) -> bool:
	_ensure_save_slots_ready()
	if not _valid_slot(slot_id) or save_slot_exists(slot_id):
		return false
	_active_save_slot = slot_id
	return save_game(state)


func load_save_slot(slot_id: int) -> Dictionary:
	_ensure_save_slots_ready()
	if not _valid_slot(slot_id):
		return {}
	var path := get_save_slot_path(slot_id)
	if not FileAccess.file_exists(path):
		return {}
	var loaded := _load_json_object(path, {})
	if loaded.is_empty():
		return {}
	var migrated := migrate_save_state(loaded)
	migrated["slot_id"] = slot_id
	var now := int(Time.get_unix_time_from_system())
	if int(migrated.get("slot_created_at_unix", 0)) <= 0:
		migrated["slot_created_at_unix"] = int(migrated.get("slot_updated_at_unix", now))
	if int(migrated.get("slot_updated_at_unix", 0)) <= 0:
		migrated["slot_updated_at_unix"] = now
	if JSON.stringify(loaded) != JSON.stringify(migrated):
		_write_json(path, migrated)
	_active_save_slot = slot_id
	_touch_slot_index(slot_id, int(migrated["slot_created_at_unix"]), int(migrated["slot_updated_at_unix"]))
	return migrated


func delete_save_slot(slot_id: int) -> bool:
	_ensure_save_slots_ready()
	if not _valid_slot(slot_id):
		return false
	var path := get_save_slot_path(slot_id)
	if FileAccess.file_exists(path):
		var error := DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
		if error != OK:
			return false
	var slots: Dictionary = _slot_index.get("slots", {})
	slots.erase(str(slot_id))
	_slot_index["slots"] = slots
	if _active_save_slot == slot_id:
		_active_save_slot = 0
	if int(_slot_index.get("last_used_slot", 0)) == slot_id:
		_slot_index["last_used_slot"] = _most_recent_occupied_slot()
	return _save_slot_index()


func list_save_slots() -> Array:
	_ensure_save_slots_ready()
	var result: Array = []
	for slot_id in range(1, MAX_SAVE_SLOTS + 1):
		result.append(get_save_slot_summary(slot_id))
	return result


func get_save_slot_summary(slot_id: int) -> Dictionary:
	_ensure_save_slots_ready()
	var empty_summary := {
		"slot_id": slot_id,
		"occupied": false,
		"protagonist_id": "",
		"protagonist_name": "",
		"progress_percent": 0,
		"current_zone_id": "",
		"current_zone_name": "",
		"play_seconds": 0.0,
		"coins": 0,
		"updated_at_unix": 0,
		"created_at_unix": 0,
		"save_version": "",
		"visits_completed": 0,
		"visits_total": 0
	}
	if not _valid_slot(slot_id):
		return empty_summary
	var path := get_save_slot_path(slot_id)
	if not FileAccess.file_exists(path):
		return empty_summary
	var state := _load_json_object(path, {})
	if state.is_empty():
		return empty_summary
	state = migrate_save_state(state)
	var player: Dictionary = state.get("player", {}) if typeof(state.get("player", {})) == TYPE_DICTIONARY else {}
	var player_id := str(player.get("id", ""))
	var player_name := str(player.get("display_name", player.get("name", "")))
	if player_name.is_empty() and not player_id.is_empty():
		var character := get_character(player_id)
		player_name = str(character.get("display_name", character.get("name", player_id.capitalize())))
	var progress := _story_progress(state, player_id)
	var zone_id := str(state.get("current_zone_id", get_default_zone_id()))
	var zone := get_world_map(zone_id)
	empty_summary.merge({
		"occupied": true,
		"protagonist_id": player_id,
		"protagonist_name": player_name,
		"progress_percent": int(progress.get("percent", 0)),
		"current_zone_id": zone_id,
		"current_zone_name": str(zone.get("name", zone_id.replace("_", " ").capitalize())),
		"play_seconds": maxf(0.0, float(state.get("slot_play_seconds", 0.0))),
		"coins": maxi(0, int(state.get("coins", 0))),
		"updated_at_unix": int(state.get("slot_updated_at_unix", 0)),
		"created_at_unix": int(state.get("slot_created_at_unix", 0)),
		"save_version": str(state.get("save_version", "")),
		"visits_completed": int(progress.get("completed", 0)),
		"visits_total": int(progress.get("total", 0))
	}, true)
	return empty_summary


func _story_progress(state: Dictionary, player_id: String) -> Dictionary:
	var expected: Array[String] = []
	for character_id in get_character_ids(true):
		if character_id != player_id:
			expected.append(character_id)
	var completed_set: Dictionary = {}
	var raw_completed: Variant = state.get("completed_characters", [])
	if typeof(raw_completed) == TYPE_ARRAY:
		for raw_id in raw_completed as Array:
			var character_id := str(raw_id)
			if expected.has(character_id):
				completed_set[character_id] = true
	var total := expected.size()
	var completed := completed_set.size()
	if total <= 0:
		return {"percent": 0, "completed": completed, "total": total}
	if str(state.get("node_id", "")) == "__END__" or completed >= total:
		return {"percent": 100, "completed": mini(completed, total), "total": total}
	var partial := 0.0
	var checkpoints: Variant = state.get("conversation_checkpoints", {})
	if typeof(checkpoints) == TYPE_DICTIONARY:
		for character_id in expected:
			if completed_set.has(character_id):
				continue
			if not str((checkpoints as Dictionary).get(character_id, "")).is_empty():
				partial += 0.5
	var ratio := clampf((float(completed) + partial) / float(total), 0.0, 1.0)
	return {"percent": roundi(ratio * 100.0), "completed": completed, "total": total}


func _ensure_save_slots_ready() -> void:
	if _slots_ready:
		return
	# Marcar primero evita reentradas: los resúmenes de slots consultan datos que
	# a su vez llaman a ensure_loaded().
	_slots_ready = true
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(SAVE_SLOTS_DIR))
	_slot_index = _load_json_object(SAVE_SLOTS_INDEX_PATH, {}) if FileAccess.file_exists(SAVE_SLOTS_INDEX_PATH) else {}
	if typeof(_slot_index.get("slots", {})) != TYPE_DICTIONARY:
		_slot_index["slots"] = {}
	_slot_index["schema_version"] = SAVE_SLOTS_SCHEMA_VERSION
	_rebuild_slot_index_from_disk()
	_migrate_single_save_to_slot_one_once()
	var last_used := int(_slot_index.get("last_used_slot", 0))
	if not (_valid_slot(last_used) and FileAccess.file_exists(get_save_slot_path(last_used))):
		_slot_index["last_used_slot"] = _most_recent_occupied_slot()
	_save_slot_index()


func _rebuild_slot_index_from_disk() -> void:
	var slots: Dictionary = _slot_index.get("slots", {})
	for slot_id in range(1, MAX_SAVE_SLOTS + 1):
		var key := str(slot_id)
		var path := get_save_slot_path(slot_id)
		if not FileAccess.file_exists(path):
			slots.erase(key)
			continue
		var state := _load_json_object(path, {})
		if state.is_empty():
			continue
		var created := int(state.get("slot_created_at_unix", state.get("slot_updated_at_unix", 0)))
		var updated := int(state.get("slot_updated_at_unix", created))
		slots[key] = {"created_at_unix": created, "updated_at_unix": updated}
	_slot_index["slots"] = slots


func _migrate_single_save_to_slot_one_once() -> void:
	if bool(_slot_index.get("legacy_import_completed", false)):
		return
	var old_path := get_save_path()
	if not FileAccess.file_exists(get_save_slot_path(1)) and FileAccess.file_exists(old_path):
		var old_state := _load_json_object(old_path, {})
		if not old_state.is_empty():
			var migrated := migrate_save_state(old_state)
			var now := int(Time.get_unix_time_from_system())
			migrated["slot_id"] = 1
			migrated["slot_created_at_unix"] = int(migrated.get("slot_created_at_unix", now))
			migrated["slot_updated_at_unix"] = int(migrated.get("slot_updated_at_unix", now))
			migrated["slot_play_seconds"] = maxf(0.0, float(migrated.get("slot_play_seconds", 0.0)))
			if _write_json(get_save_slot_path(1), migrated):
				_touch_slot_index(1, int(migrated["slot_created_at_unix"]), int(migrated["slot_updated_at_unix"]), false)
				_slot_index["last_used_slot"] = 1
	_slot_index["legacy_import_completed"] = true


func _touch_slot_index(slot_id: int, created_at: int, updated_at: int, save_now: bool = true) -> void:
	var slots: Dictionary = _slot_index.get("slots", {})
	slots[str(slot_id)] = {
		"created_at_unix": created_at,
		"updated_at_unix": updated_at
	}
	_slot_index["slots"] = slots
	_slot_index["last_used_slot"] = slot_id
	if save_now:
		_save_slot_index()


func _save_slot_index() -> bool:
	_slot_index["schema_version"] = SAVE_SLOTS_SCHEMA_VERSION
	return _write_json(SAVE_SLOTS_INDEX_PATH, _slot_index)


func _resolve_slot_for_write() -> int:
	if _valid_slot(_active_save_slot):
		return _active_save_slot
	var last_used := get_last_used_save_slot()
	if _valid_slot(last_used):
		return last_used
	var occupied := _first_occupied_slot()
	return occupied if occupied > 0 else 1


func _resolve_slot_for_read() -> int:
	if _valid_slot(_active_save_slot) and FileAccess.file_exists(get_save_slot_path(_active_save_slot)):
		return _active_save_slot
	var last_used := get_last_used_save_slot()
	if _valid_slot(last_used):
		return last_used
	return _first_occupied_slot()


func _first_occupied_slot() -> int:
	for slot_id in range(1, MAX_SAVE_SLOTS + 1):
		if FileAccess.file_exists(get_save_slot_path(slot_id)):
			return slot_id
	return 0


func _most_recent_occupied_slot() -> int:
	var best_slot := 0
	var best_time := -1
	for slot_id in range(1, MAX_SAVE_SLOTS + 1):
		var path := get_save_slot_path(slot_id)
		if not FileAccess.file_exists(path):
			continue
		var state := _load_json_object(path, {})
		var updated := int(state.get("slot_updated_at_unix", 0))
		if updated >= best_time:
			best_time = updated
			best_slot = slot_id
	return best_slot


func _valid_slot(slot_id: int) -> bool:
	return slot_id >= 1 and slot_id <= MAX_SAVE_SLOTS
