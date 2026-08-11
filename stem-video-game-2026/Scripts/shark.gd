extends PathFollow3D

enum State {PATROL, CHASE}

@export var patrol_speed : float = 6.0
@export var chase_speed : float = 14.0

@onready var shark_area = $Shark

var current_state : State = State.PATROL
var target_sub : RigidBody3D = null
var can_bite : bool = false

# Called when the node enters the scene tree for the first time.
func _ready():
	if shark_area:
		shark_area.body_entered.connect(_on_body_entered)
		shark_area.area_entered.connect(_on_area_entered)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	match current_state:
		State.PATROL:
			progress += patrol_speed * delta
		State.CHASE:
			if is_instance_valid(target_sub):
				var target_pos = target_sub.global_position
				shark_area.look_at(target_pos, Vector3.UP)
				shark_area.global_position = shark_area.global_position.move_toward(
					target_pos,chase_speed * delta
				)
			else:
				current_state = State.PATROL

func _on_area_entered(area:Area3D):
	if area.is_in_group("playerlight"):
		target_sub = area.get_owner() as RigidBody3D
		if target_sub:
			current_state = State.CHASE

func _on_body_entered(body:Node3D):
	if body == target_sub and can_bite:
		can_bite = false
		if body.has_method("take_damage"):
			body.take_damage(40)
		if body is RigidBody3D:
			var push_dir = (body.global_position - shark_area.global_position).normalized()
			body.apply_central_impulse(push_dir * 25)
		var camera = get_viewport().get_camera_3d()
		if camera and camera.has_method("apply_shake"):
			camera.apply_shake(2.0)
			
		await get_tree().create_timer(1.2).timeout
		shark_area.position = Vector3.ZERO
		current_state = State.PATROL
		can_bite = true
