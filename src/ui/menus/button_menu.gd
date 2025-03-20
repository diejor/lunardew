class_name ButtonMenu extends Button

func _ready() -> void:
	pressed.connect(on_button_pressed)
	mouse_entered.connect(on_button_hovered)
	
func on_button_pressed():
	UI.sfx_player.queue("button_clicked")
	UI.ButtonPressed.emit(name)
	

func on_button_hovered():
	UI.sfx_player.play("button_hovered")
