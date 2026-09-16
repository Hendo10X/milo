extends RigidBody2D
class_name Block
## One rectangular block. It lives in four phases:
##   MOVING  – frozen (kinematic); the spawner slides it left/right
##   FALLING – a normal rigid body; gravity pulls it down
##   PLACED  – frozen (static); part of the tower
##   MISSED  – landed with too little overlap; stays dynamic so physics
##             tips it off the tower and into the water

signal landed(block: Block, other: Node)

enum Phase { MOVING, FALLING, PLACED, MISSED }

const FALL_GRAVITY_SCALE := 2.6

var phase: Phase = Phase.MOVING
var size := Vector2(200, 36)
var color := Color(0.95, 0.55, 0.3)

@onready var shape: CollisionShape2D = $Shape


func _ready() -> void:
	freeze_mode = RigidBody2D.FREEZE_MODE_KINEMATIC
	freeze = true
	gravity_scale = FALL_GRAVITY_SCALE
	contact_monitor = true
	max_contacts_reported = 4
	body_entered.connect(_on_body_entered)


func setup(width: float, height: float, tint: Color) -> void:
	size = Vector2(width, height)
	color = tint
	var rect := RectangleShape2D.new()
	rect.size = size
	shape.shape = rect
	queue_redraw()


func half_width() -> float:
	return size.x * 0.5


func half_height() -> float:
	return size.y * 0.5


## Let go: gravity takes over.
func drop() -> void:
	if phase != Phase.MOVING:
		return
	phase = Phase.FALLING
	freeze = false
	linear_velocity = Vector2.ZERO
	angular_velocity = 0.0


## Lock into the tower as a static collider.
func place() -> void:
	phase = Phase.PLACED
	freeze_mode = RigidBody2D.FREEZE_MODE_STATIC
	freeze = true
	linear_velocity = Vector2.ZERO
	angular_velocity = 0.0


## Too little overlap: leave it to physics.
func miss() -> void:
	phase = Phase.MISSED


## Tower collapse: a placed block becomes loose again.
func release() -> void:
	phase = Phase.MISSED
	freeze = false


func _on_body_entered(body: Node) -> void:
	if phase != Phase.FALLING:
		return
	# Signals fire mid physics step; defer so listeners can safely reparent/freeze.
	_emit_landed.call_deferred(body)


func _emit_landed(body: Node) -> void:
	if phase == Phase.FALLING:
		landed.emit(self, body)


func _draw() -> void:
	var r := Rect2(-size * 0.5, size)
	draw_rect(r, color)
	draw_rect(Rect2(r.position, Vector2(size.x, 4)), color.lightened(0.3))
	draw_rect(Rect2(r.position + Vector2(0, size.y - 4), Vector2(size.x, 4)), color.darkened(0.3))
	draw_rect(r, color.darkened(0.5), false, 2.0)
