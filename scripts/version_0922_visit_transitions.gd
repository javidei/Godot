extends "res://scripts/version_0919_visit_transitions.gd"

const NewGamePrelude0922 = preload("res://scripts/new_game_prelude_0922.gd")

var _next_generic_starts_black_0922 := false


# El primer texto narrativo posterior a Naranjal debe heredar el negro total del
# preludio. Así no hacemos un nuevo fundido 0 -> 1 que deje ver el mapa debajo.
func prime_next_generic_from_black() -> void:
	_next_generic_starts_black_0922 = true


func play_new_game_intro(on_finished: Callable = Callable()) -> void:
	if main == null:
		main = get_parent() as Control
	if main == null:
		if on_finished.is_valid():
			on_finished.call()
		return
	if _new_game_prelude_0917 != null and is_instance_valid(_new_game_prelude_0917):
		return

	var prelude := NewGamePrelude0922.new() as Control
	if prelude == null:
		if on_finished.is_valid():
			on_finished.call()
		return
	prelude.name = "NewGamePrelude0922"
	prelude.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	prelude.connect("prelude_finished", Callable(self, "_on_new_game_prelude_finished").bind(on_finished), CONNECT_ONE_SHOT)
	_new_game_prelude_0917 = prelude
	main.add_child(prelude)


func play_generic_transition(
	title: String,
	message: String,
	auto_continue_seconds: float = 0.0,
	on_midpoint: Callable = Callable()
) -> void:
	if not _next_generic_starts_black_0922:
		await super(title, message, auto_continue_seconds, on_midpoint)
		return
	if transition_active:
		return

	_next_generic_starts_black_0922 = false
	_ensure_runtime_overlay()
	if overlay == null:
		if on_midpoint.is_valid():
			on_midpoint.call()
		return

	transition_active = true
	continue_requested = false
	_prepare_generic_text(title, message)
	overlay.visible = true
	# El negro ya está al 100 % antes de que el preludio de Naranjal se retire.
	shade.modulate.a = 1.0
	text_box.modulate.a = 0.0
	await _fade(text_box, 1.0, 0.20)
	await _wait_for_continue_or_timeout(auto_continue_seconds)
	await _fade(text_box, 0.0, 0.16)
	if on_midpoint.is_valid():
		on_midpoint.call()
	await get_tree().process_frame
	await get_tree().process_frame
	await _fade(shade, 0.0, 0.42)
	overlay.visible = false
	transition_active = false
