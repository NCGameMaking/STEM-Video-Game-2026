extends MeshInstance3D

@export var max_turn_angle: float = 20
@export var turn_speed: float = 2.0       
@export var return_speed: float = 1.5     

var target_rotation: float = 0.0
var current_rotation: float = 0.0
var is_actively_moving: bool = false

var original_transform: Transform3D

func _ready() -> void:
	original_transform = transform

func turn_wheel(mouse_delta_x: float) -> void:
	is_actively_moving = true
	target_rotation += mouse_delta_x * 0.8
	target_rotation = clamp(target_rotation, -max_turn_angle, max_turn_angle)

func _process(delta: float) -> void:
	if not is_actively_moving:
		target_rotation = move_toward(target_rotation, 0.0, return_speed * delta * 40.0)
	
	current_rotation = lerp(current_rotation, target_rotation, turn_speed * delta)
	var rad_rotation: float = deg_to_rad(current_rotation)
	transform = original_transform.rotated_local(Vector3.UP, rad_rotation)
	is_actively_moving = false
