extends Node2D
class_name Game
## Game manager. Owns the state machine, wires the systems together, keeps
## the score and feeds the difficulty curve to the water and camera.
##
## Flow: MENU → PLAYING ⇄ PAUSED → GAME_OVER → (scene reload) → PLAYING

## Ignore taps for this long after game over so nobody restarts by accident.
const GAME_OVER_INPUT_DELAY := 0.8

@onready var tower: Tower = $World/Tower
@onready var water: Water = $World/Water
@onready var well: Well = $World/Well
@onready var camera: GameCamera = $World/Camera2D
@onready var milo: Milo = $Milo
@onready var spawner: BlockSpawner = $BlockSpawner
@onready var hud: HUD = $UI/HUD
@onready var main_menu: MainMenu = $UI/MainMenu
@onready var game_over_screen: GameOverScreen = $UI/GameOver
@onready var pause_menu: PauseMenu = $UI/PauseMenu

var state: GameState.State = GameState.State.MENU
var height := 0

var _game_over_lock := 0.0


func _ready() -> void:
	# Wire the systems together here so the scene stays free of node paths.
	spawner.tower = tower
	spawner.left_limit = -well.inner_half_width
	spawner.right_limit = well.inner_half_width
	tower.ground_half_width = well.inner_half_width
	well.camera = camera
	camera.target = milo
	water.target = milo

	tower.block_placed.connect(_on_block_placed)
	tower.block_missed.connect(_on_block_missed)
	tower.stability_changed.connect(_on_stability_changed)
	tower.collapsed.connect(_on_collapsed)
	water.reached_target.connect(_on_water_reached_milo)
	spawner.block_spawned.connect(func(block: Block) -> void: milo.look_target = block)
	spawner.block_dropped.connect(func(_block: Block) -> void:
		milo.on_block_dropped()
		Audio.play("drop", 0.95, 1.05))
	hud.pause_pressed.connect(toggle_pause)
	pause_menu.resume_pressed.connect(toggle_pause)

	milo.stand_at(tower.top_surface_global())
	hud.set_height(0)
	hud.set_best(GameState.best_height)
	main_menu.set_best(GameState.best_height)

	hud.visible = false
	game_over_screen.visible = false
	pause_menu.visible = false
	main_menu.visible = true

	Audio.play_music("loop")
	if GameState.skip_menu:
		GameState.skip_menu = false
		start_game()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("pause"):
		if state == GameState.State.PLAYING or state == GameState.State.PAUSED:
			toggle_pause()
		return
	if not event.is_action_pressed("drop"):
		return
	match state:
		GameState.State.MENU:
			start_game()
		GameState.State.PLAYING:
			spawner.drop()
			hud.hide_hint()
		GameState.State.PAUSED:
			toggle_pause()
		GameState.State.GAME_OVER:
			if _game_over_lock <= 0.0:
				restart()


func _process(delta: float) -> void:
	match state:
		GameState.State.PLAYING:
			water.base_speed = Difficulty.water_speed(tower.block_count())
			camera.shake_amount = maxf(0.0, tower.instability() - 0.55) * 6.0
		GameState.State.GAME_OVER:
			_game_over_lock -= delta


# --- State changes ----------------------------------------------------------

func start_game() -> void:
	if state != GameState.State.MENU:
		return
	state = GameState.State.PLAYING
	main_menu.visible = false
	hud.visible = true
	water.rising = true
	spawner.start()
	Audio.play("start")


func toggle_pause() -> void:
	if state == GameState.State.PLAYING:
		state = GameState.State.PAUSED
		get_tree().paused = true
		pause_menu.visible = true
	elif state == GameState.State.PAUSED:
		state = GameState.State.PLAYING
		get_tree().paused = false
		pause_menu.visible = false


func game_over(reason: String) -> void:
	if state == GameState.State.GAME_OVER:
		return
	state = GameState.State.GAME_OVER
	_game_over_lock = GAME_OVER_INPUT_DELAY
	spawner.stop()
	water.rising = false
	camera.shake_amount = 0.0
	hud.visible = false
	Audio.stop_music(1.0)
	Audio.play("game_over", 1.0, 1.0, -4.0)
	var is_new_best := GameState.submit_height(height)
	game_over_screen.show_result(reason, height, GameState.best_height, is_new_best)


func restart() -> void:
	GameState.skip_menu = true
	get_tree().paused = false
	get_tree().reload_current_scene()


# --- System callbacks -------------------------------------------------------

func _on_block_placed(block: Block, _overlap: float, rating: Tower.Rating) -> void:
	height = tower.block_count()
	hud.set_height(height)
	var perfect := rating == Tower.Rating.PERFECT
	milo.climb_onto(block, perfect)
	# A landing thud always, pitched slightly lower the worse the placement.
	Audio.play("land", 0.9 if rating >= Tower.Rating.UNSTABLE else 1.0, 1.1)
	if perfect:
		hud.popup("PERFECT!", Color(1.0, 0.9, 0.4))
		Audio.play("perfect")
	elif rating == Tower.Rating.CRITICAL:
		camera.kick(5.0)
	elif rating == Tower.Rating.UNSTABLE:
		camera.kick(2.0)


func _on_block_missed(_block: Block) -> void:
	milo.on_block_missed()
	hud.popup("MISS", Color(1.0, 0.5, 0.45))
	Audio.play("miss")


func _on_stability_changed(stability: float) -> void:
	milo.set_stability(stability)


func _on_collapsed() -> void:
	camera.kick(10.0)
	milo.fall()
	Audio.play("collapse")
	game_over("THE TOWER FELL")


func _on_water_reached_milo() -> void:
	if state != GameState.State.PLAYING:
		return
	milo.drown()
	Audio.play("splash")
	game_over("MILO GOT WET")
