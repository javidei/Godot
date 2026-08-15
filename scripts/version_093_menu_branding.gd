extends Node

const LOGO_TEXTURE := preload("res://assets/ui/naranjal-studio-menu-white.svg")
const LOGO_RATIO := 945.0 / 964.0

var menu_screen: Control
var logo: TextureRect


func _ready() -> void:
	call_deferred("_install_branding")


func _install_branding() -> void:
	await get_tree().process_frame
	var main := get_parent()
	if main == null:
		return
	menu_screen = main.get("menu_screen") as Control
	if menu_screen == null:
		menu_screen = main.get_node_or_null("MenuScreen") as Control
	if menu_screen == null:
		await get_tree().process_frame
		menu_screen = main.get("menu_screen") as Control
	if menu_screen == null:
		push_warning("No se encontró MenuScreen para añadir el logo de Naranjal Studio.")
		return

	var existing := menu_screen.get_node_or_null("NaranjalStudioMenuLogo093") as TextureRect
	if existing != null:
		logo = existing
	else:
		logo = TextureRect.new()
		logo.name = "NaranjalStudioMenuLogo093"
		logo.texture = LOGO_TEXTURE
		logo.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		logo.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		logo.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
		logo.mouse_filter = Control.MOUSE_FILTER_IGNORE
		logo.modulate = Color(1.0, 1.0, 1.0, 0.94)
		logo.z_index = 6
		menu_screen.add_child(logo)

	if not menu_screen.resized.is_connected(_layout_logo):
		menu_screen.resized.connect(_layout_logo)
	_layout_logo()


func _layout_logo() -> void:
	if menu_screen == null or logo == null:
		return
	var viewport_size := menu_screen.size
	if viewport_size.x <= 1.0 or viewport_size.y <= 1.0:
		return

	var width := clampf(viewport_size.x * 0.085, 92.0, 146.0)
	if viewport_size.x < 800.0:
		width = 78.0
	if viewport_size.y < 600.0:
		width = minf(width, 72.0)
	var height := width * LOGO_RATIO
	var margin := clampf(viewport_size.x * 0.014, 14.0, 28.0)
	logo.size = Vector2(width, height)
	logo.position = Vector2(
		viewport_size.x - width - margin,
		viewport_size.y - height - margin
	)
