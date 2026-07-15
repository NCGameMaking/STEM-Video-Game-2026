extends RigidBody3D

enum SubState {IDLE, MOVEMENT, SPRINTING}
var current_state : SubState = SubState.IDLE
const DIRECTIONS = ["N", "NE", "E", "SE", "S", "SW", "W", "NW"]

@export var normal_fov : float = 75
@export var sprint_fov : float = 85
@export var zoom_speed : float = 5

@export var move_force : float = 50.0
@export var strafe_force : float = 1000.0
@export var vertical_force : float = 40.0
@export var sprint_multiplier : float = 2.0
@export var mouse_sensitivity : float = 0.1

@export var max_stamina : float = 100.0
@export var current_stamina : float = 100.0
@export var drain_rate : float = 20.0
@export var regen_rate : float = 7.0

@export var max_health: float = 100.0
var current_health: float = 100.0
@export var damage_threshold : float = 5
@export var damage_multiplier : float = 2.5

@onready var debug_ui = $DebugUI
@onready var third_person_camera = $CameraMount/SpringArm3D/ThirdPersonCamera
@onready var first_person_camera = $FirstPersonCamera

@onready var center_booster = $CenterBooster
@onready var dive_booster = $DiveBooster
@onready var climb_booster = $ClimbBooster
@onready var left_booster = $LeftBooster
@onready var right_booster = $RightBooster
@onready var strafe_left_booster = $StrafeLeftBooster
@onready var strafe_right_booster = $StrafeRightBooster
@onready var top_ui = $TopViewport/TopUI
@onready var center_ui = $CenterViewport/CenterUI
@onready var bottom_ui = $BottomViewport/BottomUI
@onready var stamina_bar_bottom_ui = $BottomViewport/BottomUI/StaminaBar
@onready var state_label_bottom_ui = $BottomViewport/BottomUI/StateLabel

@onready var top_screen = $Submarine/TopScreen
@onready var top_viewport = $TopViewport

@export var sway_amount: float  = 0.5
@export var sway_speed: float  = 4.0
@onready var camera_mount = $CameraMount

var is_exhausted: bool = false

var mouse_input : float = 0.0
var is_first_person: bool = false
var fp_camera_base_pos : Vector3 = Vector3.ZERO

func _ready():
	body_entered.connect(_on_body_entered)
	
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	third_person_camera.current = true
	fp_camera_base_pos = first_person_camera.position

	var screen_mesh = $Submarine/TopScreen
	var viewport_node = $TopViewport

	var mat = screen_mesh.get_active_material(0)
	if mat:
		mat.albedo_texture = viewport_node.get_texture()
		mat.uv1_scale = Vector3(-2.0, 2.0, 2.0) 
		print("Texture successfully linked at runtime!")

func _process(delta):
	if current_stamina <= 0.0:
		is_exhausted = true
		if current_state == SubState.SPRINTING:
			current_state = SubState.MOVEMENT
	elif current_stamina >= max_stamina * 0.2:
		is_exhausted = false

	var can_sprint = Input.is_action_pressed("Sprint") and not is_exhausted and linear_velocity.length() > 3
	
	if can_sprint:
		current_stamina -= drain_rate * delta
	else:
		current_stamina += regen_rate * delta
	current_stamina = clamp(current_stamina, 0.0, max_stamina)
	
	var current_multiplier = 1.0
	if can_sprint:
		current_multiplier = 1 / sprint_multiplier
	

	update_stamina(current_stamina, max_stamina, can_sprint)


	update_dashboard_ui()
	if Input.is_key_pressed(KEY_ESCAPE):
		get_tree().quit()

func _unhandled_input(event):
	if event is InputEventMouseMotion:
		mouse_input = -event.relative.x * mouse_sensitivity
	
	if event.is_action_pressed("Toggle_camera"):
		is_first_person = !is_first_person
		if is_first_person:
			first_person_camera.current = true
		else:
			third_person_camera.current = true

