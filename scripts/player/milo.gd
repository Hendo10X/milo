extends Node2D
class_name Milo
## Milo the dog. Drawn entirely with primitives; personality comes from a
## mood that drives the face, eyes that follow the incoming block, and
## small tweens for hops and squash-and-stretch.
##
## Milo has no physics body. He "rides" a node (the top block) and mirrors
## its transform every frame, so tower sway carries him along. Animation
## offsets are expressed in the ride's local space so hops stay upright
## relative to the block.
##
## The origin (0, 0) is between Milo's feet.

enum Mood { IDLE, HAPPY, EXCITED, WORRIED, SCARED, DEAD }

const BODY_W := 46.0
const BODY_H := 26.0
const LEG_H := 10.0
const LEG_W := 6.0
const LEG_X := [-17.0, -8.0, 8.0, 17.0]
const PRE_JUMP_HEIGHT := 56.0

const COAT := Color(0.93, 0.72, 0.42)
const COAT_DARK := Color(0.62, 0.42, 0.22)
const INK := Color(0.12, 0.10, 0.10)
const EYE_WHITE := Color(0.98, 0.98, 0.95)

var mood: Mood = Mood.IDLE
## Node whose transform the eyes track (the moving block).
var look_target: Node2D = null

var _base_mood: Mood = Mood.IDLE
var _mood_timer := 0.0
var _time := 0.0

var _ride: Node2D = null
var _ride_offset := Vector2.ZERO
var _ground_position := Vector2.ZERO
var _anim_offset := Vector2.ZERO
var _anim_rotation := 0.0
var _anim_tween: Tween
var _squash_tween: Tween


# --- Riding ---------------------------------------------------------------

## Stand on nothing in particular, at a fixed global position.
func stand_at(global_pos: Vector2) -> void:
	_ride = null
	_ground_position = global_pos
	_anim_offset = Vector2.ZERO
	_anim_rotation = 0.0


## Switch to riding `node` at `offset` (node-local) while keeping Milo
## visually where he is, so a follow-up tween can settle him in.
func _ride_on(node: Node2D, offset: Vector2) -> void:
	var current := global_position
	_ride = node
	_ride_offset = offset
	_anim_offset = node.to_local(current) - offset


func _update_transform() -> void:
	if _ride != null:
		global_position = _ride.to_global(_ride_offset + _anim_offset)
		global_rotation = _ride.global_rotation + _anim_rotation
	else:
		global_position = _ground_position + _anim_offset
		global_rotation = _anim_rotation


# --- Reactions (called by the game) ----------------------------------------

## The player let go of a block: hop up so it can slide in underneath.
func on_block_dropped() -> void:
	_kill_anim()
	_anim_tween = create_tween()
	_anim_tween.tween_interval(0.18)
	_anim_tween.tween_property(self, "_anim_offset:y", -PRE_JUMP_HEIGHT, 0.28) \
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	_squash(Vector2(0.85, 1.18), 0.25)


## A block was placed: land on it.
func climb_onto(block: Block, perfect: bool) -> void:
	_kill_anim()
	_ride_on(block, Vector2(0, -block.half_height()))
	_anim_tween = create_tween()
	_anim_tween.tween_property(self, "_anim_offset", Vector2.ZERO, 0.14) \
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	_anim_tween.tween_callback(_squash.bind(Vector2(1.25, 0.72), 0.3))
	if perfect:
		_anim_tween.tween_property(self, "_anim_offset:y", -22.0, 0.12).set_ease(Tween.EASE_OUT)
		_anim_tween.tween_property(self, "_anim_offset:y", 0.0, 0.12).set_ease(Tween.EASE_IN)
		_anim_tween.tween_property(self, "_anim_offset:y", -14.0, 0.1).set_ease(Tween.EASE_OUT)
		_anim_tween.tween_property(self, "_anim_offset:y", 0.0, 0.1).set_ease(Tween.EASE_IN)
		react(Mood.EXCITED, 1.0)
	else:
		react(Mood.HAPPY, 0.5)


