extends CanvasLayer
class_name PauseMenu
## Pause overlay. Keeps processing while the tree is paused so its button
## still works; the game toggles it.

signal resume_pressed

@onready var resume_button: Button = $Root/ResumeButton


func _ready() -> void:
	resume_button.pressed.connect(func() -> void: resume_pressed.emit())
