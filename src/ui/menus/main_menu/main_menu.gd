extends Control

func _on_play_button_up() -> void:
	UI.sfx_player.queue("transition_game")
	UI.songs_mixer.set("parameters/conditions/is_level1", true)
	UI.sfx_player.queue("start_game")
