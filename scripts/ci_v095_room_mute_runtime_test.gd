extends SceneTree

const SOUND_ON_PATH := "res://assets/ui/icons/sound-on.svg"
const MUTED_PATH := "res://assets/ui/icons/mute.svg"
const ICON_NODE_NAME := "MuteStateIcon090"


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
	for _frame in range(10):
		await process_frame

	var manager := main.get_node_or_null("Version040Manager")
	var audio_manager := main.get("audio_manager") as Node
	var room_button := main.find_child("RoomMasterMute084", true, false) as Button
	var menu_button := main.find_child("MasterMute084", true, false) as Button
	if manager == null or audio_manager == null or room_button == null or menu_button == null:
		_fail("No se han construido los controles de audio unificado")
		return

	audio_manager.set("music_muted", false)
	audio_manager.set("effects_muted", false)
	audio_manager.call("_apply_audio_settings")
	manager.call("_refresh_master_ui")
	await process_frame
	if not _expect_single_icon(room_button, SOUND_ON_PATH):
		_fail("La habitación no muestra únicamente sound-on cuando el audio está activo")
		return
	if not _expect_single_icon(menu_button, SOUND_ON_PATH):
		_fail("El menú no muestra únicamente sound-on cuando el audio está activo")
		return

	room_button.emit_signal("pressed")
	await process_frame
	if not bool(audio_manager.call("is_muted")):
		_fail("Pulsar mute en la habitación no silencia el audio general")
		return
	if not _expect_single_icon(room_button, MUTED_PATH):
		_fail("La habitación no muestra únicamente mute tras silenciar")
		return
	if not _expect_single_icon(menu_button, MUTED_PATH):
		_fail("El menú no muestra únicamente mute al sincronizarse")
		return

	room_button.emit_signal("pressed")
	await process_frame
	if bool(audio_manager.call("is_muted")):
		_fail("Pulsar de nuevo el mute de habitación no reactiva el audio")
		return
	if not _expect_single_icon(room_button, SOUND_ON_PATH):
		_fail("La habitación no vuelve a mostrar únicamente sound-on")
		return
	if not _expect_single_icon(menu_button, SOUND_ON_PATH):
		_fail("El menú no vuelve a mostrar únicamente sound-on")
		return

	print("V095 ROOM MUTE OK: un solo icono visible alterna sound-on/mute en habitación y menú.")
	quit(0)


func _expect_single_icon(button: Button, expected_path: String) -> bool:
	# No puede coexistir Button.icon con el TextureRect: eso fue lo que produjo
	# visualmente dos símbolos superpuestos.
	if button.icon != null:
		return false
	var count := 0
	var icon_view: TextureRect = null
	for child in button.get_children():
		if child.name == ICON_NODE_NAME:
			count += 1
			icon_view = child as TextureRect
	if count != 1 or icon_view == null or icon_view.texture == null:
		return false
	return icon_view.texture.resource_path == expected_path


func _fail(message: String) -> void:
	push_error("V095 ROOM MUTE FAIL: " + message)
	quit(1)
