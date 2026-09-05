extends Node3D


@export var bounce_speed:float = 3.0
@export var bounce_height:float = 0.5
var start_y :float
func _ready():
	start_y = position.y
func _process(delta):
	position.y = start_y + sin(Time.get_ticks_msec()*0.001*bounce_speed)*bounce_height
	rotate_z(delta*1.5)
	
