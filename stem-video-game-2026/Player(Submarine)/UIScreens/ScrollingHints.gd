extends Label

@export var scroll_speed:float = 150

var start_x:float
var end_x:float
# Called when the node enters the scene tree for the first time.
func _ready():
	var parent_width = get_parent().size.x
	start_x = parent_width
	end_x = -self.size.x
	position.x = start_x

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	position.x -= scroll_speed*delta
	if position.x < end_x:
		position.x = start_x
