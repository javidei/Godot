extends RefCounted
class_name DemoStory

const DataAccess = preload("res://scripts/data_access.gd")

const LEGACY_START_NODES: Array[String] = ["casa_01", "bar_01", "bosque_01"]
const FEMININE_ORDINALS: Array[String] = [
	"", "primera", "segunda", "tercera", "cuarta", "quinta", "sexta",
	"séptima", "octava", "novena", "décima", "undécima", "duodécima",
	"decimotercera", "decimocuarta", "decimoquinta", "decimosexta",
	"decimoséptima", "decimoctava", "decimonovena", "vigésima"
]

# Fachada compatible con la API histórica. La fuente real es DataManager/JSON.
static var ENCOUNTER_ORDER: Array[String] = _load_encounter_order()
static var ENCOUNTERS: Dictionary = _build_encounters()
static var NODES: Dictionary = _build_nodes()
static var START: String = _default_start()


static func refresh() -> void:
	var dm: Variant = DataAccess.dm()
	if dm == null:
		return
	dm.call("ensure_loaded")
	ENCOUNTER_ORDER = _load_encounter_order()
	ENCOUNTERS = _build_encounters()
	NODES = _build_nodes()
	START = _default_start()


static func game_title() -> String:
	if ENCOUNTER_ORDER.is_empty():
		refresh()
	return title_for_character_count(ENCOUNTER_ORDER.size())


static func menu_title() -> String:
	return game_title().replace(": ", ":\n")


static func title_for_character_count(character_count: int) -> String:
	var chair_number := maxi(character_count + 1, 1)
	return "Entre líneas: La %s silla" % _feminine_ordinal(chair_number)


static func question_count(character_id: String) -> int:
	var dm: Variant = DataAccess.dm()
	if dm == null:
		return 0
	var questions: Array = dm.call("get_questions", character_id)
	return questions.size()


static func max_affinity_for_character(character_id: String) -> int:
	var dm: Variant = DataAccess.dm()
	if dm == null:
		return 0
	var total := 0
	var questions: Array = dm.call("get_questions", character_id)
	for raw_question in questions:
		if typeof(raw_question) != TYPE_DICTIONARY:
			continue
		var question := raw_question as Dictionary
		var best := 0
		var answers: Variant = question.get("answers", [])
		if typeof(answers) == TYPE_ARRAY:
			for raw_answer in answers as Array:
				if typeof(raw_answer) != TYPE_DICTIONARY:
					continue
				best = maxi(best, int((raw_answer as Dictionary).get("score", 0)))
		total += best
	return total


static func max_affinity_for_player(player_id: String) -> int:
	var total := 0
	for character_id in encounter_order_for_player(player_id):
		total += max_affinity_for_character(character_id)
	return total


static func final_feedback_ids(character_id: String) -> Array[String]:
	var count := question_count(character_id)
	if count <= 0:
		return []
	return ["%s_q%d_correct" % [character_id, count], "%s_q%d_wrong" % [character_id, count]]


static func is_final_feedback_node(node_id: String) -> bool:
	var character_id := character_for_node(node_id)
	if character_id.is_empty():
		return false
	return final_feedback_ids(character_id).has(node_id)


static func encounter_order_for_player(player_id: String) -> Array[String]:
	if ENCOUNTER_ORDER.is_empty():
		refresh()
	var order: Array[String] = []
	for character_id in ENCOUNTER_ORDER:
		if character_id != player_id:
			order.append(character_id)
	return order


static func start_for_player(player_id: String) -> String:
	var order := encounter_order_for_player(player_id)
	if order.is_empty():
		return "__END__"
	return order[0] + "_intro_01"


static func character_for_node(node_id: String) -> String:
	if ENCOUNTER_ORDER.is_empty():
		refresh()
	for character_id in ENCOUNTER_ORDER:
		if node_id.begins_with(character_id + "_"):
			return character_id
	return ""


static func resolve_for_player(node_id: String, player_id: String) -> String:
	if node_id.is_empty() or LEGACY_START_NODES.has(node_id):
		return start_for_player(player_id)
	if character_for_node(node_id) != player_id:
		return node_id
	var player_index := ENCOUNTER_ORDER.find(player_id)
	if player_index >= 0 and player_index + 1 < ENCOUNTER_ORDER.size():
		return ENCOUNTER_ORDER[player_index + 1] + "_intro_01"
	return "__END__"


static func _load_encounter_order() -> Array[String]:
	var dm: Variant = DataAccess.dm()
	if dm == null:
		return []
	dm.call("ensure_loaded")
	var raw_ids: Array = dm.call("get_character_ids", true)
	var result: Array[String] = []
	for raw_id in raw_ids:
		result.append(str(raw_id))
	return result


static func _build_encounters() -> Dictionary:
	var dm: Variant = DataAccess.dm()
	if dm == null:
		return {}
	var result: Dictionary = {}
	for character_id in ENCOUNTER_ORDER:
		var character: Dictionary = dm.call("get_character", character_id)
		var questions_json: Array = dm.call("get_questions", character_id)
		var compatibility_questions: Array = []
		for raw_question in questions_json:
			if typeof(raw_question) != TYPE_DICTIONARY:
				continue
			var question := raw_question as Dictionary
			var labels: Array = []
			var correct_index := 0
			var best_score := -2147483648
			var answers: Variant = question.get("answers", [])
			if typeof(answers) == TYPE_ARRAY:
				for answer_index in range((answers as Array).size()):
					var raw_answer: Variant = (answers as Array)[answer_index]
					if typeof(raw_answer) != TYPE_DICTIONARY:
						continue
					var answer := raw_answer as Dictionary
					labels.append(str(answer.get("text", "")))
					var score := int(answer.get("score", 0))
					if score > best_score:
						best_score = score
						correct_index = answer_index
			var feedback: Dictionary = question.get("feedback", {})
			var correct_feedback: Dictionary = feedback.get("correct", {})
			var wrong_feedback: Dictionary = feedback.get("wrong", {})
			compatibility_questions.append({
				"id": str(question.get("id", "")),
				"text": str(question.get("text", "")),
				"choices": labels,
				"correct": correct_index,
				"correct_text": str(correct_feedback.get("text", "¡Correcto!")),
				"wrong_text": str(wrong_feedback.get("text", "No era esa.")),
				"answers": (question.get("answers", []) as Array).duplicate(true),
				"feedback": feedback.duplicate(true)
			})
		var intro: Array = dm.call("get_intro", character_id)
		result[character_id] = {
			"name": str(character.get("story_name", character.get("name", character_id.capitalize()))),
			"background": str(dm.call("get_character_background_id", character_id)),
			"intro": intro,
			"questions": compatibility_questions
		}
	return result


