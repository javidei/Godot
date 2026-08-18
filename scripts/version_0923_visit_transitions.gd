extends "res://scripts/version_0922_visit_transitions.gd"

const NewGamePrelude0923 = preload("res://scripts/new_game_prelude_0923.gd")


func play_new_game_intro(on_finished: Callable = Callable()) -> void:
    if main == null:
        main = get_parent() as Control
    if main == null:
        if on_finished.is_valid():
            on_finished.call()
        return
    if _new_game_prelude_0917 != null and is_instance_valid(_new_game_prelude_0917):
        return

    var prelude := NewGamePrelude0923.new() as Control
    if prelude == null:
        if on_finished.is_valid():
            on_finished.call()
        return

    # Conservamos el identificador histórico porque los smoke tests y la capa
    # de compatibilidad de Nueva partida lo usan como contrato interno.
    prelude.name = "NewGamePrelude0917"
    prelude.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    prelude.connect("prelude_finished", Callable(self, "_on_new_game_prelude_finished").bind(on_finished), CONNECT_ONE_SHOT)
    _new_game_prelude_0917 = prelude
    main.add_child(prelude)
