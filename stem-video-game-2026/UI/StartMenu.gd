extends CanvasLayer

@onready var color_rect = $ColorRect
@onready var start_button = $VBoxContainer/StartButton
@onready var quit = $VBoxContainer/Quit

@onready var brief_label = $BriefLabel
@onready var accept_button = $AcceptButton
@onready var help_button = $VBoxContainer/HelpButton
@onready var help_panel = $HelpPanel

var briefing_text = "OPERATION: ABYSSAL RECOVERY\n\nContact lost with Transport Sub-01. (333m below)\nSix active warheads remain in the wreckage.\nDescend into the trench. Recover the payloads.\n\nBeware of structural collapses."

var debriefing_text = "MISSION ACCOMPLISHED\n\n5 warheads salvaged successfully from trench depths.\nThreat neutralized.\n\n[ RETURNED TO SURFACE ]"
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	help_panel.visible = false
	accept_button.visible = false
	brief_label.visible = false
	start_button.visible = true
	quit.visible = true
	color_rect.modulate.a = 0.0
	start_button.modulate.a = 1.0
	quit.modulate.a = 1.0
	accept_button.modulate.a = 0.0
	
	if Global.show_debrief_on_menu:
		Global.show_debrief_on_menu = false
		trigger_debrief_sequence()

func _on_quit_pressed():
	get_tree().quit()

func _on_start_button_pressed():
	var btn_tween = create_tween()
	btn_tween.tween_property(color_rect,"modulate:a",1.0,2.0)
	await btn_tween.finished
	start_button.queue_free()
	quit.queue_free()
	brief_label.text = briefing_text
	brief_label.visible_characters = 0
	brief_label.visible = true
	var text_tween = create_tween()
	text_tween.tween_property(brief_label,"visible_characters", briefing_text.length(),4.0)
	text_tween.finished.connect(reveal_accept_button)
	
func reveal_accept_button():
	accept_button.visible = true
	var abtn_tween = create_tween()
	abtn_tween.tween_property(accept_button,"modulate:a",1.0,2.0)


func _on_accept_button_pressed():
	if brief_label.text == debriefing_text:
		get_tree().reload_current_scene()
	else:
		get_tree().change_scene_to_file("res://Player(Submarine)/TestScene.tscn")

func trigger_debrief_sequence():
	start_button.visible = false
	quit.visible = false
	color_rect.modulate.a = 1.0
	brief_label.text = debriefing_text
	brief_label.visible_characters = 0
	brief_label.visible = true
	var text_tween = create_tween()
	text_tween.tween_property(brief_label,"visible_characters", debriefing_text.length(),4.0)
	text_tween.finished.connect(reveal_menu_return_button)

func reveal_menu_return_button():
	accept_button.visible = true
	accept_button.text = " [   R E T U R N   T O   M A I N   M E N U   ]"
	var abtn_tween = create_tween()
	abtn_tween.tween_property(accept_button,"modulate:a",1.0,2.0)

func _on_help_button_mouse_entered():
	help_panel.visible = true

func _on_help_button_mouse_exited():
	help_panel.visible = false
