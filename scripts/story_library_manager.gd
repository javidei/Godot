extends Node

const DATA_PATH := "res://data/story_library.json"
const BACK_ICON_PATH := "res://assets/ui/icons/arrow-left.svg"
const GOLD := Color("e8b86a")
const TEXT := Color("f2eee8")
const TEXT_DIM := Color("aaa39a")
const STORY_BG := Color(0.0, 0.0, 0.0, 1.0)

var main: Control
var menu_screen: Control
var menu_content: VBoxContainer
var menu_scroll: ScrollContainer
var story_row: HBoxContainer

var story_screen: Control
var story_outer: MarginContainer
var story_title: Label
var story_subtitle: Label
var story_scroll: ScrollContainer
var story_content: VBoxContainer
var story_gallery: GridContainer
var story_gallery_caption: Label
var story_body: RichTextLabel
var back_button: Button
var footer_hint: Label

var stories: Dictionary = {}
var current_story_id := ""


func _ready() -> void:
	# El menú se termina de componer por varios managers históricos. Esperamos a
	# Extras para insertar esta biblioteca sobre la estructura final, no sobre
	# una versión intermedia que después vuelva a reordenarse.
	for _i in range(28):
		await get_tree().process_frame

	main = get_parent() as Control
	if main == null:
		return

	menu_screen = main.get("menu_screen") as Control
	menu_content = main.get("menu_content") as VBoxContainer
	if menu_screen == null or menu_content == null:
		push_error("StoryLibraryManager: no se ha podido localizar el menú principal")
		return

	_load_library()
	_wrap_main_menu_for_growth()
	_add_story_actions()
	_build_story_screen()

	get_viewport().size_changed.connect(_queue_layout)
	_apply_layout()
	set_process_unhandled_input(true)


func _load_library() -> void:
	stories.clear()
	if not FileAccess.file_exists(DATA_PATH):
		push_error("StoryLibraryManager: falta " + DATA_PATH)
		return

	var file := FileAccess.open(DATA_PATH, FileAccess.READ)
	if file == null:
		push_error("StoryLibraryManager: no se ha podido abrir " + DATA_PATH)
		return

	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if typeof(parsed) != TYPE_DICTIONARY:
		push_error("StoryLibraryManager: story_library.json no contiene un objeto válido")
		return

	var raw_stories: Variant = (parsed as Dictionary).get("stories", [])
	if typeof(raw_stories) != TYPE_ARRAY:
		return

	for raw_story in raw_stories:
		if typeof(raw_story) != TYPE_DICTIONARY:
			continue
		var story := raw_story as Dictionary
		var story_id := str(story.get("id", ""))
		if not story_id.is_empty():
			stories[story_id] = story


func _wrap_main_menu_for_growth() -> void:
	if menu_content.get_parent() is ScrollContainer:
		menu_scroll = menu_content.get_parent() as ScrollContainer
		return

	menu_scroll = ScrollContainer.new()
	menu_scroll.name = "MainMenuScroll0101"
	menu_scroll.z_index = menu_content.z_index
	menu_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	menu_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	menu_scroll.scroll_deadzone = 8
	menu_scroll.mouse_filter = Control.MOUSE_FILTER_PASS

	# Conservamos la caja que los patches actuales ya han calculado.
	menu_scroll.anchor_left = menu_content.anchor_left
	menu_scroll.anchor_top = menu_content.anchor_top
	menu_scroll.anchor_right = menu_content.anchor_right
	menu_scroll.anchor_bottom = menu_content.anchor_bottom
	menu_scroll.offset_left = menu_content.offset_left
	menu_scroll.offset_top = menu_content.offset_top
	menu_scroll.offset_right = menu_content.offset_right
	menu_scroll.offset_bottom = menu_content.offset_bottom

	menu_screen.add_child(menu_scroll)
	menu_content.reparent(menu_scroll)
	menu_content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	menu_content.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	menu_content.anchor_left = 0.0
	menu_content.anchor_top = 0.0
	menu_content.anchor_right = 0.0
	menu_content.anchor_bottom = 0.0
	menu_content.offset_left = 0.0
	menu_content.offset_top = 0.0
	menu_content.offset_right = 0.0
	menu_content.offset_bottom = 0.0


func _add_story_actions() -> void:
	if stories.is_empty():
		return

	story_row = HBoxContainer.new()
	story_row.name = "MenuStoryActions0101"
	story_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	story_row.add_theme_constant_override("separation", 12)
	menu_content.add_child(story_row)

	for story_id in ["historia_asesino", "trilogia_innecesaria"]:
		if not stories.has(story_id):
			continue
		var story := stories[story_id] as Dictionary
		var label := str(story.get("menu_label", story.get("title", story_id)))
		var button := main.call("_make_button", label, false) as Button
		if button == null:
			continue
		button.name = "StoryButton_" + story_id
		button.custom_minimum_size = Vector2(0, 58)
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.add_theme_font_size_override("font_size", 15)
		button.tooltip_text = str(story.get("subtitle", "Abrir historia"))
		button.pressed.connect(_open_story.bind(story_id))
		story_row.add_child(button)

	# La fila queda inmediatamente después de las acciones secundarias
	# Pantalla completa / Extras y antes del botón Salir.
	var secondary_row := menu_content.find_child("MenuSecondaryActions045", true, false) as HBoxContainer
	if secondary_row != null:
		menu_content.move_child(story_row, secondary_row.get_index() + 1)
	else:
		var exit_button := menu_content.find_child("ExitGameButton", true, false) as Button
		if exit_button != null:
			menu_content.move_child(story_row, exit_button.get_index())

	menu_content.add_theme_constant_override("separation", 8)


