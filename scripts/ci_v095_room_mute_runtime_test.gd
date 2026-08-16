extends SceneTree

const SOUND_ON_PATH := "res://assets/ui/icons/sound-on.svg"
const MUTED_PATH := "res://assets/ui/icons/mute.svg"
const SOUND_NODE_NAME := "MuteSoundOn096"
const MUTED_NODE_NAME := "MuteOff096"
const LEGACY_NODE_NAME := "MuteStateIcon090"


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var main_scene := load("res://scenes/main.tscn") as PackedScene
	if main_scene == null:
		_fail("No se puede cargar la escena principal")
		return
	var main := main_scene.instantiate() as Control
	if main == null:
		_fail("No se puede instanciar la escena principal")
		return
	root.add_child(main)
	for _frame in range(12):
		await process_frame

	var guard := main.get_node_or_null("Version096MuteVisualGuard")
	var audio_manager := main.get("audio_manager") as Node
	var room_button := main.find_child("RoomMasterMute084", true, false) as Button
	var menu_button := main.find_child("MasterMute084", true, false) as Button
	if guard == null or audio_manager == null or room_button == null or menu_button == null:
		_fail("No se han construido el guard y los controles de audio")
		return

	audio_manager.set("music_muted", false)
	audio_manager.set("effects_muted", false)
	audio_manager.call("_apply_audio_settings")
	guard.call("refresh_now")
	await process_frame
	await process_frame
	if not _expect_state(room_button, false):
		_fail("La habitación no muestra solo el icono de sonido cuando está activo")
		return
	if not _expect_state(menu_button, false):
		_fail("El menú no muestra solo el icono de sonido cuando está activo")
		return

	room_button.emit_signal("pressed")
	await process_frame
	await process_frame
	if not bool(audio_manager.call("is_muted")):
		_fail("Pulsar mute en la habitación no silencia el audio general")
		return
	if not _expect_state(room_button, true):
		_fail("La habitación no muestra solo el icono mute al silenciar")
		return
	if not _expect_state(menu_button, true):
		_fail("El menú no sincroniza el icono mute")
		return

	room_button.emit_signal("pressed")
	await process_frame
	await process_frame
	if bool(audio_manager.call("is_muted")):
		_fail("Pulsar de nuevo no reactiva el audio general")
		return
	if not _expect_state(room_button, false):
		_fail("La habitación no vuelve al icono de sonido")
		return
	if not _expect_state(menu_button, false):
		_fail("El menú no vuelve al icono de sonido")
		return

	print("V095 ROOM MUTE OK: dos recursos de estado, exactamente un icono visible y sin superposición.")
	quit(0)


func _expect_state(button: Button, muted: bool) -> bool:
	# Ningún icono heredado del propio Button puede seguir dibujándose.
	if button.icon != null:
		return false
	if button.get_node_or_null(LEGACY_NODE_NAME) != null:
		return false

	var sound_on := button.get_node_or_null(SOUND_NODE_NAME) as TextureRect
	var mute_off := button.get_node_or_null(MUTED_NODE_NAME) as TextureRect
	if sound_on == null or mute_off == null:
		return false
	if sound_on.texture == null or mute_off.texture == null:
		return false
	if sound_on.texture.resource_path != SOUND_ON_PATH:
		return false
	if mute_off.texture.resource_path != MUTED_PATH:
		return false

	# XOR visual: jamás pueden estar los dos visibles ni los dos ocultos.
	if sound_on.visible == mute_off.visible:
		return false
	return mute_off.visible == muted and sound_on.visible == not muted


func _fail(message: String) -> void:
	push_error("V095 ROOM MUTE FAIL: " + message)
	quit(1)
