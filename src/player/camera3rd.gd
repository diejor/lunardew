extends Camera3D

@export var target: Node3D
@export var planet_center: Vector3 = Vector3.ZERO
@export var offset: Vector3 = Vector3(0, 5, 5)
@export var smoothing_speed: float = 5.0

func _ready() -> void:
	UI.ButtonPressed.connect(on_ui_button_up)

func _process(delta: float) -> void:
	if not target:
		return

	# 1) Get the local 'up' for the target's position on the planet
	var planet_up = (target.global_transform.origin - planet_center).normalized()

	# 2) Flatten the target's forward vector so it lies horizontally on the tangent plane
	var forward = -target.global_transform.basis.z
	forward = forward - forward.dot(planet_up) * planet_up
	forward = forward.normalized()

	# 3) Build a new basis (right, up, forward) that's "horizontal"
	var right = forward.cross(planet_up).normalized()
	var up = right.cross(forward).normalized()  # re-orthonormalize
	var target_basis = Basis(right, up, forward)

	# 4) Compute the final desired position
	#    This takes the target's global position and moves "behind & above" it
	var desired_position = target.global_transform.origin + target_basis * offset

	# 5) Construct a transform that "looks at" the target from that new position
	var desired_transform = Transform3D()
	desired_transform.origin = desired_position
	# 'looking_at()' sets the basis to look at target's global position, with planet_up as the up vector
	desired_transform.basis = desired_transform.looking_at(target.global_transform.origin, planet_up).basis

	# 6) Compute interpolation factor for smoothing (exponential approach)
	var alpha = 1.0 - exp(-smoothing_speed * delta)  # yields a 0..1 factor based on smoothing_speed

	# 7) Convert the current and desired orientation to Quaternions for slerp
	var current_quat = Quaternion(transform.basis)
	var desired_quat = Quaternion(desired_transform.basis)
	var final_quat = current_quat.slerp(desired_quat, alpha)

	# 8) Smoothly interpolate position
	var final_pos = transform.origin.lerp(desired_transform.origin, alpha)

	# 9) Apply the results
	transform.origin = final_pos
	transform.basis = Basis(final_quat)


func on_ui_button_up(button_name: StringName) -> void:
	if button_name == "Play":
		smoothing_speed = 2.5
