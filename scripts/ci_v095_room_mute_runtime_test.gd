extends SceneTree

const SOUND_ON_PATH := "res://assets/ui/icons/sound-on.svg"
const MUTED_PATH := "res://assets/ui/icons/mute.svg"
const LEGACY_ICON_NODE_NAME := "MuteStateIcon090"


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
	print("V095 DEBUG state before refresh master=%s music=%s effects=%s" % [str(audio_manager.call("is_muted")), str(audio_manager.call("is_music_muted")), str(audio_manager.call("is_effects_muted"))])
	manager.call("_refresh_master_ui")
	_dump_button("ROOM IMMEDIATE", room_button)
	print("V095 DEBUG state after refresh master=%s music=%s effects=%s" % [str(audio_manager.call("is_muted")), str(audio_manager.call("is_music_muted")), str(audio_manager.call("is_effects_muted"))])
	await process_frame
	print("V095 DEBUG state after frame master=%s music=%s effects=%s" % [str(audio_manager.call("is_muted")), str(audio_manager.call("is_music_muted")), str(audio_manager.call("is_effects_muted"))])
	if not _expect_single_button_icon(room_button, SOUND_ON_PATH):
		_dump_button("ROOM ACTIVE", room_button)
		_fail("La habitación no muestra únicamente sound-on cuando el audio está activo")
		return
	if not _expect_single_button_icon(menu_button, SOUND_ON_PATH):
		_dump_button("MENU ACTIVE", menu_button)
		_fail("El menú no muestra únicamente sound-on cuando el audio está activo")
		return

	room_button.emit_signal("pressed")
	await process_frame
	if not bool(audio_manager.call("is_muted")):
		_fail("Pulsar mute en la habitación no silencia el audio general")
		return
	if not _expect_single_button_icon(room_button, MUTED_PATH):
		_dump_button("ROOM MUTED", room_button)
		_fail("La habitación no cambia a mute sin superposiciones")
		return
	if not _expect_single_button_icon(menu_button, MUTED_PATH):
		_dump_button("MENU MUTED", menu_button)
		_fail("El menú no se sincroniza con el icono mute")
		return

	room_button.emit_signal("pressed")
	await process_frame
	if bool(audio_manager.call("is_muted")):
		_fail("Pulsar de nuevo el mute de habitación no reactiva el audio")
		return
	if not _expect_single_button_icon(room_button, SOUND_ON_PATH):
		_dump_button("ROOM UNMUTED", room_button)
		_fail("La habitación no vuelve a sound-on sin superposiciones")
		return
	if not _expect_single_button_icon(menu_button, SOUND_ON_PATH):
		_dump_button("MENU UNMUTED", menu_button)
		_fail("El menú no vuelve a sound-on")
		return

	print("V095 ROOM MUTE OK: un único Button.icon alterna sound-on/mute sin capas superpuestas.")
	quit(0)


func _expect_single_button_icon(button: Button, expected_path: String) -> bool:
	if button.icon == null:
		return false
	var expected := load(expected_path) as Texture2D
	if expected == null:
		return false
	if button.icon.get_rid() != expected.get_rid():
		return false
	for child in button.get_children():
		if child.name == LEGACY_ICON_NODE_NAME:
			return false
	return true


func _dump_button(prefix: String, button: Button) -> void:
	var icon_path := "<null>" if button.icon == null else button.icon.resource_path
	print("V095 DEBUG %s icon=%s children=%d" % [prefix, icon_path, button.get_child_count()])
	for child in button.get_children():
		var texture_path := ""
		if child is TextureRect and (child as TextureRect).texture != null:
			texture_path = (child as TextureRect).texture.resource_path
		print("V095 DEBUG child name=%s type=%s texture=%s" % [child.name, child.get_class(), texture_path])


func _fail(message: String) -> void:
	push_error("V095 ROOM MUTE FAIL: " + message)
	quit(1)
