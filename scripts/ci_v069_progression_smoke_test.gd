extends "res://scripts/ci_v060_progression_smoke_test.gd"

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
