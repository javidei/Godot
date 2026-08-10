extends SceneTree

const Story = preload("res://scripts/story.gd")


func _initialize() -> void:
	var dynamic_title := Story.game_title()
	ProjectSettings.set_setting("application/config/name", dynamic_title)
	var save_error := ProjectSettings.save()
	if save_error != OK:
		push_error("No se ha podido guardar el título dinámico: %s" % error_string(save_error))
		quit(1)
		return
	print("DYNAMIC TITLE: " + dynamic_title)
	quit(0)
