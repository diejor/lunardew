extends CanvasLayer

signal ToggleUi(id:String, value:bool, previous:String)
signal ReturnToMainMenu()
signal WindowResized(_value:Vector2i)
signal OptionUpdated(id:String, value)
signal TogglePauseGame(value:bool)
signal PopupSmall(text:String, icon:Texture2D)
signal PopupLarge(severity, title:String, text:String, popup_id:String, icon:CompressedTexture2D, timer:float)
signal PopupResult(id:String, result:bool)
signal ButtonPressed()

var height:float  = 648
var width:float = 1152
@onready var player_ui: AnimationPlayer = $PlayerUI

func _ready() -> void:
	ButtonPressed.connect(_on_button_pressed)
	player_ui.play("main_theme")

func _on_button_pressed() -> void:
	player_ui.play("button_clicked")
