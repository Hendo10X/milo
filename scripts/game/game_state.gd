extends Node
## Autoload (GameState). Holds the game-state enum, the best height, and
## save/load. It is the only thing that survives a scene reload, so it also
## carries the "restart straight into a game" flag.

enum State { MENU, PLAYING, PAUSED, GAME_OVER }

const SAVE_PATH := "user://milo.cfg"

var best_height: int = 0
var last_height: int = 0
## Set before reloading the scene so the next run skips the main menu.
var skip_menu: bool = false


func _ready() -> void:
	load_save()


## Records a finished run. Returns true if it is a new best.
func submit_height(height: int) -> bool:
	last_height = height
	if height > best_height:
		best_height = height
		save()
		return true
	return false


func load_save() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(SAVE_PATH) == OK:
		best_height = int(cfg.get_value("score", "best_height", 0))


func save() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("score", "best_height", best_height)
	cfg.save(SAVE_PATH)
