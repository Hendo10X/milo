extends Node2D
class_name BlockSpawner
## Creates blocks, slides the current one left/right, drops it on input and
## hands landed blocks to the Tower. Sits at the well centre (same origin
## as the tower), so local x is the distance from the centre of the well.

signal block_spawned(block: Block)
signal block_dropped(block: Block)

const BLOCK_SCENE := preload("res://scenes/blocks/Block.tscn")
const BLOCK_HEIGHT := 36.0
const SPAWN_HEIGHT_ABOVE_TOWER := 380.0
const RESPAWN_DELAY := 0.25
## How far below the tower top a loose block may fall before we free it.
const LOOSE_CLEANUP_DISTANCE := 1400.0

const PALETTE: Array[Color] = [
	Color("#f4a259"), Color("#f25f5c"), Color("#70c1b3"),
	Color("#ffe066"), Color("#b388eb"), Color("#8ac926"),
]

var tower: Tower
## The block centre may travel between these local x values.
var left_limit := -220.0
var right_limit := 220.0

var current: Block = null
var speed := 200.0
var _dir := 1.0
var _active := false
var _loose: Array[Block] = []


func start() -> void:
	_active = true
	spawn()


## Stop spawning. A block that is still sliding is removed; a falling one
## is left to finish its fall.
func stop() -> void:
	_active = false
	if current != null and current.phase == Block.Phase.MOVING:
		current.queue_free()
		current = null


func spawn() -> void:
	if not _active or current != null:
		return
	var placed := tower.block_count()
	var width := Difficulty.block_width(placed)
	speed = Difficulty.block_speed(placed)

	var block: Block = BLOCK_SCENE.instantiate()
	add_child(block)
	block.setup(width, BLOCK_HEIGHT, PALETTE[placed % PALETTE.size()])

	_dir = 1.0 if randf() < 0.5 else -1.0
	var half := width * 0.5
	var start_x := (left_limit + half) if _dir > 0.0 else (right_limit - half)
	var spawn_y := tower.top_surface_global().y - SPAWN_HEIGHT_ABOVE_TOWER
	block.position = Vector2(start_x, to_local(Vector2(0, spawn_y)).y)
	block.landed.connect(_on_block_landed)

	current = block
	block_spawned.emit(block)


func drop() -> void:
	if current == null or current.phase != Block.Phase.MOVING:
		return
	current.drop()
	block_dropped.emit(current)


func _physics_process(delta: float) -> void:
	if current != null and current.phase == Block.Phase.MOVING:
		var half := current.half_width()
		var x := current.position.x + _dir * speed * delta
		if x + half > right_limit:
			x = right_limit - half
			_dir = -1.0
		elif x - half < left_limit:
			x = left_limit + half
			_dir = 1.0
		current.position.x = x

	if not _loose.is_empty():
		var floor_y := tower.top_surface_global().y + LOOSE_CLEANUP_DISTANCE
		for block in _loose.duplicate():
			if not is_instance_valid(block) or block.global_position.y > floor_y:
				_loose.erase(block)
				if is_instance_valid(block):
					block.queue_free()


func _on_block_landed(block: Block, other: Node) -> void:
	if block != current:
		return
	# Only the tower counts: the ground or a placed block. Bouncing off a
	# loose block keeps the block FALLING so it can still land properly.
	if other is Block and (other as Block).phase != Block.Phase.PLACED:
		return
	current = null
	if not tower.try_place(block):
		_loose.append(block)
	if _active:
		get_tree().create_timer(RESPAWN_DELAY).timeout.connect(spawn)