func _integrate_forces(state):

	var is_moving_forward = Input.is_action_pressed("Move_forward")
	left_booster.emitting = is_moving_forward
	center_booster.emitting = is_moving_forward
	right_booster.emitting = is_moving_forward
	
	if is_moving_forward:
		if current_state == SubState.SPRINTING:
			left_booster.amount_ratio = 1.5
			center_booster.amount_ratio = 1.5
			right_booster.amount_ratio = 1.5
		else:
			left_booster.amount_ratio = 1.0
			center_booster.amount_ratio = 1.0
			right_booster.amount_ratio = 1.0
	strafe_left_booster.emitting = Input.is_action_pressed("Move_right")
	strafe_right_booster.emitting = Input.is_action_pressed("Move_left")
	
	climb_booster.emitting = Input.is_action_pressed("Move_up")
	dive_booster.emitting = Input.is_action_pressed("Move_down")
	
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
		debug_ui.update_property("FPS: ", Engine.get_frames_per_second())
		debug_ui.update_property("Linear Velocity", state.linear_velocity.snapped(Vector3(0.1, 0.1, 0.1)))
		debug_ui.update_property("Speed (m/s)", "%0.2f" % state.linear_velocity.length())
	
	var target_fov = normal_fov
	if current_state == SubState.SPRINTING:
		target_fov = sprint_fov
	if is_first_person:
		first_person_camera.fov = lerp(third_person_camera.fov, target_fov, state.step * zoom_speed)
	else:
		third_person_camera.fov = lerp(third_person_camera.fov, target_fov, state.step * zoom_speed)
		
	if not is_first_person and camera_mount:
		var target_sway = Vector3.ZERO
		
		if Input.is_action_pressed("Move_left"):
			target_sway.x = sway_amount
		if Input.is_action_pressed("Move_right"):
			target_sway.x = -sway_amount
		if Input.is_action_pressed("Move_up"):
			target_sway.y = -sway_amount * 0.5
		if Input.is_action_pressed("Move_down"):
			target_sway.y = sway_amount * 0.5
		camera_mount.position = camera_mount.position.lerp(target_sway, state.step * sway_speed)
			
	if is_first_person and first_person_camera:
		var target_fp_sway = Vector3.ZERO
		
		if Input.is_action_pressed("Move_left"):
			target_fp_sway.x = sway_amount * 0.1
		if Input.is_action_pressed("Move_right"):
			target_fp_sway.x = -sway_amount * 0.1
		if Input.is_action_pressed("Move_up"):
			target_fp_sway.y = -sway_amount * 0.1
		if Input.is_action_pressed("Move_down"):
			target_fp_sway.y = sway_amount * 0.1
			
		var final_target = fp_camera_base_pos + target_fp_sway
		first_person_camera.position = first_person_camera.position.lerp(final_target,state.step * sway_speed)
		
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
		
	if Input.is_action_pressed("Sprint"):
		if current_stamina > 0 and not is_exhausted:
			current_state = SubState.SPRINTING
		else:
			current_state = SubState.MOVEMENT
		
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
	
	if not Input.is_action_pressed("Sprint") or is_exhausted:
		current_state = SubState.MOVEMENT

func get_state_string() -> String:
	match current_state:
		SubState.IDLE: return "IDLE"
		SubState.MOVEMENT: return "MOVING"
		SubState.SPRINTING: return "SPRINTING"
	return "UNKNOWN"
	
func update_dashboard_ui() -> void:
	var current_speed = linear_velocity.length()
	center_ui.get_node("SpeedLabel").text = "SPEED : " + String("%.1f" % current_speed) + "m/s"
	
	var current_depth = abs(global_position.y)
	center_ui.get_node("DepthLabel").text = "DEPTH : " + str(int(current_depth)) + "m"
	
	var heading_degrees = int(rad_to_deg(global_transform.basis.get_euler().y))
	update_heading(heading_degrees)
	
	var system_state = get_state_string()
	bottom_ui.get_node("StateLabel").text = "SYSTEM STATE : " + str(system_state)
	
func update_heading(heading_degress: float)-> void:
	var degrees = posmod(int(360-heading_degress), 360)
	var index = int(posmod(degrees + 22.5, 360) / 45.0)
	
	var string_direction = DIRECTIONS[index]
	
	bottom_ui.get_node("HeadingLabel").text = "HEADING : " + str(degrees) + "° {" + string_direction + "}"

func update_stamina(current_stamina: float, max_stamina: float, is_sprinting: bool) -> void:
	if is_sprinting and current_stamina > 0:
		state_label_bottom_ui.text = "SYSTEM STATE : SPRINTING"
	else:
		state_label_bottom_ui.text = "SYSTEM STATE : ACTIVE"
	
	stamina_bar_bottom_ui.max_value = max_stamina
	stamina_bar_bottom_ui.value = current_stamina

func _on_body_entered(body: Node) -> void:
	
	var state = PhysicsServer3D.body_get_direct_state(get_rid())
	
	var impact_speed = linear_velocity.length()
	
	if impact_speed > damage_threshold:
		var damage = (impact_speed - damage_threshold) * damage_multiplier
		
		current_health -= damage
		current_health = clamp(current_health, 0.0, max_health)
		
		print("COLLISION DETECTED Hit body: ", body.name,"| Speed: ", impact_speed," | Damage: ", damage)
