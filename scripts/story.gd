extends RefCounted
class_name DemoStory

const START := "intro_01"

const NODES := {
	"intro_01": {
		"speaker": "Narrador",
		"text": "La tarde se ha alargado más de la cuenta. Fuera ya es de noche, pero nadie parece tener demasiada prisa por marcharse.",
		"background": "cafeteria",
		"show": ["javi", "sue", "smokey"],
		"positions": {"javi": "left", "sue": "center", "smokey": "right"},
		"expressions": {"javi": "neutral", "sue": "neutral", "smokey": "neutral"},
		"focus": "all",
		"next": "intro_02"
	},
	"intro_02": {
		"speaker": "Javi",
		"text": "A ver... creo que por fin me sale sin equivocarme.",
		"expressions": {"javi": "thoughtful"},
		"focus": "javi",
		"effect": {"type": "sfx", "text": "RAS RAS", "sfx": "strum"},
		"next": "intro_03"
	},
	"intro_03": {
		"speaker": "Smokey",
		"text": "Eso has dicho las tres últimas veces. Pero adelante, sorpréndenos.",
		"expressions": {"smokey": "teasing", "javi": "embarrassed"},
		"focus": "smokey",
		"effect": {"type": "emote", "character": "javi", "text": "!"},
		"next": "intro_04"
	},
	"intro_04": {
		"speaker": "Sue",
		"text": "Yo voto por darle una oportunidad. Como salga mal, hacemos como que no ha pasado.",
		"expressions": {"sue": "happy", "smokey": "laugh"},
		"focus": "sue",
		"next": "choice_01"
	},
	"choice_01": {
		"speaker": "Narrador",
		"text": "La conversación se queda suspendida un instante. ¿Qué haces?",
		"focus": "all",
		"choices": [
			{"label": "Escuchar a Javi", "next": "javi_route_01", "affinity": {"javi": 1}},
			{"label": "Preguntarle a Smokey", "next": "smokey_route_01", "affinity": {"smokey": 1}},
			{"label": "Sentarte junto a Sue", "next": "sue_route_01", "affinity": {"sue": 1}}
		]
	},
	"javi_route_01": {
		"speaker": "Javi",
		"text": "Vale. Pero si fallo en el estribillo, oficialmente era una versión alternativa.",
		"expressions": {"javi": "embarrassed", "sue": "happy", "smokey": "neutral"},
		"focus": "javi",
		"effect": {"type": "sfx", "text": "TRIN", "sfx": "strum"},
		"next": "converge_01"
	},
	"smokey_route_01": {
		"speaker": "Smokey",
		"text": "¿Mi opinión profesional? Necesitamos café. Mucho café. Y quizá un plan B.",
		"expressions": {"smokey": "teasing", "javi": "thoughtful", "sue": "happy"},
		"focus": "smokey",
		"effect": {"type": "emote", "character": "smokey", "text": "!"},
		"next": "converge_01"
	},
	"sue_route_01": {
		"speaker": "Sue",
		"text": "Buena elección. Desde aquí se ve mejor el desastre antes de que ocurra.",
		"expressions": {"sue": "happy", "smokey": "laugh", "javi": "embarrassed"},
		"focus": "sue",
		"effect": {"type": "zoom", "character": "sue", "text": "!"},
		"next": "converge_01"
	},
	"converge_01": {
		"speaker": "Narrador",
		"text": "Un acorde torcido rompe la solemnidad del momento. Durante medio segundo, nadie dice nada.",
		"expressions": {"javi": "embarrassed", "sue": "annoyed", "smokey": "laugh"},
		"focus": "all",
		"effect": {"type": "shake", "text": "CLONK!", "sfx": "clonk"},
		"next": "converge_02"
	},
	"converge_02": {
		"speaker": "Smokey",
		"text": "La versión alternativa. Claramente.",
		"expressions": {"smokey": "teasing", "javi": "embarrassed", "sue": "happy"},
		"focus": "smokey",
		"next": "choice_02"
	},
	"choice_02": {
		"speaker": "Sue",
		"text": "Queda el último café. Decisión importante: ¿para quién?",
		"focus": "sue",
		"choices": [
			{"label": "Dárselo a Sue", "next": "coffee_sue", "affinity": {"sue": 1}},
			{"label": "Dárselo a Javi", "next": "coffee_javi", "affinity": {"javi": 1}},
			{"label": "Dárselo a Smokey", "next": "coffee_smokey", "affinity": {"smokey": 1}}
		]
	},
	"coffee_sue": {
		"speaker": "Sue",
		"text": "Has tomado la decisión correcta. Lo recordaré cuando esto se convierta en una historia dramática de doce capítulos.",
		"expressions": {"sue": "happy"},
		"focus": "sue",
		"effect": {"type": "emote", "character": "sue", "text": "+1"},
		"next": "final_01"
	},
	"coffee_javi": {
		"speaker": "Javi",
		"text": "Gracias. Esto aumenta en un treinta por ciento la probabilidad de que el siguiente acorde sea el correcto.",
		"expressions": {"javi": "neutral"},
		"focus": "javi",
		"effect": {"type": "emote", "character": "javi", "text": "+1"},
		"next": "final_01"
	},
	"coffee_smokey": {
		"speaker": "Smokey",
		"text": "Excelente. Has entendido quién tiene ahora mismo la responsabilidad de mantener esta conversación viva.",
		"expressions": {"smokey": "laugh"},
		"focus": "smokey",
		"effect": {"type": "emote", "character": "smokey", "text": "+1"},
		"next": "final_01"
	},
	"final_01": {
		"speaker": "Narrador",
		"text": "Entre bromas, música y decisiones de dudosa importancia, la noche sigue adelante. Por ahora, esto solo ha sido el principio.",
		"expressions": {"javi": "neutral", "sue": "happy", "smokey": "neutral"},
		"focus": "all",
		"next": "__END__"
	}
}

