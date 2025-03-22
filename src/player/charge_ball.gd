extends PlanetBody

@export var _speed: float = 1.

func _ready() -> void:
	super._ready()
	$Charge.emitting = true

func _on_timer_timeout() -> void:
	queue_free()