func _build_story_screen() -> void:
	story_screen = Control.new()
	story_screen.name = "StoryLibraryScreen0101"
	story_screen.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	story_screen.z_index = 1200
	story_screen.visible = false
	main.add_child(story_screen)

	var background := ColorRect.new()
	background.name = "StoryBlackBackground"
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	background.color = STORY_BG
	background.mouse_filter = Control.MOUSE_FILTER_STOP
	story_screen.add_child(background)

	story_outer = MarginContainer.new()
	story_outer.name = "StoryOuterMargin"
	story_outer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	story_screen.add_child(story_outer)

	var root := VBoxContainer.new()
	root.name = "StoryRoot"
	root.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	root.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_theme_constant_override("separation", 10)
	story_outer.add_child(root)

	var header := HBoxContainer.new()
	header.name = "StoryHeader"
	header.custom_minimum_size = Vector2(0, 64)
	header.add_theme_constant_override("separation", 14)
	root.add_child(header)

	var heading_box := VBoxContainer.new()
	heading_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	heading_box.add_theme_constant_override("separation", 3)
	header.add_child(heading_box)

	story_title = Label.new()
	story_title.name = "StoryTitle"
	story_title.text = "Historia"
	story_title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	story_title.add_theme_color_override("font_color", TEXT)
	story_title.add_theme_font_size_override("font_size", 30)
	heading_box.add_child(story_title)

	story_subtitle = Label.new()
	story_subtitle.name = "StorySubtitle"
	story_subtitle.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	story_subtitle.add_theme_color_override("font_color", TEXT_DIM)
	story_subtitle.add_theme_font_size_override("font_size", 14)
	heading_box.add_child(story_subtitle)

	back_button = main.call("_make_button", "Volver", false) as Button
	if back_button == null:
		back_button = Button.new()
		back_button.text = "Volver"
	back_button.name = "StoryBackButton"
	back_button.custom_minimum_size = Vector2(142, 52)
	back_button.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	if ResourceLoader.exists(BACK_ICON_PATH):
		back_button.icon = ResourceLoader.load(BACK_ICON_PATH) as Texture2D
		back_button.expand_icon = true
		back_button.icon_alignment = HORIZONTAL_ALIGNMENT_LEFT
		back_button.vertical_icon_alignment = VERTICAL_ALIGNMENT_CENTER
		back_button.add_theme_constant_override("icon_max_width", 18)
		back_button.add_theme_constant_override("h_separation", 7)
	back_button.tooltip_text = "Volver al menú principal"
	back_button.pressed.connect(_close_story)
	header.add_child(back_button)

	var separator := HSeparator.new()
	separator.modulate = Color(0.55, 0.45, 0.32, 0.8)
	root.add_child(separator)

	story_scroll = ScrollContainer.new()
	story_scroll.name = "StoryScroll"
	story_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	story_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	story_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	story_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	story_scroll.scroll_deadzone = 8
	root.add_child(story_scroll)

	story_content = VBoxContainer.new()
	story_content.name = "StoryScrollContent"
	story_content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	story_content.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	story_content.add_theme_constant_override("separation", 14)
	story_scroll.add_child(story_content)

	story_gallery = GridContainer.new()
	story_gallery.name = "StoryGallery"
	story_gallery.columns = 3
	story_gallery.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	story_gallery.add_theme_constant_override("h_separation", 12)
	story_gallery.add_theme_constant_override("v_separation", 12)
	story_content.add_child(story_gallery)

	story_gallery_caption = Label.new()
	story_gallery_caption.name = "StoryGalleryCaption"
	story_gallery_caption.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	story_gallery_caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	story_gallery_caption.add_theme_color_override("font_color", TEXT_DIM)
	story_gallery_caption.add_theme_font_size_override("font_size", 12)
	story_gallery_caption.visible = false
	story_content.add_child(story_gallery_caption)

	story_body = RichTextLabel.new()
	story_body.name = "StoryBody"
	story_body.bbcode_enabled = true
	story_body.fit_content = true
	story_body.scroll_active = false
	story_body.selection_enabled = true
	story_body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	story_body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	story_body.add_theme_color_override("default_color", TEXT)
	story_body.add_theme_font_size_override("normal_font_size", 19)
	story_body.add_theme_font_size_override("bold_font_size", 19)
	story_body.add_theme_font_size_override("italics_font_size", 19)
	story_body.add_theme_constant_override("line_separation", 5)
	story_content.add_child(story_body)

	footer_hint = Label.new()
	footer_hint.name = "StoryScrollHint"
	footer_hint.text = "Desplázate con la rueda, la barra o arrastrando en pantalla táctil."
	footer_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	footer_hint.add_theme_color_override("font_color", Color(0.58, 0.56, 0.53, 0.88))
	footer_hint.add_theme_font_size_override("font_size", 11)
	root.add_child(footer_hint)


