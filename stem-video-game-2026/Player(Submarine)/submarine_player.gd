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
@export var damage_threshold : float = 12
@export var damage_multiplier : float = 2.5
var speed_last_frame: float = 0.0
var is_dead : bool = false

var flash_timer : float = 0.0
@export var flash_speed : float = 10.0

@onready var debug_ui = $DebugUI
@onready var first_person_camera = $FirstPersonCamera
@onready var periscope_camera = $CameraMount/ThirdPersonCamera
@onready var scan_light = $CameraMount/ThirdPersonCamera/ScanLight

var periscope_active : bool = false
var periscope_yaw : float = 0.0
var periscope_pitch : float = 0.0

var warheads_collected : int = 0
const total_warheads : int = 6
@export var max_water_surface_y : float = -1.0
@export var max_periscope_range : float = 500

@export var mms_range : float = 200.0
@export var mms_angle_degrees : float = 60.0

var is_deploying : bool = true
var is_evacuating : bool = false

@onready var status_label = $PeriscopeUI/GlassScreenThingy/PeriscopeUI/MMScanerstatus
@onready var readout_label = $PeriscopeUI/GlassScreenThingy/PeriscopeUI/Readoutlabel
@export var objective_target : Node3D
@onready var beacon_reader = $PeriscopeUI/GlassScreenThingy/PeriscopeUI/BeaconReader

@onready var periscope_ui = $PeriscopeUI
@onready var cracked_glass = $PeriscopeUI/CrackedGlass
@onready var glass_screen = $PeriscopeUI/GlassScreenThingy

@onready var marine_snow = $MarineSnow
@onready var lights = $Lights
@onready var light_switch = $AudioSFX/LightSwitch

@onready var engine_hum = $AudioSFX/EngineHum
@onready var impact_audio = $AudioSFX/ImpactAudio
@onready var periscope_rise = $AudioSFX/PeriscopeRise
@onready var periscope_swivel = $AudioSFX/PeriscopeSwivel
@onready var hull_alarm = $AudioSFX/HullAlarm
@onready var death = $AudioSFX/Death
@onready var switch_camera = $AudioSFX/SwitchCamera
@onready var ui_warning_alert = $AudioSFX/UIWarningAlert
@onready var metal_creaking = $AudioSFX/MetalCreaking
@onready var under_water_amb = $AudioSFX/UnderWaterAmb
@onready var periscope_rotate = $AudioSFX/PeriscopeRotate
@onready var go_up_bubble = $AudioSFX/GoUpBubble
@onready var go_down_hiss = $AudioSFX/GoDownHiss
@onready var steering_wheel_audio = $AudioSFX/SteeringWheel
@onready var mms_scan = $AudioSFX/MMSScan

var warning_played : bool = false
var target_engine_pitch : float = 0.0
var creak_timer : float = 0.0

@onready var center_booster = $BubbleBoosters/CenterBooster
@onready var dive_booster = $BubbleBoosters/DiveBooster
@onready var climb_booster = $BubbleBoosters/ClimbBooster
@onready var left_booster = $BubbleBoosters/LeftBooster
@onready var right_booster = $BubbleBoosters/RightBooster
@onready var strafe_left_booster = $BubbleBoosters/StrafeLeftBooster
@onready var strafe_right_booster = $BubbleBoosters/StrafeRightBooster

@onready var top_ui = $TopViewport/TopUI
@onready var center_ui = $CenterViewport/CenterUI
@onready var bottom_ui = $BottomViewport/BottomUI

@onready var stamina_bar_bottom_ui = $BottomViewport/BottomUI/StaminaBar
@onready var state_label_bottom_ui = $BottomViewport/BottomUI/StateLabel

@onready var left_light_1 = $TopViewport/TopUI/LeftLight1
@onready var left_light_2 = $TopViewport/TopUI/LeftLight2
@onready var left_light_3 = $BottomViewport/BottomUI/LeftLight3
@onready var left_light_4 = $BottomViewport/BottomUI/LeftLight4
var is_critical: bool = false

@onready var health_bar_top_ui = $TopViewport/TopUI/HullProgressBar
@onready var hull_label_top_ui = $TopViewport/TopUI/HullLabel
@onready var health_pct_label_top_ui = $TopViewport/TopUI/PercentageLabel

