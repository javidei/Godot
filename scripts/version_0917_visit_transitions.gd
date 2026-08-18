extends "res://scripts/version_098_visit_transitions.gd"

const NewGamePrelude0917 = preload("res://scripts/new_game_prelude_0917.gd")

var _new_game_prelude_0917: Control


func play_new_game_intro(on_finished: Callable = Callable()) -> void:
	if main == null:
		main = get_parent() as Control
	if main == null:
		if on_finished.is_valid():
			on_finished.call()
		return
	if _new_game_prelude_0917 != null and is_instance_valid(_new_game_prelude_0917):
		return

	var prelude := NewGamePrelude0917.new() as Control
	if prelude == null:
		play_generic_transition(NEW_GAME_INTRO_TITLE, NEW_GAME_INTRO_TEXT, 0.0, on_finished)
		return
	prelude.name = "NewGamePrelude0917"
	prelude.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	prelude.connect("prelude_finished", Callable(self, "_on_new_game_prelude_finished").bind(on_finished), CONNECT_ONE_SHOT)
	_new_game_prelude_0917 = prelude
	main.add_child(prelude)


func _on_new_game_prelude_finished(on_finished: Callable) -> void:
	_new_game_prelude_0917 = null
	play_generic_transition(NEW_GAME_INTRO_TITLE, NEW_GAME_INTRO_TEXT, 0.0, on_finished)
