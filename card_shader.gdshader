shader_type canvas_item;

uniform mat4 rotation;
uniform mat4 projection;

const float hf_w = 60.0;
const float hf_h = 72.0;

void vertex()
{
	vec4 pos = rotation * vec4(VERTEX.xy - vec2(hf_w, hf_h), 0.0, 1.0);
	pos.xyz += vec3(hf_w, hf_h, -hf_h / 0.267949);
	pos.xyz /= vec3(hf_h);
	pos.xy -= 0.5;
	pos = projection * pos;
	pos /= pos.w;
	pos.xy += 0.5;
	pos.xyz *= vec3(hf_h);
	VERTEX = pos.xy;
}

void fragment()
{
	COLOR = texture(TEXTURE, UV);
}