@onready var steering_wheel = $Submarine/SteeringWheel

@onready var ray = $Ray

@onready var top_screen = $Submarine/TopScreen
@onready var top_viewport = $TopViewport

@export var sway_amount: float  = 0.5
@export var sway_speed: float  = 4.0
@onready var camera_mount = $CameraMount

@onready var pause_menu = $PauseMenu
@onready var resume_button = $PauseMenu/ColorRect/VBoxContainer/ResumeButton
@onready var quit_button = $PauseMenu/ColorRect/VBoxContainer/QuitButton
@onready var pause_label = $PauseMenu/ColorRect/PauseLabel

var can_scan : bool = true

var rot_target := Vector3.ZERO

var is_exhausted: bool = false

var mouse_input : float = 0.0
var is_first_person: bool = false
var fp_camera_base_pos : Vector3 = Vector3.ZERO
var mouse_input_x: float = 0.0
var current_speed = linear_velocity.length()

func _ready():
	if engine_hum and engine_hum.stream:
		engine_hum.play()
	if under_water_amb and under_water_amb.stream:
		under_water_amb.play()
	
	is_first_person = true
	rot_target.y = global_transform.basis.get_euler().y
	glass_screen.visible = false
	if cracked_glass:
		cracked_glass.visible = false
	is_dead = false
	body_entered.connect(_on_body_entered)
	
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	toggle_periscope(false)
	fp_camera_base_pos = first_person_camera.position

	var screen_mesh = $Submarine/TopScreen
	var viewport_node = $TopViewport

	var mat = screen_mesh.get_active_material(0)
	if mat:
		mat.albedo_texture = viewport_node.get_texture()
		mat.uv1_scale = Vector3(-2.0, 2.0, 2.0) 
		print("Texture successfully linked at runtime!")


func _physics_process(delta):
	if is_dead:
		return
	speed_last_frame = linear_velocity.length()
	
	if ray and ray.is_colliding():
		bottom_ui.get_node("CollisionWarning").text = "COLLISION WARNING!"
		bottom_ui.get_node("CollisionWarning").modulate = Color(1,0,0)
	else:
		bottom_ui.get_node("CollisionWarning").text = "COLLISION : FINE"
		bottom_ui.get_node("CollisionWarning").modulate = Color(1,1,1)

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
	
	var health_pct = (current_health / max_health) * 100
	
	if is_critical:
		flash_timer += delta * flash_speed
		
		var flash_state = sin(flash_timer) > 0.0
		
		left_light_1.visible = flash_state
		left_light_2.visible = flash_state
		left_light_3.visible = flash_state
		left_light_4.visible = flash_state
	else:
			left_light_1.visible = true
			left_light_2.visible = true
			left_light_3.visible = true
			left_light_4.visible = true
	var current_speed = linear_velocity.length()
	var speed_ratio = clamp(current_speed / 15, 0, 1)
	
	if engine_hum and engine_hum.stream:
		target_engine_pitch = lerp(0.85,1.4, speed_ratio)
		engine_hum.pitch_scale = lerp(engine_hum.pitch_scale, target_engine_pitch, 5.0 * delta)
	if hull_alarm:
		if is_critical and not hull_alarm.playing and not is_dead:
			hull_alarm.play()
		elif not is_critical and hull_alarm.playing:
			hull_alarm.stop()
			
	var current_depth = abs(global_position.y)
	if current_depth > 20 and not is_dead:
		creak_timer += delta
		if creak_timer > randf_range(8,15):
			creak_timer = 0.0
			if metal_creaking and not metal_creaking.playing:
				metal_creaking.play()
	if marine_snow and marine_snow.process_material:
		var target_speed = 2.0 if current_state==SubState.SPRINTING else 1.0
		marine_snow.speed_scale = lerp(marine_snow.speed_scale,target_speed, 3 * delta)

	update_dashboard_ui()

