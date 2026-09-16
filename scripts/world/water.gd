extends Node2D
class_name Water
## Rises from the bottom of the well. Speed comes from the difficulty curve
## plus a catch-up term so the water never falls hopelessly far behind.
## Emits `reached_target` when the surface passes the tracked node (Milo).

signal reached_target

## The water will not lag more than this far below the target before
## catching up.
const CATCH_UP_GAP := 480.0
const CATCH_UP_RATE := 0.12

@export var width := 900.0
@export var depth := 2400.0

var rising := false
var base_speed := 0.0
var target: Node2D = null

var _time := 0.0
var _reached := false


## Global y of the surface (this node lives at the well origin).
func level_y() -> float:
	return position.y


func _process(delta: float) -> void:
	_time += delta
	if rising:
		var speed := base_speed
		if target != null:
			var gap := position.y - target.global_position.y
			speed += maxf(0.0, gap - CATCH_UP_GAP) * CATCH_UP_RATE
		position.y -= speed * delta
		if target != null and not _reached and position.y <= target.global_position.y - 4.0:
			_reached = true
			reached_target.emit()
	queue_redraw()


func _draw() -> void:
	var steps := 28
	var half := width * 0.5
	var surface := PackedVector2Array()
	for i in steps + 1:
		var x := -half + width * float(i) / float(steps)
		var y := sin(_time * 2.2 + x * 0.025) * 5.0 + sin(_time * 3.1 + x * 0.05) * 3.0
		surface.append(Vector2(x, y))
	var body := PackedVector2Array(surface)
	body.append(Vector2(half, depth))
	body.append(Vector2(-half, depth))
	draw_colored_polygon(body, Color(0.16, 0.45, 0.85, 0.62))
	draw_polyline(surface, Color(0.78, 0.92, 1.0, 0.85), 3.0)
