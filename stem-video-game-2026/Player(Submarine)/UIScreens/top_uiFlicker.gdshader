shader_type canvas_item;

uniform sampler2D screen_texture : hint_screen_texture;

void vertex() {
	// Called for every vertex the material is visible on.
}

void fragment() {
	vec4 c = texture(screen_texture, SCREEN_UV);
	
	float flicker = 0.95 + 0.15 * sin(TIME * 40.0);
	COLOR.rgb = c.rgb * flicker;
	COLOR.a = c.a;
}

//void light() {
//	// Called for every pixel for every light affecting the CanvasItem.
//	// Uncomment to replace the default light processing function with this one.
//}
