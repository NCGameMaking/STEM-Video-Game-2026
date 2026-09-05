extends Node3D
class_name RadioHintManager
@onready var objective_target =$".."
@onready var status_label = $"../RadioUI/BannerBackground/StatusLabel"
@onready var banner_bg = $"../RadioUI/BannerBackground"
@onready var warhead_tracker_label = $"../TopViewport/TopUI/RingLabel"
@onready var engine_hum = $"../AudioSFX/EngineHum"

@export var player_sub : Node3D
@export var hint_cooldown : float = 30.0

var is_typing : bool = false
var idle_timer : float = 0.0
var closest_distance_recorded : float = 99999.0
var current_hint_index : int = 0
var warheads_collected : int = 0
var total_warheads : int = 6

var hints_locked:bool = true

var hint_messages : Array[String] = [
	"[ COMMS ] HQ : ' Approximate angle of trench entrance is 80-90૜° E. Stay cautious of sea mines.'",
	"[ COMMS ] HQ : ' Press V to enter the periscope, Followed by X to launch an MMS scan.'",
	"[ COMMS ] HQ : ' Radiation pings indicate the warhead is in the lower trench. Use the MMS scan to find the entrance to it.'",
	"[ COMMS ] HQ : ' Check your depth gauge. You need to descend into the lower canyon (333m+)'",
	"[ COMMS ] HQ : ' Depth Mapping shows that there are 3 tunnels leading to the submarine, only 1 is the safe passage'",
	"[ COMMS ] HQ : ' When you have located the warheads, touch/hover near them to attach the buoy'"

]
# Called when the node enters the scene tree for the first time.
func _ready():
	pass
func unlock_hints():
	hints_locked = false
	idle_timer = 0


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta :float):
	if hints_locked:
		return
		
	if not is_instance_valid(player_sub) or not is_instance_valid(objective_target):
		return
	var current_dist =player_sub.global_position.distance_to(objective_target.global_position)
	if current_dist < (closest_distance_recorded - 15.0):
		closest_distance_recorded = current_dist
		idle_timer = 0
	else:
		idle_timer += delta
	if idle_timer >= hint_cooldown:
		trigger_comms_hint()
		idle_timer = 0
func trigger_comms_hint():
	if hint_messages.size() > 0:
		var next_msg = hint_messages[current_hint_index]
		show_text_middle(next_msg,0.03)
		current_hint_index = (current_hint_index + 1) % hint_messages.size()

func show_text_middle(full_text:String, speed:float = 0.03):
	if is_typing:
		return
	is_typing = true
	$"../RadioUI/BorderFrame".visible = true
	banner_bg.visible = true
	play_radio_alert()
	status_label.text=""
	var flash_tween = create_tween().set_loops(4)
	flash_tween.tween_property($"../RadioUI/BorderFrame","modulate",Color(1,0.8,0),0.2)
	flash_tween.tween_property($"../RadioUI/BorderFrame","modulate",Color(0,0,0),0.2)
	var mid = full_text.length()/2
	var max_steps = max(mid,full_text.length() - mid) +1
	for step in range(1,max_steps + 1):
		var start = max(0,mid-step)
		var count = min(full_text.length()-start,step*2)
		status_label.text = full_text.substr(start,count)
		await get_tree().create_timer(speed).timeout
	await get_tree().create_timer(5).timeout
	$"../RadioUI/BorderFrame".visible = false
	status_label.text = ""
	banner_bg.visible = false
	is_typing = false

func play_radio_alert():
	if engine_hum:
		var tween = create_tween()
		tween.tween_property(engine_hum,"volume_db",-15.0,0.2)
		await get_tree().create_timer(4.0).timeout
		var return_tween = create_tween()
		return_tween.tween_property(engine_hum,"volume_db",0.0,0.5)
