extends "res://scripts/version_050_extras_codex.gd"

const DataAccess = preload("res://scripts/data_access.gd")


func _load_data() -> void:
	var dm: Variant = DataAccess.dm()
	data = dm.call("get_codex_data") if dm != null else {}
	characters = []
	var people: Variant = data.get("personajes", [])
	if typeof(people) == TYPE_ARRAY:
		characters = people
