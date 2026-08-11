extends "res://scripts/version_050_extras_codex.gd"


func _load_data() -> void:
	data = DataManager.get_codex_data()
	characters = []
	var people: Variant = data.get("personajes", [])
	if typeof(people) == TYPE_ARRAY:
		characters = people
