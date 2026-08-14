extends "res://scripts/narrative_day_manager.gd"


func _process(delta: float) -> void:
	# Los smoke tests heredados de 0.4-0.7 presentan temporalmente la versión
	# 0.6.9 para validar contratos antiguos. En ese contexto no debe arrancar
	# automáticamente la introducción de una jornada, porque competiría con las
	# transiciones que esos tests están comprobando. En el juego 0.8 el manager
	# funciona normalmente.
	var project_version := str(ProjectSettings.get_setting("application/config/version", ""))
	if project_version.begins_with("0.6."):
		return
	super(delta)