func _unhandled_input(event: InputEvent):
	if event.is_action_pressed("Toggle_light"):
		if lights:
			lights.visible = !lights.visible
			
			if light_switch and light_switch.stream:
				light_switch.play()
		
		
	if event.is_action_pressed("Toggle_camera"):
		is_first_person = !is_first_person
		toggle_periscope(!is_first_person)
			
	if event is InputEventMouseMotion and Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
		if periscope_active:
			periscope_yaw -= event.relative.x * mouse_sensitivity
			camera_mount.rotation.y = periscope_yaw
			
			periscope_pitch -= event.relative.y * mouse_sensitivity
			periscope_pitch = clamp(periscope_pitch, deg_to_rad(-25), deg_to_rad(25))
			periscope_camera.rotation.x = periscope_pitch
			if periscope_swivel and not periscope_swivel.playing:
				periscope_swivel.play()
			
		else:
			rot_target.y -= event.relative.x * mouse_sensitivity
			rot_target.y = wrapf(rot_target.y, -PI, PI)
			
			rot_target.x -= event.relative.y * mouse_sensitivity
			rot_target.x = clamp(rot_target.x, deg_to_rad(-45.0), deg_to_rad(45.0))

			if steering_wheel and steering_wheel.has_method("turn_wheel"):
				steering_wheel.turn_wheel(event.relative.x)
			#if event.relative.x !=0 and steering_wheel_audio and not steering_wheel_audio.playing:
				#steering_wheel_audio.play()

func _integrate_forces(state):
	var is_moving_forward = Input.is_action_pressed("Move_forward")
	left_booster.emitting = is_moving_forward
	center_booster.emitting = is_moving_forward
	right_booster.emitting = is_moving_forward
	
	strafe_left_booster.emitting = Input.is_action_pressed("Move_right")
	strafe_right_booster.emitting = Input.is_action_pressed("Move_left")
	climb_booster.emitting = Input.is_action_pressed("Move_up")
	dive_booster.emitting = Input.is_action_pressed("Move_down")
	if is_moving_forward:
		var ratio = 1.5 if current_state == SubState.SPRINTING else 1.0
		if current_state == SubState.SPRINTING:
			left_booster.amount_ratio = ratio
			center_booster.amount_ratio = ratio
			right_booster.amount_ratio = ratio
	if not periscope_active:
		var current_euler = state.transform.basis.get_euler()
		var new_x = lerp_angle(current_euler.x, rot_target.x, 15.0 * state.step)
		var new_y = lerp_angle(current_euler.y, rot_target.y, 15.0 * state.step)
		state.transform.basis = Basis.from_euler(Vector3(new_x, new_y, 0.0))
		state.angular_velocity = Vector3.ZERO
	
	var force_vector = Vector3.ZERO
	var basis = state.transform.basis

	if Input.is_action_pressed("Move_forward"):
		force_vector -= basis.z * move_force
	if Input.is_action_pressed("Move_backward"):
		force_vector += basis.z * move_force
	if Input.is_action_pressed("Move_left"):
		force_vector -= basis.x * move_force
	if Input.is_action_pressed("Move_right"):
		force_vector += basis.x * move_force
	if Input.is_action_pressed("Move_up"):
		force_vector += Vector3.UP * move_force
		if go_up_bubble : go_up_bubble.play()
	elif Input.is_action_just_released("Move_up"):
		if go_up_bubble : go_up_bubble.stop()

	if Input.is_action_pressed("Move_down"):
		force_vector -= Vector3.UP * move_force
		if go_down_hiss and not go_down_hiss.playing: go_down_hiss.play()
	elif Input.is_action_just_released("Move_down"):
		if go_down_hiss and not go_up_bubble.playing : go_down_hiss.stop()

	var is_sprinting = Input.is_action_pressed("Sprint") and not is_exhausted and force_vector != Vector3.ZERO
	if is_sprinting:
		force_vector *= sprint_multiplier
		current_state = SubState.SPRINTING
	elif force_vector != Vector3.ZERO:
		current_state = SubState.MOVEMENT
	else:
		current_state = SubState.IDLE
		
	if state.transform.origin.y > max_water_surface_y:
		state.transform.origin.y = max_water_surface_y
		if state.linear_velocity.y > 0:
			state.linear_velocity.y = 0.0
	
	
	state.apply_central_force(force_vector)

	if debug_ui:
		debug_ui.update_property("Current State", get_state_string())
		debug_ui.update_property("FPS: ", Engine.get_frames_per_second())
		debug_ui.update_property("Linear Velocity", state.linear_velocity.snapped(Vector3(0.1, 0.1, 0.1)))
		debug_ui.update_property("Speed (m/s)", "%0.2f" % state.linear_velocity.length())
	
	var target_fov = sprint_fov if current_state == SubState.SPRINTING else normal_fov

	if is_first_person:
		first_person_camera.fov = lerp(first_person_camera.fov, target_fov, state.step * zoom_speed)
		
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
	else:
		periscope_camera.fov = lerp(periscope_camera.fov, target_fov, state.step * zoom_speed)
		
		if camera_mount:
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

