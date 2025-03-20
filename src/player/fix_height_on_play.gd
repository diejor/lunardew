extends AnimatedSprite3D

func _ready() -> void:
	UI.ButtonPressed.connect(on_button_down)

func on_button_down(button_name: StringName):
	if button_name == "Play":
		position.y = 0.0
