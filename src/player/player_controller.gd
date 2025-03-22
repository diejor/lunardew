extends CharacterBody3D

@export var _speed: float = 256.0
@export var _turn_speed: float = 2.0
@export var _jump_velocity: float = 4.0
@export var _gravity_strength: float = 9.8
@export var _vertical_correction_speed: float = PI
@export var _planet_center: Vector3 = Vector3(0, 0, 0)  # Define the planet's center

@onready var _animation_tree: AnimationTree = $AnimationTree
@onready var _sprite_animations: AnimatedSprite3D = $Visuals/PlayerAnimations
@onready var _animation_player: AnimationPlayer = $AnimationPlayer
@onready var _is_grounded_check: RayCast3D = $CheckIfGround
@onready var _state_chart: StateChart = %PlayerStateChart

var _planet_up: Vector3
var _input_dir = Vector2(0., 1.)

func _ready() -> void:
	set_process_input(false)
	UI.ButtonPressed.connect(on_ui_button_up)
	_sprite_animations.play("idle_down")
	
	
func on_ui_button_up(button_name: StringName):
	if button_name == "Play":
		set_process_input(true)
		_animation_player.queue("idle_up")
		_state_chart.send_event("jump")

func is_grounded() -> bool:
	return (is_on_floor() or _is_grounded_check.is_colliding())

func jump() -> void:
	# Extract the horizontal component by subtracting the current vertical component
	var horizontal_velocity = velocity - velocity.project(_planet_up)
	# Set the vertical component to your jump value along _planet_up
	velocity = horizontal_velocity + _planet_up * _jump_velocity

func _physics_process(delta: float) -> void:
	# Determine _planet_up.
	_planet_up = (global_position - _planet_center).normalized()

	# Separate current velocity into vertical (__planet_up) and horizontal components.
	var vertical_velocity = velocity.project(_planet_up)
	var tangent_plane = Plane(_planet_up)
	var horizontal_velocity = tangent_plane.project(velocity)

	# Tank-style movement:
	#    - input_dir.x = turn left/right
	#    - input_dir.y = move forward/back
	var input_dir = Vector2.ZERO
	if is_processing_input():
		input_dir = Input.get_vector("move_left", "move_right", "move_forward", "move_backward")
		_animation_tree.set("parameters/conditions/is_walking", input_dir.y != 0.0)
		_animation_tree.set("parameters/conditions/is_idle", input_dir.y == 0.0)
		if input_dir.y != 0:
			_animation_tree.set("parameters/Idle/blend_position", -input_dir.y)
			_input_dir = input_dir
			_state_chart.send_event("walk")
		else:
			_state_chart.send_event("idle")
		
		if _animation_tree.get("parameters/Idle/blend_position") != 0:
			input_dir.x = sign(_animation_tree.get("parameters/Idle/blend_position")) * input_dir.x
		
	
	# (A) Rotate around _planet_up if the user is pressing left or right.
	#     If input_dir.x is negative => turn left, if positive => turn right.
	if abs(input_dir.x) > 0.0001:
		# We'll rotate our basis around _planet_up by some angle.
		# angle = _turn_speed * input_dir.x * delta
		var angle = -_turn_speed * input_dir.x * delta
		var basis_rot = Basis().rotated(_planet_up, angle)
		transform.basis = basis_rot * transform.basis
	
	# (B) Move forward/backward. 
	#     The "forward" direction in Godot 3D is typically -transform.basis.z, but adjust if needed.
	var forward_dir = -transform.basis.z
	# Flatten 'forward_dir' onto the tangent plane in case the character is oriented diagonally.
	forward_dir = forward_dir - forward_dir.dot(_planet_up) * _planet_up
	forward_dir = forward_dir.normalized()
	
	# input_dir.y is positive when moving forward, negative for backward.
	var target_h_speed = input_dir.y * _speed
	# Multiply by delta if you want velocity to be distance per second:
	horizontal_velocity = forward_dir * target_h_speed * delta
	
	# Reassemble final velocity from horizontal + vertical.
	velocity = horizontal_velocity + vertical_velocity

	# Gradually rotate the character so its Y-axis aligns with _planet_up.
	var current_up = transform.basis.y
	up_direction = current_up
	var angle_between = acos(clamp(current_up.dot(_planet_up), -1, 1))
	if angle_between > 0.0001:
		var rotation_axis = current_up.cross(_planet_up).normalized()
		var rot = Basis().rotated(rotation_axis, angle_between * _vertical_correction_speed * delta)
		transform.basis = rot * transform.basis

	# Move and slide, passing _planet_up as the up direction.
	move_and_slide()
	
func _on_animation_player_animation_finished(anim_name: StringName) -> void:
	if anim_name == "jump":
		_state_chart.send_event("jump_finished")

func _on_jumping_state_entered() -> void:
	_animation_player.queue("jump")
	
	

func _on_check_jump_grounded_state_physics_processing(delta: float) -> void:
	if Input.is_action_just_pressed("jump") and is_grounded() and is_processing_input():
		_state_chart.send_event("jump")

func _on_grounded_state_physics_processing(delta: float) -> void:
	# Apply planet gravity (if not on the floor).
	# floor meaning that is sticking to the ground, since grounded allows to be slightly above ground
	if not is_on_floor():
		_state_chart.send_event("airbone")

func _on_airbone_state_physics_processing(delta: float) -> void:
	if not is_on_floor():
		velocity += -_planet_up * _gravity_strength * delta
	else:
		_state_chart.send_event("grounded")

func _on_coyote_time_state_physics_processing(delta: float) -> void:
	if Input.is_action_just_pressed("jump"):
		_state_chart.send_event("jump")
