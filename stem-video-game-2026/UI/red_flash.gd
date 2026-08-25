extends MeshInstance3D
@onready var alarm_5 = $"."

var mat : StandardMaterial3D = null
# Called when the node enters the scene tree for the first time.
func _ready():
	if alarm_5.material_override:
		mat = alarm_5.material_override as StandardMaterial3D
	alarm_5.material_override = mat
	var tween = create_tween().set_loops()
	tween.tween_property(mat,"emission_energy_multiplier", 10.0,0.05)
	tween.tween_property(mat,"emission_energy_multiplier",0.0,0.2)
	tween.tween_interval(3.1)
