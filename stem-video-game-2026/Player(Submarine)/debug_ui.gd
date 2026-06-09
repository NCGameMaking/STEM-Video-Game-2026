extends CanvasLayer

@onready var debug_label = $PanelContainer/MarginContainer/DebugLabel

var debug_properties: Dictionary = {}

func _ready():
	visible = true
	
func _process(_delta):
	var text = ""
	# Loop through all properties and format them nicely
	for key in debug_properties.keys():
		text += str(key) + ": " + str(debug_properties[key]) + "\n"
	
	debug_label.text = text

# Call this from any script to update a value on screen
func update_property(property_name: String, value):
	debug_properties[property_name] = value
