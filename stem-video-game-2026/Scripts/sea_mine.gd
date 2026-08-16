extends RigidBody3D

@export var detection_radius: float = 12.0
@onready var warning_alarm = $TriggersBase/Alarm
@onready var alarm_sfx = $AlarmSFX
@onready var explosion_sfx = $ExplosionSFX
@onready var flash_particles = $FlashParticles
@onready var debris_particles = $DebrisParticles
@onready var bubble_particles = $BubbleParticles
@onready var white_bubble_particles = $WhiteBubbleParticles
@onready var alarm = $TriggersBase/Alarm

var player_sub: Node3D = null
var is_warning_active: bool = false
var tween: Tween = null
var mat : StandardMaterial3D =null

func _ready():
	if warning_alarm:
		warning_alarm.visible = false
		
		if warning_alarm.material_override:
			mat = warning_alarm.material_override as StandardMaterial3D
		else:
			mat = StandardMaterial3D.new()
			mat.emission_enabled = true
			mat.emission = Color(1,0,0)
			warning_alarm.material_override = mat

func _process(_delta:float):
	if not is_instance_valid(player_sub):
		var players = get_tree().get_nodes_in_group("player")
		if players.size()>0:
			player_sub = players[0]
			print("Found player sub: ", player_sub.name)
		return
	var alarm_pos = warning_alarm.global_position if warning_alarm else global_position
	var dist = alarm_pos.distance_to(player_sub.global_position)
	if dist <= detection_radius:
		if not is_warning_active:
			is_warning_active = true
			start_warning()
	else:
		if is_warning_active:
			stop_warning()

func start_warning():
	if not warning_alarm or not mat:
		return
		
	warning_alarm.visible = true
	if tween and tween.is_running():
		tween.kill()
	
	tween = create_tween().set_loops()
	tween.tween_property(mat,"emission_energy_multiplier", 10.0,0.05)
	tween.tween_property(mat,"emission_energy_multiplier",0.0,0.2)
	tween.tween_interval(0.25)
	
	if alarm_sfx and alarm_sfx.stream:
		alarm_sfx.play()
	
	await tween.finished
	
	if is_warning_active:
		await get_tree().create_timer(0.25).timeout
		start_warning()
	
func stop_warning():
	is_warning_active = false
	if tween and tween.is_running():
		tween.kill()
	if warning_alarm:
		warning_alarm.visible = false
	if alarm_sfx:
		alarm_sfx.playing = false
	if mat:
		mat.emission_energy_multiplier = 0.0


func _on_body_entered(body:Node3D):
	if body.is_in_group("player") or body.name == "Submarine":
		explode(body)
		print(body.name)

func explode(sub : Node3D):
	var blast_pos = alarm.global_position
	print("sea mine eplodeed")
	if sub.has_method("take_damage"):
		sub.take_damage(50)
	if sub.has_method("apply_camera_shake"):
		sub.apply_camera_shake(1.5)
	
	var particle_systems = [flash_particles,debris_particles,bubble_particles,white_bubble_particles]
	if explosion_sfx and explosion_sfx.stream:
		explosion_sfx.reparent(get_parent())
		explosion_sfx.play()
	for particle_node in particle_systems:
		if is_instance_valid(particle_node):
			particle_node.reparent(get_parent())
			particle_node.global_position = blast_pos
			particle_node.emitting = true
			particle_node.restart()
	visible = false
	
	get_tree().create_timer(2).timeout
	queue_free()
	


func _on_detonation_body_entered(body):
	if body.is_in_group("player") or body.name == "Submarine":
		explode(body)
		print(body.name)
