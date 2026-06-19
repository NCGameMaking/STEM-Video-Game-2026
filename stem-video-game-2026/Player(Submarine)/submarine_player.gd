extends RigidBody3D

enum SubState {IDLE, MOVEMENT, SPRINTING}
var current_state : SubState = SubState.IDLE

@export var move_force : float = 50.0
@export var strafe_force : float = 1000.0
@export var vertical_force : float = 40.0
@export var sprint_multiplier : float = 2.0
@export var mouse_sensitivity : float = 0.1

#var mouse_input_x : float = 0.0

@onready var debug_ui = $DebugUI
@onready var camera = $CameraMount/SpringArm3D/Camera3D

var mouse_input : float = 0.0

func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
func _process(delta):
	if Input.is_key_pressed(KEY_ESCAPE):
		get_tree().quit()

func _unhandled_input(event):
	if event is InputEventMouseMotion:
		mouse_input = -event.relative.x * mouse_sensitivity

func _integrate_forces(state):
	if mouse_input != 0.0:
		var rotation_increment = Basis(Vector3.UP, mouse_input)
		state.transform.basis = state.transform.basis * rotation_increment
		mouse_input = 0.0
		
	match current_state:
		SubState.IDLE:
			process_idle_state(state)
		SubState.MOVEMENT:
			process_movement_state(state)
		SubState.SPRINTING:
			process_sprinting_state(state)
	if debug_ui:
		debug_ui.update_property("Current State", get_state_string())
		debug_ui.update_property("Linear Velocity", state.linear_velocity.snapped(Vector3(0.1, 0.1, 0.1)))
		debug_ui.update_property("Speed (m/s)", "%0.2f" % state.linear_velocity.length())

func process_idle_state(state):
	if Input.is_action_pressed("Move_forward") or Input.is_action_pressed("Move_backward") or Input.is_action_pressed("Move_left") or Input.is_action_pressed("Move_right") or Input.is_action_pressed("Move_down") or Input.is_action_pressed("Move_up"):
		current_state = SubState.MOVEMENT
	
func process_movement_state(state):
	var force_vector = Vector3.ZERO

	if Input.is_action_pressed("Move_forward"):
		force_vector -= state.transform.basis.z * move_force
	if Input.is_action_pressed("Move_backward"):
		force_vector += state.transform.basis.z * move_force
	if Input.is_action_pressed("Move_left"):
		force_vector -= state.transform.basis.x * strafe_force
	if Input.is_action_pressed("Move_right"):
		force_vector += state.transform.basis.x * strafe_force
	if Input.is_action_pressed("Move_up"):
		force_vector += state.transform.basis.y * vertical_force
	if Input.is_action_pressed("Move_down"):
		force_vector -= state.transform.basis.y * vertical_force
		
	state.apply_central_force(force_vector)
	
	if force_vector == Vector3.ZERO:
		current_state = SubState.IDLE
	if  Input.is_action_pressed("Sprint"):
		current_state = SubState.SPRINTING
		
func process_sprinting_state(state):
	var force_vector = Vector3.ZERO
	
	if Input.is_action_pressed("Move_forward"):
		force_vector -= state.transform.basis.z * move_force
	if Input.is_action_pressed("Move_backward"): force_vector += state.transform.basis.z * move_force
	if Input.is_action_pressed("Move_left"): force_vector -= state.transform.basis.x * strafe_force
	if Input.is_action_pressed("Move_right"): force_vector += state.transform.basis.x * strafe_force
	if Input.is_action_pressed("Move_up"): force_vector += state.transform.basis.y * vertical_force
	if Input.is_action_pressed("Move_down"): force_vector -= state.transform.basis.y * vertical_force
	
	state.apply_central_force(force_vector * sprint_multiplier)
	
	if not Input.is_action_pressed("Sprint"):
		current_state = SubState.MOVEMENT
#
#func _physics_process(delta):
	#
	#var move_speed = speed
	#
	#if Input.is_action_pressed("Sprint"):
		#move_speed = boost_speed
		#camera.fov = lerp(camera.fov, 85.0, delta * 2.0)
	#else:
		#camera.fov = lerp(camera.fov, 75.0, delta * 2.0)
		#
	## 1. Forward/Backward (Z axis)
	#var f_input = Input.get_axis("Move_backward", "Move_forward")
	#apply_central_force(-global_transform.basis.z * f_input * speed)
	#
	## 2. Turning (Y axis)
	#var steer_input = Input.get_axis("Rotate_right", "Rotate_left")
	## We use 'apply_torque' to spin, but with lower power
	#apply_torque(Vector3(0, steer_input * turn_speed, 0))
#
	## 3. STRAFING (X Axis)
	#var s_input = Input.get_axis("Move_left", "Move_right")
	#apply_central_force(global_transform.basis.x * s_input * move_speed)
#
	## 4. Vertical Height (Y axis)
	#if Input.is_action_pressed("Move_up"):
		#apply_central_force(Vector3.UP * speed)
	#if Input.is_action_pressed("Move_down"):
		#apply_central_force(Vector3.DOWN * speed)

func get_state_string() -> String:
	match current_state:
		SubState.IDLE: return "IDLE"
		SubState.MOVEMENT: return "MOVING"
		SubState.SPRINTING: return "SPRINTING"
	return "UNKNOWN"
