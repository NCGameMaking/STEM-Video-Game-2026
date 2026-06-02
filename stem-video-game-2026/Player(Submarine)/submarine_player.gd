extends RigidBody3D
#MUST MAKE THIS A STATE MACHINE!!!
@export var speed = 500.0
@export var boost_speed = 1000.0
@export var turn_speed = 10.0 
@onready var camera = $CameraMount/Camera3D

func _physics_process(delta):
	
	var move_speed = speed
	
	if Input.is_action_pressed("Sprint"):
		move_speed = boost_speed
		camera.fov = lerp(camera.fov, 85.0, delta * 2.0)
	else:
		camera.fov = lerp(camera.fov, 75.0, delta * 2.0)
		
	# 1. Forward/Backward (Z axis)
	var f_input = Input.get_axis("Move_backward", "Move_forward")
	apply_central_force(-global_transform.basis.z * f_input * speed)
	
	# 2. Turning (Y axis)
	var steer_input = Input.get_axis("Rotate_right", "Rotate_left")
	# We use 'apply_torque' to spin, but with lower power
	apply_torque(Vector3(0, steer_input * turn_speed, 0))

	# 3. STRAFING (X Axis)
	var s_input = Input.get_axis("Move_left", "Move_right")
	apply_central_force(global_transform.basis.x * s_input * move_speed)

	# 4. Vertical Height (Y axis)
	if Input.is_action_pressed("Move_up"):
		apply_central_force(Vector3.UP * speed)
	if Input.is_action_pressed("Move_down"):
		apply_central_force(Vector3.DOWN * speed)
