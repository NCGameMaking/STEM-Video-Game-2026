extends Node3D

@export var submarine:RigidBody3D
@export var world_environment:WorldEnvironment
@export var sunlight:DirectionalLight3D

const surface_depth = 3
const zone_2_depth = 100.0
const zone_3_depth = 200.0

@onready var first_person_camera = $Submarine/FirstPersonCamera
@onready var rocks_falling = $RocksFalling
@onready var ring_label = $Submarine/TopViewport/TopUI/RingLabel
@onready var radio_manager = $Submarine/RadioManager
@onready var color_rect = $LAYER/ColorRect
@onready var target_wall = $WaterShaderExamples/VisibilityRangeLodGroup/TargetWall
@onready var animation_player = $AnimationPlayer
@onready var win_zone = $WinZone

var warhead_node_ref : Node3D = null
var waiting_for_ram : bool = false
@onready var warhead_4 = $WaterShaderExamples/VisibilityRangeLodGroup/Warhead4

func _ready():
	run_prologue()
	if win_zone and not win_zone.body_entered.is_connected(_on_surface_reached):
		win_zone.body_entered.connect(_on_surface_reached)

func _process(delta):
	if not submarine or not world_environment or not world_environment.environment:
		return
	var depth = abs(submarine.global_position.y)
	var env = world_environment.environment
	if submarine.global_position.y >= -surface_depth:
		if sunlight:
			sunlight.light_energy = 2.0
		env.volumetric_fog_enabled = false
		env.volumetric_fog_density = 0.0
		env.volumetric_fog_albedo = Color("#ffffff")
	if depth >= surface_depth and depth < zone_2_depth:
		env.volumetric_fog_enabled = true
		var t = (depth - surface_depth) / (zone_2_depth - surface_depth)
		if sunlight:
			sunlight.light_energy = lerp(1.8,0.2,t)
		env.volumetric_fog_density = lerp(0.015,0.04,t)
		env.volumetric_fog_albedo = lerp(Color("#1a6b72"), Color("#0b2545"), t)
	elif depth >= zone_2_depth and depth < zone_3_depth:
		var t = (depth-zone_2_depth) / (zone_3_depth - zone_2_depth)
		if sunlight:
			sunlight.light_energy = 1
		env.volumetric_fog_density = lerp(0.01,0.04,t)
		env.volumetric_fog_albedo = lerp(Color("#0b2545"), Color("#020813"), t)
		
func start_jammed_warhead_event(warhead_object : Node3D):
	warhead_node_ref = warhead_object
	await radio_manager.show_text_middle("[ WARNING ] : PAYLOAD 6 : MECHANISM JAMMED]",0.05)
	submarine.apply_camera_shake(.2)
	rocks_falling.play()
	await radio_manager.show_text_middle("[ COMMS ] HQ : ' Ceiling collapse imminent! RAM the warhead to force ignition!'",0.05)
	waiting_for_ram = true

func trigger_warhead_ignition(warhead_object : Node3D):
	await radio_manager.show_text_middle("[ CRITICAL ] HULL BREACH IGNITION!")
	await get_tree().create_timer(1.0).timeout
	color_rect.modulate.a = 0.0
	color_rect.color = Color(1,1,1,1)

	var move_tween = create_tween()
	move_tween.tween_property(warhead_4,"position:z", warhead_4.position.z + 120,3)
	submarine.apply_camera_shake(.3)
	await move_tween.finished
	$UnderwaterExplosion.play()
	$EarsRinging.play()
	warhead_4.queue_free()
	submarine.apply_camera_shake(.3)

	var flash_tween = create_tween()
	flash_tween.tween_property(color_rect,"modulate:a",1.0,0.5)
	await get_tree().create_timer(0.4).timeout
	submarine.apply_camera_shake(.3)
	$ExplosionRocksFall.play()
	rocks_falling.stop()

	if target_wall:
		var slide_tween = create_tween()
		slide_tween.tween_property(target_wall,"position:y", target_wall.position.y + 90,0.1)
	var fade_back_tween = create_tween()
	fade_back_tween.tween_property(color_rect, "modulate:a",0.0,2)
	submarine.apply_camera_shake(.3)
	await get_tree().create_timer(1.0).timeout
	color_rect.color = Color(0,0,0,0)
	color_rect.modulate.a = 1.0
	await radio_manager.show_text_middle("[ OBJECTIVE ] ESCAPE THROUGH THE BREACH!")

func run_prologue():
	var fade_in = create_tween()
	fade_in.tween_property(color_rect, "color:a",0,8)
	color_rect.visible = true
	color_rect.color = Color(0,0,0,1)
	color_rect.modulate.a = 1.0
	if animation_player:
		animation_player.play("prologue_drop")
	#await animation_player.animation_finished
	await get_tree().create_timer(6).timeout
	await radio_manager.show_text_middle("[ TUGBOAT COMM ] : Deployment cable locked. Lowering into Trench...", 0.05)
	submarine.set_deploying(false)
	await radio_manager.show_text_middle("[ OBJECTIVE ] SECURE ALL 6 WARHEADS", 0.05)
	radio_manager.unlock_hints()

func _on_surface_reached(body: Node3D):
	if body.is_in_group("player"):
		win_zone.set_deferred("monitoring",false)
		start_epilogue_extraction()

func start_epilogue_extraction():
	submarine.set_extraction(true)
	if animation_player:
		animation_player.play("epilogue_extraction")
	await radio_manager.show_text_middle("[ TUGBOAT COMM ] : Visual on your ascent. Securing recovery cables...", 0.05)
	await get_tree().create_timer(2.0).timeout
	await radio_manager.show_text_middle("[ TUGBOAT COMM ] : Warhead payload confirmed aboard. Great work, operator.", 0.05)
	await get_tree().create_timer(4.0).timeout
	color_rect.modulate.a = 1.0
	color_rect.color = Color(0,0,0,0)
	await animation_player.animation_finished
	var fade_out = create_tween()
	fade_out.tween_property(color_rect, "color:a",1,2)
	color_rect.color = Color(0,0,0,1)
	await get_tree().create_timer(1.5).timeout
	Global.show_debrief_on_menu = true
	get_tree().change_scene_to_file("res://UI/cinematic_menu.tscn")
	