## The block fell away: drop back onto where we were standing.
func on_block_missed() -> void:
	_kill_anim()
	_anim_tween = create_tween()
	_anim_tween.tween_property(self, "_anim_offset", Vector2.ZERO, 0.16) \
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	_anim_tween.tween_callback(_squash.bind(Vector2(1.15, 0.85), 0.25))
	react(Mood.WORRIED, 0.8)


## Base mood from tower stability (0..100).
func set_stability(stability: float) -> void:
	if stability >= 65.0:
		_base_mood = Mood.IDLE
	elif stability >= 35.0:
		_base_mood = Mood.WORRIED
	else:
		_base_mood = Mood.SCARED
	if _mood_timer <= 0.0:
		mood = _base_mood


## Temporary expression that returns to the base mood afterwards.
func react(new_mood: Mood, duration: float) -> void:
	if mood == Mood.DEAD:
		return
	mood = new_mood
	_mood_timer = duration


## The tower collapsed under him.
func fall() -> void:
	_kill_anim()
	stand_at(global_position)
	_set_dead()
	_anim_tween = create_tween().set_parallel(true)
	_anim_tween.tween_property(self, "_anim_offset:y", 700.0, 1.2) \
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	_anim_tween.tween_property(self, "_anim_rotation", 3.4, 1.2)


## The water got him.
func drown() -> void:
	_kill_anim()
	_set_dead()
	_anim_tween = create_tween()
	_anim_tween.tween_property(self, "_anim_offset:y", 40.0, 1.4) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)


func _set_dead() -> void:
	mood = Mood.DEAD
	_base_mood = Mood.DEAD
	_mood_timer = 0.0
	look_target = null


func _kill_anim() -> void:
	if _anim_tween != null and _anim_tween.is_valid():
		_anim_tween.kill()


func _squash(to: Vector2, duration: float) -> void:
	if _squash_tween != null and _squash_tween.is_valid():
		_squash_tween.kill()
	scale = to
	_squash_tween = create_tween()
	_squash_tween.tween_property(self, "scale", Vector2.ONE, duration) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


# --- Per-frame ------------------------------------------------------------

func _process(delta: float) -> void:
	_time += delta
	if _mood_timer > 0.0:
		_mood_timer -= delta
		if _mood_timer <= 0.0 and mood != Mood.DEAD:
			mood = _base_mood
	_update_transform()
	queue_redraw()


# --- Drawing --------------------------------------------------------------

