extends Node2D
class_name Tower
## Owns the placed blocks. Computes overlap and stability, sways the whole
## stack when it gets unstable, and triggers collapse.
##
## This node sits at the centre of the ground surface and rotates around
## that point to sway, so placed blocks are children with local positions.

signal block_placed(block: Block, overlap: float, rating: Rating)
signal block_missed(block: Block)
signal stability_changed(stability: float)
signal collapsed

enum Rating { PERFECT, STABLE, UNSTABLE, CRITICAL }

# --- Overlap thresholds (design doc §5) ---------------------------------
@export var perfect_threshold := 0.90
@export var stable_threshold := 0.60
@export var unstable_threshold := 0.30
## Below this overlap the block is not placed at all; physics tips it off.
@export var miss_threshold := 0.12

# --- Stability (0..100). Collapse at 0. ---------------------------------
const STABILITY_CHANGE := {
	Rating.PERFECT: 8.0,
	Rating.STABLE: 3.0,
	Rating.UNSTABLE: -14.0,
	Rating.CRITICAL: -30.0,
}
const MISS_PENALTY := 8.0

# --- Sway --------------------------------------------------------------
## Continuous sway at zero stability, in degrees. Scales with instability².
@export var max_sway_degrees := 3.5
@export var sway_hz := 0.9
## Landing jolt: a damped spring kicked in the direction of the offset.
@export var jolt_stiffness := 60.0
@export var jolt_damping := 5.0
@export var jolt_strength := 1.4

## Ground surface, in this node's local space.
var ground_top_y := 0.0
var ground_half_width := 220.0

var blocks: Array[Block] = []
var stability := 100.0

var _sway_time := 0.0
var _jolt_angle := 0.0
var _jolt_velocity := 0.0
var _collapsed := false


func block_count() -> int:
	return blocks.size()


func top_block() -> Block:
	return blocks.back() if not blocks.is_empty() else null


## Global position of the centre of the tower's top surface.
func top_surface_global() -> Vector2:
	var top := top_block()
	if top == null:
		return to_global(Vector2(0, ground_top_y))
	return top.to_global(Vector2(0, -top.half_height()))


## 0 = rock solid, 1 = about to fall.
func instability() -> float:
	return 1.0 - stability / 100.0


func _process(delta: float) -> void:
	if _collapsed:
		return
	_sway_time += delta
	var accel := -jolt_stiffness * _jolt_angle - jolt_damping * _jolt_velocity
	_jolt_velocity += accel * delta
	_jolt_angle += _jolt_velocity * delta
	var inst := instability()
	var sway := sin(_sway_time * TAU * sway_hz) * deg_to_rad(max_sway_degrees) * inst * inst
	rotation = sway + _jolt_angle


## Called when a falling block touches the tower. Places it if the overlap
## is good enough and returns true; otherwise marks it missed and returns
## false (the block stays dynamic and falls away on its own).
func try_place(block: Block) -> bool:
	var support := top_block()
	var support_x: float
	var support_half_width: float
	var support_top_y: float
	if support == null:
		support_x = 0.0
		support_half_width = ground_half_width
		support_top_y = ground_top_y
	else:
		support_x = support.position.x
		support_half_width = support.half_width()
		support_top_y = support.position.y - support.half_height()

	var block_x := to_local(block.global_position).x
	var left := maxf(block_x - block.half_width(), support_x - support_half_width)
	var right := minf(block_x + block.half_width(), support_x + support_half_width)
	var overlap_px := right - left
	var overlap := clampf(overlap_px / minf(block.size.x, support_half_width * 2.0), 0.0, 1.0)

	if overlap < miss_threshold:
		block.miss()
		_change_stability(-MISS_PENALTY)
		block_missed.emit(block)
		if stability <= 0.0:
			collapse()
		return false

	var rating := rate(overlap)
	block.reparent(self)
	block.place()
	block.rotation = 0.0
	if rating == Rating.PERFECT and support != null:
		block_x = support_x  # snap: a perfect drop should look perfect
	block.position = Vector2(block_x, support_top_y - block.half_height())
	blocks.append(block)

	_change_stability(STABILITY_CHANGE[rating])
	_jolt_velocity += signf(block_x - support_x) * (1.0 - overlap) * jolt_strength
	block_placed.emit(block, overlap, rating)

	if stability <= 0.0:
		collapse()
	return true


func rate(overlap: float) -> Rating:
	if overlap >= perfect_threshold:
		return Rating.PERFECT
	if overlap >= stable_threshold:
		return Rating.STABLE
	if overlap >= unstable_threshold:
		return Rating.UNSTABLE
	return Rating.CRITICAL


## Unfreeze the upper part of the stack and shove it sideways.
func collapse() -> void:
	if _collapsed:
		return
	_collapsed = true
	var count := mini(blocks.size(), 12)
	var base_index := blocks.size() - count
	var lean: float = blocks.back().position.x - blocks[base_index].position.x
	var dir := 1.0
	if absf(lean) > 1.0:
		dir = signf(lean)
	elif rotation != 0.0:
		dir = signf(rotation)
	for i in count:
		var block := blocks[base_index + i]
		block.release()
		var height_factor := float(i + 1) / float(count)
		block.apply_impulse(Vector2(dir * 90.0 * height_factor, -30.0 * height_factor))
		block.apply_torque_impulse(dir * 400.0 * height_factor)
	collapsed.emit()


func _change_stability(amount: float) -> void:
	stability = clampf(stability + amount, 0.0, 100.0)
	stability_changed.emit(stability)
