shader_type canvas_item;

uniform sampler2D crack_texture;
uniform float fragile_value : hint_range(0,1);
uniform sampler2D shininess_mask_texture;
uniform float shininess_offset : hint_range(0.0, 1.0);

vec4 fragile(vec4 color, vec2 uv)
{
	vec4 crack = texture(crack_texture, uv);
	crack.a *= color.a;
	crack *= fragile_value;
	return vec4(mix(color.rgb, crack.rgb, crack.a), color.a);
}

vec4 shininess(vec4 color, vec2 uv)
{
	vec4 mask = texture(shininess_mask_texture, uv);
	float line_pos = mod(TIME * 0.4 + shininess_offset, 1.0);
	vec2 rotated_uv = vec2(uv.x + uv.y, uv.y - uv.x) * 0.5;
	float line = smoothstep(0.2, 0.0, abs(line_pos - rotated_uv.x));
	line *= mask.a;
	return vec4(mix(color.rgb, vec3(1.0, 1.0, 1.0), line), color.a);
}

void vertex() 
{
	// Called for every vertex the material is visible on.
}

void fragment() 
{
	vec4 tex = texture(TEXTURE, UV);
	COLOR = shininess(tex, UV);
	COLOR = fragile(COLOR, UV);
}

//void light() {
	// Called for every pixel for every light affecting the CanvasItem.
	// Uncomment to replace the default light processing function with this one.
//}
