extends RefCounted
class_name DemoStory

const START := "bar_01"
const START_BY_LOCATION := {
	"casa": "casa_01",
	"bar": "bar_01",
	"bosque": "bosque_01"
}

const ENCOUNTER_ORDER: Array[String] = ["javi", "sue", "smokey", "carmen", "jony", "ana", "argentino"]

const ENCOUNTERS := {
	"javi": {
		"name": "Javi",
		"background": "asturias_home",
		"intro": [
			{"expression": "thoughtful", "text": "Soy Javi. Normalmente voy tranquilo, pero cuando algo no tiene sentido me sale el ‘Pero vamos a ver...’ antes de poder evitarlo."},
			{"expression": "happy", "text": "Soy curioso, sarcástico y bastante cabezota. Me encantan los videojuegos, la informática, la guitarra y, para qué engañarnos, comer."}
		],
		"questions": [
			{
				"text": "Primera pregunta: ¿qué combinación de aficiones me representa mejor?",
				"choices": ["Videojuegos, informática y guitarra", "Cine, pintura y moda", "Pokémon, Magic y rol"],
				"correct": 0,
				"correct_text": "Exacto. Si hay un ordenador, un juego o una guitarra cerca, ya tienes tema conmigo.",
				"wrong_text": "No exactamente. Lo mío son los videojuegos, la informática y la guitarra. Y comer también cuenta."
			},
			{
				"text": "¿Qué frase es más probable que diga cuando algo no me cuadra?",
				"choices": ["Te lo dije.", "Pero vamos a ver...", "Confía en mí."],
				"correct": 1,
				"correct_text": "Pero vamos a ver... esa era fácil, illo.",
				"wrong_text": "La respuesta era ‘Pero vamos a ver...’. Si después digo ‘illo’, ya no quedan dudas."
			},
			{
				"text": "Y la última: ¿cómo describirías mi forma de ser?",
				"choices": ["Sarcástico, curioso, tranquilo y cabezota", "Serio, distante y nada curioso", "Impulsivo, imprevisible y despreocupado"],
				"correct": 0,
				"correct_text": "Me tienes bien calado. Sobre todo en lo de cabezota.",
				"wrong_text": "Casi. Soy sarcástico, curioso, tranquilo y bastante cabezota."
			}
		]
	},
	"sue": {
		"name": "Sue",
		"background": "asturias_home",
		"intro": [
			{"expression": "happy", "text": "Soy Susana, aunque aquí todos me llaman Sue. Soy directa, divertida y observadora; si veo algo claro, probablemente lo diga tal cual."},
			{"expression": "thoughtful", "text": "Me gusta pintar, leer fantasía y mezclar ropa gótica con un estilo más urbano. Tengo carácter, pero también sé reírme de casi todo."}
		],
		"questions": [
			{
				"text": "¿Qué me gusta hacer cuando tengo tiempo para mí?",
				"choices": ["Pintar y leer fantasía", "Programar y tocar la guitarra", "Jugar a Magic y Pokémon"],
				"correct": 0,
				"correct_text": "Sí. Dame pinturas o un buen libro de fantasía y ya tengo plan.",
				"wrong_text": "Te lo dije: pintar y leer fantasía. Esa era la combinación correcta."
			},
			{
				"text": "¿Qué estilo de ropa encaja más conmigo?",
				"choices": ["Deportivo y clásico", "Gótico y urbano", "Colorido con aros grandes"],
				"correct": 1,
				"correct_text": "Correcto: gótico y urbano, según el día y las ganas.",
				"wrong_text": "La respuesta era gótico y urbano. Ya estamos... hay que fijarse un poco más."
			},
			{
				"text": "¿Qué descripción se acerca más a mi personalidad?",
				"choices": ["Directa, divertida, observadora y con carácter", "Despreocupada, impulsiva e imprevisible", "Tranquila, sarcástica y cabezota"],
				"correct": 0,
				"correct_text": "Bien. Me conoces mejor de lo que parecía.",
				"wrong_text": "Soy directa, divertida, observadora y con carácter. Para la próxima ya lo sabes."
			}
		]
	},
	"smokey": {
		"name": "Smokey",
		"background": "cafeteria",
		"intro": [
			{"expression": "confident", "text": "Soy Fran, aunque todo el mundo me llama Smokey. Suelo ir bastante despreocupado y no necesito tener cada detalle del plan cerrado."},
			{"expression": "laugh", "text": "Soy gracioso, impulsivo e imprevisible. Si digo ‘Confía en mí, tengo una idea’, puede salir genial... o convertirse en otra historia que contar."}
		],
		"questions": [
			{
				"text": "Empezamos fácil: ¿cómo me llamo fuera del apodo Smokey?",
				"choices": ["Jony", "Fran", "Javi"],
				"correct": 1,
				"correct_text": "Eso es: Fran. Aunque seguramente me oigas más veces Smokey.",
				"wrong_text": "Mi nombre es Fran. Smokey es el apodo que terminó ganando."
			},
			{
				"text": "¿Qué descripción encaja mejor con mi forma de actuar?",
				"choices": ["Despreocupado, impulsivo e imprevisible", "Directo, observador y muy organizado", "Serio, tranquilo y enemigo de improvisar"],
				"correct": 0,
				"correct_text": "Exacto. La improvisación también es un método, más o menos.",
				"wrong_text": "Soy despreocupado, impulsivo e imprevisible. Organizarlo todo no sería muy propio de mí."
			},
			{
				"text": "¿Qué frase encaja conmigo antes de explicar un plan?",
				"choices": ["Ya estamos...", "¿Llegué tarde?", "Confía en mí. Tengo una idea."],
				"correct": 2,
				"correct_text": "Confía en mí. Sabía que esa la acertabas.",
				"wrong_text": "Era ‘Confía en mí. Tengo una idea’. La próxima vez quizá convenga preguntar por la idea primero."
			}
		]
	},
	"carmen": {
		"name": "Carmen",
		"background": "cafeteria",
		"intro": [
			{"expression": "neutral", "text": "Soy Carmen, aunque también puedes llamarme Carmela. Estudio Cine, soy vegetariana y casi siempre encuentro una excusa para bromear."},
			{"expression": "neutral", "text": "Me gusta salir, comer, vapear y la ropa colorida. Las gafas, los tatuajes y los aros o pendientes también forman parte de mi estilo."}
		],
		"questions": [
			{
				"text": "¿Qué estoy estudiando?",
				"choices": ["Informática", "Bellas Artes", "Cine"],
				"correct": 2,
				"correct_text": "Cine, correcto. Algún día todo esto podría acabar en una película.",
				"wrong_text": "Estudio Cine. Tendrás que prestar más atención a los créditos."
			},
			{
				"text": "Si vamos a comer en grupo, ¿qué detalle deberías recordar?",
				"choices": ["Soy vegetariana", "No me gusta salir a comer", "Solo tomo postre"],
				"correct": 0,
				"correct_text": "Exacto: opción vegetariana y todos contentos.",
				"wrong_text": "Soy vegetariana. Avisar antes de pedir por todo el mundo siempre ayuda."
			},
			{
				"text": "¿Qué conjunto de detalles pega más conmigo?",
				"choices": ["Ropa colorida, aros y bromas", "Gabardina negra y gafas oscuras", "Guitarra, informática y sarcasmo"],
				"correct": 0,
				"correct_text": "Sí: color, aros y alguna broma por el camino.",
				"wrong_text": "Ropa colorida, aros y bromas. Esa es la mezcla más Carmela."
			}
		]
	},
	"jony": {
		"name": "Jony",
		"background": "cafeteria",
		"intro": [
			{"expression": "neutral", "text": "Soy Jony, o Jon si quieres ahorrar una letra. Soy informático y puedo hablar bastante más de la cuenta cuando aparece alguno de mis temas favoritos."},
			{"expression": "neutral", "text": "Me gustan Pokémon y Magic, y también soy vegetariano. Con esas tres pistas ya tienes una buena parte de mi ficha."}
		],
		"questions": [
			{
				"text": "¿A qué me dedico?",
				"choices": ["Informática", "Cine", "Música"],
				"correct": 0,
				"correct_text": "Correcto. Informático dentro y fuera de horario.",
				"wrong_text": "Soy informático. Esa respuesta estaba en mi presentación."
			},
			{
				"text": "¿Qué dos juegos pueden darme conversación para rato?",
				"choices": ["Ajedrez y dominó", "Pokémon y Magic", "Fútbol y tenis"],
				"correct": 1,
				"correct_text": "Pokémon y Magic. Con eso has elegido una conversación larga.",
				"wrong_text": "Pokémon y Magic. La próxima pregunta quizá necesite menos maná."
			},
			{
				"text": "¿Qué comparto con Carmen a la hora de comer?",
				"choices": ["Los dos somos vegetarianos", "Los dos evitamos los postres", "Los dos odiamos salir a comer"],
				"correct": 0,
				"correct_text": "Eso es. Los dos somos vegetarianos.",
				"wrong_text": "Carmen y yo somos vegetarianos. Esa era la coincidencia."
			}
		]
	},
	"ana": {
		"name": "Ana",
		"background": "bosque",
		"intro": [
			{"expression": "neutral", "text": "Soy Ana. Me atrae todo lo gótico, witchy, vampírico y barroco; cuanto más misterio tenga una estética o una historia, mejor."},
			{"expression": "neutral", "text": "Me gustan los libros, los vampiros, el rol, la fantasía, el pole dance y el arte. Soy sensible e impulsiva, y a veces puedo parecer más seria de lo que estoy."}
		],
		"questions": [
			{
				"text": "¿Qué estética encaja mejor conmigo?",
				"choices": ["Gótica, witchy, vampírica y barroca", "Minimalista y deportiva", "Colorida y tropical"],
				"correct": 0,
				"correct_text": "Sí. Si parece salido de una historia de vampiros, probablemente me interese.",
				"wrong_text": "Lo mío es lo gótico, witchy, vampírico y barroco."
			},
			{
				"text": "¿Qué grupo de aficiones es más mío?",
				"choices": ["Cine, vapeo y ropa colorida", "Libros, rol, fantasía, pole dance y arte", "Informática, guitarra y videojuegos"],
				"correct": 1,
				"correct_text": "Exacto. Ahí hay varias formas distintas de contar o vivir una historia.",
				"wrong_text": "Libros, rol, fantasía, pole dance y arte. Esa era mi combinación."
			},
			{
				"text": "¿Qué descripción se acerca más a mi personalidad?",
				"choices": ["Sensible, impulsiva y a veces seria", "Despreocupada y siempre indiferente", "Tranquila, sarcástica y cabezota"],
				"correct": 0,
				"correct_text": "Sí. Has sabido mirar un poco más allá de la estética.",
				"wrong_text": "Soy sensible, impulsiva y a veces seria. No todo se ve a primera vista."
			}
		]
	},
	"argentino": {
		"name": "El Argentino",
		"background": "bosque",
		"intro": [
			{"expression": "neutral", "text": "Me llaman El Argentino. Con eso ya tienes el nombre por el que me conoce todo el grupo."},
			{"expression": "neutral", "text": "Gabardina negra, gafas oscuras y tatuajes: no es difícil reconocerme cuando aparezco. Lo de llegar cuando los demás aún están decidiendo también ayuda a que la entrada se note."}
		],
		"questions": [
			{
				"text": "¿Cómo me conoce el grupo?",
				"choices": ["Smokey", "El Argentino", "Jon"],
				"correct": 1,
				"correct_text": "El Argentino. Directo y fácil de recordar.",
				"wrong_text": "Me conocen como El Argentino. No hacía falta darle muchas vueltas."
			},
			{
				"text": "¿Qué detalles forman mi aspecto más reconocible?",
				"choices": ["Gabardina negra, gafas oscuras y tatuajes", "Ropa colorida, aros y gafas", "Estilo gótico urbano y pinturas"],
				"correct": 0,
				"correct_text": "Correcto. Una silueta bastante difícil de confundir.",
				"wrong_text": "Gabardina negra, gafas oscuras y tatuajes. Esa es la imagen."
			},
			{
				"text": "Cuando aparecí por primera vez, ¿qué pregunté?",
				"choices": ["¿Ya habéis pedido de comer?", "¿Llegué tarde o todavía estáis decidiendo?", "¿Quién quiere jugar a Magic?"],
				"correct": 1,
				"correct_text": "Exacto. Y, por supuesto, todavía seguían decidiendo.",
				"wrong_text": "Pregunté si había llegado tarde o si todavía estaban decidiendo. Seguían decidiendo."
			}
		]
	}
}

