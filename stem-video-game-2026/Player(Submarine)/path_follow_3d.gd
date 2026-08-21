extends PathFollow3D



# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	progress += 20*delta
