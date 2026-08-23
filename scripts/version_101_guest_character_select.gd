extends "res://scripts/version_0922_character_select_manager.gd"

const GUEST_PROFILE_101 := {
	"id": "custom",
	"name": "Invitado",
	"display_name": "Invitado",
	"gender": "No especificar",
	"appearance": "",
	"role": "invitado",
	"custom": true,
	"guest": true
}


# El selector de personaje deja de formar parte de una run nueva. Tras elegir
# slot, el jugador entra siempre como Invitado. El reparto completo sigue
# disponible, aunque la run usa por defecto el subconjunto configurado en datos.
func _begin_new_game() -> void:
	_pending_new_game_prelude_0919 = true
	_start_guest_run_101()


# Compatibilidad con botones antiguos (por ejemplo «Jugar de nuevo») que aún
# puedan apuntar al antiguo selector antes de que SaveSlots los reconfigure.
func open_selection() -> void:
	if main != null:
		var slots := main.get_node_or_null("SaveSlotsManager")
		if slots != null and slots.has_method("open_new_game_slots") and slots.get("slots_screen") != null:
			slots.call("open_new_game_slots")
			return
	_pending_new_game_prelude_0919 = true
	_start_guest_run_101()


func _show_character_selection() -> void:
	_start_guest_run_101()


func _show_creation() -> void:
	_start_guest_run_101()


func _confirm_custom_character() -> void:
	_start_guest_run_101()


func _start_guest_run_101() -> void:
	pending_profile = GUEST_PROFILE_101.duplicate(true)
	_start_game()
