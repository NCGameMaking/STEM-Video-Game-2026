extends Area3D

signal warhead_secured

@export var surface_y_level : float = 0.0
@export var float_duration: float = 8.0
@onready var buoy_visual = $PickupArea/BuoyVisual
@onready var collision_shape_3d = $CollisionShape3D
@onready var pickup_area = $PickupArea
var is_recovering : bool = false
@onready var bang_sound = $BangSound

@export var is_explosive_breach : bool = false
var is_igniting = false
func _ready():
	is_igniting = false
	if buoy_visual:
		buoy_visual.visible = false
	if pickup_area:
		pickup_area.body_entered.connect(_on_player_entered)

func _on_player_entered(body : Node3D):
	if is_recovering:
		return
	if body.is_in_group("player"):
		if is_explosive_breach:
			if is_igniting == true:
				var main_scene = get_tree().current_scene
				if main_scene.get("waiting_for_ram") and main_scene.warhead_node_ref == self:
					var player = get_tree().root.find_child("Submarine", true,false)
					if $".".has_overlapping_bodies():
						bang_sound.play()
						if player.linear_velocity.length() > 12.0:
							main_scene.trigger_warhead_ignition(self)
							$RocketFire.emitting = true
			else:
				trigger_jammed_sequence()
		else:
			is_recovering = true
			start_sequence_recovery()
			body.warheads_collected +=1
			
func start_sequence_recovery():
	is_recovering = true
	if buoy_visual:
		buoy_visual.visible = true
		buoy_visual.scale = Vector3.ZERO

	emit_signal("warhead_secured")
	
	var float_tween = create_tween()
	float_tween.tween_property(buoy_visual,"scale", Vector3(120,120,120), 0.6).set_trans(Tween.TRANS_SPRING).set_ease(Tween.EASE_OUT)
	float_tween.tween_interval(1.5)
	if collision_shape_3d:
		collision_shape_3d.set_deferred("disabled", true)
	float_tween.tween_property(self, "global_position:y",surface_y_level,float_duration)
	float_tween.parallel().tween_property(self, "rotation_degrees:y", rotation_degrees.y+180,float_duration)
	
	float_tween.finished.connect(_on_reached_surface)

func _on_reached_surface():
	queue_free()

func trigger_jammed_sequence():
	var level = get_tree().current_scene
	if level.has_method("start_jammed_warhead_event"):
		level.start_jammed_warhead_event(self)
	is_igniting = true
