extends Area3D

@onready var mms_box_highlight = $MMSBoxHighlight

func _on_body_entered(body):
	if body.is_in_group("player") or body.name == "Submarine":
		
		queue_free()

func trigger_mms_scan() -> void:
	if mms_box_highlight:
		mms_box_highlight.visible = true
		var tween = create_tween()
		tween.tween_property(mms_box_highlight, "scale", Vector3(1.2,1.2,1.2),0.2)
		tween.tween_property(mms_box_highlight, "scale", Vector3(1.0,1.0,1.0),0.3)
		
		await get_tree().create_timer(2).timeout
		mms_box_highlight.visible = false
