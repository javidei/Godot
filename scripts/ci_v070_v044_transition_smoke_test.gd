extends "res://scripts/ci_v044_transition_smoke_test.gd"

func _initialize() -> void:
	ProjectSettings.set_setting("application/config/version", "0.6.9")
	super()
