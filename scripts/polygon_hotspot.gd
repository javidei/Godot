extends Control

# Control transparente con hit-test poligonal. Permite mantener un área
# interactiva irregular sin convertir todo su rectángulo envolvente en clicable.
var hit_polygon := PackedVector2Array()


func set_hit_polygon(points: PackedVector2Array) -> void:
	hit_polygon = points


func get_hit_polygon() -> PackedVector2Array:
	return hit_polygon


func _has_point(point: Vector2) -> bool:
	var count := hit_polygon.size()
	if count < 3:
		return false
	var inside := false
	var previous := count - 1
	for current in range(count):
		var a := hit_polygon[current]
		var b := hit_polygon[previous]
		if (a.y > point.y) != (b.y > point.y):
			var crossing_x := (b.x - a.x) * (point.y - a.y) / (b.y - a.y) + a.x
			if point.x < crossing_x:
				inside = not inside
		previous = current
	return inside