static var NODES: Dictionary = _build_nodes()


static func _build_nodes() -> Dictionary:
	var nodes: Dictionary = {}
	_add_opening(nodes, "casa_01", "asturias_home", "CASA")
	_add_opening(nodes, "bar_01", "cafeteria", "BAR")
	_add_opening(nodes, "bosque_01", "bosque", "BOSQUE")

	for character_index in range(ENCOUNTER_ORDER.size()):
		var character_id: String = ENCOUNTER_ORDER[character_index]
		var encounter: Dictionary = ENCOUNTERS[character_id]
		var display_name := str(encounter.get("name", character_id.capitalize()))
		var chapter := "ENCUENTRO %d/7 · %s" % [character_index + 1, display_name.to_upper()]
		var intro_lines: Array = encounter.get("intro", [])
		for intro_index in range(intro_lines.size()):
			var line: Dictionary = intro_lines[intro_index]
			var node_id := "%s_intro_%02d" % [character_id, intro_index + 1]
			var next_id := "%s_intro_%02d" % [character_id, intro_index + 2] if intro_index + 1 < intro_lines.size() else "%s_q1" % character_id
			var node := _single_character_node(character_id, display_name, str(line.get("text", "")), next_id, chapter)
			node["expressions"] = {character_id: str(line.get("expression", "neutral"))}
			if character_index > 0 and intro_index == 0:
				node["background"] = str(encounter.get("background", "cafeteria"))
			nodes[node_id] = node

		var questions: Array = encounter.get("questions", [])
		for question_index in range(questions.size()):
			var question: Dictionary = questions[question_index]
			var number := question_index + 1
			var question_id := "%s_q%d" % [character_id, number]
			var correct_feedback_id := "%s_q%d_correct" % [character_id, number]
			var wrong_feedback_id := "%s_q%d_wrong" % [character_id, number]
			var question_node := _single_character_node(
				character_id,
				display_name,
				str(question.get("text", "")),
				"",
				"%s · PREGUNTA %d/3" % [chapter, number]
			)
			question_node.erase("next")
			question_node["question_character"] = character_id
			question_node["question_number"] = number
			question_node["choices"] = []
			var labels: Array = question.get("choices", [])
			var correct_index := int(question.get("correct", 0))
			for choice_index in range(labels.size()):
				var is_correct := choice_index == correct_index
				var choice := {
					"label": str(labels[choice_index]),
					"next": correct_feedback_id if is_correct else wrong_feedback_id
				}
				if is_correct:
					choice["affinity"] = {character_id: 1}
				question_node["choices"].append(choice)
			nodes[question_id] = question_node

			var following_id := _following_node(character_index, question_index, questions.size())
			var correct_node := _single_character_node(character_id, display_name, str(question.get("correct_text", "¡Correcto!")), following_id, chapter)
			correct_node["expressions"] = {character_id: "happy"}
			correct_node["answer_result"] = "correct"
			nodes[correct_feedback_id] = correct_node
			var wrong_node := _single_character_node(character_id, display_name, str(question.get("wrong_text", "No era esa.")), following_id, chapter)
			wrong_node["expressions"] = {character_id: "thoughtful"}
			wrong_node["answer_result"] = "wrong"
			nodes[wrong_feedback_id] = wrong_node

	return nodes


