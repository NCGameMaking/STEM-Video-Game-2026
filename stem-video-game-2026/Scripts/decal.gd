extends Decal

func _process(delta):
	# This slowly shifts the texture so the light "waves"
	# Tweak the 0.1 and 0.05 to change the speed
	albedo_mix = 0.5 + (sin(Time.get_ticks_msec() * 0.002) * 0.1)
	size.x += sin(Time.get_ticks_msec() * 0.001) * 0.001
