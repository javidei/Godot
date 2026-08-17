extends "res://autoload/data_manager_v090.gd"

const JAVI_QUESTION_POOL_PATH := "res://data/javi_question_pool.json"
const JAVI_QUESTION_STEP := 5

var _javi_question_pool: Dictionary = {}
var _runtime_javi_question_seed := 0


func reload_all() -> void:
	_javi_question_pool = _load_json_object(JAVI_QUESTION_POOL_PATH, {})
	super()


func set_runtime_javi_question_seed(seed: int) -> void:
	_runtime_javi_question_seed = maxi(0, seed)


func get_runtime_javi_question_seed() -> int:
	return _runtime_javi_question_seed


func get_question_bundle(character_id: String) -> Dictionary:
	var bundle := super.get_question_bundle(character_id)
	if character_id != "javi" or _legacy_contract() or not _runtime_day_enabled:
		return bundle

	var raw_questions: Variant = _javi_question_pool.get("questions", [])
	if typeof(raw_questions) != TYPE_ARRAY:
		return bundle
	var pool := raw_questions as Array
	if pool.is_empty():
		return bundle

	var day_offset := maxi(0, _runtime_day_id - 1)
	var selected_index := (_runtime_javi_question_seed + day_offset * JAVI_QUESTION_STEP) % pool.size()
	var selected: Variant = pool[selected_index]
	if typeof(selected) != TYPE_DICTIONARY:
		return bundle

	bundle["questions"] = [(selected as Dictionary).duplicate(true)]
	return bundle