static func _build_nodes() -> Dictionary:
	var nodes: Dictionary = {}
	var encounter_total := ENCOUNTER_ORDER.size()
	for character_index in range(encounter_total):
		var character_id: String = ENCOUNTER_ORDER[character_index]
		var encounter: Dictionary = ENCOUNTERS.get(character_id, {})
		var display_name := str(encounter.get("name", character_id.capitalize()))
		var chapter := "ENCUENTRO %d/%d · %s" % [character_index + 1, encounter_total, display_name.to_upper()]
		var intro_lines: Array = encounter.get("intro", [])
		for intro_index in range(intro_lines.size()):
			var line: Dictionary = intro_lines[intro_index]
			var node_id := "%s_intro_%02d" % [character_id, intro_index + 1]
			var next_id := "%s_intro_%02d" % [character_id, intro_index + 2] if intro_index + 1 < intro_lines.size() else "%s_q1" % character_id
			var node := _single_character_node(character_id, display_name, str(line.get("text", "")), next_id, chapter)
			node["expressions"] = {character_id: str(line.get("expression", "neutral"))}
			nodes[node_id] = node

		var questions: Array = encounter.get("questions", [])
		for question_index in range(questions.size()):
			var question: Dictionary = questions[question_index]
			var number := question_index + 1
			var question_id := "%s_q%d" % [character_id, number]
			var correct_feedback_id := "%s_q%d_correct" % [character_id, number]
			var wrong_feedback_id := "%s_q%d_wrong" % [character_id, number]
			var question_node := _single_character_node(character_id, display_name, str(question.get("text", "")), "", "%s · PREGUNTA %d/%d" % [chapter, number, questions.size()])
			question_node.erase("next")
			question_node["question_character"] = character_id
			question_node["question_number"] = number
			question_node["question_count"] = questions.size()
			question_node["choices"] = []
			var answers: Array = question.get("answers", [])
			for raw_answer in answers:
				if typeof(raw_answer) != TYPE_DICTIONARY:
					continue
				var answer := raw_answer as Dictionary
				var feedback_kind := str(answer.get("feedback", "wrong"))
				var target := correct_feedback_id if feedback_kind == "correct" else wrong_feedback_id
				var choice := {
					"label": str(answer.get("text", "")),
					"side": str(answer.get("side", "")),
					"next": target
				}
				var score := int(answer.get("score", 0))
				if score != 0:
					choice["affinity"] = {character_id: score}
				question_node["choices"].append(choice)
			nodes[question_id] = question_node

			var following_id := _following_node(character_index, question_index, questions.size())
			var feedback: Dictionary = question.get("feedback", {})
			var correct_data: Dictionary = feedback.get("correct", {})
			var wrong_data: Dictionary = feedback.get("wrong", {})
			var correct_node := _single_character_node(character_id, display_name, str(correct_data.get("text", question.get("correct_text", "¡Correcto!"))), following_id, chapter)
			correct_node["expressions"] = {character_id: str(correct_data.get("expression", "happy"))}
			correct_node["answer_result"] = "correct"
			nodes[correct_feedback_id] = correct_node
			var wrong_node := _single_character_node(character_id, display_name, str(wrong_data.get("text", question.get("wrong_text", "No era esa."))), following_id, chapter)
			wrong_node["expressions"] = {character_id: str(wrong_data.get("expression", "thoughtful"))}
			wrong_node["answer_result"] = "wrong"
			nodes[wrong_feedback_id] = wrong_node
	return nodes


static func _single_character_node(character_id: String, speaker: String, text: String, next_id: String, chapter: String) -> Dictionary:
	var encounter: Dictionary = ENCOUNTERS.get(character_id, {})
	var node := {
		"speaker": speaker,
		"text": text,
		"background": str(encounter.get("background", "bar")),
		"show": [character_id],
		"positions": {character_id: "center"},
		"focus": character_id,
		"chapter": chapter
	}
	if not next_id.is_empty():
		node["next"] = next_id
	return node


static func _following_node(character_index: int, question_index: int, question_count_value: int) -> String:
	if question_index + 1 < question_count_value:
		return "%s_q%d" % [ENCOUNTER_ORDER[character_index], question_index + 2]
	if character_index + 1 < ENCOUNTER_ORDER.size():
		return "%s_intro_01" % ENCOUNTER_ORDER[character_index + 1]
	return "__END__"


static func _default_start() -> String:
	if ENCOUNTER_ORDER.is_empty():
		return "__END__"
	return ENCOUNTER_ORDER[0] + "_intro_01"


static func _feminine_ordinal(value: int) -> String:
	if value >= 0 and value < FEMININE_ORDINALS.size():
		return FEMININE_ORDINALS[value]
	return "%d.ª" % value
