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
	var dm: Variant = DataAccess.dm()
	if dm == null:
		return []
	var questions: Array = dm.call("get_questions", character_id)
	if questions.is_empty():
		return []
	var raw_question: Variant = questions[questions.size() - 1]
	if typeof(raw_question) != TYPE_DICTIONARY:
		return []
	var question := raw_question as Dictionary
	var number := questions.size()
	var after_lines := _normalise_dialogue_lines(question.get("after", []))
	if not after_lines.is_empty():
		return [_after_node_id(character_id, number, after_lines.size() - 1)]

	var feedback: Dictionary = _feedback_dictionary(question)
	var result: Array[String] = []
	for feedback_key in _feedback_keys(question):
		var lines := _feedback_lines(feedback, feedback_key)
		var terminal_id := _feedback_node_id(character_id, number, feedback_key, maxi(0, lines.size() - 1))
		if not result.has(terminal_id):
			result.append(terminal_id)
	return result


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
	var resolved := node_id
	var guard := 0
	while guard < 64:
		guard += 1
		var encounter_character := character_for_node(resolved)
		if encounter_character == player_id:
			var player_index := ENCOUNTER_ORDER.find(player_id)
			if player_index >= 0 and player_index + 1 < ENCOUNTER_ORDER.size():
				resolved = ENCOUNTER_ORDER[player_index + 1] + "_intro_01"
			else:
				return "__END__"
			continue
		var node: Dictionary = NODES.get(resolved, {})
		if node.is_empty() or not _node_hidden_for_player(node, player_id):
			return resolved
		if not node.has("next"):
			return "__END__"
		resolved = str(node.get("next", "__END__"))
		if resolved == "__END__":
			return resolved
	return resolved


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
			var feedback := _feedback_dictionary(question)
			var correct_feedback := _first_feedback_line(feedback, "correct")
			var wrong_feedback := _first_feedback_line(feedback, "wrong")
			compatibility_questions.append({
				"id": str(question.get("id", "")),
				"text": str(question.get("text", "")),
				"choices": labels,
				"correct": correct_index,
				"correct_text": str(correct_feedback.get("text", "¡Correcto!")),
				"wrong_text": str(wrong_feedback.get("text", "No era esa.")),
				"answers": (question.get("answers", []) as Array).duplicate(true),
				"feedback": feedback.duplicate(true),
				"after": _normalise_dialogue_lines(question.get("after", []))
			})
		var intro: Array = dm.call("get_intro", character_id)
		result[character_id] = {
			"name": str(character.get("story_name", character.get("display_name", character.get("name", character_id.capitalize())))),
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
		var intro_lines := _normalise_dialogue_lines(encounter.get("intro", []))
		for intro_index in range(intro_lines.size()):
			var node_id := "%s_intro_%02d" % [character_id, intro_index + 1]
			var next_id := "%s_intro_%02d" % [character_id, intro_index + 2] if intro_index + 1 < intro_lines.size() else "%s_q1" % character_id
			nodes[node_id] = _dialogue_node(character_id, display_name, intro_lines[intro_index], next_id, chapter)

		var questions: Array = encounter.get("questions", [])
		for question_index in range(questions.size()):
			var question: Dictionary = questions[question_index]
			var number := question_index + 1
			var question_id := "%s_q%d" % [character_id, number]
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
				var feedback_key := str(answer.get("feedback", "wrong"))
				var choice := {
					"label": str(answer.get("text", "")),
					"side": str(answer.get("side", "")),
					"next": _feedback_node_id(character_id, number, feedback_key, 0)
				}
				var score := int(answer.get("score", 0))
				if score != 0:
					choice["affinity"] = {character_id: score}
				question_node["choices"].append(choice)
			nodes[question_id] = question_node

			var following_id := _following_node(character_index, question_index, questions.size())
			var after_lines := _normalise_dialogue_lines(question.get("after", []))
			var after_start := _after_node_id(character_id, number, 0) if not after_lines.is_empty() else following_id
			var feedback := _feedback_dictionary(question)
			for feedback_key in _feedback_keys(question):
				var feedback_lines := _feedback_lines(feedback, feedback_key)
				for feedback_index in range(feedback_lines.size()):
					var feedback_id := _feedback_node_id(character_id, number, feedback_key, feedback_index)
					var feedback_next := _feedback_node_id(character_id, number, feedback_key, feedback_index + 1) if feedback_index + 1 < feedback_lines.size() else after_start
					var feedback_node := _dialogue_node(character_id, display_name, feedback_lines[feedback_index], feedback_next, chapter)
					feedback_node["answer_result"] = feedback_key
					nodes[feedback_id] = feedback_node

			for after_index in range(after_lines.size()):
				var after_id := _after_node_id(character_id, number, after_index)
				var after_next := _after_node_id(character_id, number, after_index + 1) if after_index + 1 < after_lines.size() else following_id
				nodes[after_id] = _dialogue_node(character_id, display_name, after_lines[after_index], after_next, chapter)
	return nodes


static func _dialogue_node(character_id: String, default_speaker: String, raw_line: Variant, next_id: String, chapter: String) -> Dictionary:
	var line: Dictionary = raw_line as Dictionary if typeof(raw_line) == TYPE_DICTIONARY else {"text": str(raw_line)}
	var speaker_id := str(line.get("speaker_id", character_id))
	var speaker := str(line.get("speaker", ""))
	if speaker.is_empty():
		speaker = _display_name_for(speaker_id) if not speaker_id.is_empty() else "Narrador"

	var shown := _string_array(line.get("show", []))
	if shown.is_empty():
		shown.append(character_id)
		if not speaker_id.is_empty() and speaker_id != character_id and not shown.has(speaker_id):
			shown.append(speaker_id)
	var positions: Dictionary = {}
	var raw_positions: Variant = line.get("positions", {})
	if typeof(raw_positions) == TYPE_DICTIONARY:
		positions = (raw_positions as Dictionary).duplicate(true)
	if positions.is_empty():
		positions = _default_positions(shown)
	var focus := str(line.get("focus", speaker_id if shown.has(speaker_id) else (character_id if shown.has(character_id) else "all")))

	var encounter: Dictionary = ENCOUNTERS.get(character_id, {})
	var node := {
		"speaker": speaker,
		"text": str(line.get("text", "")),
		"background": str(line.get("background", encounter.get("background", "bar"))),
		"show": shown,
		"positions": positions,
		"focus": focus,
		"chapter": chapter
	}
	if not next_id.is_empty():
		node["next"] = next_id

	var expression_changes: Dictionary = {}
	var raw_expressions: Variant = line.get("expressions", {})
	if typeof(raw_expressions) == TYPE_DICTIONARY:
		expression_changes = (raw_expressions as Dictionary).duplicate(true)
	if line.has("expression") and not speaker_id.is_empty():
		expression_changes[speaker_id] = str(line.get("expression", "neutral"))
	if not expression_changes.is_empty():
		node["expressions"] = expression_changes
	if line.has("effect") and typeof(line.get("effect")) == TYPE_DICTIONARY:
		node["effect"] = (line.get("effect") as Dictionary).duplicate(true)
	if line.has("exclude_players"):
		node["exclude_players"] = _string_array(line.get("exclude_players", []))
	if line.has("include_players"):
		node["include_players"] = _string_array(line.get("include_players", []))
	return node


static func _single_character_node(character_id: String, speaker: String, text: String, next_id: String, chapter: String) -> Dictionary:
	return _dialogue_node(character_id, speaker, {"speaker_id": character_id, "speaker": speaker, "text": text}, next_id, chapter)


static func _feedback_dictionary(question: Dictionary) -> Dictionary:
	var raw: Variant = question.get("feedback", {})
	return (raw as Dictionary).duplicate(true) if typeof(raw) == TYPE_DICTIONARY else {}


static func _feedback_keys(question: Dictionary) -> Array[String]:
	var result: Array[String] = []
	var answers: Variant = question.get("answers", [])
	if typeof(answers) == TYPE_ARRAY:
		for raw_answer in answers as Array:
			if typeof(raw_answer) != TYPE_DICTIONARY:
				continue
			var key := str((raw_answer as Dictionary).get("feedback", "wrong"))
			if not result.has(key):
				result.append(key)
	if result.is_empty():
		result = ["correct", "wrong"]
	return result


static func _feedback_lines(feedback: Dictionary, feedback_key: String) -> Array[Dictionary]:
	var raw: Variant = feedback.get(feedback_key, null)
	if raw == null and feedback_key != "wrong":
		raw = feedback.get("wrong", null)
	var lines := _normalise_dialogue_lines(raw)
	if lines.is_empty():
		lines.append({"text": "¡Correcto!" if feedback_key == "correct" else "No era esa.", "expression": "happy" if feedback_key == "correct" else "thoughtful"})
	return lines


static func _first_feedback_line(feedback: Dictionary, feedback_key: String) -> Dictionary:
	var lines := _feedback_lines(feedback, feedback_key)
	return lines[0] if not lines.is_empty() else {}


static func _normalise_dialogue_lines(raw: Variant) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	if typeof(raw) == TYPE_DICTIONARY:
		result.append((raw as Dictionary).duplicate(true))
	elif typeof(raw) == TYPE_ARRAY:
		for item in raw as Array:
			if typeof(item) == TYPE_DICTIONARY:
				result.append((item as Dictionary).duplicate(true))
			elif typeof(item) == TYPE_STRING:
				result.append({"text": str(item)})
	elif typeof(raw) == TYPE_STRING and not str(raw).is_empty():
		result.append({"text": str(raw)})
	return result


static func _feedback_node_id(character_id: String, number: int, feedback_key: String, index: int) -> String:
	var base := "%s_q%d_%s" % [character_id, number, feedback_key]
	return base if index <= 0 else "%s_%02d" % [base, index + 1]


static func _after_node_id(character_id: String, number: int, index: int) -> String:
	return "%s_q%d_after_%02d" % [character_id, number, index + 1]


static func _following_node(character_index: int, question_index: int, question_count_value: int) -> String:
	if question_index + 1 < question_count_value:
		return "%s_q%d" % [ENCOUNTER_ORDER[character_index], question_index + 2]
	if character_index + 1 < ENCOUNTER_ORDER.size():
		return "%s_intro_01" % ENCOUNTER_ORDER[character_index + 1]
	return "__END__"


static func _display_name_for(character_id: String) -> String:
	if character_id.is_empty():
		return "Narrador"
	var encounter: Dictionary = ENCOUNTERS.get(character_id, {})
	if not encounter.is_empty():
		return str(encounter.get("name", character_id.capitalize()))
	var dm: Variant = DataAccess.dm()
	if dm != null:
		var character: Dictionary = dm.call("get_character", character_id)
		if not character.is_empty():
			return str(character.get("story_name", character.get("display_name", character.get("name", character_id.capitalize()))))
	return character_id.capitalize()


static func _default_positions(shown: Array[String]) -> Dictionary:
	var result: Dictionary = {}
	if shown.size() <= 1:
		if not shown.is_empty():
			result[shown[0]] = "center"
		return result
	if shown.size() == 2:
		result[shown[0]] = "left"
		result[shown[1]] = "right"
		return result
	var slots := ["left", "center", "right"]
	for index in range(shown.size()):
		result[shown[index]] = str(slots[mini(index, slots.size() - 1)])
	return result


static func _string_array(raw: Variant) -> Array[String]:
	var result: Array[String] = []
	if typeof(raw) == TYPE_ARRAY:
		for item in raw as Array:
			result.append(str(item))
	return result


static func _node_hidden_for_player(node: Dictionary, player_id: String) -> bool:
	if player_id.is_empty():
		return false
	var excluded := _string_array(node.get("exclude_players", []))
	if excluded.has(player_id):
		return true
	var included := _string_array(node.get("include_players", []))
	return not included.is_empty() and not included.has(player_id)


static func _default_start() -> String:
	if ENCOUNTER_ORDER.is_empty():
		return "__END__"
	return ENCOUNTER_ORDER[0] + "_intro_01"


static func _feminine_ordinal(value: int) -> String:
	if value >= 0 and value < FEMININE_ORDINALS.size():
		return FEMININE_ORDINALS[value]
	return "%d.ª" % value
