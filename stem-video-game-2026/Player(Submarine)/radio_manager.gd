extends Node3D
class_name RadioHintManager
@onready var objective_target = $"../../WaterShaderExamples/VisibilityRangeLodGroup/SubmarineReal"
@onready var status_label = $"../RadioUI/BannerBackground/StatusLabel"
@onready var banner_bg = $"../RadioUI/BannerBackground"
@onready var warhead_tracker_label = $"../TopViewport/TopUI/RingLabel"

@export var player_sub : Node3D
@export var hint_cooldown : float = 60.0

var is_typing : bool = false
var idle_timer : float = 0.0
var closest_distance_recorded : float = 99999.0
var current_hint_index : int = 0
var warheads_collected : int = 0
var total_warheads : int = 6

var hint_messages : Array[String] = [
	"[ COMMS ] HQ : 'Sub 1, perform an MMS scan to locate the entrance to the lower trench.'",
	"[ COMMS ] HQ : 'Radiation pings indicate the warhead is in the lower trench.'",
	"[ COMMS ] HQ : 'Check your depth gauge. You need to descend into the lower canyon (300m)'"
]

# Called when the node enters the scene tree for the first time.
func _ready():
	update_tracker_ui()
	
	var all_warheads = get_tree().get_nodes_in_group("warheads")
	for warhead in all_warheads:
		warhead.warhead_secured.connect(_on_warhead_secured)
	
	show_text_middle("[ MISSION : LOCATE AND RECOVER 6 WARHEADS ]",0.05)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta :float):
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
	banner_bg.visible = true
	status_label.text=""
	var mid = full_text.length()/2
	var max_steps = max(mid,full_text.length() - mid) +1
	for step in range(1,max_steps + 1):
		var start = max(0,mid-step)
		var count = min(full_text.length()-start,step*2)
		status_label.text = full_text.substr(start,count)
		await get_tree().create_timer(speed).timeout
	await get_tree().create_timer(3).timeout
	status_label.text = ""
	banner_bg.visible = false
	is_typing = false

func _on_warhead_secured():
	warheads_collected +=1
	update_tracker_ui()
	if warheads_collected < total_warheads:
		var remaining = total_warheads - warheads_collected
		var msg = "[ COMMS ] HQ : 'Warhead secured. %s remaining in the trench'" % remaining
	hint_messages.clear()
	idle_timer = -9999
	show_text_middle("[ COMMS ] HQ : 'Target secured. Ascend to surface for immediate EVAC'")
func update_tracker_ui():
		warhead_tracker_label.text = "WARHEADS: %d / %d" % [warheads_collected, total_warheads]
