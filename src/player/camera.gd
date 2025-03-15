extends Camera3D

@export var target: Node3D
@export var planet_center: Vector3 = Vector3.ZERO
@export var offset: Vector3 = Vector3(0, 5, 5)
@export var smoothing_speed: float = 5.0

func _process(delta: float) -> void:
	if not target:
		return
	
	# 1) Compute planet_up based on the target's position relative to the planet center
	var planet_up = (target.global_transform.origin - planet_center).normalized()
	
	# 2) Find target's forward direction, ignoring tilt around planet_up
	#    (Typical Godot 3D forward is -Z)
	var forward = -target.global_transform.basis.z
	# Flatten the forward vector against planet_up
	forward = forward - forward.dot(planet_up) * planet_up
	forward = forward.normalized()

	# 3) Build a basis aligned horizontally with respect to planet_up
	var right = forward.cross(planet_up).normalized()
	var up = right.cross(forward).normalized()  # Recomputed up to ensure orthonormal
	var target_basis = Basis(right, up, forward)
	
	# 4) Compute the final desired camera position
	#    - Move to the target's position, then add the local-space offset
	#      in the direction of 'target_basis'
	var target_position = target.global_transform.origin + target_basis.xform(offset)
	
	# 5) Smoothly interpolate from the camera’s current transform to the target transform
	
	# (A) Slerp the rotation
	#     We'll use an exponential approach so that smoothing behaves well regardless of framerate.
	var alpha = 1.0 - exp(-smoothing_speed * delta)  # 0..1
	transform.basis = transform.basis.slerp(target_basis, alpha)

	# (B) Lerp the position
	transform.origin = transform.origin.lerp(target_position, alpha)
