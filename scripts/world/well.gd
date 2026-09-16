extends Node2D
class_name Well
## Draws the well: a brick back wall that repeats forever as the camera
## climbs, thick side walls, and the ground slab at the bottom. The Ground
## StaticBody2D child is what the first block lands on.

const BRICK_H := 28.0
const BRICK_W := 56.0

@export var inner_half_width := 220.0

var camera: Camera2D

var _back_color := Color(0.13, 0.15, 0.21)
var _mortar_color := Color(0.09, 0.10, 0.15)
var _wall_color := Color(0.05, 0.06, 0.09)
var _wall_edge_color := Color(0.25, 0.27, 0.35)
var _ground_color := Color(0.22, 0.18, 0.15)


func _process(_delta: float) -> void:
	queue_redraw()


func _draw() -> void:
	var view_h := get_viewport_rect().size.y
	var cam_y := camera.global_position.y if camera != null else 0.0
	var top := cam_y - view_h
	var bottom := cam_y + view_h
	var w := inner_half_width * 2.0

	# Back wall with staggered bricks.
	draw_rect(Rect2(-inner_half_width, top, w, bottom - top), _back_color)
	var first_row := floori(top / BRICK_H)
	var last_row := ceili(bottom / BRICK_H)
	for row in range(first_row, last_row):
		var y := row * BRICK_H
		draw_line(Vector2(-inner_half_width, y), Vector2(inner_half_width, y), _mortar_color, 2.0)
		var x := -inner_half_width + (BRICK_W * 0.5 if posmod(row, 2) == 1 else 0.0)
		while x < inner_half_width:
			draw_line(Vector2(x, y), Vector2(x, y + BRICK_H), _mortar_color, 2.0)
			x += BRICK_W

	# Side walls, extended far out so wide windows never show the void.
	draw_rect(Rect2(-inner_half_width - 3000.0, top, 3000.0, bottom - top), _wall_color)
	draw_rect(Rect2(inner_half_width, top, 3000.0, bottom - top), _wall_color)
	draw_line(Vector2(-inner_half_width, top), Vector2(-inner_half_width, bottom), _wall_edge_color, 4.0)
	draw_line(Vector2(inner_half_width, top), Vector2(inner_half_width, bottom), _wall_edge_color, 4.0)

	# Ground slab.
	draw_rect(Rect2(-inner_half_width, 0.0, w, 400.0), _ground_color)
	draw_line(Vector2(-inner_half_width, 0.0), Vector2(inner_half_width, 0.0), _ground_color.lightened(0.35), 4.0)