func get_state_string() -> String:
	match current_state:
		SubState.IDLE: return "IDLE"
		SubState.MOVEMENT: return "MOVING"
		SubState.SPRINTING: return "SPRINTING"
	return "UNKNOWN"
	
func update_dashboard_ui() -> void:
	if is_dead:
		return
	
	var current_speed = linear_velocity.length()
	center_ui.get_node("SpeedLabel").text = "SPEED : " + String("%.1f" % current_speed) + "m/s"
	
	var current_depth = abs(global_position.y)
	center_ui.get_node("DepthLabel").text = "DEPTH : " + str(int(current_depth)) + "m"
	
	var heading_degrees = int(rad_to_deg(global_transform.basis.get_euler().y))
	update_heading(heading_degrees)
	
	var system_state = get_state_string()
	bottom_ui.get_node("StateLabel").text = "SYSTEM STATE : " + str(system_state)
	
	update_hull_health(current_health, max_health)
	
	top_ui.get_node("PercentageLabel").text = str( "%.0f" % current_health) + "%"
	
	top_ui.get_node("RingLabel").text ="WARHEADS : " +str(warheads_collected)+ " / " + str(total_warheads)
func update_heading(heading_degress: float)-> void:
	var degrees = posmod(int(360-heading_degress), 360)
	var index = int(posmod(degrees + 22.5, 360) / 45.0)
	
	var string_direction = DIRECTIONS[index]
	
	bottom_ui.get_node("HeadingLabel").text = "HEADING : " + str(degrees) + "° {" + string_direction + "}"

@warning_ignore("shadowed_variable")
func update_stamina(current_stamina: float, max_stamina: float, is_sprinting: bool) -> void:
	if is_dead:
		return
	
	if is_sprinting and current_stamina > 0:
		state_label_bottom_ui.text = "SYSTEM STATE : SPRINTING"
	else:
		state_label_bottom_ui.text = "SYSTEM STATE : ACTIVE"
	
	stamina_bar_bottom_ui.max_value = max_stamina
	stamina_bar_bottom_ui.value = current_stamina

func _on_body_entered(body: Node) -> void:
	var impact_speed = speed_last_frame
	speed_last_frame = 0
	
	if impact_speed > damage_threshold:
		var damage = (impact_speed - damage_threshold) * damage_multiplier
		
		current_health -= damage
		current_health = clamp(current_health, 0.0, max_health)
		
		if impact_audio and impact_audio.stream:
			var impact_intensity = clamp((impact_speed - damage_threshold) / 20,0,1)
			impact_audio.volume_db = lerp(-10, 2,impact_intensity)
			impact_audio.pitch_scale = randf_range(0.9,1.1)
			impact_audio.play()
			
		print("COLLISION DETECTED Hit body: ", body.name,"| Speed: ", impact_speed," | Damage: ", damage)
		var shake_tween = create_tween()
		var camera = $FirstPersonCamera
		
		var shake_intensity = (impact_speed - damage_threshold) * 0.01
		
		shake_tween.tween_property(camera, "h_offset", shake_intensity, 0.05)
		shake_tween.tween_property(camera, "h_offset", -shake_intensity, 0.05)
		shake_tween.tween_property(camera, "h_offset", 0.0, 0.05)
		if current_health <= 0.0 and not is_dead:
			trigger_submarine_destruction()

func take_damage(amount:float)-> void:
	current_health -= amount
	current_health = clamp(current_health,0.0,max_health)
	if current_health <=0:
		trigger_submarine_destruction()

