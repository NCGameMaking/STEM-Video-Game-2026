extends RigidBody3D

# Lower these numbers if it's still too fast!
@export var speed = 500.0 
@export var turn_speed = 10.0 

func _physics_process(delta):
	# 1. Forward/Backward (Z axis)
	var f_input = Input.get_axis("ui_down", "ui_up")
	apply_central_force(-global_transform.basis.z * f_input * speed)
	
	# 2. Turning (Y axis)
	var steer_input = Input.get_axis("ui_right", "ui_left")
	# We use 'apply_torque' to spin, but with lower power
	apply_torque(Vector3(0, steer_input * turn_speed, 0))

	# 3. Vertical (Y axis)
	if Input.is_key_pressed(KEY_E):
		apply_central_force(Vector3.UP * speed)
	if Input.is_key_pressed(KEY_Q):
		apply_central_force(Vector3.DOWN * speed)
