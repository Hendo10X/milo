extends Node
## Developer helpers driven by command-line user args (after "--"):
##
##   godot --path . -- --autoplay
##       Start immediately and drop blocks automatically, with a little
##       random error, so the whole loop runs without a human.
##   godot --path . -- --autoplay --screenshot=C:/tmp/milo.png --frames=400
##       Also save a screenshot after N frames and quit.
##   --error=140
##       Widen the autoplay's random drop error (default 70 px) to force
##       unstable drops, misses and collapses.
##
## Removing this node from Main.tscn removes the feature entirely.


var _autoplay := false
## Max random horizontal error of an autoplay drop, px (--error=N).
var _drop_error := 70.0
var _screenshot_path := ""
var _quit_frame := -1
var _target_x := 0.0
var _has_target := false
var _frame := 0

var game: Game
var spawner: BlockSpawner
var tower: Tower
var water: Water


func _ready() -> void:
	set_process(false)
	set_physics_process(false)
	for arg: String in OS.get_cmdline_user_args():
		if arg == "--autoplay":
			_autoplay = true
		elif arg.begins_with("--screenshot="):
			_screenshot_path = arg.trim_prefix("--screenshot=")
		elif arg.begins_with("--frames="):
			_quit_frame = int(arg.trim_prefix("--frames="))
		elif arg.begins_with("--error="):
			_drop_error = float(arg.trim_prefix("--error="))
	if not _autoplay and _screenshot_path.is_empty() and _quit_frame < 0:
		return
	# Children are ready before their parent, so wait for Main to finish wiring.
	game = get_parent()
	await game.ready
	spawner = game.spawner
	tower = game.tower
	water = game.water
	set_process(true)
	set_physics_process(true)
	if _autoplay:
		game.start_game()
		spawner.block_spawned.connect(func(_b: Block) -> void: _has_target = false)
		tower.block_placed.connect(func(_b: Block, overlap: float, rating: Tower.Rating) -> void:
			print("[dev] placed #%d overlap=%.2f %s stability=%.0f" % [
				tower.block_count(), overlap, Tower.Rating.keys()[rating], tower.stability]))
		tower.block_missed.connect(func(_b: Block) -> void: print("[dev] MISS stability=%.0f" % tower.stability))
		tower.collapsed.connect(func() -> void: print("[dev] COLLAPSE at %d blocks" % tower.block_count()))
		water.reached_target.connect(func() -> void: print("[dev] DROWNED at %d blocks" % tower.block_count()))


func _physics_process(delta: float) -> void:
	if not _autoplay or game.state != GameState.State.PLAYING:
		return
	var block := spawner.current
	if block == null or block.phase != Block.Phase.MOVING:
		return
	if not _has_target:
		var top := tower.top_block()
		var top_x := top.position.x if top != null else 0.0
		_target_x = top_x + randf_range(-_drop_error, _drop_error)
		var half := block.half_width()
		_target_x = clampf(_target_x, spawner.left_limit + half, spawner.right_limit - half)
		_has_target = true
	if absf(block.position.x - _target_x) <= spawner.speed * delta:
		spawner.drop()


func _process(_delta: float) -> void:
	_frame += 1
	if _quit_frame >= 0 and _frame == _quit_frame:
		if not _screenshot_path.is_empty():
			await RenderingServer.frame_post_draw
			var image := get_viewport().get_texture().get_image()
			var err := image.save_png(_screenshot_path)
			print("[dev] screenshot -> %s (%s)" % [_screenshot_path, error_string(err)])
		print("[dev] blocks=%d stability=%.0f state=%s" % [tower.block_count(), tower.stability, GameState.State.keys()[game.state]])
		get_tree().quit()
