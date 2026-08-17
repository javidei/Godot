extends "res://autoload/data_manager_v090.gd"

const JAVI_QUESTION_POOL_PATH := "res://data/javi_question_pool.json"
const JAVI_QUESTION_STEP := 5
const JAVI_GAME_NOTICE := {
	"expression": "happy",
	"text": "Antes de empezar: esto es un juego de insultos piratas. Yo te lanzo uno y tú eliges la mejor réplica. No va en serio."
}

var _javi_question_pool: Dictionary = {}
var _runtime_javi_question_seed := 0


func reload_all() -> void:
	_javi_question_pool = _load_json_object(JAVI_QUESTION_POOL_PATH, {})
	super()


func set_runtime_javi_question_seed(seed: int) -> void:
	_runtime_javi_question_seed = maxi(0, seed)


func get_runtime_javi_question_seed() -> int:
	return _runtime_javi_question_seed


func reroll_javi_question_for_visit() -> int:
	var raw_questions: Variant = _javi_question_pool.get("questions", [])
	if typeof(raw_questions) != TYPE_ARRAY:
		return -1
	var pool := raw_questions as Array
	if pool.is_empty():
		return -1

	var day_offset := maxi(0, _runtime_day_id - 1)
	var previous_index := (_runtime_javi_question_seed + day_offset * JAVI_QUESTION_STEP) % pool.size()
	var candidate_seed := randi_range(1, 2147483646)
	var selected_index := (candidate_seed + day_offset * JAVI_QUESTION_STEP) % pool.size()

	# Si hay alternativas, una revisita no repite inmediatamente el mismo insulto.
	if pool.size() > 1 and selected_index == previous_index:
		candidate_seed = 1 if candidate_seed >= 2147483646 else candidate_seed + 1
		selected_index = (candidate_seed + day_offset * JAVI_QUESTION_STEP) % pool.size()

	_runtime_javi_question_seed = candidate_seed
	return selected_index


func get_question_bundle(character_id: String) -> Dictionary:
	var bundle := super.get_question_bundle(character_id)
	if character_id != "javi" or _legacy_contract() or not _runtime_day_enabled:
		return bundle

	var intro: Array = bundle.get("intro", []) if typeof(bundle.get("intro", [])) == TYPE_ARRAY else []
	intro = intro.duplicate(true)
	intro.append(JAVI_GAME_NOTICE.duplicate(true))
	bundle["intro"] = intro

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
