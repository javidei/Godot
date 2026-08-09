extends RefCounted
class_name DemoStory

const START := "bar_01"
const START_BY_LOCATION := {
	"casa": "casa_01",
	"bar": "bar_01",
	"calle": "calle_01"
}

const NODES := {
	"casa_01": {
		"speaker": "Narrador",
		"text": "La partida empieza en casa. Es uno de esos lugares donde una conversación normal puede acabar convirtiéndose en un plan, una discusión o las dos cosas a la vez.",
		"background": "asturias_home",
		"show": ["javi", "sue", "smokey"],
		"positions": {"javi": "left", "sue": "center", "smokey": "right"},
		"expressions": {"javi": "neutral", "sue": "neutral", "smokey": "neutral"},
		"focus": "all",
		"next": "casa_02"
	},
	"casa_02": {
		"speaker": "Javi",
		"text": "Pero vamos a ver... ¿vamos a decidir qué hacemos o vamos a seguir dándole vueltas toda la tarde?",
		"expressions": {"javi": "thoughtful", "sue": "neutral", "smokey": "neutral"},
		"focus": "javi",
		"next": "casa_03"
	},
	"casa_03": {
		"speaker": "Smokey",
		"text": "Tengo una idea.",
		"expressions": {"smokey": "confident", "javi": "annoyed", "sue": "neutral"},
		"focus": "smokey",
		"effect": {"type": "emote", "character": "smokey", "text": "!"},
		"next": "plan_choice"
	},

	"bar_01": {
		"speaker": "Narrador",
		"text": "La partida empieza en el bar. Entre conversaciones, comida y bebidas, decidir algo sencillo ya parece suficiente para abrir varias rutas distintas.",
		"background": "cafeteria",
		"show": ["javi", "sue", "smokey"],
		"positions": {"javi": "left", "sue": "center", "smokey": "right"},
		"expressions": {"javi": "neutral", "sue": "neutral", "smokey": "neutral"},
		"focus": "all",
		"next": "bar_02"
	},
	"bar_02": {
		"speaker": "Sue",
		"text": "Ya estamos... Si al final pedimos pizza, yo lo tengo claro: la número 9 sin champiñones.",
		"expressions": {"sue": "happy", "javi": "neutral", "smokey": "neutral"},
		"focus": "sue",
		"next": "bar_03"
	},
	"bar_03": {
		"speaker": "Javi",
		"text": "illo, pues decidamos ya. Esperar por esperar no mejora ningún plan.",
		"expressions": {"javi": "thoughtful", "sue": "happy", "smokey": "teasing"},
		"focus": "javi",
		"next": "plan_choice"
	},

	"calle_01": {
		"speaker": "Narrador",
		"text": "La partida empieza en la calle. No hay un destino cerrado todavía, así que cualquier propuesta puede cambiar el lugar al que termina llegando el grupo.",
		"background": "calle",
		"show": ["javi", "sue", "smokey"],
		"positions": {"javi": "left", "sue": "center", "smokey": "right"},
		"expressions": {"javi": "neutral", "sue": "neutral", "smokey": "neutral"},
		"focus": "all",
		"next": "calle_02"
	},
	"calle_02": {
		"speaker": "Smokey",
		"text": "Confía en mí. Tengo una idea.",
		"expressions": {"smokey": "confident", "sue": "annoyed", "javi": "thoughtful"},
		"focus": "smokey",
		"effect": {"type": "emote", "character": "smokey", "text": "!"},
		"next": "calle_03"
	},
	"calle_03": {
		"speaker": "Sue",
		"text": "Ya estamos... Primero dinos la idea y luego decidimos si hay que confiar en ti.",
		"expressions": {"sue": "teasing", "smokey": "laugh", "javi": "neutral"},
		"focus": "sue",
		"next": "plan_choice"
	},

	"plan_choice": {
		"speaker": "Narrador",
		"text": "El plan todavía no está decidido. ¿A quién le das espacio para marcar el siguiente paso?",
		"focus": "all",
		"choices": [
			{"label": "Preguntar a Sue qué le apetece", "next": "plan_sue", "affinity": {"sue": 1}},
			{"label": "Dejar que Smokey explique su idea", "next": "plan_smokey", "affinity": {"smokey": 1}},
			{"label": "Pedir a Javi que concrete el plan", "next": "plan_javi", "affinity": {"javi": 1}}
		]
	},
	"plan_sue": {
		"speaker": "Sue",
		"text": "Te lo dije. Si elegimos algo sencillo ahora, luego ya veremos cómo se complica solo.",
		"expressions": {"sue": "happy"},
		"focus": "sue",
		"next": "group_01"
	},
	"plan_smokey": {
		"speaker": "Smokey",
		"text": "Confía en mí. Lo importante es que el plan no sea demasiado serio.",
		"expressions": {"smokey": "laugh"},
		"focus": "smokey",
		"next": "group_01"
	},
	"plan_javi": {
		"speaker": "Javi",
		"text": "Perfecto. Una cosa cada vez y sin darle veinte vueltas. Así sí.",
		"expressions": {"javi": "happy"},
		"focus": "javi",
		"next": "group_01"
	},

	"group_01": {
		"speaker": "Narrador",
		"text": "La conversación acaba reuniendo también a Carmen, Jony y Ana. A partir de aquí, cualquiera de ellos puede acabar teniendo mucho más peso del que parecía al principio.",
		"show": ["carmen", "jony", "ana"],
		"positions": {"carmen": "left", "jony": "center", "ana": "right"},
		"expressions": {"carmen": "neutral", "jony": "neutral", "ana": "neutral"},
		"focus": "all",
		"next": "carmen_01"
	},
	"carmen_01": {
		"speaker": "Carmen",
		"text": "Como el plan incluya comer, avisad antes de pedir por todo el mundo. Yo voy con opción vegetariana.",
		"expressions": {"carmen": "neutral"},
		"focus": "carmen",
		"next": "jony_01"
	},
	"jony_01": {
		"speaker": "Jony",
		"text": "Si esto termina derivando en Pokémon o Magic, por mí bien.",
		"expressions": {"jony": "neutral"},
		"focus": "jony",
		"next": "ana_01"
	},
	"ana_01": {
		"speaker": "Ana",
		"text": "Y si acaba en libros, rol, fantasía o vampiros, tampoco suena mal.",
		"expressions": {"ana": "neutral"},
		"focus": "ana",
		"next": "final_choice"
	},
	"final_choice": {
		"speaker": "Narrador",
		"text": "Parece una decisión pequeña, pero este tipo de elecciones son las que irán cambiando relaciones, rutas y escenas más adelante.",
		"focus": "all",
		"choices": [
			{"label": "Seguir con el plan que ha salido", "next": "final_01"},
			{"label": "Dejar el plan abierto por ahora", "next": "final_02"}
		]
	},
	"final_01": {
		"speaker": "Narrador",
		"text": "El grupo se pone en marcha con un plan provisional. No parece gran cosa todavía, pero ya hay una primera decisión detrás.",
		"show": ["javi", "sue", "smokey"],
		"expressions": {"javi": "neutral", "sue": "happy", "smokey": "neutral"},
		"focus": "all",
		"next": "__END__"
	},
	"final_02": {
		"speaker": "Narrador",
		"text": "Nadie fuerza una decisión. El plan sigue abierto y, precisamente por eso, todavía puede acabar en cualquier sitio.",
		"show": ["carmen", "jony", "ana"],
		"expressions": {"carmen": "neutral", "jony": "neutral", "ana": "neutral"},
		"focus": "all",
		"next": "__END__"
	}
}
