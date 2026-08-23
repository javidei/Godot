extends "res://autoload/data_manager_v102.gd"


# 0.9.41: primera pasada de revisión de guion. Durante esta revisión mantenemos
# los diálogos aprobados sobre la capa de datos ya cargada para no duplicar ni
# reescribir el resto de jornadas todavía pendientes de revisar.
func get_question_bundle(character_id: String) -> Dictionary:
	var bundle := super(character_id)
	if _legacy_contract() or not _runtime_day_enabled or character_id != "javi":
		return bundle

	var result := bundle.duplicate(true)
	if _runtime_day_id == 1:
		result["intro"] = [{
			"expression": "thoughtful",
			"text": "Pasa. No mires el escritorio. Bueno, míralo, pero no preguntes."
		}]
		result["questions"] = [{
			"id": "q1",
			"text": "Estoy entre seguir con una web, coger la guitarra o echar una partida.",
			"answers": [
				{
					"text": "Vas a hacer las tres y no vas a terminar ninguna.",
					"side": "left",
					"score": 1,
					"feedback": "correct"
				},
				{
					"text": "Coge la guitarra.",
					"side": "right",
					"score": 0,
					"feedback": "wrong"
				},
				{
					"text": "Juega y mañana ya decides.",
					"side": "left",
					"score": 0,
					"feedback": "wrong"
				},
				{
					"text": "La web. Por una vez termina algo.",
					"side": "right",
					"score": 0,
					"feedback": "wrong"
				}
			],
			"feedback": {
				"correct": {
					"text": "Eso ha dolido porque es verdad.",
					"expression": "happy"
				},
				"wrong": {
					"text": "Eso sería lo sensato, sí.",
					"expression": "thoughtful"
				}
			}
		}]
		return result

	if _runtime_day_id == 2:
		result["intro"] = [{
			"expression": "thoughtful",
			"text": "Hay algo que no encaja. Podría ignorarlo, pero los dos sabemos que no va a pasar."
		}]
		return result

	return bundle