func update_hull_health(current_health: float, max_health: float) -> void:
	if is_dead:
		return
	
	health_bar_top_ui.max_value = max_health
	health_bar_top_ui.value = current_health
	
	var health_pct = (current_health / max_health) * 100
	
	if health_pct <= 66 and not warning_played:
		warning_played = true
		if ui_warning_alert:
			ui_warning_alert.play()
	elif health_pct > 66.0:
		warning_played = false
	
	if health_pct >= 66:
		is_critical = false
		hull_label_top_ui.text="HULL INTEGRITY: STABLE"
		health_bar_top_ui.set_tint_progress(Color(1,1,1))
		
		left_light_1.modulate = (Color(0,1,0))
		left_light_2.modulate = (Color(0,1,0))
		left_light_3.modulate = (Color(0,1,0))
		left_light_4.modulate = (Color(0,1,0))
		
	elif health_pct >= 25:
		is_critical = false
		hull_label_top_ui.text="HULL INTEGRITY: DAMAGED"
		health_bar_top_ui.set_tint_progress(Color(1,.5,0))
		
		left_light_1.modulate = (Color(1,.5,0))
		left_light_2.modulate = (Color(1,.5,0))
		left_light_3.modulate = (Color(1,.5,0))
		left_light_4.modulate = (Color(1,.5,0))
	else:
		is_critical = true
		hull_label_top_ui.text="HULL INTEGRITY: CRITICAL"
		health_bar_top_ui.set_tint_progress(Color(1,0,0))
		
		left_light_1.modulate = (Color(1,0,0))
		left_light_2.modulate = (Color(1,0,0))
		left_light_3.modulate = (Color(1,0,0))
		left_light_4.modulate = (Color(1,0,0))

func trigger_submarine_destruction():
	update_dashboard_ui()
	is_dead = true
	print("ZUB IS DED")
	linear_velocity = Vector3.ZERO
	angular_velocity = Vector3(50, 50, 50)
	var camera = $FirstPersonCamera

	var camera_tween = get_tree().create_tween()
	
	camera_tween.tween_property(camera, "rotation_degrees", Vector3(15,0,8), 0.3).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	await get_tree().create_timer(1).timeout
	if engine_hum:engine_hum.stop()
	if hull_alarm:hull_alarm.stop()
	death.play()

	freeze = true

	if has_node("TopViewport/TopUI/HullLabel"):
		hull_label_top_ui.text = "ERROR : HULL BREACHED"
	if has_node("BottomViewport/BottomUI/StateLabel"):
		state_label_bottom_ui.text = "FAILURE : POWER LOST"
	
	left_light_1.visible = false
	left_light_2.visible = false
	left_light_3.visible = false
	left_light_4.visible = false
	
	await get_tree().create_timer(0.4).timeout
	var fade_tween = create_tween().set_parallel(true)
	fade_tween.tween_property(center_ui.get_node("ColorRect"), "modulate:a", 1.0, 1.8)
	fade_tween.tween_property(top_ui.get_node("ColorRect"), "modulate:a", 1.0, 1.8)
	fade_tween.tween_property(bottom_ui.get_node("ColorRect"), "modulate:a", 1.0, 1.8)
	await get_tree().create_timer(1).timeout
	pause_menu.trigger_death()

func toggle_periscope(enable: bool):
	periscope_active = enable
	
	if switch_camera and switch_camera.stream:
		switch_camera.play()
		if periscope_rise and periscope_rise.stream:
			periscope_rise.play()

	if periscope_active:
		periscope_camera.current = true
		set_process_unhandled_input(false)
		$AnimationPlayer.play("periscope rise")
		periscope_camera.fov = 35.0
		glass_screen.visible = true
		$PeriscopeUI/GlassScreenThingy/PeriscopeUI.visible = true
		await $AnimationPlayer.animation_finished
		set_process_unhandled_input(true)
		if current_health <= 25:
			cracked_glass.visible = true
		else:
			cracked_glass.visible = false
	else:
		$PeriscopeUI/GlassScreenThingy/PeriscopeUI.visible = false
		set_process_unhandled_input(false)
		$AnimationPlayer.play("periscope falls")
		await $AnimationPlayer.animation_finished
		$FirstPersonCamera.current = true
		set_process_unhandled_input(true)
		periscope_camera.fov = 75.0
		glass_screen.visible = false
		cracked_glass.visible = false

