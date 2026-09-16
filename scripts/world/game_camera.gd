extends Camera2D
class_name GameCamera
## Follows the target (Milo) upward, smoothly and never back down, so the
## bottom of the well slides out of view as the tower grows. A small,
## continuous shake is applied while the tower is unstable, plus one-off
## kicks on bad landings.

## Target sits this many px below the screen centre, leaving room above
## for the incoming block.
@export var target_screen_offset := 170.0
@export var follow_speed := 4.0

var target: Node2D = null
## Continuous shake radius in px (set by the game from tower instability).
var shake_amount := 0.0

var _follow_y := 0.0
var _kick := 0.0


func _ready() -> void:
	_follow_y = position.y


func kick(amount: float) -> void:
	_kick = maxf(_kick, amount)


func _process(delta: float) -> void:
	if target != null:
		var desired := minf(target.global_position.y - target_screen_offset, _follow_y)
		_follow_y = lerpf(_follow_y, desired, 1.0 - exp(-follow_speed * delta))
	position.y = _follow_y

	_kick = lerpf(_kick, 0.0, 1.0 - exp(-6.0 * delta))
	var radius := shake_amount + _kick
	if radius > 0.05:
		offset = Vector2(randf_range(-1.0, 1.0), randf_range(-1.0, 1.0)) * radius
	else:
		offset = Vector2.ZERO
