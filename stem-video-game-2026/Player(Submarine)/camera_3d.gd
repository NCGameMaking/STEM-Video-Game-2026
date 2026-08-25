extends Camera3D
@onready var camera = $"."

func _ready():
	start_camera_drift()

func start_camera_drift():
	var drift_tween = create_tween().set_loops()
	drift_tween.tween_property(camera,"rotation_degrees:z", 1.5,8.0).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	drift_tween.tween_property(camera,"rotation_degrees:z", -1.5,8.0).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	
	var pitch_tween = create_tween().set_loops()
	pitch_tween.tween_property(camera, "rotation_degrees:x",1.0,12.0).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	pitch_tween.tween_property(camera, "rotation_degrees:x",-1.0,12.0).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

	
