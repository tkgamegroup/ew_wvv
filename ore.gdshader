shader_type canvas_item;

uniform sampler2D crack_texture;
uniform float fragile : hint_range(0, 1);
uniform sampler2D acid_texture;
uniform float acid : hint_range(0, 1);
uniform sampler2D shininess_mask_texture;
uniform float shininess_offset : hint_range(0.0, 1.0);

vec4 fragile_effect(vec4 color, vec2 uv)
{
	vec4 crack_img = texture(crack_texture, uv);
	crack_img.a *= color.a;
	crack_img *= fragile;
	return vec4(mix(color.rgb, crack_img.rgb, crack_img.a), color.a);
}

vec4 acid_effect(vec4 color, vec2 uv)
{
	vec4 acid_img = texture(acid_texture, uv);
	acid_img.a *= color.a;
	acid_img *= color.a * acid;
	return vec4(color.rgb * (1.0 - acid * 0.2) + acid_img.rgb * 0.5, color.a);
}

vec4 shininess_effect(vec4 color, vec2 uv)
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
	COLOR = shininess_effect(tex, UV);
	COLOR = acid_effect(COLOR, UV);
	COLOR = fragile_effect(COLOR, UV);
}

//void light() {
	// Called for every pixel for every light affecting the CanvasItem.
	// Uncomment to replace the default light processing function with this one.
//}
