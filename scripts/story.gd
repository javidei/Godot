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
		"background": "bar",
		"intro": [
			{"expression": "thoughtful", "text": "Soy Javi. Cuando se me mete un proyecto en la cabeza, puedo pasar horas dándole vueltas hasta que consigo verlo funcionar."},
			{"expression": "happy", "text": "Con mis amigos suelo analizar cada plan, encontrarle alguna pega y, aun así, terminar apuntándome. Supongo que esa contradicción también dice bastante de mí."}
		],
		"questions": [
			{
				"text": "Primera pregunta: ¿qué combinación de aficiones me representa mejor?",
				"choices": ["Videojuegos, informática y guitarra", "Cine, pintura y moda", "Pokémon, Magic y rol", "Senderismo, cocina y fotografía"],
				"correct": 0,
				"correct_text": "Exacto. Si hay un ordenador, un juego o una guitarra cerca, ya tienes tema conmigo.",
				"wrong_text": "No exactamente. Lo mío son los videojuegos, la informática y la guitarra. Y comer también cuenta."
			},
			{
				"text": "¿Qué frase es más probable que diga cuando algo no me cuadra?",
				"choices": ["Te lo dije.", "Pero vamos a ver...", "Confía en mí.", "Ya estamos otra vez."],
				"correct": 1,
				"correct_text": "Pero vamos a ver... esa era fácil, illo.",
				"wrong_text": "La respuesta era ‘Pero vamos a ver...’. Si después digo ‘illo’, ya no quedan dudas."
			},
			{
				"text": "Y la última: ¿cómo describirías mi forma de ser?",
				"choices": ["Sarcástico, curioso, tranquilo y cabezota", "Serio, distante y nada curioso", "Impulsivo, imprevisible y despreocupado", "Creativo, tímido y muy indeciso"],
				"correct": 0,
				"correct_text": "Me tienes bien calado. Sobre todo en lo de cabezota.",
				"wrong_text": "Casi. Soy sarcástico, curioso, tranquilo y bastante cabezota."
			}
		]
	},
	"sue": {
		"name": "Sue",
		"background": "bosque",
		"intro": [
			{"expression": "happy", "text": "Soy Sue. No necesito hacer mucho ruido para sentirme parte de un plan; me importa más que la gente a mi lado pueda ser ella misma."},
			{"expression": "thoughtful", "text": "Me gusta que las cosas tengan identidad y no parezcan copiadas de todo lo demás. Con confianza, cualquier tarde corriente puede acabar teniendo algo especial."}
		],
		"questions": [
			{
				"text": "¿Qué me gusta hacer cuando tengo tiempo para mí?",
				"choices": ["Pintar y leer fantasía", "Programar y tocar la guitarra", "Jugar a Magic y Pokémon", "Hacer senderismo y fotografía"],
				"correct": 0,
				"correct_text": "Sí. Dame pinturas o un buen libro de fantasía y ya tengo plan.",
				"wrong_text": "Te lo dije: pintar y leer fantasía. Esa era la combinación correcta."
			},
			{
				"text": "¿Qué estilo de ropa encaja más conmigo?",
				"choices": ["Deportivo y clásico", "Gótico y urbano", "Colorido con aros grandes", "Elegante y barroco"],
				"correct": 1,
				"correct_text": "Correcto: gótico y urbano, según el día y las ganas.",
				"wrong_text": "La respuesta era gótico y urbano. Ya estamos... hay que fijarse un poco más."
			},
			{
				"text": "¿Qué descripción se acerca más a mi personalidad?",
				"choices": ["Directa, divertida, observadora y con carácter", "Despreocupada, impulsiva e imprevisible", "Tranquila, sarcástica y cabezota", "Serena, tímida y muy reservada"],
				"correct": 0,
				"correct_text": "Bien. Me conoces mejor de lo que parecía.",
				"wrong_text": "Soy directa, divertida, observadora y con carácter. Para la próxima ya lo sabes."
			}
		]
	},
	"smokey": {
		"name": "Smokey",
		"background": "habitacion_fran",
		"intro": [
			{"expression": "confident", "text": "Puedes llamarme Smokey. No soy muy de presentaciones formales; prefiero que una conversación empiece sola y termine en alguna historia memorable."},
			{"expression": "laugh", "text": "A veces mis mejores recuerdos comienzan cuando nadie tenía demasiado claro qué iba a pasar. Si acabamos riéndonos, para mí el plan ya ha salido bien."}
		],
		"questions": [
			{
				"text": "Empezamos fácil: ¿cómo me llamo fuera del apodo Smokey?",
				"choices": ["Jony", "Fran", "Javi", "Juan"],
				"correct": 1,
				"correct_text": "Eso es: Fran. Aunque seguramente me oigas más veces Smokey.",
				"wrong_text": "Mi nombre es Fran. Smokey es el apodo que terminó ganando."
			},
			{
				"text": "¿Qué descripción encaja mejor con mi forma de actuar?",
				"choices": ["Despreocupado, impulsivo e imprevisible", "Directo, observador y muy organizado", "Serio, tranquilo y enemigo de improvisar", "Metódico, prudente y previsor"],
				"correct": 0,
				"correct_text": "Exacto. La improvisación también es un método, más o menos.",
				"wrong_text": "Soy despreocupado, impulsivo e imprevisible. Organizarlo todo no sería muy propio de mí."
			},
			{
				"text": "¿Qué frase encaja conmigo antes de explicar un plan?",
				"choices": ["Ya estamos...", "¿Llegué tarde?", "Confía en mí. Tengo una idea.", "Primero hacemos una lista."],
				"correct": 2,
				"correct_text": "Confía en mí. Sabía que esa la acertabas.",
				"wrong_text": "Era ‘Confía en mí. Tengo una idea’. La próxima vez quizá convenga preguntar por la idea primero."
			}
		]
	},
	"carmen": {
		"name": "Carmen",
		"background": "habitacion_fran",
		"intro": [
			{"expression": "neutral", "text": "Soy Carmen, aunque también puedes llamarme Carmela. Si alguien propone un plan con buena compañía, no suele costar mucho convencerme."},
			{"expression": "neutral", "text": "Me gusta que la gente tenga algo propio y que una tarde cualquiera pueda acabar siendo una anécdota. Los planes demasiado serios no suelen durar mucho a mi alrededor."}
		],
		"questions": [
			{
				"text": "¿Qué estoy estudiando?",
				"choices": ["Informática", "Bellas Artes", "Cine", "Diseño gráfico"],
				"correct": 2,
				"correct_text": "Cine, correcto. Algún día todo esto podría acabar en una película.",
				"wrong_text": "Estudio Cine. Tendrás que prestar más atención a los créditos."
			},
			{
				"text": "Si vamos a comer en grupo, ¿qué detalle deberías recordar?",
				"choices": ["Soy vegetariana", "No me gusta salir a comer", "Solo tomo postre", "No tomo bebidas con gas"],
				"correct": 0,
				"correct_text": "Exacto: opción vegetariana y todos contentos.",
				"wrong_text": "Soy vegetariana. Avisar antes de pedir por todo el mundo siempre ayuda."
			},
			{
				"text": "¿Qué conjunto de detalles pega más conmigo?",
				"choices": ["Ropa colorida, aros y bromas", "Gabardina negra y gafas oscuras", "Guitarra, informática y sarcasmo", "Ropa deportiva, cocina y timidez"],
				"correct": 0,
				"correct_text": "Sí: color, aros y alguna broma por el camino.",
				"wrong_text": "Ropa colorida, aros y bromas. Esa es la mezcla más Carmela."
			}
		]
	},
	"jony": {
		"name": "Jony",
		"background": "habitacion_ana",
		"intro": [
			{"expression": "neutral", "text": "Soy Jony, o Jon si quieres ahorrar una letra. Al principio puedo parecer algo reservado, pero con el tema adecuado se me pasa bastante rápido."},
			{"expression": "neutral", "text": "Cuando algo me interesa de verdad, puedo analizar hasta el último detalle y alargar la conversación más de la cuenta. Avisado quedas."}
		],
		"questions": [
			{
				"text": "¿A qué me dedico?",
				"choices": ["Informática", "Cine", "Música", "Hostelería"],
				"correct": 0,
				"correct_text": "Correcto. Informático dentro y fuera de horario.",
				"wrong_text": "Soy informático. Esa tendrás que recordarla para la próxima."
			},
			{
				"text": "¿Qué dos juegos pueden darme conversación para rato?",
				"choices": ["Ajedrez y dominó", "Pokémon y Magic", "Fútbol y tenis", "Rol y Warhammer"],
				"correct": 1,
				"correct_text": "Pokémon y Magic. Con eso has elegido una conversación larga.",
				"wrong_text": "Pokémon y Magic. La próxima pregunta quizá necesite menos maná."
			},
			{
				"text": "¿Qué comparto con Carmen a la hora de comer?",
				"choices": ["Los dos somos vegetarianos", "Los dos evitamos los postres", "Los dos odiamos salir a comer", "Los dos pedimos siempre carne"],
				"correct": 0,
				"correct_text": "Eso es. Los dos somos vegetarianos.",
				"wrong_text": "Carmen y yo somos vegetarianos. Esa era la coincidencia."
			}
		]
	},
	"ana": {
		"name": "Ana",
		"background": "habitacion_ana",
		"intro": [
			{"expression": "neutral", "text": "Soy Ana. No suelo contarlo todo de primeras; prefiero observar, coger confianza y decidir cuánto de mí enseño en cada momento."},
			{"expression": "neutral", "text": "Las historias que dejan espacio para imaginar me atrapan con facilidad. Por dentro casi siempre está pasando bastante más de lo que cuento en voz alta."}
		],
		"questions": [
			{
				"text": "¿Qué estética encaja mejor conmigo?",
				"choices": ["Gótica, witchy, vampírica y barroca", "Minimalista y deportiva", "Colorida y tropical", "Retro y futurista"],
				"correct": 0,
				"correct_text": "Sí. Si parece salido de una historia de vampiros, probablemente me interese.",
				"wrong_text": "Lo mío es lo gótico, witchy, vampírico y barroco."
			},
			{
				"text": "¿Qué grupo de aficiones es más mío?",
				"choices": ["Cine, vapeo y ropa colorida", "Libros, rol, fantasía, pole dance y arte", "Informática, guitarra y videojuegos", "Música, cocina y senderismo"],
				"correct": 1,
				"correct_text": "Exacto. Ahí hay varias formas distintas de contar o vivir una historia.",
				"wrong_text": "Libros, rol, fantasía, pole dance y arte. Esa era mi combinación."
			},
			{
				"text": "¿Qué descripción se acerca más a mi personalidad?",
				"choices": ["Sensible, impulsiva y a veces seria", "Despreocupada y siempre indiferente", "Tranquila, sarcástica y cabezota", "Extrovertida, paciente y muy práctica"],
				"correct": 0,
				"correct_text": "Sí. Has sabido mirar un poco más allá de la estética.",
				"wrong_text": "Soy sensible, impulsiva y a veces seria. No todo se ve a primera vista."
			}
		]
	},
	"argentino": {
		"name": "El Argentino",
		"background": "habitacion_argentino",
		"intro": [
			{"expression": "neutral", "text": "No soy de soltar discursos largos sobre mí. Prefiero aparecer, escuchar un rato y hablar cuando tengo algo que merece la pena decir."},
			{"expression": "neutral", "text": "Dentro del grupo suelo ir a mi ritmo. Puede que llegue con cara de saber exactamente qué ocurre, aunque muchas veces solo esté esperando a que alguien se decida."}
		],
		"questions": [
			{
				"text": "¿Qué suelo fumar cuando estoy con el grupo?",
				"choices": ["Tabaco de liar", "Puros", "Cigarrillos mentolados", "No fumo"],
				"correct": 0,
				"correct_text": "Tabaco de liar, correcto. Esa sí era una pista fácil de ver.",
				"wrong_text": "Suelo fumar tabaco de liar. La próxima vez fíjate en el cigarro."
			},
			{
				"text": "¿Qué detalles forman mi aspecto más reconocible?",
				"choices": ["Gabardina negra, gafas oscuras y tatuajes", "Ropa colorida, aros y gafas", "Estilo gótico urbano y pinturas", "Camisa rosa y un vaper"],
				"correct": 0,
				"correct_text": "Correcto. Una silueta bastante difícil de confundir.",
				"wrong_text": "Gabardina negra, gafas oscuras y tatuajes. Esa es la imagen."
			},
			{
				"text": "Cuando aparecí por primera vez, ¿qué pregunté?",
				"choices": ["¿Ya habéis pedido de comer?", "¿Llegué tarde o todavía estáis decidiendo?", "¿Quién quiere jugar a Magic?", "¿Dónde está mi vaso?"],
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
	_add_opening(nodes, "casa_01", "casa_asturias", "CASA")
	_add_opening(nodes, "bar_01", "bar", "BAR")
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


static func _following_node(character_index: int, question_index: int, question_count: int) -> String:
	if question_index + 1 < question_count:
		return "%s_q%d" % [ENCOUNTER_ORDER[character_index], question_index + 2]
	if character_index + 1 < ENCOUNTER_ORDER.size():
		return "%s_intro_01" % ENCOUNTER_ORDER[character_index + 1]
	return "__END__"
