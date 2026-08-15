extends "res://scripts/version_080_world_map_days.gd"

const DataAccess090 = preload("res://scripts/data_access.gd")


func _active_ids() -> Array[String]:
	var state := _state()
	var raw: Variant = state.get("active_characters", [])
	var result: Array[String] = []
	if typeof(raw) == TYPE_ARRAY:
		for raw_id in raw as Array:
			var character_id := str(raw_id)
			if not character_id.is_empty() and not result.has(character_id):
				result.append(character_id)
	if not result.is_empty():
		return result
	var dm: Variant = DataAccess090.dm()
	if dm != null and dm.has_method("get_runtime_active_characters"):
		var runtime: Variant = dm.call("get_runtime_active_characters")
		if typeof(runtime) == TYPE_ARRAY:
			for raw_id in runtime as Array:
				var character_id := str(raw_id)
				if not character_id.is_empty() and not result.has(character_id):
					result.append(character_id)
	return result


func _character_is_active(character_id: String) -> bool:
	var active := _active_ids()
	return active.is_empty() or active.has(character_id)


func _add_character_marker(parent: Control, marker: Dictionary, ordinal: int, list_layout: bool) -> bool:
	var character_id := str(marker.get("character_id", marker.get("id", "")))
	if not character_id.is_empty() and not _character_is_active(character_id):
		return false
	return super(parent, marker, ordinal, list_layout)


func _resident_ids(zone: Dictionary) -> Array[String]:
	var residents := super(zone)
	var active := _active_ids()
	if active.is_empty():
		return residents
	var result: Array[String] = []
	for character_id in residents:
		if active.has(character_id):
			result.append(character_id)
	return result


func _connection_list(zone: Dictionary) -> Array[Dictionary]:
	var connections := super(zone)
	var active := _active_ids()
	if active.is_empty():
		return connections
	var result: Array[Dictionary] = []
	for connection in connections:
		var filtered := connection.duplicate(true)
		var raw: Variant = filtered.get("residents", [])
		if typeof(raw) == TYPE_ARRAY:
			var residents: Array[String] = []
			for raw_id in raw as Array:
				var character_id := str(raw_id)
				if active.has(character_id):
					residents.append(character_id)
			filtered["residents"] = residents
		result.append(filtered)
	return result
