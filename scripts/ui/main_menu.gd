extends CanvasLayer
class_name MainMenu
## Title screen. Input is handled by the game (any tap starts).

@onready var best_label: Label = $Root/BestLabel


func set_best(best: int) -> void:
	best_label.visible = best > 0
	best_label.text = "BEST %dm" % best
