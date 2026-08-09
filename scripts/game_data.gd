extends RefCounted
class_name GameData

const CHARACTER_ORDER: Array[String] = ["javi", "sue", "smokey", "carmen", "jony", "ana"]

const CHARACTERS := {
	"javi": {
		"name": "Javi",
		"alias": "Javi",
		"role": "principal",
		"summary": "Sarcástico · curioso · tranquilo · cabezota"
	},
	"sue": {
		"name": "Susana",
		"alias": "Sue",
		"role": "principal",
		"summary": "Directa · divertida · observadora · con carácter"
	},
	"smokey": {
		"name": "Fran",
		"alias": "Smokey",
		"role": "principal",
		"summary": "Gracioso · despreocupado · impulsivo · imprevisible"
	},
	"carmen": {
		"name": "Carmen",
		"alias": "Carmela",
		"role": "secundario",
		"summary": "Graciosa · estudiante de Cine · vegetariana"
	},
	"jony": {
		"name": "Jony",
		"alias": "Jon",
		"role": "secundario",
		"summary": "Informático · Pokémon · Magic · vegetariano"
	},
	"ana": {
		"name": "Ana",
		"alias": "Ana",
		"role": "secundario",
		"summary": "Gótico · libros · vampiros · rol · fantasía"
	}
}

const LOCATION_ORDER: Array[String] = ["casa", "bar", "calle"]

const LOCATIONS := {
	"casa": {
		"name": "Casa",
		"description": "Lugar habitual donde los personajes pueden hablar y tomar decisiones.",
		"background": "asturias_home",
		"chapter": "PRÓLOGO · CASA"
	},
	"bar": {
		"name": "Bar",
		"description": "Lugar donde se reúnen y ocurren conversaciones importantes o situaciones cómicas.",
		"background": "cafeteria",
		"chapter": "PRÓLOGO · BAR"
	},
	"calle": {
		"name": "Calle",
		"description": "Escenario para desplazamientos, encuentros inesperados y eventos.",
		"background": "calle",
		"chapter": "PRÓLOGO · CALLE"
	}
}


static func character_profile(character_id: String) -> Dictionary:
	var data: Dictionary = CHARACTERS.get(character_id, {})
	if data.is_empty():
		return {}
	return {
		"id": character_id,
		"name": str(data.get("name", character_id)),
		"display_name": str(data.get("alias", data.get("name", character_id))),
		"gender": "",
		"appearance": "",
		"role": str(data.get("role", "principal")),
		"custom": false
	}


static func display_name(character_id: String) -> String:
	var data: Dictionary = CHARACTERS.get(character_id, {})
	return str(data.get("alias", data.get("name", character_id.capitalize())))


static func location_name(location_id: String) -> String:
	var data: Dictionary = LOCATIONS.get(location_id, {})
	return str(data.get("name", location_id.capitalize()))


static func location_chapter(location_id: String) -> String:
	var data: Dictionary = LOCATIONS.get(location_id, {})
	return str(data.get("chapter", "PRÓLOGO"))
