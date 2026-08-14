extends "res://scripts/ci_v070_save_slots_smoke_test.gd"

func _initialize() -> void:
	# El test base protege el contrato funcional de los slots introducido en 0.7
	# y conserva una guard clause histórica para esa rama. En 0.8 seguimos
	# validando exactamente ese contrato sobre el DataManager actualizado.
	ProjectSettings.set_setting("application/config/version", "0.7.0")
	super()
