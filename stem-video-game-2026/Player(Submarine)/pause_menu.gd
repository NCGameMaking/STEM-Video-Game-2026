extends CanvasLayer

@onready var resume_button = $ColorRect/VBoxContainer/ResumeButton
@onready var quit_button = $ColorRect/VBoxContainer/QuitButton
@onready var pause_label = $ColorRect/PauseLabel
@onready var color_rect = $ColorRect

var is_dead:bool = false

func _ready():
	visible = false
	
func _unhandled_input(event: InputEvent):
	if event.is_action_pressed("pause"):
		toggle_pause()
		
func toggle_pause():
	var new_pause_state = not get_tree().paused
	get_tree().paused = new_pause_state
	visible=new_pause_state
	if new_pause_state:
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	else:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


func _on_resume_button_pressed():
	if is_dead == true:
		return
	toggle_pause()

func _on_quit_button_pressed():
	get_tree().paused = false
	get_tree().change_scene_to_file("res://UI/cinematic_menu.tscn")

func trigger_death():
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	is_dead = true
	get_tree().paused
	pause_label.text = "HULL FAILURE : YOU DIED"
	resume_button.visible = false
	self.visible = true
	var rect_tween = create_tween()
	rect_tween.tween_property(color_rect, "color:a",1,1)

func _on_restart_button_pressed():
	get_tree().paused = false
	get_tree().reload_current_scene()
