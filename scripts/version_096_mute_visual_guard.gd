extends Node

const SOUND_ON_TEXTURE := preload("res://assets/ui/icons/sound-on.svg")
const MUTED_TEXTURE := preload("res://assets/ui/icons/mute.svg")

const SOUND_NODE_NAME := "MuteSoundOn096"
const MUTED_NODE_NAME := "MuteOff096"
const LEGACY_NODE_NAME := "MuteStateIcon090"
const ICON_INSET := 8.0

var main: Control
var audio_manager: Node


func _ready() -> void:
	# Este nodo debe ser la última autoridad visual del HUD. Los managers
	# heredados pueden refrescar botones durante el frame; una prioridad alta
	# hace que este guard se ejecute después y deje el estado definitivo.
	process_priority = 1000
	main = get_parent() as Control
	if main == null:
		set_process(false)
		return
	audio_manager = main.get("audio_manager") as Node
	_refresh_all()


func _process(_delta: float) -> void:
	_refresh_all()


func refresh_now() -> void:
	_refresh_all()


func _refresh_all() -> void:
	if main == null or audio_manager == null:
		return
	var muted := bool(audio_manager.call("is_muted"))
	for button_name in ["MasterMute084", "RoomMasterMute084"]:
		var button := main.find_child(button_name, true, false) as Button
		if button != null:
			_apply_state(button, muted)


func _apply_state(button: Button, muted: bool) -> void:
	# Nunca se usa Button.icon en 0.9.6. Así no puede coexistir el icono
	# heredado con los dos estados visuales gestionados por este guard.
	button.icon = null
	button.expand_icon = false
	button.text = ""
	button.tooltip_text = "Activar todo el audio" if muted else "Silenciar todo el audio"
	button.set_meta("audio_muted_visual", muted)

	# Eliminar cualquier capa del intento anterior para evitar residuos al
	# actualizar una partida ya abierta o al reconstruir controles.
	for child in button.get_children():
		if child.name == LEGACY_NODE_NAME:
			button.remove_child(child)
			child.queue_free()

	var sound_on := _ensure_icon(button, SOUND_NODE_NAME, SOUND_ON_TEXTURE)
	var mute_off := _ensure_icon(button, MUTED_NODE_NAME, MUTED_TEXTURE)

	# Regla central: exactamente uno de los dos iconos es visible.
	sound_on.visible = not muted
	mute_off.visible = muted
	sound_on.queue_redraw()
	mute_off.queue_redraw()
	button.queue_redraw()


func _ensure_icon(button: Button, node_name: String, texture: Texture2D) -> TextureRect:
	var icon := button.get_node_or_null(node_name) as TextureRect
	if icon == null:
		icon = TextureRect.new()
		icon.name = node_name
		icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
		button.add_child(icon)
		icon.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		icon.offset_left = ICON_INSET
		icon.offset_top = ICON_INSET
		icon.offset_right = -ICON_INSET
		icon.offset_bottom = -ICON_INSET
	icon.texture = texture
	return icon
