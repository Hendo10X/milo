extends CanvasLayer
class_name GameOverScreen
## Game-over screen. Input is handled by the game (tap to restart).

@onready var reason_label: Label = $Root/Panel/Reason
@onready var height_label: Label = $Root/Panel/Height
@onready var best_label: Label = $Root/Panel/Best
@onready var new_best_label: Label = $Root/Panel/NewBest
@onready var panel: Control = $Root/Panel


func show_result(reason: String, height: int, best: int, is_new_best: bool) -> void:
	reason_label.text = reason
	height_label.text = "%dm" % height
	best_label.text = "BEST %dm" % best
	new_best_label.visible = is_new_best
	visible = true
	panel.modulate.a = 0.0
	panel.scale = Vector2(0.9, 0.9)
	var t := create_tween().set_parallel(true)
	t.tween_property(panel, "modulate:a", 1.0, 0.3)
	t.tween_property(panel, "scale", Vector2.ONE, 0.3).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
