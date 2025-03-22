extends Node

@export var _projectile_scene: PackedScene
@onready var _p: Node3D = $".."

@onready var _animation_player: AnimationPlayer = $"../AnimationPlayer"

func _ready() -> void:
	set_process_input(true)

func fire_projectile() -> void:
	# Instantiate the projectile.
	var projectile = _projectile_scene.instantiate()
	# Add projectile to the scene. (This example adds it to the current scene; adjust as needed.)
	get_tree().current_scene.add_child(projectile)
	# Set the projectile’s spawn position to be the same as the Weapon (or player’s) global position.
	projectile.global_position = _p.global_position
	
	# Compute the 3D shoot direction from the 2D input.
	# Get the local right and forward directions from our transform.
	# (Assuming that the player's transform has been aligned so its basis lies in the tangent plane.
	var forward: Vector3 = -_p.global_transform.basis.z
	
	# Combine the components from the last nonzero input.
	var shoot_direction: Vector3 = (forward * _p._input_dir.y).normalized()

	
	# Ensure our shooting direction is within the tangent plane of the planet.
	shoot_direction = shoot_direction - shoot_direction.dot(_p._planet_up) * _p._planet_up
	shoot_direction = shoot_direction.normalized()
	
	projectile.global_position += shoot_direction * 0.5
	projectile.linear_velocity = shoot_direction * projectile._speed

func _on_grounded_state_physics_processing(delta: float) -> void:
	if Input.is_action_just_pressed("fire") and is_processing_input():
		%PlayerStateChart.send_event("shoot")

func _on_shooting_state_entered() -> void:
	fire_projectile()
	$"../AnimationPlayer".play("shoot")