func _input(event:InputEvent):
	if event.is_action_pressed("mms_scan"):
		if periscope_active == true:
			fire_mms_scan()

func fire_mms_scan():
	if not can_scan:
		print("MMS scane on cooldown")
		return
	mms_scan.play()
	can_scan = false
	scan_light.position = Vector3(0,0,-1.0)
	scan_light.light_energy = 8.0
	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(scan_light, "position:z", -25.0, 0.6).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(scan_light, "light_energy", 0.0,0.6)
	status_label.text = "[ MMS SCANNER - SCANNING... ]"
	print("MMS scan fired")
	
	var mines_found :int = 0
	var sharks_found :int = 0
	var forward_dir = -periscope_camera.global_transform.basis.z.normalized()

				
	#mines
	var mine = get_tree().get_nodes_in_group("seamine")
	
	for mines in mine:
		var to_target = (mines.global_position - periscope_camera.global_position)
		var dist = to_target.length()
		var angle = rad_to_deg(forward_dir.angle_to(to_target.normalized()))
		if dist <=mms_range and angle <= mms_angle_degrees:
			mines_found += 1
			
	#sharks
	var shark = get_tree().get_nodes_in_group("shark")
	
	for sharks in shark:
		var to_target = (sharks.global_position - periscope_camera.global_position)
		var dist = to_target.length()
		var angle = rad_to_deg(forward_dir.angle_to(to_target.normalized()))
		if dist <=mms_range and angle <= mms_angle_degrees:
			sharks_found += 1
	update_readout_note(mines_found,sharks_found)
	
	await get_tree().create_timer(3.0).timeout
	status_label.text = "[ MMS SCANNER - READY ]"
	can_scan = true

func update_readout_note(mines : int, sharks : int):
	var text_out = "=== SCAN RESULTS ===\n"
	if mines > 0:
		text_out += "[ WARNING ] MINES IN RANGE : " +str(mines) + "\n"
	if sharks > 0:
		text_out += "[ DANGER ] HOSTILE BIOMASS : " + str(sharks) + "\n"
		
	var beacon_info = get_beacon_readout(objective_target)
	
	
	readout_label.text = text_out
	beacon_reader.text = beacon_info
	
func get_beacon_readout(target_node:Node3D):
	if not is_instance_valid(target_node):
		return "\n[ BEACON ] NO SIGNAL DETECTED"
	var dist = global_position.distance_to(target_node.global_position)
	var strength_str: String=""
	if dist > 1000:
		strength_str = "VERY WEAK"
	elif dist > 800:
		strength_str = "WEAK"
	elif dist > 500.0:
		strength_str = "MODERATE"
	else:
		strength_str = "STRONG (NEARBY)"
	
	var forward = -global_transform.basis.z.normalized()
	var to_target = (target_node.global_position - global_position).normalized()
	var angle = rad_to_deg(forward.signed_angle_to(to_target, Vector3.UP))
	
	var dir_str:String = "AHEAD"
	if angle > 30.0:
		dir_str = "STARBOARD (RIGHT)"
	if angle < -30.0:
		dir_str = "PORT (LEFT)"
	elif abs(angle) > 135.0:
		dir_str = "BEHIND"
	var y_difference = target_node.global_position.y - global_position.y
	var vert_str : String = "LEVEL"
	if y_difference < -15.0:
		vert_str = "BELOW"
	elif y_difference > 15.0:
		vert_str = "ABOVE"
	return "\n[ BEACON ] SIGNAL : %s | DIRECTION : %s | DEPTH: %s" %[strength_str,dir_str,vert_str]
	
	
func apply_camera_shake(shake_intensity:float):
		var shake_tween = create_tween()
		var camera = $FirstPersonCamera

		shake_tween.tween_property(camera, "h_offset", shake_intensity, 0.05)
		shake_tween.tween_property(camera, "h_offset", -shake_intensity, 0.05)
		shake_tween.tween_property(camera, "h_offset", 0.0, 0.05)

func set_deploying(value:bool):
	is_deploying = value
func set_extraction(value:bool):
	is_evacuating = value