static func _add_opening(nodes: Dictionary, node_id: String, background: String, location_name: String) -> void:
	nodes[node_id] = {
		"speaker": "Narrador",
		"text": "Empiezas en %s. Hoy conocerás al grupo de uno en uno: escucha lo que cuenta cada persona y responde tres preguntas para descubrir cuánto la conoces." % location_name.to_lower(),
		"background": background,
		"show": ["javi"],
		"positions": {"javi": "center"},
		"expressions": {"javi": "neutral"},
		"focus": "javi",
		"chapter": "ENCUENTRO 1/7 · JAVI",
		"next": "javi_intro_01"
	}


static func _single_character_node(character_id: String, speaker: String, text: String, next_id: String, chapter: String) -> Dictionary:
	var node := {
		"speaker": speaker,
		"text": text,
		"show": [character_id],
		"positions": {character_id: "center"},
		"focus": character_id,
		"chapter": chapter
	}
	if not next_id.is_empty():
		node["next"] = next_id
	return node


static func _following_node(character_index: int, question_index: int, question_count: int) -> String:
	if question_index + 1 < question_count:
		return "%s_q%d" % [ENCOUNTER_ORDER[character_index], question_index + 2]
	if character_index + 1 < ENCOUNTER_ORDER.size():
		return "%s_intro_01" % ENCOUNTER_ORDER[character_index + 1]
	return "__END__"
