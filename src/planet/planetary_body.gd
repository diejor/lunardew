extends RigidBody3D

@export var gravity_strength = 9.8

func _ready() -> void:
	# Optionally disable built-in gravity if not needed
	gravity_scale = 0

func _integrate_forces(state: PhysicsDirectBodyState3D) -> void:
	var planet_center = Vector3.ZERO
	# Calculate the direction from the current position to the planet's center.
	var gravity_direction = (planet_center - global_transform.origin).normalized()
	
	# Apply the gravitational acceleration.
	state.linear_velocity += gravity_direction * gravity_strength * state.step
