extends "res://scripts/ci_character_smoke_test.gd"

# El smoke histórico conserva una guard clause de la rama 0.6. Sus contratos de
# personajes y escenas siguen siendo obligatorios en 0.7; solo este proceso de
# test presenta temporalmente 0.6.9 al script heredado.
func _initialize() -> void:
	ProjectSettings.set_setting("application/config/version", "0.6.9")
	super()
