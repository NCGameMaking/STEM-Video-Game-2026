extends Control

@export var max_sonar_range:float = 200.0
var blip_positions : Array=[]


func _draw():
	var center = size / 2
	var radius = min(size.x,size.y)/2.0
	draw_circle(center,radius,Color(0,0.1,0,0.4))
	draw_arc(center, radius,0, TAU,32, Color(0,1,0,0.8),2.0)
	draw_arc(center,radius*0.66,0,TAU,32,Color(0,0.6,0,0.5),1.0)
	draw_arc(center,radius*0.33,0,TAU,32,Color(0,0.6,0,0.5),1.0)
	
	draw_line(Vector2(center.x,0), Vector2(center.x,size.y), Color(0,0.5, 0,0.5),1.0)
	draw_line(Vector2(0,center.y), Vector2(size.x,center.y), Color(0,0.5, 0,0.5),1.0)
	
	for blip in blip_positions:
		var pos = center + blip.pos
		var blip_color:Color = blip.color
		var is_below:bool= blip.is_below
		if is_below:
			var faded_color = blip_color
			faded_color.a = 0.5
			draw_circle(pos, 4.0, faded_color)
			draw_line(pos,pos+Vector2(0,6),faded_color,1.5)
		else:
			draw_circle(pos,4.0,blip_color)

func update_sonar_blips(detected_nodes:Array, player_transform:Transform3D):
	blip_positions.clear()
	var radius = min(size.x,size.y)/2.0
	for target in detected_nodes:
		var local_pos = player_transform.basis.inverse()* (target.global_position - player_transform.origin)
		var distance = Vector2(local_pos.x, local_pos.z).length()
		
		if distance <= max_sonar_range:
			var norm_dist = (distance/max_sonar_range)*radius
			var angle = atan2(local_pos.x, -local_pos.z)
			var blip_x = sin(angle)*norm_dist
			var blip_y = -cos(angle)*norm_dist
			var is_below = local_pos.y < -70
			
			var target_color = Color(1,0,0,0.9)
			if target.is_in_group("warhead"):
				target_color = Color(1.0,1.0,0.0,0.9)
			blip_positions.append({
				"pos":Vector2(blip_x,blip_y),
				"is_below":is_below,
				"color":target_color
				
			})
	queue_redraw()
