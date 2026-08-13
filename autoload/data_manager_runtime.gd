extends "res://autoload/data_manager.gd"

# La validación base distingue recursos opcionales y valida también los datos
# nuevos. Este punto queda disponible para futuras comprobaciones de runtime.
func _validate_data() -> void:
	super._validate_data()
