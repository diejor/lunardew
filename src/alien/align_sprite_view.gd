extends SpriteBase3D

@onready var _p = $"../.."

func _process(delta):
	# Get the current camera (make sure your camera is the active one)
	var planet_up = _p._planet_up
	var cam = get_viewport().get_camera_3d()
	if cam == null:
		return  # Safety check in case there's no camera

	# Compute the vector from the sprite to the camera
	var to_camera = cam.global_transform.origin - global_transform.origin

	# Project that vector onto the plane defined by planet_up
	var projected_dir = to_camera - planet_up * to_camera.dot(planet_up)
	
	# Only update if there's a valid direction to look at
	if projected_dir.length() > 0.01:
		# Use look_at to orient the sprite towards the camera along the projected direction.
		look_at(global_transform.origin + projected_dir, planet_up)
