extends Decal

func _process(delta):

	albedo_mix = 0.5 + (sin(Time.get_ticks_msec() * 0.002) * 0.1)
	size.x += sin(Time.get_ticks_msec() * 0.001) * 0.001
