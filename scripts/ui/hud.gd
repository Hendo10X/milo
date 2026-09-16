extends CanvasLayer
class_name HUD
## In-game overlay: current height, best height, a one-shot hint, short
## feedback popups ("PERFECT!") and the pause button.

signal pause_pressed

@onready var height_label: Label = $Root/HeightLabel
@onready var best_label: Label = $Root/BestLabel
@onready var hint_label: Label = $Root/Hint
@onready var popup_label: Label = $Root/Popup
@onready var pause_button: Button = $Root/PauseButton

var _popup_tween: Tween


func _ready() -> void:
	popup_label.modulate.a = 0.0
	pause_button.pressed.connect(func() -> void: pause_pressed.emit())


func set_height(height: int) -> void:
	height_label.text = "%dm" % height


func set_best(best: int) -> void:
	best_label.text = "BEST %dm" % best


func hide_hint() -> void:
	if hint_label.visible:
		var t := create_tween()
		t.tween_property(hint_label, "modulate:a", 0.0, 0.3)
		t.tween_callback(hint_label.hide)


func popup(text: String, color: Color = Color.WHITE) -> void:
	if _popup_tween != null and _popup_tween.is_valid():
		_popup_tween.kill()
	popup_label.text = text
	popup_label.modulate = color
	popup_label.scale = Vector2(0.6, 0.6)
	_popup_tween = create_tween()
	_popup_tween.tween_property(popup_label, "scale", Vector2.ONE, 0.18) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_popup_tween.tween_interval(0.4)
	_popup_tween.tween_property(popup_label, "modulate:a", 0.0, 0.25)