func _draw() -> void:
	var bob := 0.0
	var shiver := 0.0
	var leg_wiggle := 0.0
	match mood:
		Mood.IDLE, Mood.HAPPY:
			bob = sin(_time * 3.0) * 1.5
		Mood.EXCITED:
			bob = absf(sin(_time * 14.0)) * -3.0
			leg_wiggle = sin(_time * 24.0) * 2.0
		Mood.WORRIED:
			bob = sin(_time * 2.0) * 0.8
		Mood.SCARED:
			shiver = (randf() - 0.5) * 3.0
		Mood.DEAD:
			bob = 0.0

	var body_bottom := -LEG_H
	var body_top := body_bottom - BODY_H + bob
	var top_left := Vector2(-BODY_W * 0.5 + shiver, body_top)

	# Legs
	for i in 4:
		var x: float = LEG_X[i] - LEG_W * 0.5 + shiver
		var wiggle := leg_wiggle * (1.0 if i % 2 == 0 else -1.0)
		draw_rect(Rect2(x, body_bottom - 2.0 + bob, LEG_W, LEG_H + 2.0 - bob + wiggle), COAT_DARK)

	# Tail (wags with mood, tucked when scared or dead)
	var wag_speed := 4.0
	var wag_amount := 0.35
	match mood:
		Mood.HAPPY:
			wag_speed = 12.0
			wag_amount = 0.6
		Mood.EXCITED:
			wag_speed = 20.0
			wag_amount = 0.8
		Mood.WORRIED:
			wag_speed = 1.5
			wag_amount = 0.15
		Mood.SCARED, Mood.DEAD:
			wag_speed = 0.0
			wag_amount = 0.0
	var tail_base := Vector2(top_left.x + 1.0, body_top + BODY_H * 0.45)
	var tail_angle := PI * 0.75 + sin(_time * wag_speed) * wag_amount
	if mood == Mood.SCARED or mood == Mood.DEAD:
		tail_angle = PI * 0.5 + 0.4  # tucked down
	draw_line(tail_base, tail_base + Vector2.from_angle(tail_angle) * 14.0, COAT_DARK, 4.0)

	# Ears
	draw_rect(Rect2(top_left.x - 5.0, body_top + 3.0, 8.0, 15.0), COAT_DARK)
	draw_rect(Rect2(top_left.x + BODY_W - 3.0, body_top + 3.0, 8.0, 15.0), COAT_DARK)

	# Body
	draw_rect(Rect2(top_left, Vector2(BODY_W, BODY_H)), COAT)
	draw_rect(Rect2(top_left, Vector2(BODY_W, BODY_H)), COAT_DARK, false, 2.0)

	# Face
	var face_x := shiver
	var eye_y := body_top + 9.0
	_draw_eyes(Vector2(face_x - 11.0, eye_y), Vector2(face_x + 11.0, eye_y))
	draw_circle(Vector2(face_x, body_top + 15.0), 2.2, INK)  # nose
	var mouth := Vector2(face_x, body_top + 17.5)
	match mood:
		Mood.IDLE:
			draw_arc(mouth, 4.0, 0.3, PI - 0.3, 8, INK, 1.5)
		Mood.HAPPY:
			draw_arc(mouth, 5.0, 0.2, PI - 0.2, 8, INK, 2.0)
		Mood.EXCITED:
			draw_arc(mouth, 5.5, 0.1, PI - 0.1, 8, INK, 2.0)
			draw_rect(Rect2(mouth.x - 2.0, mouth.y + 3.0, 4.0, 5.0), Color(0.93, 0.45, 0.5))  # tongue
		Mood.WORRIED:
			draw_arc(mouth + Vector2(0, 5.0), 4.0, PI + 0.4, TAU - 0.4, 8, INK, 1.5)
		Mood.SCARED:
			draw_circle(mouth + Vector2(0, 2.0), 3.0, INK)
		Mood.DEAD:
			draw_line(mouth + Vector2(-4.0, 2.0), mouth + Vector2(4.0, 2.0), INK, 1.5)


func _draw_eyes(left: Vector2, right: Vector2) -> void:
	if mood == Mood.DEAD:
		for eye: Vector2 in [left, right]:
			draw_line(eye + Vector2(-3, -3), eye + Vector2(3, 3), INK, 2.0)
			draw_line(eye + Vector2(-3, 3), eye + Vector2(3, -3), INK, 2.0)
		return

	var radius := 4.5
	var pupil := 2.2
	if mood == Mood.SCARED:
		radius = 5.5
		pupil = 1.6
	elif mood == Mood.EXCITED:
		pupil = 2.8

	# Pupils drift toward whatever Milo is watching.
	var gaze := Vector2.ZERO
	if look_target != null and is_instance_valid(look_target):
		gaze = to_local(look_target.global_position).normalized() * (radius - pupil - 0.3)
	elif mood == Mood.WORRIED:
		gaze = Vector2(0, -1.5)

	for eye: Vector2 in [left, right]:
		draw_circle(eye, radius, EYE_WHITE)
		draw_circle(eye + gaze, pupil, INK)
		if mood == Mood.WORRIED or mood == Mood.SCARED:
			# Brows slanting inward
			var inward := 1.0 if eye.x < 0.0 else -1.0
			draw_line(eye + Vector2(-4.0 * inward, -7.0), eye + Vector2(4.0 * inward, -5.0), INK, 2.0)
