extends OmniLight3D


@export var min_energy:float=1
@export var max_energy:float=3.5
@export var pulse_speed:float = 2.0
var time_passed=0

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	time_passed += delta*pulse_speed
	light_energy=lerp(min_energy,max_energy,(sin(time_passed)+1.0)/2.0)