func _open_story(story_id: String) -> void:
	if not stories.has(story_id) or story_screen == null:
		return

	var story := stories[story_id] as Dictionary
	var content_file := str(story.get("content_file", ""))
	var body := ""
	if not content_file.is_empty() and FileAccess.file_exists(content_file):
		var file := FileAccess.open(content_file, FileAccess.READ)
		if file != null:
			body = file.get_as_text()

	if body.is_empty():
		body = "[center][i]Esta historia todavía no tiene texto disponible.[/i][/center]"

	current_story_id = story_id
	story_title.text = str(story.get("title", story_id))
	story_subtitle.text = str(story.get("subtitle", ""))
	story_body.text = body
	_populate_gallery(story)

	menu_screen.visible = false
	story_screen.visible = true
	story_scroll.scroll_vertical = 0
	back_button.grab_focus()
	_apply_layout()


func _populate_gallery(story: Dictionary) -> void:
	for child in story_gallery.get_children():
		story_gallery.remove_child(child)
		child.queue_free()

	var raw_images: Variant = story.get("images", [])
	if typeof(raw_images) == TYPE_ARRAY:
		for raw_path in raw_images:
			var path := str(raw_path)
			if path.is_empty() or not ResourceLoader.exists(path):
				continue
			var image := TextureRect.new()
			image.custom_minimum_size = Vector2(0, 250)
			image.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			image.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			image.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			image.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
			image.texture = ResourceLoader.load(path) as Texture2D
			image.mouse_filter = Control.MOUSE_FILTER_IGNORE
			story_gallery.add_child(image)

	var caption := str(story.get("image_caption", ""))
	story_gallery.visible = story_gallery.get_child_count() > 0
	story_gallery_caption.text = caption
	story_gallery_caption.visible = story_gallery.visible and not caption.is_empty()


func _close_story() -> void:
	if story_screen == null:
		return
	story_screen.visible = false
	current_story_id = ""
	if menu_screen != null:
		menu_screen.visible = true


func _unhandled_input(event: InputEvent) -> void:
	if story_screen == null or not story_screen.visible:
		return
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_ESCAPE:
		get_viewport().set_input_as_handled()
		_close_story()


func _queue_layout() -> void:
	call_deferred("_apply_layout")


func _apply_layout() -> void:
	var viewport_size := get_viewport().get_visible_rect().size
	var portrait := viewport_size.y > viewport_size.x

	# El ScrollContainer es el dueño de la caja del menú. Los managers antiguos
	# pueden seguir tocando menu_content durante un resize; esta llamada diferida
	# es la última capa y restaura una geometría válida con scroll vertical.
	if menu_scroll != null:
		if portrait:
			menu_scroll.anchor_left = 0.07
			menu_scroll.anchor_right = 0.93
			menu_scroll.anchor_top = 0.045
			menu_scroll.anchor_bottom = 0.97
		else:
			menu_scroll.anchor_left = 0.05
			menu_scroll.anchor_right = 0.45
			menu_scroll.anchor_top = 0.035
			menu_scroll.anchor_bottom = 0.97
		menu_scroll.offset_left = 0.0
		menu_scroll.offset_top = 0.0
		menu_scroll.offset_right = 0.0
		menu_scroll.offset_bottom = 0.0

	if story_outer != null:
		var side_margin := 22 if portrait else maxi(42, int(viewport_size.x * 0.07))
		var top_margin := 18 if portrait else 26
		story_outer.add_theme_constant_override("margin_left", side_margin)
		story_outer.add_theme_constant_override("margin_right", side_margin)
		story_outer.add_theme_constant_override("margin_top", top_margin)
		story_outer.add_theme_constant_override("margin_bottom", 18 if portrait else 24)

	if story_title != null:
		story_title.add_theme_font_size_override("font_size", 24 if portrait else 30)
	if story_body != null:
		var body_size := 17 if portrait else 19
		story_body.add_theme_font_size_override("normal_font_size", body_size)
		story_body.add_theme_font_size_override("bold_font_size", body_size)
		story_body.add_theme_font_size_override("italics_font_size", body_size)
	if back_button != null:
		back_button.custom_minimum_size = Vector2(112 if portrait else 142, 48 if portrait else 52)
	if story_gallery != null:
		var image_count := story_gallery.get_child_count()
		story_gallery.columns = 1 if portrait else maxi(1, mini(3, image_count))
		for child in story_gallery.get_children():
			if child is TextureRect:
				(child as TextureRect).custom_minimum_size.y = 310 if portrait else 250
