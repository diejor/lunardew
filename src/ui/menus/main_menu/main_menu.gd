extends Control

func _on_play_button_up() -> void:
	Game.UI.sfx_player.play("transition_game")
