extends CanvasLayer

signal ButtonPressed(button_name:StringName)

var height:float  = 648
var width:float = 1152
@onready var sfx_player: AnimationPlayer = $SFXPlayer
@onready var songs_player: AnimationPlayer = $SongsPlayer
@onready var songs_mixer: AnimationTree = $SongsMixer

func _ready() -> void:
	songs_player.play("main_theme")
