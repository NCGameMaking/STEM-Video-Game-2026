extends Area3D


func _on_body_entered(body):
	if body.is_in_group("player") or body.name == "Submarine":
		queue_free()
