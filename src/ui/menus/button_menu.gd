class_name ButtonMenu extends Button

func _ready() -> void:
	pressed.connect(_button_pressed)
	
func _button_pressed():
	UI.ButtonPressed.emit()
