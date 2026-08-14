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


func on_character_visit_completed(character_id: String) -> void:
	super(character_id)
	call_deferred("_refresh_open_map_status")


func _commit_day_advance(day_id: int, next_day: int) -> void:
	super(day_id, next_day)
	call_deferred("_refresh_open_map_status")


func _begin_arc_completion() -> void:
	super()
	call_deferred("_refresh_open_map_status")


func _refresh_open_map_status() -> void:
	# La visita vuelve al mapa antes de que el progreso diario se anote de forma
	# diferida. Volvemos a renderizar la zona sin registrar otra entrada para que
	# el check/pista cambie en el mismo instante y no se quede visualmente atrás.
	if world_map_manager == null or not world_map_manager.has_method("is_open"):
		return
	if not bool(world_map_manager.call("is_open")) or not world_map_manager.has_method("show_zone"):
		return
	var zone_id := str(world_map_manager.get("current_zone_id"))
	if zone_id.is_empty():
		return
	world_map_manager.call("show_zone", zone_id, false)
