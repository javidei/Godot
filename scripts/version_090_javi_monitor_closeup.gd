extends "res://scripts/version_081_javi_monitor_closeup.gd"

const PIXEL_ADVENTURE_ENTRE_LINEAS_URL := "https://javidei.github.io/pixel-adventure/?source=entre-lineas"


func _open_pixel_adventure() -> void:
	if OS.has_feature("web"):
		var open_script := "window.__pixelAdventureTab = window.open('" + PIXEL_ADVENTURE_ENTRE_LINEAS_URL + "', '_blank'); if (window.__pixelAdventureTab) { window.__pixelAdventureTab.focus(); }"
		JavaScriptBridge.eval(open_script, true)
		return
	OS.shell_open(PIXEL_ADVENTURE_URL)


func _is_javi_room_active() -> bool:
	if not super():
		return false

	# Mientras haya respuestas en pantalla, el hotspot de los monitores no debe
	# recibir clics. Parte del polígono queda bajo la columna izquierda de opciones
	# y podía abrir accidentalmente el primer plano al elegir una respuesta.
	if main != null:
		var choices := main.get("choices_box") as Control
		if choices != null and choices.visible:
			return false

	var raw_state: Variant = main.get("state") if main != null else {}
	if typeof(raw_state) != TYPE_DICTIONARY:
		return false
	var progress: Variant = (raw_state as Dictionary).get("narrative_progress", {})
	if typeof(progress) != TYPE_DICTIONARY:
		return false
	return int((progress as Dictionary).get("current_day", 1)) == 3
