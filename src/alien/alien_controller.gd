extends CharacterBody3D

@export var speed: float = 126.0
@export var turn_speed: float = 1.0
@export var planet_center: Vector3 = Vector3(0, 0, 0)

@export var sensor_paths: Array[NodePath] = []

var _sensors: Array = []
var _planet_up: Vector3

func _ready() -> void:
	for path in sensor_paths:
		if has_node(path):
			_sensors.append(get_node(path))
		else:
			push_warning("sensor_paths contains invalid path: %s" % path)


func _physics_process(delta: float) -> void:
	# 1) Determine planet up
	_planet_up = (global_position - planet_center).normalized()

	# 2) Base "forward" direction (AI tries to move forward by default)
	var forward_dir = -transform.basis.z
	# Flatten onto tangent plane
	forward_dir = forward_dir - (forward_dir.dot(_planet_up) * _planet_up)
	forward_dir = forward_dir.normalized()

	# 3) Get avoidance (deflection) vector
	var avoidance_vec = calculate_avoidance_vector(forward_dir)

	# 4) Combine forward + avoidance
	var steering_dir = forward_dir + avoidance_vec
	if steering_dir.length() > 0.001:
		steering_dir = steering_dir.normalized()

	# 5) Turn towards that steering direction (tank-style turning)
	turn_towards_direction(steering_dir, delta)

	# 6) Build velocity
	#    We multiply horizontal velocity by delta only if we want position-based stepping.
	#    If we prefer "units/sec," remove * delta. 
	var horizontal_velocity = steering_dir * speed * delta

	# 7) Gravity + vertical velocity
	var vertical_velocity = velocity.project(_planet_up)
	if not is_on_floor():
		vertical_velocity -= _planet_up * 9.8 * delta

	# Reassemble and move
	velocity = horizontal_velocity + vertical_velocity
	move_and_slide()

	# 8) Keep aligning with planet surface
	align_with__planet_up(delta)


func calculate_avoidance_vector(forward_dir: Vector3) -> Vector3:
	"""
	For each RayCast sensor that is colliding, determine whether
	the collision is to the left or right of our forward axis.
	If it's to the right, we steer left, and vice versa.
	"""
	var avoidance = Vector3.ZERO

	for sensor in _sensors:
		if sensor.is_colliding():
			# One approach: compare the direction of the sensor to our forward axis
			var sensor_pos = sensor.global_position
			var sensor_dir = (sensor_pos - global_position).normalized()

			# Cross forward_dir and sensor_dir to see which side it’s on:
			var cross_val = forward_dir.cross(sensor_dir)
			var side_sign = cross_val.dot(_planet_up)

			if side_sign > 0.0:
				# sensor is on our left => deflect right
				# "Right" can be found by cross(forward, planet_up)
				var right_vec = forward_dir.cross(_planet_up).normalized()
				avoidance += right_vec
			else:
				# sensor is on our right => deflect left
				var left_vec = _planet_up.cross(forward_dir).normalized()
				avoidance += left_vec

	# Normalize if non-zero
	if avoidance.length() > 0.001:
		avoidance = avoidance.normalized()
	return avoidance


func turn_towards_direction(target_dir: Vector3, delta: float) -> void:
	var flat_target = target_dir - (target_dir.dot(_planet_up) * _planet_up)
	flat_target = flat_target.normalized()

	var current_forward = -transform.basis.z
	var flat_forward = current_forward - (current_forward.dot(_planet_up) * _planet_up)
	flat_forward = flat_forward.normalized()

	var dot_val = clamp(flat_forward.dot(flat_target), -1.0, 1.0)
	var angle = acos(dot_val)
	if angle > 0.001:
		var cross_val = flat_forward.cross(flat_target)
		# sign of angle depends on whether cross is "above" or "below" planet_up
		angle *= sign(cross_val.dot(_planet_up))

		var max_turn = turn_speed * delta
		angle = clamp(angle, -max_turn, max_turn)

		var basis_rot = Basis().rotated(_planet_up, angle)
		transform.basis = basis_rot * transform.basis


func align_with__planet_up(delta: float) -> void:
	var current_up = transform.basis.y
	var dot_val = clamp(current_up.dot(_planet_up), -1.0, 1.0)
	var angle_between = acos(dot_val)
	if angle_between > 0.001:
		var rotation_axis = current_up.cross(_planet_up).normalized()
		var align_speed = PI
		var rot_basis = Basis().rotated(rotation_axis, angle_between * align_speed * delta)
		transform.basis = rot_basis * transform.basis
