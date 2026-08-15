extends SceneTree

const EXPECTED_HOLD_SECONDS := 2.65
const EXPECTED_ICON_WIDTH := 30

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var audio_source := FileAccess.get_file_as_string("res://scripts/version_090_unified_audio_manager.gd")
	var splash_source := FileAccess.get_file_as_string("res://scripts/naranjal_studio_splash.gd")
	if not audio_source.contains("MUTE_ICON_MAX_WIDTH := %d" % EXPECTED_ICON_WIDTH):
		_fail("El icono de mute no se ha ampliado")
		return
	if not audio_source.contains("_mute_state_icon(muted)"):
		_fail("El mute no alterna iconos según el estado")
		return
	if not splash_source.contains("LOGO_HOLD_SECONDS := %.2f" % EXPECTED_HOLD_SECONDS):
		_fail("El splash no conserva los dos segundos extra")
		return
	if not splash_source.contains("prepared_main.visible = false"):
		_fail("El menú no se precarga oculto")
		return
	if not splash_source.contains("await get_tree().process_frame\n    await get_tree().process_frame"):
		_fail("El menú no espera dos frames antes de revelarse")
		return
	print("V094 STARTUP AUDIO OK: mute dual grande y menú precargado validados.")
	quit(0)

func _fail(message: String) -> void:
	push_error(message)
	quit(1)
