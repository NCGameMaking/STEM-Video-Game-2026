extends Node3D

@export var submarine:RigidBody3D
@export var world_environment:WorldEnvironment
@export var sunlight:DirectionalLight3D

const surface_depth = 3
const zone_2_depth = 100.0
const zone_3_depth = 200.0


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
		
