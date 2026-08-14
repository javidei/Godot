extends "res://scripts/ci_v069_progression_smoke_test.gd"

# El smoke heredado 0.6 valida mecánicas que siguen vigentes en 0.7, pero su
# guard clause exige literalmente una versión 0.6.x. Solo dentro de este proceso
# headless presentamos 0.6.9 al test heredado; el proyecto/export real conserva
# siempre su versión 0.7.x.
func _initialize() -> void:
	ProjectSettings.set_setting("application/config/version", "0.6.9")
	super()
