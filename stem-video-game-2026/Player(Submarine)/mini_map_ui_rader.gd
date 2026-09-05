extends SubViewportContainer

@export var target_sub:Node3D
@export var camera_height:float = 40
@onready var minimap_camera = $SubViewport/MiniMapCamera

func _process(delta):
	if not is_instance_valid(target_sub):
		return
	var sub_pos = target_sub.global_position
	
	minimap_camera.global_position = Vector3(sub_pos.x,sub_pos.y+camera_height,sub_pos.z)
	minimap_camera.global_rotation_degrees = Vector3(-90,0,0)
	var sub_heading = -target_sub.global_transform.basis.z
	var angle_rad = atan2(sub_heading.x, sub_heading.z)
