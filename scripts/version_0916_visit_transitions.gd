extends "res://scripts/version_098_visit_transitions.gd"

const NewGamePrelude0916 = preload("res://scripts/new_game_prelude_0916.gd")

var _new_game_prelude_0916: Control


func play_new_game_intro(on_finished: Callable = Callable()) -> void:
	if main == null:
		main = get_parent() as Control
	if main == null:
		if on_finished.is_valid():
			on_finished.call()
		return
	if _new_game_prelude_0916 != null and is_instance_valid(_new_game_prelude_0916):
		return

	var prelude := NewGamePrelude0916.new() as Control
	if prelude == null:
		play_generic_transition(NEW_GAME_INTRO_TITLE, NEW_GAME_INTRO_TEXT, 0.0, on_finished)
		return
	prelude.name = "NewGamePrelude0916"
	prelude.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	prelude.connect("prelude_finished", Callable(self, "_on_new_game_prelude_finished").bind(on_finished), CONNECT_ONE_SHOT)
	_new_game_prelude_0916 = prelude
	main.add_child(prelude)


func _on_new_game_prelude_finished(on_finished: Callable) -> void:
	_new_game_prelude_0916 = null
	# Conservamos también la transición narrativa previa a la selección de
	# protagonista; solo hemos desplazado Portugal y Naranjal al momento correcto.
	play_generic_transition(NEW_GAME_INTRO_TITLE, NEW_GAME_INTRO_TEXT, 0.0, on_finished)
