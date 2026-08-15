extends "res://scripts/ci_v060_progression_smoke_test.gd"

# El smoke completo nació en 0.6 y conserva una guard clause histórica que
# exige 0.6.x. Desde 0.7 seguimos validando exactamente esas mecánicas
# heredadas, así que solo dentro de este proceso headless presentamos 0.6.9 al
# test base aunque la versión real del juego ya sea 0.7, 0.8 o 0.9.
func _initialize() -> void:
	var current_version := str(ProjectSettings.get_setting("application/config/version", ""))
	if current_version.begins_with("0.7.") or current_version.begins_with("0.8.") or current_version.begins_with("0.9."):
		ProjectSettings.set_setting("application/config/version", "0.6.9")
	super()


# Desde 0.7 Nueva partida ya no inicia el prólogo de forma inmediata: primero
# abre el selector de slots y, tras elegir uno vacío, CharacterSelectManager
# lanza exactamente la misma introducción de 2026. Validamos ambos contratos.
func _validate_new_game_intro(main: Control, transitions: Node) -> bool:
	var new_game := _find_button_with_text(main, "Nueva partida")
	var continue_game := _find_button_with_text(main, "Continuar")
	if new_game == null or not _button_has_callback(new_game, "open_new_game_slots"):
		_fail("Nueva partida no está enlazada al selector de slots 0.7+")
		return false
	if continue_game == null or not _button_has_callback(continue_game, "continue_last_slot"):
		_fail("Continuar no está enlazado al último slot utilizado")
		return false
	if _button_has_callback(new_game, "_begin_new_game") or _button_has_callback(continue_game, "_begin_new_game"):
		_fail("El menú salta el selector de slots o reproduce el prólogo al continuar")
		return false

	intro_callback_called = false
	transitions.call("set_fast_mode", false)
	transitions.call("play_new_game_intro", Callable(self, "_on_intro_finished"))
	var waited := 0
	while not bool(transitions.get("waiting_for_continue")) and waited < 180:
		await process_frame
		waited += 1
	var name_label: Variant = transitions.get("name_label")
	var message_label: Variant = transitions.get("message_label")
	if intro_callback_called or not bool(transitions.get("waiting_for_continue")):
		_fail("La introducción de nueva partida avanza sin interacción")
		return false
	if name_label == null or message_label == null or name_label.visible or not str(name_label.text).is_empty() or str(message_label.text) != "Los hechos acontecieron desde 2026.":
		_fail("La introducción repite 2026 o no conserva la frase requerida")
		return false
	var click := InputEventMouseButton.new()
	click.button_index = MOUSE_BUTTON_LEFT
	click.pressed = true
	transitions.call("_on_transition_input", click)
	waited = 0
	while not intro_callback_called and waited < 180:
		await process_frame
		waited += 1
	if not intro_callback_called:
		_fail("Un clic no permite continuar la introducción")
		return false
	waited = 0
	while bool(transitions.get("transition_active")) and waited < 180:
		await process_frame
		waited += 1
	if bool(transitions.get("transition_active")):
		_fail("La capa negra no termina de cerrarse después del clic")
		return false
	return true


# La 0.6.9 mantiene el smoke completo de progreso 0.6, pero el retorno desde
# las localidades temporales ahora es direccional: Triana vuelve por la derecha
# y Monte del Toro por la izquierda. El test heredado llama a este helper para
# ambos casos, así que usamos la alineación del SVG como contrato de dirección.
func _button_at_panel_bottom_right(panel: Control, button: Button) -> bool:
	var panel_rect := panel.get_global_rect()
	var button_rect := button.get_global_rect()
	var at_bottom := panel_rect.encloses(button_rect) \
		and button_rect.get_center().y > panel_rect.get_center().y \
		and panel_rect.end.y - button_rect.end.y <= 40.0
	if not at_bottom or button.icon == null:
		return false
	if button.icon_alignment == HORIZONTAL_ALIGNMENT_RIGHT:
		# Triana -> Naranjal: esquina inferior derecha, flecha a la derecha.
		return panel_rect.end.x - button_rect.end.x <= 40.0
	if button.icon_alignment == HORIZONTAL_ALIGNMENT_LEFT:
		# Monte del Toro -> Naranjal: esquina inferior izquierda, flecha a la izquierda.
		return button_rect.position.x - panel_rect.position.x <= 40.0
	return false
